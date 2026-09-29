//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient
import AmplifyFoundation
import XCTest

/// What a stored session looks like after the app's configuration or keychain access group changes: the
/// plugin's `CredentialStoreConfigurationTests`, over real sign-ins and guest sessions instead of the
/// plugin's test data.
///
/// **Pool changes.** A client record's key embeds the pool namespace: the user pool ID, the identity pool
/// ID, or both (`amplify.1.<ns>.<sessionId>.session`). Adding a pool, or changing one, is a new namespace.
/// The client carries a session forward as the plugin does (`SessionRecordStore+CopyForward.swift`; this
/// replaced an earlier "no carry-over" default): identity
/// pool only → user pool added carries the guest as it is; user pool only → identity pool added
/// carries the signed-in user, whose identity is fetched on first use; a changed identity pool
/// beside the same user pool carries the user pool tokens only, where the plugin also carries the old
/// pool's identity (a deliberate difference); an identity-pool-only configuration
/// whose identity pool changed carries nothing (the plugin clears its record). The
/// old record is kept, as the plugin keeps it (an extension still on the old configuration may be reading it),
/// and a sign-out or purge deletes it only while it is untouched since the carry.
///
/// **Access groups.** A record lives in one keychain access group. With no migration, a client in another
/// group does not see it. The plugin's access-group migrations have no client counterpart, so they are
/// not ported.
///
/// **Pools.** `standard` is the default backend's outputs: its user pool (R-UP here) and its identity pool
/// (R-IP), which federates it. The identity-only role (R-IP2 in CS-1) is R-IP alone, derived from the same
/// outputs without the user pool (`IntegrationTestEnvironment.identityOnlyAuthSection()`). CS-2 and CS-3
/// refresh a session carried to a new namespace, which leaves its device record behind, so they run on a
/// role whose pool does not track devices (`untrackedFederatedRole()`: its user pool R-UP′, its identity pool
/// R-IP′); CS-3's R-IP2 is a second identity pool, with guest access, that does not federate R-UP′
/// (`secondIdentityPool(besides:)`: another backend's, or the credentials file's `second_identity_pool_id`).
/// The access-group rows use `standard`. Gen2 outputs require
/// `auth.user_pool_id` (the plugin's `AmplifyOutputsData.Auth` requires it too), so identity-pool-only
/// configurations are built with the programmatic initializer, as an app with an identity pool only would
/// build them. `alice` and `bob` are fresh users each test signs up (`makeSignInUser()`).
final class StorageConfigurationTests: ClientIntegrationTestCase {

    /// The default backend's outputs: R-UP and R-IP.
    private var standard: AuthClientConfiguration!

    override func setUp() async throws {
        try await super.setUp()
        standard = try IntegrationTestEnvironment.configuration()
    }

    // MARK: - Pool changes

    /// A guest record from an identity-pool-only configuration survives adding a user pool: it is carried
    /// forward with its identity and credentials (CS-1; the plugin's
    /// `testCredentialsMigratedOnValidConfigurationChange`).
    ///
    /// - Given: a session made a guest by `fetchAuthSession()` over R-IP2 alone, its identity ID and access
    ///   key ID noted, then released
    /// - When:
    ///    - the configuration gains R-UP (R-UP + R-IP2), and a client over the same session ID, the recorder
    ///      installed, reads its state and fetches its session
    /// - Then:
    ///    - it is `.guest`, and the fetch returns the same identity ID and the same AWS credentials (access key
    ///      ID): nothing was fetched again, since a new `GetId` or `GetCredentialsForIdentity` mints new ones
    ///    - no user pool request was made
    ///    - the old record is kept, as the plugin keeps it: the identity-pool-only configuration still lists the
    ///      session as a guest
    ///
    func testGuestRecordSurvivesAddingAUserPool() async throws {
        let identityOnly = try Self.identityOnlyConfiguration()
        let withUserPool = try AuthClientConfiguration(userPool: standard.userPool, identityPool: identityOnly.identityPool)
        let sessionId = try tracked("guest-add-up", in: [identityOnly, withUserPool])
        let original = try await guest(sessionId, over: identityOnly)

        let recorder = RecordingHTTPClient()
        let carried: AWSGuest
        do {
            let client = try AmplifyCognitoClient(
                configuration: withUserPool,
                options: .init(sessionId: sessionId, configureUserPoolClient: recorder.configureUserPoolClient)
            )
            let state = await client.currentSessionState()
            XCTAssertState(state, .guest, "the guest is carried forward")
            let session = try await client.fetchAuthSession()
            carried = try AWSGuest(session)
        }
        try await SessionCleanup.waitUntilReleased([sessionId])

        XCTAssertTrue(carried.identityId == original.identityId, "the same guest identity")
        XCTAssertTrue(carried.accessKeyId == original.accessKeyId, "the same AWS credentials, not fetched again")
        XCTAssertEqual(recorder.operations, [], "no user pool request")
        let old = try await AmplifyCognitoClient.storedSessions(configuration: identityOnly, includingSignedOut: true)
        XCTAssertEqual(old.first { $0.sessionId == sessionId }?.kind, .guest, "the old record is kept")
    }

