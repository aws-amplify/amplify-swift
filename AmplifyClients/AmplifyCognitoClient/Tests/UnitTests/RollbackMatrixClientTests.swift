//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import Foundation
import InternalAmplifyKeychain
import InternalAWSCognitoAuth
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// The rollback matrix, the client's side, for the shared saved login: `.default` reads
/// and writes the Auth plugin's own record, so the plugin and the client, alternating over one keychain, each see the
/// other's latest login at rest.
///
/// Each row alternates the plugin's real credential store, `AWSCognitoAuthCredentialStore`, and the client (its real
/// record store, core and live engine, with scripted Cognito) over one in-memory keychain. The plugin's half of each
/// row is in `RollbackMatrixPluginTests`, under the same name, with the row map of the matrix's checklist: rows 1
/// to 7 and 9 are in both files, and row 8 (the keychain attributes) and the client's bytes decoded by the released
/// types are in the plugin's `KeychainAttributeParityTests` only. The rollback rows are in
/// `RollbackMatrixClientTests+Rollback.swift`.
///
/// Where a row says "each plugin binary", the plugin's store runs over `RollbackPluginBinary.released` (a released
/// plugin, 2.62.0) and `.current`. The two run identical code on every read, save, delete and refresh path: the
/// plugin's credential store, which touches only its own key. `.released` differs only in its view of the keychain,
/// which refuses it any read of a client record (a guard on the emulation; 2.62.0 never asks), and in the
/// access-group transition rows, where it runs 2.62.0's service-wide `_removeAll()`. So the columns are not double
/// coverage: the recorded client-record reads (`HiddenReads`) and the keychain's mutations are the evidence. The
/// released access-group migration (`migrateKeychainItemsOfUserSession: true`) is not emulated. The plugin's own
/// refresh is the engine's, which the plugin runs, over the credentials its store read.
final class RollbackMatrixClientTests: XCTestCase {

    var harness: ClientHarness!
    var live: LiveEngineHarness!

    var pluginAccount: String { SessionRecordKey.pluginSessionAccount(in: StorageFixtures.pools) }
    var sidecarAccount: String { SessionRecordKey.metaAccount(in: StorageFixtures.pools) }

    override func setUp() {
        harness = ClientHarness()
        live = LiveEngineHarness()
    }

    override func tearDown() async throws {
        await harness.waitForBaseline()
        harness = nil
        live = nil
    }

    // MARK: - Rows

    /// A client sign-in is seen by the plugin.
    ///
    /// - Given: The client signs alice in on `.default`
    /// - When:
    ///    - The plugin's credential store, over the same keychain, retrieves its credentials
    /// - Then:
    ///    - It retrieves alice's credentials, exactly the bytes the client stored, decoded
    ///
    func testMatrix_clientSignIn_isSeenByThePlugin() async throws {
        let client = try makeClient()
        try await signInAlice(client)

        let stored = try XCTUnwrap(harness.keychain.value(pluginAccount))
        let retrieved = try pluginStore().retrieveCredential()

        XCTAssertEqual(retrieved, try AmplifyCredentials.decoded(stored))
        guard case .userPoolAndIdentityPool(let signedInData, _, _) = retrieved else {
            return XCTFail("expected alice signed in with both pools, got \(retrieved)")
        }
        XCTAssertEqual(signedInData.username, "alice")
    }

    /// A sign-out by a plugin build that deletes its record is seen by the client.
    ///
    /// - Given: Alice signed in through the client, and a live core holding her
    /// - When:
    ///    - The plugin's store deletes its record while the client's next refresh is at Cognito
    /// - Then:
    ///    - The client's guarded write is discarded, the re-read finds nothing, and the session is `.signedOut`
    ///    - The record is never recreated, and a new core restores `.signedOut`
    ///
    func testMatrix_oldPluginSignOut_isSeenByTheClient() async throws {
        var client: AmplifyCognitoClient? = try makeClient()
        try await signInAlice(XCTUnwrap(client))
        let pluginKeychain = harness.keychain.itemStore(service: SessionRecordStore.unsharedService)
        live.cognito.once("GetTokensFromRefreshToken") { (_: GetTokensFromRefreshTokenInput) in
            try Self.pluginStore(over: pluginKeychain).deleteCredential()
            return GetTokensFromRefreshTokenOutput(authenticationResult: LiveEngineFixtures.tokens("alice", version: 2))
        }
        live.scriptIdentityPool(version: 2)

        _ = try? await client?.fetchAuthSession(options: .init(forceRefresh: true))

        let state = await client?.currentSessionState()
        XCTAssertEqual(state, .signedOut)
        XCTAssertNil(harness.keychain.value(pluginAccount))
        client = nil
        await harness.waitForBaseline()
        let restored = try await makeClient().currentSessionState()
        XCTAssertEqual(restored, .signedOut)
        XCTAssertNil(harness.keychain.value(pluginAccount))
    }

