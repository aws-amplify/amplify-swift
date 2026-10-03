//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyFoundation
import AWSCognitoIdentityProvider
import Foundation
import InternalAWSCognitoAuth
import Security
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// `.default` reads and writes the Auth plugin's own record: the shared record, guarded on
/// its bytes, with the sidecar holding the label and the last user, bound to that user. Named sessions keep
/// their own records, and a development build's `$default` records are never touched.
final class DefaultSessionSharedRecordTests: XCTestCase {

    private var harness: ClientHarness!
    private let work = ClientFixtures.id("work")

    private let pools = StorageFixtures.pools
    private var pluginAccount: String { SessionRecordKey.pluginSessionAccount(in: pools) }
    private var sidecarAccount: String { SessionRecordKey.metaAccount(in: pools) }
    private var challengeAccount: String { SessionRecordKey.account(for: .default, in: pools, kind: .challenge) }
    private var leftoverAccount: String { SessionRecordKey.account(for: .default, in: pools, kind: .session) }
    private var leftoverMarker: String { SessionRecordKey.markerAccount(for: .default, scope: TestKeychain.markerScope) }

    private let alice = AuthClientUser(username: "alice", userId: "sub-alice")

    override func setUp() {
        harness = ClientHarness()
    }

    override func tearDown() async throws {
        await harness.waitForBaseline()
        harness = nil
    }

    // MARK: Reading and writing in place

    /// - Given: the plugin's bytes for alice under `amplify.<ns>.session`, and its `authConfiguration` for the same
    ///   configuration
    /// - When: a `.default` client restores
    /// - Then:
    ///    - it is `.signedIn(alice)`, read in place, and nothing is written
    func testRestoreReadsTheSharedRecordInPlace() async throws {
        harness.keychain.put(PluginRecordFixtures.userPoolAndIdentityPool, pluginAccount)
        harness.keychain.recordPluginConfiguration()
        let client = try harness.client(.default)

        let state = await client.currentSessionState()

        XCTAssertEqual(state, .signedIn(AuthClientUser(username: "alice@corp", userId: "1234567890")))
        XCTAssertFalse(harness.keychain.hasMutations)
    }

    /// - Given: nothing stored
    /// - When: alice signs in on `.default` with SRP, through the live engine
    /// - Then:
    ///    - exactly three accounts are written: the plugin's record, the sidecar, and the plugin's
    ///      `authConfiguration`, which the first restore records; the record decodes with `JSONDecoder` as
    ///      `AmplifyCredentials`; no `$default` session record and no marker exist
    func testSignInWritesTheSharedRecordAndTheSidecarOnly() async throws {
        let live = LiveEngineHarness()
        live.scriptSRP()
        live.scriptIdentityPool()
        let client = try liveClient(live)

        let result = try await client.signIn(username: "alice", password: "password")

        XCTAssertEqual(result.nextStep, .done)
        XCTAssertEqual(Set(harness.keychain.writtenAccounts), [pluginAccount, sidecarAccount, SessionRecordStore.pluginConfigurationAccount])
        let stored = try XCTUnwrap(harness.keychain.value(pluginAccount))
        guard case .userPoolAndIdentityPool(let signedInData, _, _) = try JSONDecoder().decode(AmplifyCredentials.self, from: stored) else {
            return XCTFail("expected alice with both pools")
        }
        XCTAssertEqual(signedInData.username, "alice")
        XCTAssertNil(harness.keychain.value(leftoverAccount))
        XCTAssertNil(harness.keychain.value(leftoverMarker))
    }

    /// - Given: a restore that read nothing, and another writer that adds bob's record before alice's sign-in commits
    /// - When: alice signs in
    /// - Then:
    ///    - the client's add-if-absent is discarded, bob's record is kept, and the sign-in reports the other user
    func testFirstWriteExpectsAbsence() async throws {
        let client = try harness.client(.default)
        _ = await client.currentSessionState()
        let bob = FakePayload.signedIn("bob")
        let keychain = harness.keychain
        let account = pluginAccount
        harness.engine(for: .default)?.scriptSignIn { request, _ in
            keychain.put(bob.data, account)
            return .done(payload: FakePayload.signedIn(request.username).data)
        }

        let error = await authClientError { try await client.signInForTest("alice") }

        guard case .invalidState? = error else {
            return XCTFail("expected invalidState, got \(String(describing: error))")
        }
        XCTAssertEqual(harness.keychain.value(pluginAccount), bob.data)
    }

    /// - Given: alice restored, and another writer saving newer credentials while the refresh is at Cognito
    /// - When: credentials are requested
    /// - Then:
    ///    - the refresh's guarded write is discarded and the newer record is kept and used; the older refresh token
    ///      is never written back
    func testRefreshCommitsThroughTheByteGuard() async throws {
        let stale = FakePayload.signedIn("alice", stale: true)
        harness.keychain.put(stale.data, pluginAccount)
        let client = try harness.client(.default)
        _ = await client.currentSessionState()
        let newer = FakePayload.signedIn("alice", version: 5)
        let keychain = harness.keychain
        let account = pluginAccount
        harness.engine(for: .default)?.scriptRefresh { _ in
            keychain.put(newer.data, account)
            return stale.refreshed.data
        }

        let credentials = try await client.credentialsProvider.resolve()

        XCTAssertEqual(credentials as? CognitoAWSCredentials, newer.awsCredentials)
        XCTAssertEqual(harness.keychain.value(pluginAccount), newer.data)
    }