    /// A user-pool-only session is kept when an identity pool is added: it is carried forward signed in, and
    /// its identity is fetched on first use (CS-2; the plugin's
    /// `testCredentialsMigratedOnNotSupportedConfigurationChange`).
    ///
    /// Run on a role whose user pool does not track devices (`untrackedFederatedRole()`, R-UP′ and R-IP′ here):
    /// device records stay in the namespace that wrote them, so on a pool that tracks devices the carried
    /// session's refresh would be refused for want of the device key.
    ///
    /// - Given: alice signed in over R-UP′ alone, then every handle dropped
    /// - When:
    ///    - the configuration gains R-IP′ (the role's outputs), and a client over the same session ID,
    ///      the recorder installed, reads its state, then fetches its session
    /// - Then:
    ///    - the state is `.signedIn(alice)` with no request: the restore carried the record offline
    ///    - the fetch returns alice's tokens, an identity and AWS credentials; fetching the identity took one
    ///      `GetTokensFromRefreshToken` (the engine's refresh of user-pool-only credentials, with an identity
    ///      pool configured, fetches the identity)
    ///    - the old record is kept, as the plugin keeps it: the user-pool-only namespace still holds it (read raw)
    ///
    func testAddingAnIdentityPoolKeepsTheUserPoolSession() async throws {
        let role = try IntegrationTestEnvironment.untrackedFederatedRole()
        let federated = try IntegrationTestEnvironment.configuration(role)
        let userPoolOnly = try AuthClientConfiguration(userPool: federated.userPool)
        let sessionId = try tracked("alice-add-ip", in: [userPoolOnly, federated])
        let alice = try await signIn(makeFreshUser(on: role).testUser, on: sessionId, over: userPoolOnly)

        let recorder = RecordingHTTPClient()
        do {
            let client = try AmplifyCognitoClient(
                configuration: federated,
                options: .init(sessionId: sessionId, configureUserPoolClient: recorder.configureUserPoolClient)
            )
            let state = await client.currentSessionState()
            XCTAssertState(state, .signedIn(alice), "the session is carried forward")
            XCTAssertEqual(recorder.operations, [], "restoring makes no request")

            let session = try await client.fetchAuthSession()

            let sub = try IntegrationTestEnvironment.jwtClaims(session.userPoolTokensResult.get().idToken)["sub"] as? String
            XCTAssertTrue(sub == alice.userId, "alice's tokens")
            XCTAssertNoThrow(try session.identityIdResult.get(), "the identity is fetched on first use")
            XCTAssertNoThrow(try session.awsCredentialsResult.get(), "with its AWS credentials")
            XCTAssertEqual(recorder.operations, ["GetTokensFromRefreshToken"])
        }
        try await SessionCleanup.waitUntilReleased([sessionId])

        let oldAccount = SessionRecordKey.account(for: sessionId, in: userPoolOnly.poolNamespace, kind: .session)
        XCTAssertTrue(try IntegrationTestEnvironment.rawKeychainAccounts().contains(oldAccount), "the old record is kept")
    }