    /// The label is bound to the user: it is dropped when the plugin signs another user in.
    ///
    /// - Given: The client labels alice's `.default` "Work"
    /// - When:
    ///    - The plugin's store saves alice again, refreshed; then it saves bob
    /// - Then:
    ///    - With alice refreshed, the row keeps "Work"
    ///    - With bob, the row is bob's with no label, a restore shows no label, and the client's next write rewrites
    ///      the sidecar for bob without a label
    ///
    func testMatrix_labelIsDroppedWhenTheUserChanges() async throws {
        var client: AmplifyCognitoClient? = try makeClient()
        try await signInAlice(XCTUnwrap(client))
        try await client?.setSessionLabel("Work")
        client = nil
        await harness.waitForBaseline()
        let engine = try live.engine()
        let alice = try XCTUnwrap(harness.keychain.value(pluginAccount))
        live.scriptRefresh("alice", version: 2)
        live.scriptIdentityPool(version: 2)
        let aliceRefreshed = try await engine.refresh(alice, force: true)

        try pluginStore().saveCredential(AmplifyCredentials.decoded(aliceRefreshed))

        let afterAliceRefreshed = try await listed()
        XCTAssertEqual(afterAliceRefreshed, [
            StoredSession(sessionId: .default, label: "Work", username: "alice", kind: .userPoolAndIdentityPool)
        ])

        let bob = try await live.signedInPayload("bob", on: engine)
        try pluginStore().saveCredential(AmplifyCredentials.decoded(bob))

        let afterBob = try await listed()
        XCTAssertEqual(afterBob, [
            StoredSession(sessionId: .default, label: nil, username: "bob", kind: .userPoolAndIdentityPool)
        ])
        XCTAssertNil(try harness.storedRecord(.default)?.label)
        let restored = try makeClient()
        let restoredState = await restored.currentSessionState()
        XCTAssertEqual(restoredState, .signedIn(AuthClientUser(username: "bob", userId: "sub-bob")))
        live.scriptRefresh("bob", version: 3)
        _ = try await restored.fetchAuthSession(options: .init(forceRefresh: true))
        let sidecar = try XCTUnwrap(harness.keychain.value(sidecarAccount))
        guard case .meta(let meta) = DefaultSessionMeta.decode(sidecar) else {
            return XCTFail("the sidecar must be readable")
        }
        XCTAssertEqual(meta.userId, "sub-bob")
        XCTAssertEqual(meta.username, "bob")
        XCTAssertNil(meta.label)
    }

    /// A client sign-out is read by every plugin as signed out (G2 `session-noCredentials.json`).
    ///
    /// - Given: The client signs alice in on `.default` and labels her, then signs her out
    /// - When:
    ///    - Each plugin binary's credential store, over the same keychain, retrieves its credentials
    /// - Then:
    ///    - The record equals G2's `session-noCredentials.json` after decoding, and byte for byte:
    ///      `JSONEncoder().encode(AmplifyCredentials.noCredentials)`
    ///    - Each binary reads `.noCredentials`, reading no client record
    ///
    func testMatrix_clientSignOut_readByEveryPluginAsSignedOut() async throws {
        let client = try makeClient()
        try await signInAlice(client)
        try await client.setSessionLabel("Work")
        live.scriptSignOut()

        let signedOut = await client.signOut()
        XCTAssertEqual(signedOut, .complete, "\(signedOut)")

        let stored = try XCTUnwrap(harness.keychain.value(pluginAccount))
        let golden = try PluginTestResources.goldenStoredFormat("session-noCredentials.json")
        XCTAssertEqual(try AmplifyCredentials.decoded(stored), try AmplifyCredentials.decoded(golden))
        XCTAssertEqual(stored, golden)
        XCTAssertEqual(stored, try JSONEncoder().encode(AmplifyCredentials.noCredentials))
        let hiddenReads = HiddenReads()
        for binary in RollbackPluginBinary.allCases {
            XCTAssertEqual(try pluginStore(binary, recording: hiddenReads).retrieveCredential(), .noCredentials, "\(binary)")
        }
        XCTAssertEqual(hiddenReads.accounts, [])
    }

