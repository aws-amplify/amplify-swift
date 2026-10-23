//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient
import Security
import XCTest

/// `.default` after the app's configuration changes (CS-D1 … CS-D3, and the static calls): the Auth plugin's own
/// rule, where named sessions keep each configuration's login (CS-1 … CS-3).
///
/// `.default`'s session record is the plugin's `amplify.<ns>.session`, and the plugin records the
/// configuration it last ran with in one `authConfiguration` item. On a restore `.default` runs the plugin's decision
/// from that item to the current configuration, then records the current one: an identity pool added, changed or
/// removed under the same user pool, app client and region **carries** the record as its bytes are, the old
/// identity ID included, and keeps the old one; any other change of the key **deletes** the old record and its
/// sidecar, revoking it only when the user pool is the same. The static `signOutStoredSession` and
/// `purgeStoredSession` apply the rule only when it carries, so one called with another configuration never
/// deletes the app's login.
///
/// These tests own `.default`'s items for every configuration they use, and the service's single
/// `authConfiguration` item: each removes them before it starts and at teardown, so no other suite's state is read.
/// CS-D1 and CS-D3 refresh a carried record, which leaves the old namespace's device record behind, so they run on a
/// role whose pool does not track devices (`untrackedFederatedRole()`, R-UP′ and R-IP′), as CS-2 and CS-3 do.
extension StorageConfigurationTests {

    /// CS-D1. `.default` carries its record when an identity pool is added, as the plugin does, and keeps the old one.
    ///
    /// - Given: alice signed in on `.default` over R-UP′ alone, then released, so `authConfiguration` records that
    ///   user-pool-only configuration
    /// - When:
    ///    - a client on `.default` over R-UP′ + R-IP′ (the role's outputs), the recorder installed, reads its state,
    ///      then fetches its session
    /// - Then:
    ///    - the restore carried the record offline: `.signedIn(alice)` with no request, and the new namespace's record
    ///      holds the old one's bytes, as they were
    ///    - the fetch returns alice's tokens, and an identity and AWS credentials fetched on first use (a
    ///      `userPoolOnly` record under an identity pool configuration is waiting for its identity)
    ///    - the old record is kept, as the plugin keeps it; the sidecar went along; `authConfiguration` now records
    ///      the new configuration
    ///
    func testDefaultSessionIsCarriedWhenAnIdentityPoolIsAdded() async throws {
        let role = try IntegrationTestEnvironment.untrackedFederatedRole()
        let federated = try IntegrationTestEnvironment.configuration(role)
        let userPoolOnly = try AuthClientConfiguration(userPool: federated.userPool)
        try isolateDefaultSession(over: [userPoolOnly, federated])
        let user = try await makeFreshUser(on: role).testUser
        removeDeviceRecordsAtTeardown(of: user, under: [userPoolOnly, federated])
        let alice = try await signInDefault(user, over: userPoolOnly)
        let oldAccount = SessionRecordKey.pluginSessionAccount(in: userPoolOnly.poolNamespace)
        let newAccount = SessionRecordKey.pluginSessionAccount(in: federated.poolNamespace)
        let oldBytes = try XCTUnwrap(Self.storedValue(oldAccount), "alice's sign-in wrote no record")
        XCTAssertTrue(Self.storedValue(newAccount) == nil, "the new namespace already has a record")
        XCTAssertTrue(try Self.recordsConfiguration(of: userPoolOnly), "authConfiguration does not record the first configuration")

        let recorder = RecordingHTTPClient()
        do {
            let client = try AmplifyCognitoClient(
                configuration: federated,
                options: .init(sessionId: .default, configureUserPoolClient: recorder.configureUserPoolClient)
            )
            let state = await client.currentSessionState()
            XCTAssertState(state, .signedIn(alice), "the record is carried forward")
            XCTAssertEqual(recorder.operations, [], "restoring makes no request")
            XCTAssertTrue(Self.storedValue(newAccount) == oldBytes, "the record is carried as its bytes are")

            let session = try await client.fetchAuthSession()

            let sub = try IntegrationTestEnvironment.jwtClaims(session.userPoolTokensResult.get().idToken)["sub"] as? String
            XCTAssertTrue(sub == alice.userId, "alice's tokens")
            XCTAssertNoThrow(try session.identityIdResult.get(), "the identity is fetched on first use")
            XCTAssertNoThrow(try session.awsCredentialsResult.get(), "with its AWS credentials")
        }
        try await SessionCleanup.waitUntilReleased([.default])

        XCTAssertTrue(Self.storedValue(oldAccount) == oldBytes, "the old record is kept, as the plugin keeps it")
        XCTAssertTrue(Self.storedValue(SessionRecordKey.metaAccount(in: federated.poolNamespace)) != nil, "the sidecar went with the record")
        XCTAssertTrue(try Self.recordsConfiguration(of: federated), "authConfiguration does not record the new configuration")
    }