    /// A changed identity pool never sees the old guest record, nor a signed-in session's identity
    /// (CS-3; the plugin's `testCredentialsMigratedOnNotSupportedIdentityPoolConfigurationChange`).
    ///
    /// Run, as CS-2, on a role whose user pool does not track devices (R-UP′ and R-IP′), with a second
    /// identity pool (R-IP2) that does not federate it.
    ///
    /// - Given: a session made a guest over R-IP2 alone, and alice signed in on another session over R-UP′ +
    ///   R-IP′ with her identity ID noted, both released
    /// - When:
    ///    - the guest session is read over R-IP′ alone, and alice's over R-UP′ + R-IP2 (only the identity pool
    ///      changed)
    /// - Then:
    ///    - both configurations are a different namespace from the one that wrote the record (the key embeds
    ///      the identity pool ID even beside a user pool)
    ///    - identity pool only, changed: nothing is carried, and the old guest record is kept (the plugin clears
    ///      it; the client keeps it, as an app may switch configurations at runtime). The guest session reads
    ///      `.signedOut`, its provider throws `.notSignedIn`, no row is listed, and its first fetch acquires a
    ///      new identity
    ///    - user pool beside a changed identity pool: alice is carried, `.signedIn(alice)` with no request, and
    ///      her token provider returns her access token. Only the tokens are carried, never R-IP′'s identity
    ///      (where the plugin's `:138` branch copies it): the carried record holds `userPoolOnly` credentials,
    ///      the old record is kept, and her session's fetch never reports that identity. R-IP2 does not
    ///      federate R-UP′, so the identity fetch fails: her tokens and sub still succeed, and a second fetch
    ///      makes no request (the failure is not retried on every call)
    ///
    func testChangedIdentityPoolDoesNotSeeTheOldGuestRecord() async throws {
        let role = try IntegrationTestEnvironment.untrackedFederatedRole()
        let federated = try IntegrationTestEnvironment.configuration(role)
        let identityOnly = try AuthClientConfiguration(
            identityPool: IntegrationTestEnvironment.secondIdentityPool(besides: federated.identityPool?.poolId)
        )
        let otherIdentityOnly = try AuthClientConfiguration(identityPool: federated.identityPool)
        let otherIdentityPool = try AuthClientConfiguration(userPool: federated.userPool, identityPool: identityOnly.identityPool)
        XCTAssertFalse(identityOnly.poolNamespace == otherIdentityOnly.poolNamespace, "identity pool only")
        XCTAssertFalse(federated.poolNamespace == otherIdentityPool.poolNamespace, "user pool and identity pool")
        let guestId = try tracked("guest-change-ip", in: [identityOnly, otherIdentityOnly])
        let aliceId = try tracked("alice-change-ip", in: [federated, otherIdentityPool])
        let original = try await guest(guestId, over: identityOnly)
        let aliceCredentials = try await makeFreshUser(on: role).testUser
        let (alice, aliceIdentity) = try await signInWithIdentity(aliceCredentials, on: aliceId, over: federated)

        try await assertSignedOutWithNoRow(guestId, over: otherIdentityOnly, "after the identity pool changed")
        let oldStore = SessionRecordStore(namespace: SessionStorageNamespace(pools: identityOnly.poolNamespace, accessGroup: nil))
        guard case .record(let kept) = try oldStore.read(guestId) else {
            return XCTFail("the old guest record is kept (the plugin clears it)")
        }
        XCTAssertEqual(kept.record.kind, .guest)
        XCTAssertTrue(kept.record.credentials.flatMap(CredentialSlot.identityId) == original.identityId, "with its identity")
        let replacement = try await guest(guestId, over: otherIdentityOnly)
        XCTAssertFalse(replacement.identityId == original.identityId, "the changed identity pool acquires its own identity")

        let recorder = RecordingHTTPClient()
        do {
            let client = try AmplifyCognitoClient(
                configuration: otherIdentityPool,
                options: .init(sessionId: aliceId, configureUserPoolClient: recorder.configureUserPoolClient)
            )
            let state = await client.currentSessionState()
            XCTAssertState(state, .signedIn(alice), "the user pool session is carried forward")
            XCTAssertEqual(recorder.operations, [], "restoring makes no request")
            let token = try await client.userPoolTokenProvider.accessToken()
            XCTAssertTrue(
                try IntegrationTestEnvironment.jwtClaims(token)["username"] as? String == aliceCredentials.username,
                "the carried token is alice's"
            )
            try Self.assertCarriedTokensOnly(aliceId, under: otherIdentityPool, keptUnder: federated)

            let first = try await client.fetchAuthSession()
            recorder.reset()
            let second = try await client.fetchAuthSession()

            for session in [first, second] {
                XCTAssertFalse((try? session.identityIdResult.get()) == aliceIdentity, "R-IP's identity is never carried")
                // R-IP2 does not federate R-UP, so the lazy identity fetch fails there: only the identity.
                XCTAssertThrowsError(try session.identityIdResult.get())
                let sub = try IntegrationTestEnvironment.jwtClaims(session.userPoolTokensResult.get().idToken)["sub"] as? String
                XCTAssertTrue(sub == alice.userId, "the tokens still succeed")
                XCTAssertTrue(try session.userSubResult.get() == alice.userId, "the sub still succeeds")
            }
            XCTAssertEqual(recorder.operations, [], "a permanent identity failure is not retried on every call")
        }
        try await SessionCleanup.waitUntilReleased([aliceId])
    }