    /// A development build's `$default` records are never listed: the only `.default` row is the shared record's.
    ///
    /// - Given: A leftover `$default.session` holding bob and a `$default` namespace marker, beside the plugin's
    ///   record for alice
    /// - When:
    ///    - The saved sessions are listed, signed-out rows included
    /// - Then:
    ///    - The only row is alice's, from the plugin's record
    ///
    func testMatrix_oldDollarDefaultRecordsAreIgnoredByListing() async throws {
        let leftover = SessionRecordEnvelope(
            generation: 1,
            lastWriteTimestamp: TestClock.start,
            record: FakePayload.signedIn("bob").record()
        )
        harness.keychain.put(try leftover.encoded(), SessionRecordKey.account(for: .default, in: StorageFixtures.pools, kind: .session))
        harness.keychain.put(
            Data(#"{"copies":[],"poolNamespace":"us-east-1_Other","schemaVersion":1}"#.utf8),
            SessionRecordKey.markerAccount(for: .default, scope: TestKeychain.markerScope)
        )
        let alice = try await live.signedInPayload("alice", on: live.engine())
        try pluginStore().saveCredential(AmplifyCredentials.decoded(alice))

        let rows = try await listed(includingSignedOut: true)
        XCTAssertEqual(rows, [
            StoredSession(sessionId: .default, label: nil, username: "alice", kind: .userPoolAndIdentityPool)
        ])
    }

    // MARK: - Configuration changes: `.default` follows the plugin's rule and records `authConfiguration`

    /// A configuration change, then a rollback to a plugin build: no stale overwrite.
    ///
    /// - Given: The plugin ran with an identity-pool-only configuration A and stored a guest under A's account
    /// - When:
    ///    - The client restores `.default` under C (a user pool added beside the same identity pool), which carries the
    ///      guest, and signs alice in; then the plugin's store is built with C
    /// - Then:
    ///    - The client restored the guest, and recorded C; the plugin reads alice, since its carry branch does not run
    ///      again
    ///    - Negative control: with `authConfiguration` rewound to A, the plugin copies the stale guest over alice
    ///
    func testMatrix_configurationChangeThenPluginRollback_noStaleOverwrite() async throws {
        let guest = try ChangePayloads.guest()
        try pluginStore(ChangeConfigs.identityPoolOnly).saveCredential(AmplifyCredentials.decoded(guest))
        var client: AmplifyCognitoClient? = try makeClient()

        let carried = await client?.currentSessionState()
        try await signInAlice(XCTUnwrap(client))
        client = nil
        await harness.waitForBaseline()

        XCTAssertEqual(carried, .guest)
        XCTAssertEqual(harness.keychain.recordedPluginConfiguration(), AuthConfiguration(client: ClientFixtures.configuration))
        let alice = try XCTUnwrap(harness.keychain.value(pluginAccount))
        XCTAssertEqual(try pluginStore().retrieveCredential(), try AmplifyCredentials.decoded(alice))

        harness.keychain.recordPluginConfiguration(ChangeConfigs.identityPoolOnly)
        XCTAssertEqual(try pluginStore().retrieveCredential(), try AmplifyCredentials.decoded(guest))
    }

    /// A change the plugin does not carry deletes `.default`'s login, and keeps a named session's.
    ///
    /// - Given: `.default` and `.named("work")` both signed in through the client under user pool A
    /// - When:
    ///    - Both restore under user pool B; then both again under A
    /// - Then:
    ///    - Under B both are signed out: A's plugin record is gone, while work's record under A is kept
    ///    - Back on A, `.default` is signed out and work is signed in
    ///
    func testMatrix_uncarriedChange_deletesUnderDefault_keepsUnderANamedSession() async throws {
        let work = ClientFixtures.id("work")
        var defaultClient: AmplifyCognitoClient? = try makeClient()
        var workClient: AmplifyCognitoClient? = try makeClient(work)
        try await signInAlice(XCTUnwrap(defaultClient))
        try await signInAlice(XCTUnwrap(workClient))
        defaultClient = nil
        workClient = nil
        await harness.waitForBaseline()
        let workAccount = SessionRecordKey.account(for: work, in: StorageFixtures.pools, kind: .session)
        let workRecord = try XCTUnwrap(harness.keychain.value(workAccount))

        var defaultUnderB: AmplifyCognitoClient? = try makeClient(configuration: ChangeConfigs.otherUserPool)
        var workUnderB: AmplifyCognitoClient? = try makeClient(work, configuration: ChangeConfigs.otherUserPool)
        let defaultStateUnderB = await defaultUnderB?.currentSessionState()
        let workStateUnderB = await workUnderB?.currentSessionState()
        defaultUnderB = nil
        workUnderB = nil
        await harness.waitForBaseline()

        XCTAssertEqual(defaultStateUnderB, .signedOut)
        XCTAssertEqual(workStateUnderB, .signedOut)
        XCTAssertNil(harness.keychain.value(pluginAccount))
        XCTAssertEqual(harness.keychain.value(workAccount), workRecord)
        let defaultBack = await (try makeClient()).currentSessionState()
        let workBack = await (try makeClient(work)).currentSessionState()
        XCTAssertEqual(defaultBack, .signedOut)
        XCTAssertEqual(workBack, .signedIn(AuthClientUser(username: "alice", userId: "sub-alice")))
    }

    /// A plugin build with the older configuration runs its own rule after the client recorded a newer one.
    ///
    /// - Given: For each pair of configurations, an older login saved by the plugin under the older configuration A;
    ///   the client's `.default` then restored under the newer configuration C, alice signed in, and
    ///   `authConfiguration` is C
    /// - When:
    ///    - A plugin store is built with A over the same keychain
    /// - Then:
    ///    - It runs exactly its own rule from C to A: a carried change copies alice's record to A's key, so the newest
    ///      login wins; a deleting change deletes alice's record under C, and the plugin reads what A's key still holds
    ///    - No pair writes an older copy over a newer login: C's account holds alice or nothing
    ///
    func testMatrix_pluginBuildWithTheOldConfiguration_runsItsOwnRuleAfterTheClient() async throws {
        let alice = try await live.signedInPayload("alice", on: live.engine())
        for pair in ChangeConfigs.pairs {
            guard let older = pair.previous else {
                continue
            }
            let keychain = TestKeychain()
            let pluginKeychain = keychain.itemStore(service: SessionRecordStore.unsharedService)
            let olderLogin = older.getUserPoolConfiguration() == nil
                ? try ChangePayloads.guest()
                : try await live.signedInPayload("olderuser", on: live.engine())
            try AWSCognitoAuthCredentialStore(authConfiguration: older, keychain: pluginKeychain, logger: DiscardingEngineLogger())
                .saveCredential(AmplifyCredentials.decoded(olderLogin))
            let client = keychain.recordStore(for: SessionStorageNamespace(pools: PoolNamespace(pair.current), accessGroup: nil))
            _ = try client.applyPluginConfigurationRule(current: pair.current)
            let version: RecordVersion? = if case .record(let held) = try client.read(.default) { held.version } else { nil }
            let summary = PluginRecordSummary.peek(alice)
            let record = SessionRecord(label: nil, username: summary.username, userId: summary.userId, kind: summary.kind, credentials: alice)
            XCTAssertTrue(try client.write(record, for: .default, expecting: version).didCommit, pair.name)
            let olderAccount = AWSCognitoAuthCredentialStore.sessionAccount(for: older)
            let newerAccount = AWSCognitoAuthCredentialStore.sessionAccount(for: pair.current)
            let leftAtOlder = keychain.value(olderAccount)

            let retrieved = try? AWSCognitoAuthCredentialStore(authConfiguration: older, keychain: pluginKeychain, logger: DiscardingEngineLogger())
                .retrieveCredential()

            switch AWSCognitoAuthCredentialStore.configurationChange(from: pair.current, to: older) {
            case .carry, .unchanged:
                XCTAssertEqual(retrieved, try AmplifyCredentials.decoded(alice), pair.name)
            case .clear:
                XCTAssertNil(keychain.value(newerAccount), pair.name)
                XCTAssertEqual(retrieved, try leftAtOlder.map(AmplifyCredentials.decoded), pair.name)
            }
            let atNewer = keychain.value(newerAccount)
            XCTAssertTrue(atNewer == nil || (try? AmplifyCredentials.decoded(XCTUnwrap(atNewer))) == (try? AmplifyCredentials.decoded(alice)), pair.name)
        }
    }

    // MARK: - Helpers

    /// The plugin's own credential store over the harness's keychain, with the client's configuration, as a plugin
    /// build of the same app runs it.
    func pluginStore() -> AWSCognitoAuthCredentialStore {
        Self.pluginStore(over: harness.keychain.itemStore(service: SessionRecordStore.unsharedService))
    }

    /// The plugin's own credential store over the harness's keychain, with `configuration`.
    func pluginStore(_ configuration: AuthClientConfiguration) -> AWSCognitoAuthCredentialStore {
        AWSCognitoAuthCredentialStore(
            authConfiguration: AuthConfiguration(client: configuration),
            keychain: harness.keychain.itemStore(service: SessionRecordStore.unsharedService),
            logger: DiscardingEngineLogger()
        )
    }

    /// `binary`'s credential store over the harness's keychain, with `configuration`, recording its reads of client
    /// records in `hiddenReads`.
    func pluginStore(
        _ binary: RollbackPluginBinary,
        _ configuration: AuthClientConfiguration = ClientFixtures.configuration,
        recording hiddenReads: HiddenReads
    ) -> AWSCognitoAuthCredentialStore {
        AWSCognitoAuthCredentialStore(
            authConfiguration: AuthConfiguration(client: configuration),
            keychain: binary.keychainStore(over: harness.keychain.itemStore(service: SessionRecordStore.unsharedService), recording: hiddenReads),
            logger: DiscardingEngineLogger()
        )
    }

    static func pluginStore(over keychain: any KeychainItemStoreBehavior) -> AWSCognitoAuthCredentialStore {
        AWSCognitoAuthCredentialStore(
            authConfiguration: AuthConfiguration(client: ClientFixtures.configuration),
            keychain: keychain,
            logger: DiscardingEngineLogger()
        )
    }

    func signInAlice(_ client: AmplifyCognitoClient) async throws {
        live.scriptSRP()
        live.scriptIdentityPool()
        let result = try await client.signIn(username: "alice", password: "password")
        XCTAssertEqual(result.nextStep, .done)
    }

    func listed(includingSignedOut: Bool = false) async throws -> [StoredSession] {
        try await AmplifyCognitoClient.storedSessions(
            configuration: ClientFixtures.configuration,
            accessGroup: nil,
            includingSignedOut: includingSignedOut,
            dependencies: dependencies
        )
    }

    /// The harness's dependencies, with the live engine over scripted Cognito in place of the fake engine.
    var dependencies: SessionCoreDependencies {
        let base = harness.dependencies
        let live = live!
        var dependencies = SessionCoreDependencies(
            registry: base.registry,
            gates: base.gates,
            makeStore: base.makeStore,
            makeClients: base.makeClients,
            makeEngine: { _ in try live.engine() },
            makeRevoker: base.makeRevoker,
            scheduleRestore: base.scheduleRestore,
            bounds: base.bounds,
            now: base.now
        )
        dependencies.makePreviousConfigurationRevoker = base.makePreviousConfigurationRevoker
        #if os(iOS) || os(macOS) || os(visionOS)
        dependencies.sheetLock = base.sheetLock
        #endif
        return dependencies
    }

    func makeClient(
        _ sessionId: SessionID = .default,
        configuration: AuthClientConfiguration = ClientFixtures.configuration
    ) throws -> AmplifyCognitoClient {
        try AmplifyCognitoClient(
            configuration: configuration,
            options: .init(sessionId: sessionId),
            dependencies: dependencies
        )
    }
}