    /// CS-D2. `.default` deletes its record when the user pool changes, as the plugin does, and does not revoke it.
    ///
    /// - Given: alice signed in on `.default` over the default backend (R-UP + R-IP), her refresh token and device
    ///   key noted, then released
    /// - When:
    ///    - a client on `.default` over another user pool (the untracked role's R-UP′ + R-IP′), the recorder
    ///      installed, reads its state
    ///    - then a client on `.default` over the default backend again reads its state
    /// - Then:
    ///    - over the other user pool, `.default` is `.signedOut`, with no request
    ///    - alice's record is deleted, with its sidecar, and `authConfiguration` records the other configuration
    ///    - her refresh token was not revoked (the user pool is not the same): Cognito still refreshes it. The
    ///      test revokes it at teardown
    ///    - back on the default backend, `.default` stays signed out, and no `.default` row is listed
    ///
    func testDefaultSessionIsDeletedWhenTheUserPoolChanges() async throws {
        let standard = try IntegrationTestEnvironment.configuration()
        let other = try IntegrationTestEnvironment.configuration(IntegrationTestEnvironment.untrackedFederatedRole())
        XCTAssertFalse(standard.userPool?.poolId == other.userPool?.poolId, "the untracked role shares the default user pool")
        try isolateDefaultSession(over: [standard, other])
        let raw = try RawUserPool()
        let alice = try await makeSignInUser()
        removeDeviceRecordsAtTeardown(of: alice, under: [standard, other])
        let (user, tokens) = try await signInDefaultKeepingTokens(alice, over: standard)
        let refreshToken = tokens.refreshToken
        addTeardownBlock { try? await raw.revoke(refreshToken) }
        let oldAccount = SessionRecordKey.pluginSessionAccount(in: standard.poolNamespace)
        let oldSidecar = SessionRecordKey.metaAccount(in: standard.poolNamespace)
        XCTAssertTrue(Self.storedValue(oldAccount) != nil, "alice's sign-in wrote no record")
        XCTAssertTrue(Self.storedValue(oldSidecar) != nil, "alice's sign-in wrote no sidecar")

        let recorder = RecordingHTTPClient()
        do {
            let client = try AmplifyCognitoClient(
                configuration: other,
                options: .init(sessionId: .default, configureUserPoolClient: recorder.configureUserPoolClient)
            )
            let state = await client.currentSessionState()
            XCTAssertState(state, .signedOut, "another user pool's login is not carried")
            XCTAssertEqual(recorder.operations, [], "restoring makes no request")
        }
        try await SessionCleanup.waitUntilReleased([.default])

        XCTAssertTrue(Self.storedValue(oldAccount) == nil, "the old record is deleted, as the plugin deletes it")
        XCTAssertTrue(Self.storedValue(oldSidecar) == nil, "the old record's sidecar is deleted with it")
        XCTAssertTrue(try Self.recordsConfiguration(of: other), "authConfiguration does not record the new configuration")
        let refreshed = await raw.refresh(refreshToken, deviceKey: RawUserPool.deviceKey(of: tokens.accessToken))
        if case .failure(let error) = refreshed {
            XCTFail("another user pool's deleted login should not be revoked: \(type(of: error))")
        }

        do {
            let client = try AmplifyCognitoClient(configuration: standard, options: .init(sessionId: .default))
            let state = await client.currentSessionState()
            XCTAssertState(state, .signedOut, "the deleted login does not come back on the old configuration")
            XCTAssertFalse(state == .signedIn(user), "alice is back")
        }
        try await SessionCleanup.waitUntilReleased([.default])
        let listed = try await AmplifyCognitoClient.storedSessions(configuration: standard, includingSignedOut: true)
        XCTAssertFalse(listed.contains { $0.sessionId == .default }, "a `.default` row is listed for the deleted login")
    }