    /// The carried record under `pools` holds user pool tokens only (the plugin's stored format
    /// `{"userPoolOnly": …}`, no identity ID and no AWS credentials), and the record under `old` is kept.
    private static func assertCarriedTokensOnly(
        _ sessionId: SessionID,
        under pools: AuthClientConfiguration,
        keptUnder old: AuthClientConfiguration,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let store = SessionRecordStore(namespace: SessionStorageNamespace(pools: pools.poolNamespace, accessGroup: nil))
        guard case .record(let envelope) = try store.read(sessionId), let credentials = envelope.record.credentials else {
            return XCTFail("no carried record", file: file, line: line)
        }
        let payload = try XCTUnwrap(JSONSerialization.jsonObject(with: credentials) as? [String: Any], file: file, line: line)
        XCTAssertEqual(Array(payload.keys), ["userPoolOnly"], "the carried payload holds the user pool tokens only", file: file, line: line)
        let oldAccount = SessionRecordKey.account(for: sessionId, in: old.poolNamespace, kind: .session)
        XCTAssertTrue(try IntegrationTestEnvironment.rawKeychainAccounts().contains(oldAccount), "the old record is kept", file: file, line: line)
    }

    // MARK: - Access groups

    /// A session in the default access group is not visible from the shared group (CS-4; the
    /// plugin's `testCredentialsDoNotRemainOnNonMigrationToSharedAccessGroup`).
    ///
    /// - Given: alice signed in on a session in the default group, then released
    /// - When:
    ///    - a client over the same session ID in `…Shared` reads it, and the shared group is listed
    /// - Then:
    ///    - it reads `.signedOut`, `getCurrentUser()` and its provider fail as not signed in, and the shared
    ///      listing has no row for the session
    ///    - the default group still lists it for alice
    ///
    func testSessionInTheDefaultGroupIsNotVisibleFromTheSharedGroup() async throws {
        let aliceCredentials = try await makeSignInUser()
        let sessionId = try makeSessionID("alice-default-group")
        _ = try await signIn(aliceCredentials, on: sessionId, over: standard)

        try await assertSignedOutWithNoRow(sessionId, over: standard, accessGroup: IntegrationTestEnvironment.sharedAccessGroup(), "from the shared group")

        let listed = try await AmplifyCognitoClient.storedSessions(configuration: standard)
        XCTAssertTrue(listed.first { $0.sessionId == sessionId }?.username == aliceCredentials.username, "the default group keeps it")
    }