    /// The plugin may save the same credentials again in other bytes (another key order): that is not a change.
    ///
    /// - Given: alice restored, and another writer re-encoding the same credentials while the refresh is at Cognito
    /// - When: credentials are requested
    /// - Then:
    ///    - the refresh rebases (decoded comparison): its refreshed tokens are committed, with no `sessionExpired` and
    ///      no event
    func testPluginReEncodingTheSameCredentials_isRebasedNotSuperseded() async throws {
        let stale = FakePayload.signedIn("alice", stale: true)
        harness.keychain.put(stale.data, pluginAccount)
        let client = try harness.client(.default)
        let events = StreamRecorder(client.listenToAuthEvents())
        _ = await client.currentSessionState()
        let reencoded = try reencode(stale)
        let keychain = harness.keychain
        let account = pluginAccount
        harness.engine(for: .default)?.scriptRefresh { _ in
            keychain.put(reencoded, account)
            return stale.refreshed.data
        }

        let credentials = try await client.credentialsProvider.resolve()

        XCTAssertEqual(credentials as? CognitoAWSCredentials, stale.refreshed.awsCredentials)
        XCTAssertEqual(harness.keychain.value(pluginAccount), stale.refreshed.data)
        XCTAssertEqual(events.received, [])
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedIn(alice))
    }

    /// - Given: a refresh token reused twice, `RefreshTokenReuse.minimumGap` apart, with the plugin re-encoding the
    ///   same credentials in between
    /// - When: credentials are requested each time
    /// - Then:
    ///    - the first is retryable and the second `sessionExpired`, as when nothing was saved again
    func testPluginReEncodingTheSameCredentials_stillLetsTheDeadTokenRuleFire() async throws {
        let stale = FakePayload.signedIn("alice", stale: true)
        harness.keychain.put(stale.data, pluginAccount)
        let client = try harness.client(.default)
        harness.engine(for: .default)?.scriptRefresh { _ in throw SessionEngineError.refreshTokenReused }

        let first = await credentialsError { try await client.credentialsProvider.resolve() }
        harness.keychain.put(try reencode(stale), pluginAccount)
        harness.advanceClock(by: RefreshTokenReuse.minimumGap)
        let second = await credentialsError { try await client.credentialsProvider.resolve() }

        XCTAssertEqual(first?.isUnknown, true, "\(String(describing: first))")
        XCTAssertEqual(second?.isSessionExpired, true, "\(String(describing: second))")
    }

    /// `identityPending` is derived for `.default`: a `userPoolOnly` record under a configuration with an
    /// identity pool.
    ///
    /// - Given: the plugin's `userPoolOnly` bytes for alice, and a configuration with an identity pool
    /// - When: AWS credentials are asked for, through the live engine
    /// - Then:
    ///    - the identity is fetched first (`GetId`, `GetCredentialsForIdentity`) and committed through the guard;
    ///      no `notConfigured`
    func testUserPoolOnlyPayloadUnderAnIdentityPoolConfiguration_isIdentityPending() async throws {
        let producer = LiveEngineHarness(configuration: ClientFixtures.userPoolOnlyConfiguration)
        producer.scriptSRP()
        guard case .done(let userPoolOnly) = try await producer.engine().signIn(.srp(), current: nil) else {
            return XCTFail("the scripted sign-in did not finish")
        }
        harness.keychain.put(userPoolOnly, pluginAccount)
        guard case .record(let read) = try harness.store().read(.default) else {
            return XCTFail("the shared record should read")
        }
        XCTAssertTrue(read.record.identityPending)
        let live = LiveEngineHarness()
        live.scriptRefresh()
        live.scriptIdentityPool()
        let client = try liveClient(live)

        let credentials = try await client.credentialsProvider.resolve()

        XCTAssertEqual((credentials as? CognitoAWSCredentials)?.accessKeyId, "AKID-v1")
        let identityCalls = live.cognito.operations.filter { $0 == "GetId" || $0 == "GetCredentialsForIdentity" }
        XCTAssertEqual(identityCalls, ["GetId", "GetCredentialsForIdentity"])
        let stored = try XCTUnwrap(harness.keychain.value(pluginAccount))
        guard case .userPoolAndIdentityPool = try JSONDecoder().decode(AmplifyCredentials.self, from: stored) else {
            return XCTFail("the identity should be committed to the shared record")
        }
    }

    // MARK: macOS's delete-then-add

    /// - Given: the re-read on, and a keychain that answers "absent" once, then alice's bytes
    /// - When: `.default` is read, and a client restores
    /// - Then:
    ///    - it is alice, after exactly two reads of the shared record; absent twice is absent after two reads; with the
    ///      re-read off, one read
    func testAbsentSharedRecordIsReReadOnce_beforeSignedOut() async throws {
        let account = pluginAccount
        let keychain = harness.keychain
        let rereading = harness.keychain.recordStore(for: StorageFixtures.namespace, rereadsAbsentSharedRecord: true)
        let alice = FakePayload.signedIn("alice")

        harness.keychain.onceAfterReading(account) { keychain.put(alice.data, account) }
        guard case .record(let read) = try rereading.read(.default) else {
            return XCTFail("the second read should find alice")
        }
        XCTAssertEqual(read.record.username, "alice")
        XCTAssertEqual(reads(of: account), 2)

        try harness.keychain.itemStore(service: SessionRecordStore.unsharedService).remove(account)
        harness.keychain.resetLogs()
        XCTAssertEqual(try rereading.read(.default), .absent)
        XCTAssertEqual(reads(of: account), 2)

        harness.keychain.resetLogs()
        XCTAssertEqual(try harness.store().read(.default), .absent)
        XCTAssertEqual(reads(of: account), 1)

        harness.keychain.resetLogs()
        harness.keychain.onceAfterReading(account) { keychain.put(alice.data, account) }
        let client = try AmplifyCognitoClient(
            configuration: ClientFixtures.configuration,
            options: .init(sessionId: .default),
            dependencies: dependencies(makeStore: { keychain.recordStore(for: $0, rereadsAbsentSharedRecord: true) })
        )
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedIn(self.alice))
    }

    /// - Given: the platform
    /// - When: a store over the real keychain is built
    /// - Then:
    ///    - the re-read is on on macOS, and off elsewhere
    func testTheReReadIsOnByDefaultOnMacOSOnly() {
        #if os(macOS)
        let expected = true
        #else
        let expected = false
        #endif
        XCTAssertEqual(SessionRecordStore.rereadsAbsentSharedRecordByDefault, expected)
        XCTAssertEqual(SessionRecordStore(namespace: StorageFixtures.namespace).rereadsAbsentSharedRecord, expected)
    }

    // MARK: Sign-out and purge

    /// - Given: alice signed in on `.default`, labelled "Home"
    /// - When: she signs out
    /// - Then:
    ///    - the record's bytes equal `JSONEncoder().encode(AmplifyCredentials.noCredentials)`; the sidecar holds
    ///      alice's username, user ID and label; the row is a signed-out row with both
    func testSignOutWritesNoCredentialsThroughTheGuardAndKeepsTheSidecar() async throws {
        harness.keychain.put(FakePayload.signedIn("alice").data, pluginAccount)
        let client = try harness.client(.default)
        try await client.setSessionLabel("Home")

        let signedOut = await client.signOut()
        XCTAssertEqual(signedOut, .complete, "\(signedOut)")

        XCTAssertEqual(harness.keychain.value(pluginAccount), try JSONEncoder().encode(AmplifyCredentials.noCredentials))
        let meta = try XCTUnwrap(sidecar())
        XCTAssertEqual([meta.label, meta.username, meta.userId], ["Home", "alice", "sub-alice"])
        XCTAssertEqual(try harness.store().storedSessions(includingSignedOut: true), [
            StoredSession(sessionId: .default, label: "Home", username: "alice", kind: .signedOut)
        ])
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedOut)
    }

    /// - Given: `.default` on the plugin's record, with its sidecar and an interrupted sign-in record
    /// - When: it is purged
    /// - Then:
    ///    - the shared record, then the sidecar, then the challenge record are deleted, and nothing else
    func testPurgeDeletesTheSharedRecordTheSidecarAndTheChallengeRecord() async throws {
        harness.keychain.put(FakePayload.signedIn("alice").data, pluginAccount)
        _ = try harness.store().setDefaultLabel("Home")
        harness.keychain.put(Data("challenge".utf8), challengeAccount)
        harness.keychain.resetLogs()

        try await AmplifyCognitoClient.purgeStoredSession(
            sessionId: .default,
            configuration: ClientFixtures.configuration,
            accessGroup: nil,
            dependencies: harness.dependencies
        )

        XCTAssertEqual(harness.keychain.removedAccounts, [pluginAccount, sidecarAccount, challengeAccount])
        XCTAssertEqual(try harness.store().read(.default), .absent)
    }

    // MARK: A record this build cannot read

    /// - Given: bytes under the plugin's account that are not the plugin's format
    /// - When: `.default` restores, is labelled, refreshes, then signs out
    /// - Then:
    ///    - it is `.failed`; the label throws `.unknown`; the refresh writes nothing; the sign-out replaces it with
    ///      `{"noCredentials":{}}`
    func testUndecodableSharedRecordIsFailedAndNeverOverwrittenByALabelOrRefresh() async throws {
        let corrupt = Data("not the plugin's format".utf8)
        harness.keychain.put(corrupt, pluginAccount)
        harness.keychain.recordPluginConfiguration()
        let client = try harness.client(.default)

        let state = await client.currentSessionState()
        guard case .failed = state else {
            return XCTFail("expected .failed, got \(state)")
        }
        let labelError = await authClientError { try await client.setSessionLabel("Home") }
        guard case .unknown? = labelError else {
            return XCTFail("expected .unknown, got \(String(describing: labelError))")
        }
        _ = try? await client.credentialsProvider.resolve()
        XCTAssertEqual(harness.keychain.writtenAccounts, [])
        XCTAssertEqual(harness.keychain.value(pluginAccount), corrupt)

        let signedOut = await client.signOut()
        XCTAssertEqual(signedOut, .complete, "\(signedOut)")

        XCTAssertEqual(harness.keychain.value(pluginAccount), PluginRecordSummary.signedOutPayload)
    }

    // MARK: Named sessions and development leftovers

    /// - Given: the plugin's record and `.default`'s sidecar, and a named session
    /// - When: the named session signs in, is labelled, signs out and is purged
    /// - Then:
    ///    - neither the shared record nor the sidecar is ever read, written or deleted
    func testNamedSessionsNeverTouchTheSharedRecordOrTheSidecar() async throws {
        harness.keychain.put(FakePayload.signedIn("alice").data, pluginAccount)
        _ = try harness.store().setDefaultLabel("Home")
        let sidecarBytes = harness.keychain.value(sidecarAccount)
        harness.keychain.resetLogs()
        let client = try harness.client(work)

        try await client.signInForTest("bob")
        try await client.setSessionLabel("Work")
        let signedOut = await client.signOut()
        XCTAssertEqual(signedOut, .complete, "\(signedOut)")
        try await AmplifyCognitoClient.purgeStoredSession(
            sessionId: work,
            configuration: ClientFixtures.configuration,
            accessGroup: nil,
            dependencies: harness.dependencies
        )

        for account in [pluginAccount, sidecarAccount] {
            XCTAssertFalse(touched().contains(account), account)
        }
        XCTAssertEqual(harness.keychain.value(pluginAccount), FakePayload.signedIn("alice").data)
        XCTAssertEqual(harness.keychain.value(sidecarAccount), sidecarBytes)
    }

    /// No `.default` operation reads, writes or deletes a development build's leftovers, and every one touches only
    /// the shared record, the sidecar and the challenge record.
    ///
    /// - Given: a signed-in envelope at `amplify.1.<ns>.$default.session` and a `$default` namespace marker
    /// - When: `.default` restores, signs in, is labelled, signs out and is purged, and the sessions and signed-in
    ///   users are listed
    /// - Then:
    ///    - neither leftover is read, written or deleted, and every account touched is one of `.default`'s three, or
    ///      the plugin's `authConfiguration`
    func testLeftoverDollarDefaultRecordIsNeverReadWrittenOrDeleted() async throws {
        let envelope = SessionRecordEnvelope(generation: 1, lastWriteTimestamp: TestClock.start, record: FakePayload.signedIn("bob").record())
        harness.keychain.put(try envelope.encoded(), leftoverAccount)
        harness.keychain.put(Data(#"{"copies":[],"poolNamespace":"us-east-1_Other","schemaVersion":1}"#.utf8), leftoverMarker)
        let leftovers = (harness.keychain.value(leftoverAccount), harness.keychain.value(leftoverMarker))
        let client = try harness.client(.default)

        let restored = await client.currentSessionState()
        try await client.signInForTest("alice")
        try await client.setSessionLabel("Home")
        let signedOut = await client.signOut()
        XCTAssertEqual(signedOut, .complete, "\(signedOut)")
        let listed = try harness.store().storedSessions(includingSignedOut: true)
        try await client.signInForTest("alice")
        let userIds = try harness.store().signedInUserIds(describe: { FakePayload.decode($0).map { CredentialSummary(kind: .userPoolAndIdentityPool, username: $0.username, userId: $0.userId) } })
        try await AmplifyCognitoClient.purgeStoredSession(
            sessionId: .default,
            configuration: ClientFixtures.configuration,
            accessGroup: nil,
            dependencies: harness.dependencies
        )

        XCTAssertEqual(restored, .signedOut)
        XCTAssertEqual(listed, [StoredSession(sessionId: .default, label: "Home", username: "alice", kind: .signedOut)])
        XCTAssertEqual(userIds, [.default: "sub-alice"])
        XCTAssertFalse(touched().contains(leftoverAccount))
        XCTAssertFalse(touched().contains(leftoverMarker))
        XCTAssertTrue(
            Set(touched()).isSubset(of: [pluginAccount, sidecarAccount, challengeAccount, SessionRecordStore.pluginConfigurationAccount]),
            "\(Set(touched()))"
        )
        XCTAssertEqual(harness.keychain.value(leftoverAccount), leftovers.0)
        XCTAssertEqual(harness.keychain.value(leftoverMarker), leftovers.1)
    }

    // MARK: The sidecar

    /// - Given: alice labelled "Home", needing a refresh
    /// - When: the session refreshes
    /// - Then:
    ///    - the label is kept, in the sidecar and in the record read
    func testLabelIsKeptAcrossTheSameUsersRefresh() async throws {
        harness.keychain.put(FakePayload.signedIn("alice", stale: true).data, pluginAccount)
        let client = try harness.client(.default)
        try await client.setSessionLabel("Home")

        _ = try await client.credentialsProvider.resolve()

        XCTAssertEqual(harness.keychain.value(pluginAccount), FakePayload.signedIn("alice", stale: true).refreshed.data)
        XCTAssertEqual(sidecar()?.label, "Home")
        XCTAssertEqual(try harness.storedRecord(.default)?.label, "Home")
    }

    /// - Given: alice labelled "Home", then the plugin signing bob in over the shared record
    /// - When: `.default` is read, and its next write lands
    /// - Then:
    ///    - the label is not shown for bob, and the sidecar is rewritten for bob with no label
    func testLabelIsDroppedWhenTheRecordHoldsAnotherUser() async throws {
        harness.keychain.put(FakePayload.signedIn("alice").data, pluginAccount)
        _ = try harness.store().setDefaultLabel("Home")
        let bob = FakePayload.signedIn("bob", stale: true)
        harness.keychain.put(bob.data, pluginAccount)

        XCTAssertNil(try harness.storedRecord(.default)?.label)
        let client = try harness.client(.default)
        _ = try await client.credentialsProvider.resolve()

        let meta = try XCTUnwrap(sidecar())
        XCTAssertEqual(meta.userId, "sub-bob")
        XCTAssertEqual(meta.username, "bob")
        XCTAssertNil(meta.label)
    }

    /// - Given: alice signed in, labelled "Home", then signed out (her signed-out row)
    /// - When: `.default`'s session is fetched, which fetches a guest
    /// - Then:
    ///    - the label is dropped: the sidecar names no user and no label
    func testGuestOverAUsersSidecarDropsTheLabel() async throws {
        harness.keychain.put(FakePayload.signedIn("alice").data, pluginAccount)
        let client = try harness.client(.default)
        try await client.setSessionLabel("Home")
        let signedOut = await client.signOut()
        XCTAssertEqual(signedOut, .complete, "\(signedOut)")

        _ = try await client.fetchAuthSession()

        XCTAssertEqual(try harness.storedRecord(.default)?.kind, .guest)
        XCTAssertNil(try harness.storedRecord(.default)?.label)
        let meta = try XCTUnwrap(sidecar())
        XCTAssertNil(meta.label)
        XCTAssertNil(meta.userId)
    }

    /// a label set before anyone signed in is kept by the first sign-in.
    ///
    /// - Given: nothing stored, and `.default` labelled "Home"
    /// - When: alice signs in
    /// - Then:
    ///    - the label is kept, and the sidecar is now bound to alice
    func testLabelSetBeforeAnyoneSignedInIsKeptByTheFirstSignIn() async throws {
        let client = try harness.client(.default)
        try await client.setSessionLabel("Home")
        XCTAssertNil(harness.keychain.value(pluginAccount))
        XCTAssertNil(sidecar()?.userId)

        try await client.signInForTest("alice")

        XCTAssertEqual(try harness.storedRecord(.default)?.label, "Home")
        XCTAssertEqual(sidecar()?.userId, "sub-alice")
        XCTAssertEqual(sidecar()?.label, "Home")
    }

    /// a signed-out row's label is kept when the same user signs in again.
    ///
    /// - Given: alice signed in, labelled "Home", then signed out
    /// - When: alice signs in again
    /// - Then:
    ///    - the label is kept
    func testSignedOutRowsLabelIsKeptWhenTheSameUserSignsInAgain() async throws {
        let client = try harness.client(.default)
        try await client.signInForTest("alice")
        try await client.setSessionLabel("Home")
        let signedOut = await client.signOut()
        XCTAssertEqual(signedOut, .complete, "\(signedOut)")

        try await client.signInForTest("alice")

        XCTAssertEqual(try harness.storedRecord(.default)?.label, "Home")
        XCTAssertEqual(sidecar()?.label, "Home")
    }

    /// a signed-out row's label is dropped when another user signs in.
    ///
    /// - Given: alice signed in, labelled "Home", then signed out
    /// - When: bob signs in
    /// - Then:
    ///    - the label is dropped, and the sidecar is bound to bob
    func testSignedOutRowsLabelIsDroppedWhenAnotherUserSignsIn() async throws {
        let client = try harness.client(.default)
        try await client.signInForTest("alice")
        try await client.setSessionLabel("Home")
        let signedOut = await client.signOut()
        XCTAssertEqual(signedOut, .complete, "\(signedOut)")

        try await client.signInForTest("bob")

        XCTAssertNil(try harness.storedRecord(.default)?.label)
        XCTAssertEqual(sidecar()?.userId, "sub-bob")
        XCTAssertNil(sidecar()?.label)
    }

    /// The sidecar is cosmetic: failing to write it never fails the session.
    ///
    /// - Given: every write of the sidecar failing
    /// - When: alice signs in on `.default`
    /// - Then:
    ///    - the sign-in succeeds, the session is alice, and the shared record holds her; there is no sidecar
    func testSidecarWriteFailure_leavesTheSessionSignedInAndCorrect() async throws {
        harness.keychain.failingWrites(of: sidecarAccount, with: errSecInteractionNotAllowed)
        let client = try harness.client(.default)

        let result = try await client.signInForTest("alice")

        XCTAssertEqual(result.nextStep, .done)
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedIn(alice))
        XCTAssertEqual(harness.keychain.value(pluginAccount), FakePayload.signedIn("alice").data)
        XCTAssertNil(harness.keychain.value(sidecarAccount))
        harness.keychain.clearFailures()
    }

    // MARK: The same credentials in other bytes

    /// The live engine compares decoded `AmplifyCredentials`, not bytes.
    ///
    /// - Given: a live sign-in's payload, the same credentials pretty-printed with sorted keys, and the payload with
    ///   another refresh token
    /// - When: the live engine compares them
    /// - Then:
    ///    - the re-encoding is the same credentials, and the other refresh token is not
    func testLiveEngineSameCredentialsComparesDecodedCredentials() async throws {
        let live = LiveEngineHarness()
        let engine = try live.engine()
        let payload = try await live.signedInPayload(on: engine)
        let sorted = try sortedKeys(payload)
        let text = String(decoding: payload, as: UTF8.self)
        let otherToken = Data(text.replacingOccurrences(of: #""refreshToken":"refresh-alice-v1""#, with: #""refreshToken":"refresh-other""#).utf8)
        XCTAssertNotEqual(otherToken, payload)

        XCTAssertTrue(engine.sameCredentials(payload, sorted))
        XCTAssertTrue(engine.sameCredentials(payload, payload))
        XCTAssertFalse(engine.sameCredentials(payload, otherToken))
        XCTAssertFalse(engine.sameCredentials(payload, Data("not credentials".utf8)))
    }

    /// The rebase of a refresh over a re-encoded record, through the live engine.
    ///
    /// - Given: alice signed in on `.default` through the live engine, and the plugin re-encoding the same credentials
    ///   while a forced refresh is at Cognito
    /// - When: the session is fetched with a forced refresh
    /// - Then:
    ///    - the refreshed tokens are committed over the re-encoded record, not thrown away
    func testLiveRefreshOverAReEncodedRecordIsRebased() async throws {
        let live = LiveEngineHarness()
        live.scriptSRP()
        live.scriptIdentityPool()
        let client = try liveClient(live)
        _ = try await client.signIn(username: "alice", password: "password")
        let signedIn = try XCTUnwrap(harness.keychain.value(pluginAccount))
        let reencoded = try sortedKeys(signedIn)
        let keychain = harness.keychain
        let account = pluginAccount
        live.cognito.once("GetTokensFromRefreshToken") { (_: GetTokensFromRefreshTokenInput) in
            keychain.put(reencoded, account)
            return GetTokensFromRefreshTokenOutput(authenticationResult: LiveEngineFixtures.tokens("alice", version: 2))
        }

        _ = try await client.fetchAuthSession(options: .init(forceRefresh: true))

        let stored = try XCTUnwrap(harness.keychain.value(pluginAccount))
        guard case .userPoolAndIdentityPool(let signedInData, _, _) = try JSONDecoder().decode(AmplifyCredentials.self, from: stored) else {
            return XCTFail("expected alice with both pools")
        }
        XCTAssertEqual(signedInData.cognitoUserPoolTokens.accessToken, LiveEngineFixtures.jwt("alice", use: "access", version: 2))
    }

    /// A sign-out compares decoded credentials too, so a re-encoding during the revoke is not another writer.
    ///
    /// - Given: alice signed in on `.default`, and the plugin re-encoding the same credentials while the revoke is at
    ///   Cognito
    /// - When: she signs out globally
    /// - Then:
    ///    - the revoke and the global sign-out run once, the result is `.complete`, and the record is
    ///      `{"noCredentials":{}}`
    func testSignOutOverAReEncodedRecordRevokesOnce() async throws {
        let alice = FakePayload.signedIn("alice")
        harness.keychain.put(alice.data, pluginAccount)
        let client = try harness.client(.default)
        _ = await client.currentSessionState()
        let reencoded = try reencode(alice)
        let keychain = harness.keychain
        let account = pluginAccount
        let engine = try XCTUnwrap(harness.engine(for: .default))
        engine.scriptRevoke { _ in keychain.put(reencoded, account) }

        let result = await client.signOut(options: .init(globalSignOut: true))

        XCTAssertEqual(result, .complete)
        XCTAssertEqual(engine.revokeCalls.count, 1)
        XCTAssertEqual(harness.keychain.value(pluginAccount), PluginRecordSummary.signedOutPayload)
    }

    /// - Given: the plugin's record re-encoded since a sign-out revoked it
    /// - When: the store signs it out, removing the bytes the sign-out revoked
    /// - Then:
    ///    - it is signed out, not superseded
    func testStoreSignOutRemovingAReEncodedRecordSignsItOut() throws {
        let alice = FakePayload.signedIn("alice")
        harness.keychain.put(try reencode(alice), pluginAccount)

        XCTAssertEqual(try harness.store().signOut(.default, removing: alice.data), .signedOut)
        XCTAssertEqual(harness.keychain.value(pluginAccount), PluginRecordSummary.signedOutPayload)
    }

    /// The forced sign-out after repeated lost races compares decoded credentials.
    ///
    /// - Given: the plugin's record for alice, re-encoded in another form after every read, so each guarded write loses
    ///   its race while the credentials stay the same
    /// - When: the store signs it out
    /// - Then:
    ///    - it is signed out, through the last-resort replace, not superseded
    func testForcedSignOutOverRepeatedReEncodingsSignsItOut() throws {
        let alice = FakePayload.signedIn("alice")
        let encodings = try [alice.data, reencode(alice), prettyPrinted(alice)]
        XCTAssertEqual(Set(encodings).count, 3)
        harness.keychain.put(encodings[0], pluginAccount)
        let keychain = harness.keychain
        let account = pluginAccount
        let next = ReadTally()
        harness.keychain.afterEveryRead(of: account) {
            keychain.put(encodings[next.next() % encodings.count], account)
        }

        let outcome = try harness.store().signOut(.default)
        harness.keychain.afterEveryRead(of: account, nil)

        XCTAssertEqual(outcome, .signedOut)
        XCTAssertEqual(harness.keychain.value(pluginAccount), PluginRecordSummary.signedOutPayload)
    }

    // MARK: Sidecar races

    /// A sidecar write that loses its race re-reads and tries once more.
    ///
    /// - Given: alice's record and no sidecar, and a label with no user written to the sidecar between the write's
    ///   read of the sidecar and its guarded write
    /// - When: the store commits alice's refreshed record
    /// - Then:
    ///    - the retry keeps that label and binds the sidecar to alice
    func testALostSidecarRaceIsRetriedOnce() throws {
        let alice = FakePayload.signedIn("alice")
        harness.keychain.put(alice.data, pluginAccount)
        let keychain = harness.keychain
        let sidecar = sidecarAccount
        let labelled = try DefaultSessionMeta(lastWriteTimestamp: TestClock.start, label: "Home", username: nil, userId: nil).encoded()
        harness.keychain.onceAfterReading(sidecar) { keychain.put(labelled, sidecar) }

        let outcome = try harness.store().write(alice.refreshed.record(), for: .default, expecting: .storedBytes(alice.data))

        XCTAssertTrue(outcome.didCommit)
        let meta = try XCTUnwrap(self.sidecar())
        XCTAssertEqual(meta.label, "Home")
        XCTAssertEqual(meta.userId, "sub-alice")
    }

    /// The label is written through a guard on the sidecar's bytes.
    ///
    /// - Given: alice's record and her sidecar labelled "Home", and another writer relabelling the sidecar "Other"
    ///   between the label's read of the sidecar and its write
    /// - When: `.default` is labelled "Work" through the store, then again
    /// - Then:
    ///    - the first write is discarded and leaves "Other"; the second, over what it read, writes "Work"
    func testSetDefaultLabelIsGuardedOnTheSidecarsBytes() throws {
        harness.keychain.put(FakePayload.signedIn("alice").data, pluginAccount)
        let store = harness.store()
        _ = try store.setDefaultLabel("Home")
        let keychain = harness.keychain
        let sidecar = sidecarAccount
        let other = try DefaultSessionMeta(lastWriteTimestamp: TestClock.start, label: "Other", username: "alice", userId: "sub-alice").encoded()
        harness.keychain.onceAfterReading(sidecar) { keychain.put(other, sidecar) }

        XCTAssertEqual(try store.setDefaultLabel("Work"), .discarded)
        XCTAssertEqual(self.sidecar()?.label, "Other")

        guard case .written = try store.setDefaultLabel("Work") else {
            return XCTFail("the second label should be written")
        }
        XCTAssertEqual(self.sidecar()?.label, "Work")
    }

    /// - Given: a live `.default` holding alice, and another writer relabelling the sidecar during the label's first
    ///   attempt
    /// - When: the session is labelled "Work"
    /// - Then:
    ///    - the core retries the discarded write, and the label is "Work"
    func testSetSessionLabelRetriesADiscardedSidecarWrite() async throws {
        harness.keychain.put(FakePayload.signedIn("alice").data, pluginAccount)
        let client = try harness.client(.default)
        _ = await client.currentSessionState()
        let keychain = harness.keychain
        let sidecar = sidecarAccount
        let other = try DefaultSessionMeta(lastWriteTimestamp: TestClock.start, label: "Other", username: "alice", userId: "sub-alice").encoded()
        harness.keychain.onceAfterReading(sidecar) { keychain.put(other, sidecar) }

        try await client.setSessionLabel("Work")

        XCTAssertEqual(self.sidecar()?.label, "Work")
        XCTAssertEqual(try harness.storedRecord(.default)?.label, "Work")
    }

    /// A newer version's sidecar is never overwritten, and the error says it is the label that cannot be read.
    ///
    /// - Given: alice's readable record under the plugin's last configuration, and a sidecar written by a newer schema
    /// - When: `.default` is labelled
    /// - Then:
    ///    - it throws `.unknown` naming the saved label, and neither item is written
    func testLabelOverANewerSchemasSidecarNamesTheLabel() async throws {
        harness.keychain.put(FakePayload.signedIn("alice").data, pluginAccount)
        harness.keychain.recordPluginConfiguration()
        let newer = Data(#"{"lastWriteTimestamp":0,"schemaVersion":2}"#.utf8)
        harness.keychain.put(newer, sidecarAccount)
        let client = try harness.client(.default)
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedIn(alice))

        let error = await authClientError { try await client.setSessionLabel("Home") }

        guard case .unknown(let description, _, _)? = error else {
            return XCTFail("expected .unknown, got \(String(describing: error))")
        }
        XCTAssertTrue(description.contains("saved label"), description)
        XCTAssertFalse(description.contains("saved record"), description)
        XCTAssertEqual(harness.keychain.value(sidecarAccount), newer)
        XCTAssertEqual(harness.keychain.writtenAccounts, [])
    }

    /// A sign-out writes the sidecar only after its guarded commit: a commit another writer beat
    /// leaves that writer's sidecar, never one naming the user who was signing out.
    ///
    /// - Given: alice's record with her sidecar labelled "Work", and another client signing bob in (his record, then
    ///   his sidecar) between the sign-out's guard read of the shared record and its guarded write
    /// - When: the store signs out the alice it read
    /// - Then:
    ///    - the sign-out is superseded; the shared record and the sidecar are bob's, as he wrote them
    func testASupersededSignOutLeavesTheNewWritersSidecar() throws {
        let alice = FakePayload.signedIn("alice")
        harness.keychain.put(alice.data, pluginAccount)
        let store = harness.store()
        _ = try store.setDefaultLabel("Work")
        XCTAssertEqual(sidecar()?.username, "alice")
        let keychain = harness.keychain
        let account = pluginAccount
        let sidecar = sidecarAccount
        let bob = FakePayload.signedIn("bob")
        let bobsSidecar = try DefaultSessionMeta(lastWriteTimestamp: TestClock.start, label: nil, username: "bob", userId: "sub-bob").encoded()
        // The sign-out reads the shared record, then the write reads it again for its guard.
        harness.keychain.onceAfterReading(account, occurrence: 2) {
            keychain.put(bob.data, account)
            keychain.put(bobsSidecar, sidecar)
        }

        let outcome = try store.signOut(.default, removing: alice.data)

        XCTAssertEqual(outcome, .superseded)
        XCTAssertEqual(harness.keychain.value(account), bob.data)
        XCTAssertEqual(harness.keychain.value(sidecar), bobsSidecar)
    }

    /// The label binds to the user it read, never to one another writer signs in meanwhile.
    ///
    /// - Given: a live `.default` holding alice, and the plugin signing bob in between the label's read of the shared
    ///   record and its write
    /// - When: the session is labelled "Work"
    /// - Then:
    ///    - the sidecar is alice's; bob is shown with no label, in the listing and in the session's record
    func testAUserSwitchDuringALabelDoesNotBindTheLabelToTheNewUser() async throws {
        harness.keychain.put(FakePayload.signedIn("alice").data, pluginAccount)
        let client = try harness.client(.default)
        _ = await client.currentSessionState()
        let keychain = harness.keychain
        let account = pluginAccount
        let bob = FakePayload.signedIn("bob")
        harness.keychain.onceAfterReading(account) { keychain.put(bob.data, account) }

        try await client.setSessionLabel("Work")

        let meta = try XCTUnwrap(sidecar())
        XCTAssertEqual(meta.userId, "sub-alice")
        XCTAssertEqual(meta.label, "Work")
        XCTAssertNil(try harness.storedRecord(.default)?.label)
        XCTAssertEqual(try harness.storedRecord(.default)?.username, "bob")
        XCTAssertEqual(try harness.store().storedSessions(), [
            StoredSession(sessionId: .default, label: nil, username: "bob", kind: .userPoolAndIdentityPool)
        ])
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedIn(AuthClientUser(username: "bob", userId: "sub-bob")))
    }

    // MARK: Helpers

    private func sidecar() -> DefaultSessionMeta? {
        guard let data = harness.keychain.value(sidecarAccount), case .meta(let meta) = DefaultSessionMeta.decode(data) else {
            return nil
        }
        return meta
    }

    /// The same credentials in other bytes, deterministically: the stored form (sorted keys, compact) with a space
    /// after its opening brace. A plain `JSONEncoder`'s key order is not fixed, so it may reproduce the stored bytes.
    private func reencode(_ payload: FakePayload) throws -> Data {
        let stored = payload.data
        XCTAssertEqual(stored.first, UInt8(ascii: "{"))
        let data = Data("{ ".utf8) + stored.dropFirst()
        XCTAssertNotEqual(data, stored, "the re-encoding should differ in bytes")
        XCTAssertEqual(FakePayload.decode(data), payload)
        return data
    }

    /// The same credentials pretty-printed with sorted keys: a third encoding, which has line breaks where the stored
    /// form and `reencode` have none.
    private func prettyPrinted(_ payload: FakePayload) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(payload)
        XCTAssertTrue(data.contains(UInt8(ascii: "\n")))
        XCTAssertNotEqual(data, payload.data)
        XCTAssertEqual(FakePayload.decode(data), payload)
        return data
    }

    /// A live payload's credentials encoded again: pretty-printed with sorted keys, so its bytes always differ from
    /// the compact form the engine stores, whatever key order that has.
    private func sortedKeys(_ payload: Data) throws -> Data {
        XCTAssertFalse(payload.contains(UInt8(ascii: "\n")), "the engine's stored form should be compact")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let credentials = try JSONDecoder().decode(AmplifyCredentials.self, from: payload)
        let data = try encoder.encode(credentials)
        XCTAssertNotEqual(data, payload, "the re-encoding should differ in bytes")
        XCTAssertEqual(try JSONDecoder().decode(AmplifyCredentials.self, from: data), credentials)
        return data
    }

    private func reads(of account: String) -> Int {
        harness.keychain.readAccounts.count(where: { $0 == account })
    }

    /// Every account read, written or deleted since the logs were last cleared.
    private func touched() -> [String] {
        harness.keychain.readAccounts + harness.keychain.writtenAccounts + harness.keychain.removedAccounts
    }

    private func credentialsError(_ body: () async throws -> some Any, file: StaticString = #filePath, line: UInt = #line) async -> CredentialsError? {
        do {
            _ = try await body()
            XCTFail("expected an error", file: file, line: line)
            return nil
        } catch let error as CredentialsError {
            return error
        } catch {
            XCTFail("expected a CredentialsError, got \(error)", file: file, line: line)
            return nil
        }
    }

    /// The harness's dependencies, with another store, or with the live engine over scripted Cognito.
    private func dependencies(
        makeStore: (@Sendable (SessionStorageNamespace) -> SessionRecordStore)? = nil,
        live: LiveEngineHarness? = nil
    ) -> SessionCoreDependencies {
        let base = harness.dependencies
        var dependencies = SessionCoreDependencies(
            registry: base.registry,
            gates: base.gates,
            makeStore: makeStore ?? base.makeStore,
            makeClients: base.makeClients,
            makeEngine: { context in
                if let live {
                    return try live.engine()
                }
                return try base.makeEngine(context)
            },
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

    private func liveClient(_ live: LiveEngineHarness) throws -> AmplifyCognitoClient {
        try AmplifyCognitoClient(
            configuration: ClientFixtures.configuration,
            options: .init(sessionId: .default),
            dependencies: dependencies(live: live)
        )
    }
}

/// A count a synchronous keychain hook bumps.
private final class ReadTally: @unchecked Sendable {
    // `@unchecked Sendable`: `count` is only touched while holding `lock`.
    private let lock = NSLock()
    private var count = 0

    func next() -> Int {
        lock.lock()
        defer { lock.unlock() }
        count += 1
        return count
    }
}