    /// CS-D3. `.default` carries the old identity ID across a changed identity pool, as the plugin does.
    ///
    /// The contrast with CS-3, where a named session carries user pool tokens only. What the carried identity ID does
    /// next is the engine's reading, confirmed here against real Cognito: `GetCredentialsForIdentity` names no
    /// pool, so while the old identity pool exists the carried session keeps getting that pool's credentials. (Once
    /// Cognito refuses the ID, the old pool deleted, the engine calls `GetId` on the new pool; that half cannot be
    /// provoked on a live backend and stays pinned by the unit tests.)
    ///
    /// - Given: alice signed in on `.default` over R-UP′ + R-IP′, her identity ID and access key ID noted, then
    ///   released
    /// - When:
    ///    - a client on `.default` over R-UP′ + R-IP2 (only the identity pool changed; R-IP2 does not federate
    ///      R-UP′), the recorder installed, reads its state, fetches its session, then force-refreshes it
    /// - Then:
    ///    - the restore carried the record offline: `.signedIn(alice)` with no request, and the new namespace's
    ///      record holds the old one's bytes, R-IP′'s identity ID included; the old record is kept
    ///    - the fetch reports R-IP′'s identity ID, carried, not a new one
    ///    - the forced refresh still gets AWS credentials for that identity ID, new ones (a new access key ID), and
    ///      keeps the identity ID
    ///
    func testDefaultSessionCarriesItsIdentityIdWhenTheIdentityPoolChanges() async throws {
        let role = try IntegrationTestEnvironment.untrackedFederatedRole()
        let federated = try IntegrationTestEnvironment.configuration(role)
        let otherIdentityPool = try AuthClientConfiguration(
            userPool: federated.userPool,
            identityPool: IntegrationTestEnvironment.secondIdentityPool(besides: federated.identityPool?.poolId)
        )
        XCTAssertFalse(federated.poolNamespace == otherIdentityPool.poolNamespace, "the identity pool did not change")
        try isolateDefaultSession(over: [federated, otherIdentityPool])
        let user = try await makeFreshUser(on: role).testUser
        removeDeviceRecordsAtTeardown(of: user, under: [federated, otherIdentityPool])
        let (alice, identityId, accessKeyId) = try await signInDefaultWithIdentity(user, over: federated)
        let oldAccount = SessionRecordKey.pluginSessionAccount(in: federated.poolNamespace)
        let newAccount = SessionRecordKey.pluginSessionAccount(in: otherIdentityPool.poolNamespace)
        let oldBytes = try XCTUnwrap(Self.storedValue(oldAccount), "alice's sign-in wrote no record")

        let recorder = RecordingHTTPClient()
        do {
            let client = try AmplifyCognitoClient(
                configuration: otherIdentityPool,
                options: .init(sessionId: .default, configureUserPoolClient: recorder.configureUserPoolClient)
            )
            let state = await client.currentSessionState()
            XCTAssertState(state, .signedIn(alice), "the record is carried forward")
            XCTAssertEqual(recorder.operations, [], "restoring makes no request")
            XCTAssertTrue(Self.storedValue(newAccount) == oldBytes, "the record, its identity ID included, is carried as its bytes are")

            let carried = try await client.fetchAuthSession()
            XCTAssertTrue(try carried.identityIdResult.get() == identityId, "the carried identity ID is R-IP′'s")

            let refreshed = try await client.fetchAuthSession(options: .init(forceRefresh: true))
            XCTAssertTrue(try refreshed.identityIdResult.get() == identityId, "the forced refresh keeps the carried identity ID")
            XCTAssertTrue(
                try refreshed.awsCredentialsResult.get().accessKeyId != accessKeyId,
                "the forced refresh got no new AWS credentials for the carried identity ID"
            )
        }
        try await SessionCleanup.waitUntilReleased([.default])
        XCTAssertTrue(Self.storedValue(oldAccount) == oldBytes, "the old record is kept, as the plugin keeps it")
    }