    /// A session in the shared access group is not visible from the default group (CS-5; the
    /// plugin's `testCredentialsDoNotRemainOnNonMigrationFromSharedAccessGroup`).
    ///
    /// - Given: bob signed in on a session in `…Shared`, then released
    /// - When:
    ///    - a client over the same session ID with no access group (the default one) reads it
    /// - Then:
    ///    - it reads `.signedOut`, fails as not signed in, and the default listing has no row for it
    ///    - the shared group still lists it for bob
    ///
    func testSessionInTheSharedGroupIsNotVisibleFromTheDefaultGroup() async throws {
        let bob = try await makeSignInUser()
        let shared = try IntegrationTestEnvironment.sharedAccessGroup()
        let sessionId = try makeSessionID("bob-shared-group", accessGroup: shared)
        _ = try await signIn(bob, on: sessionId, over: standard, accessGroup: shared)

        try await assertSignedOutWithNoRow(sessionId, over: standard, "from the default group")

        let listed = try await AmplifyCognitoClient.storedSessions(configuration: standard, accessGroup: shared)
        XCTAssertTrue(listed.first { $0.sessionId == sessionId }?.username == bob.username, "the shared group keeps it")
    }

    /// A session in one shared access group is not visible from another (CS-6; the plugin's
    /// `testCredentialsDoNotRemainOnNonMigrationFromSharedAccessGroupToAnotherSharedAccessGroup`).
    ///
    /// - Given: bob signed in on a session in `…Shared`, then released
    /// - When:
    ///    - a client over the same session ID in `…Shared2` (P-11) reads it
    /// - Then:
    ///    - it reads `.signedOut`, fails as not signed in, and the `…Shared2` listing has no row for it
    ///    - `…Shared` still lists it for bob
    ///
    func testSessionInOneSharedGroupIsNotVisibleFromAnother() async throws {
        let bob = try await makeSignInUser()
        let shared = try IntegrationTestEnvironment.sharedAccessGroup()
        let sessionId = try makeSessionID("bob-shared-to-shared2", accessGroup: shared)
        _ = try await signIn(bob, on: sessionId, over: standard, accessGroup: shared)

        try await assertSignedOutWithNoRow(
            sessionId,
            over: standard,
            accessGroup: IntegrationTestEnvironment.secondSharedAccessGroup(),
            "from the second shared group"
        )

        let listed = try await AmplifyCognitoClient.storedSessions(configuration: standard, accessGroup: shared)
        XCTAssertTrue(listed.first { $0.sessionId == sessionId }?.username == bob.username, "the shared group keeps it")
    }

    // MARK: - Helpers

    /// The identity-only role alone (P-6′): the default backend's identity pool, without its user pool.
    private static func identityOnlyConfiguration() throws -> AuthClientConfiguration {
        let auth = try IntegrationTestEnvironment.identityOnlyAuthSection()
        guard let poolId = auth["identity_pool_id"] as? String, let region = auth["aws_region"] as? String else {
            throw HarnessError.malformedFixture("The default outputs have no identity pool or region.")
        }
        return try AuthClientConfiguration(identityPool: .init(
            poolId: poolId,
            region: region,
            unauthenticatedIdentitiesEnabled: auth["unauthenticated_identities_enabled"] as? Bool
        ))
    }

    /// A session ID whose records are signed out and purged at teardown under each of `configurations`,
    /// since the base class's cleanup knows only the base sandbox and parity pools.
    private func tracked(_ tag: String, in configurations: [AuthClientConfiguration]) throws -> SessionID {
        let sessionId = try IntegrationTestEnvironment.uniqueSessionID(tag)
        let session = CreatedSession(sessionId: sessionId, accessGroup: nil)
        addTeardownBlock {
            var firstError: Error?
            for configuration in configurations {
                do {
                    try await SessionCleanup.cleanUp([session], configuration: configuration)
                } catch {
                    firstError = firstError ?? error
                }
            }
            if let firstError {
                throw firstError
            }
        }
        return sessionId
    }