    /// A static `signOutStoredSession` or `purgeStoredSession` for `.default` with another configuration leaves
    /// the app's login alone.
    ///
    /// The plugin runs its rule only when the app is configured, under the configuration it then runs with. The static
    /// calls may be given any configuration, so they apply the rule only when it would carry; here it would delete.
    ///
    /// - Given: alice signed in on `.default` over the default backend, then released, so `authConfiguration` records
    ///   that configuration; and a configuration with another user pool, which nothing has used
    /// - When:
    ///    - `signOutStoredSession(sessionId: .default, configuration:)` with the other configuration
    ///    - then `purgeStoredSession(sessionId: .default, configuration:)` with it
    /// - Then:
    ///    - the sign-out is `.complete`: the other configuration has nothing to sign out
    ///    - alice's record and sidecar are byte-for-byte unchanged, `authConfiguration` still records the default
    ///      backend's configuration, and nothing was written under the other configuration
    ///    - a client on `.default` over the default backend restores `.signedIn(alice)`, with no request
    ///
    func testStaticCallsWithAnotherConfigurationLeaveTheAppsLoginAlone() async throws {
        let standard = try IntegrationTestEnvironment.configuration()
        let userPool = try XCTUnwrap(standard.userPool)
        // Made up, never contacted: nothing is stored under it, so nothing is revoked.
        let other = try AuthClientConfiguration(userPool: .init(poolId: "\(userPool.region)_C26Other0", appClientId: "c26otherclient", region: userPool.region))
        try isolateDefaultSession(over: [standard, other])
        let user = try await makeSignInUser()
        removeDeviceRecordsAtTeardown(of: user, under: [standard])
        let alice = try await signInDefault(user, over: standard)
        let record = SessionRecordKey.pluginSessionAccount(in: standard.poolNamespace)
        let sidecar = SessionRecordKey.metaAccount(in: standard.poolNamespace)
        let recordBytes = try XCTUnwrap(Self.storedValue(record), "alice's sign-in wrote no record")
        let sidecarBytes = try XCTUnwrap(Self.storedValue(sidecar), "alice's sign-in wrote no sidecar")

        let signOut = await AmplifyCognitoClient.signOutStoredSession(sessionId: .default, configuration: other)
        try await AmplifyCognitoClient.purgeStoredSession(sessionId: .default, configuration: other)

        XCTAssertSignOutComplete(signOut, "the other configuration's sign-out")
        XCTAssertTrue(Self.storedValue(record) == recordBytes, "a static call with another configuration changed the app's login")
        XCTAssertTrue(Self.storedValue(sidecar) == sidecarBytes, "a static call with another configuration changed the sidecar")
        XCTAssertTrue(try Self.recordsConfiguration(of: standard), "a static call with another configuration rewrote authConfiguration")
        for account in Self.defaultSessionAccounts(of: other) {
            XCTAssertTrue(Self.storedValue(account) == nil, "a static call wrote under the other configuration")
        }
        let recorder = RecordingHTTPClient()
        do {
            let client = try AmplifyCognitoClient(
                configuration: standard,
                options: .init(sessionId: .default, configureUserPoolClient: recorder.configureUserPoolClient)
            )
            let state = await client.currentSessionState()
            XCTAssertState(state, .signedIn(alice), "the app's login is still signed in")
            XCTAssertEqual(recorder.operations, [], "restoring makes no request")
        }
        try await SessionCleanup.waitUntilReleased([.default])
    }

    // MARK: - `.default` helpers

    /// `.default`'s items under `configuration`: the plugin's record, the sidecar and the interrupted sign-in.
    private static func defaultSessionAccounts(of configuration: AuthClientConfiguration) -> [String] {
        let pools = configuration.poolNamespace
        return [
            SessionRecordKey.pluginSessionAccount(in: pools),
            SessionRecordKey.metaAccount(in: pools),
            SessionRecordKey.account(for: .default, in: pools, kind: .challenge)
        ]
    }

    /// Removes `.default`'s items under every one of `configurations`, and `authConfiguration`, now and at teardown,
    /// so the test reads only what it wrote. The users are fresh and deleted at teardown, which ends their tokens.
    private func isolateDefaultSession(over configurations: [AuthClientConfiguration]) throws {
        let accounts = configurations.flatMap(Self.defaultSessionAccounts(of:)) + [SessionRecordStore.pluginConfigurationAccount]
        try Self.deleteAccounts(accounts)
        addTeardownBlock {
            try await SessionCleanup.waitUntilReleased([.default])
            try Self.deleteAccounts(accounts)
        }
    }

    /// Removes `user`'s device and advanced-security records under each of `configurations` at teardown, as
    /// `DeviceTestCase` does: the client keeps them per user and never removes them itself.
    private func removeDeviceRecordsAtTeardown(of user: TestUser, under configurations: [AuthClientConfiguration]) {
        let username = user.username
        let namespaces = configurations.map(\.poolNamespace)
        addTeardownBlock {
            for pools in namespaces {
                let store = DeviceRecordStore(namespace: SessionStorageNamespace(pools: pools, accessGroup: nil))
                try store.removeDeviceMetadata(for: username)
                try store.removeASFDeviceId(for: username)
            }
        }
    }

    /// Signs `user` in on `.default` over `configuration`, returns the signed-in user, and releases the session.
    private func signInDefault(_ user: TestUser, over configuration: AuthClientConfiguration) async throws -> AuthClientUser {
        try await signInDefaultKeepingTokens(user, over: configuration).user
    }

    /// Signs `user` in on `.default` over `configuration`, returns the signed-in user and the session's tokens (never
    /// printed), and releases the session.
    private func signInDefaultKeepingTokens(
        _ user: TestUser,
        over configuration: AuthClientConfiguration
    ) async throws -> (user: AuthClientUser, tokens: AuthClientUserPoolTokens) {
        let signedIn: (AuthClientUser, AuthClientUserPoolTokens)
        do {
            let client = try AmplifyCognitoClient(configuration: configuration, options: .init(sessionId: .default))
            let result = try await client.signIn(username: user.username, password: user.password)
            XCTAssertStep(result.nextStep, .done)
            signedIn = try await (client.getCurrentUser(), client.fetchAuthSession().userPoolTokensResult.get())
        }
        try await SessionCleanup.waitUntilReleased([.default])
        return signedIn
    }

    /// Signs `user` in on `.default` over a configuration with an identity pool, returns the user, its identity ID and
    /// its AWS access key ID (compared, never printed), and releases the session.
    private func signInDefaultWithIdentity(
        _ user: TestUser,
        over configuration: AuthClientConfiguration
    ) async throws -> (AuthClientUser, String, String) {
        let signedIn: (AuthClientUser, String, String)
        do {
            let client = try AmplifyCognitoClient(configuration: configuration, options: .init(sessionId: .default))
            let result = try await client.signIn(username: user.username, password: user.password)
            XCTAssertStep(result.nextStep, .done)
            let session = try await client.fetchAuthSession()
            signedIn = try await (
                client.getCurrentUser(),
                session.identityIdResult.get(),
                session.awsCredentialsResult.get().accessKeyId
            )
        }
        try await SessionCleanup.waitUntilReleased([.default])
        return signedIn
    }

    /// Whether `authConfiguration` is present and records `configuration`'s namespace, as `.default` reads it.
    private static func recordsConfiguration(of configuration: AuthClientConfiguration) throws -> Bool {
        let store = SessionRecordStore(namespace: SessionStorageNamespace(pools: configuration.poolNamespace, accessGroup: nil))
        return try store.previousPluginConfiguration() != nil && store.pluginConfigurationSource() == nil
    }

    /// The stored value of `account` in the session service, or `nil` if it is absent. Compared, never printed: assert
    /// on it with booleans only (`== nil`, `==`), since `XCTAssertNil` and `XCTAssertEqual` print it, and a record holds
    /// tokens.
    private static func storedValue(_ account: String) -> String? {
        RealKeychain.rows(service: IntegrationTestEnvironment.sessionService).first { $0.account == account }?.value
    }

    /// Deletes each of `accounts` from the session service, in every access group. Absent is fine.
    private static func deleteAccounts(_ accounts: [String]) throws {
        for account in accounts {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: IntegrationTestEnvironment.sessionService,
                kSecAttrAccount as String: account,
                kSecUseDataProtectionKeychain as String: true
            ]
            let status = SecItemDelete(query as CFDictionary)
            guard status == errSecSuccess || status == errSecItemNotFound else {
                throw HarnessError.malformedFixture(RealKeychain.redact("Deleting \(account) returned \(RealKeychain.describe(status))."))
            }
        }
    }
}