    /// A guest session's identity ID and access key ID, compared, never printed.
    private struct AWSGuest {
        let identityId: String
        let accessKeyId: String

        init(_ session: AuthClientSession) throws {
            self.identityId = try session.identityIdResult.get()
            self.accessKeyId = try session.awsCredentialsResult.get().accessKeyId
        }
    }

    /// Makes `sessionId` a guest over `configuration`, returns its identity and credentials, and releases
    /// the session.
    private func guest(_ sessionId: SessionID, over configuration: AuthClientConfiguration) async throws -> AWSGuest {
        let guest: AWSGuest
        do {
            let client = try AmplifyCognitoClient(configuration: configuration, options: .init(sessionId: sessionId))
            guest = try await AWSGuest(client.fetchAuthSession())
            let state = await client.currentSessionState()
            XCTAssertState(state, .guest)
        }
        try await SessionCleanup.waitUntilReleased([sessionId])
        return guest
    }

    /// Signs `user` in on `sessionId` over a configuration with an identity pool, returns the user and its
    /// identity ID, and releases the session.
    private func signInWithIdentity(
        _ user: TestUser,
        on sessionId: SessionID,
        over configuration: AuthClientConfiguration
    ) async throws -> (AuthClientUser, String) {
        let signedIn: (AuthClientUser, String)
        do {
            let client = try AmplifyCognitoClient(configuration: configuration, options: .init(sessionId: sessionId))
            let result = try await client.signIn(username: user.username, password: user.password)
            XCTAssertStep(result.nextStep, .done)
            signedIn = try await (client.getCurrentUser(), client.fetchAuthSession().identityIdResult.get())
        }
        try await SessionCleanup.waitUntilReleased([sessionId])
        return signedIn
    }

    /// Signs `user` in on `sessionId`, returns the signed-in user, and releases the session.
    private func signIn(
        _ user: TestUser,
        on sessionId: SessionID,
        over configuration: AuthClientConfiguration,
        accessGroup: String? = nil
    ) async throws -> AuthClientUser {
        let signedIn: AuthClientUser
        do {
            let client = try AmplifyCognitoClient(
                configuration: configuration,
                options: .init(sessionId: sessionId, accessGroup: accessGroup)
            )
            let result = try await client.signIn(username: user.username, password: user.password)
            XCTAssertStep(result.nextStep, .done)
            signedIn = try await client.getCurrentUser()
        }
        try await SessionCleanup.waitUntilReleased([sessionId])
        return signedIn
    }

    /// A client over `sessionId` in `configuration` and `accessGroup` finds no record: it reads
    /// `.signedOut`, `getCurrentUser()` and its credentials provider fail as not signed in (the provider
    /// never falls back to guest), and the listing has no row for the session. Nothing it does writes a
    /// record, and it is released on return.
    private func assertSignedOutWithNoRow(
        _ sessionId: SessionID,
        over configuration: AuthClientConfiguration,
        accessGroup: String? = nil,
        _ context: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        do {
            let client = try AmplifyCognitoClient(
                configuration: configuration,
                options: .init(sessionId: sessionId, accessGroup: accessGroup)
            )
            let state = await client.currentSessionState()
            XCTAssertState(state, .signedOut, context, file: file, line: line)
            let userError = await Expect.authClientError("getCurrentUser \(context)", file: file, line: line) {
                try await client.getCurrentUser()
            }
            XCTAssertEqual(userError?.kind, .notSignedIn, context, file: file, line: line)
            let providerError = await Expect.credentialsError("the credentials provider \(context)", file: file, line: line) {
                try await client.credentialsProvider.resolve()
            }
            XCTAssertEqual(providerError?.caseName, "notSignedIn", context, file: file, line: line)
        }
        try await SessionCleanup.waitUntilReleased([sessionId])
        let listed = try await AmplifyCognitoClient.storedSessions(
            configuration: configuration,
            accessGroup: accessGroup,
            includingSignedOut: true
        )
        XCTAssertFalse(listed.contains { $0.sessionId == sessionId }, "no row \(context)", file: file, line: line)
    }
}
