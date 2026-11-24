//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyFoundation
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// What a live client does once its session is purged through the static `purgeStoredSession`: every call
/// that needs a user throws `notSignedIn`, its providers throw `CredentialsError.notSignedIn`, every handle on
/// the session agrees, and nothing brings the deleted record back.
///
/// The purge itself, and a live session routing it, are `StoredSessionManagementTests`; a purge during a
/// pending challenge is `ChallengeTests.testAPurgeDuringAConfirmationWins`.
final class PurgedLiveSessionTests: XCTestCase {

    private var harness: ClientHarness!
    private let work = ClientFixtures.id("work")
    private var pluginAccount: String { SessionRecordKey.pluginSessionAccount(in: StorageFixtures.pools) }

    override func setUp() {
        harness = ClientHarness()
    }

    override func tearDown() async throws {
        harness.keychain.clearFailures()
        await harness.waitForBaseline()
        harness = nil
    }

    // MARK: Helpers

    private static func purge(
        _ sessionId: SessionID,
        configuration: AuthClientConfiguration = ClientFixtures.configuration,
        dependencies: SessionCoreDependencies
    ) async throws {
        try await AmplifyCognitoClient.purgeStoredSession(
            sessionId: sessionId,
            configuration: configuration,
            accessGroup: nil,
            dependencies: dependencies
        )
    }

    /// A restored, signed-in client for `sessionId`, whose session is then purged through the static call.
    private func purgedClient(_ sessionId: SessionID) async throws -> AmplifyCognitoClient {
        try harness.signIn(sessionId, .signedIn("alice"))
        let client = try harness.client(sessionId)
        _ = await client.currentSessionState()
        try await Self.purge(sessionId, dependencies: harness.dependencies)
        return client
    }

    private func assertNotSignedIn(
        _ call: () async throws -> some Any,
        _ name: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        await assertThrowsAsync(call) { error in
            XCTAssertEqual((error as? AuthClientError)?.kind, .notSignedIn, "\(name): \(error)", file: file, line: line)
        }
    }

    // MARK: Calls that need a user

    /// - Given: a live, signed-in client whose session is then purged
    /// - When: it is asked for its user, its attributes, its devices and a TOTP setup, and to delete its user
    /// - Then:
    ///    - each throws `notSignedIn`, without a refresh and without reaching the engine
    func testCallsThatNeedAUserThrowNotSignedIn() async throws {
        let client = try await purgedClient(work)
        let engine = try XCTUnwrap(harness.engine(for: work))

        await assertNotSignedIn({ try await client.getCurrentUser() }, "getCurrentUser")
        await assertNotSignedIn({ try await client.fetchUserAttributes() }, "fetchUserAttributes")
        await assertNotSignedIn({ try await client.fetchDevices() }, "fetchDevices")
        await assertNotSignedIn({ try await client.setUpTOTP() }, "setUpTOTP")
        await assertNotSignedIn({ try await client.deleteUser() }, "deleteUser")

        XCTAssertEqual(engine.refreshCalls, [])
        XCTAssertEqual(engine.accountOperationCalls, [])
        XCTAssertEqual(engine.deleteUserCalls, [])
    }

    // MARK: Providers

    /// A provider handed to another client (Kinesis, Firehose, AppSync) before the purge follows its session.
    ///
    /// - Given: the credentials and token providers of a live, signed-in client, taken before its session is
    ///   purged
    /// - When: each is asked for credentials after the purge
    /// - Then:
    ///    - both throw `CredentialsError.notSignedIn`, whose disposition tells a buffering client to discard
    ///      its queued records; no refresh is attempted
    func testProvidersTakenBeforeThePurgeThrowNotSignedIn() async throws {
        try harness.signIn(work, .signedIn("alice"))
        let client = try harness.client(work)
        _ = await client.currentSessionState()
        let credentialsProvider = client.credentialsProvider
        let tokenProvider = client.userPoolTokenProvider

        try await Self.purge(work, dependencies: harness.dependencies)

        await assertThrowsAsync({ try await credentialsProvider.resolve() }) { error in
            let credentialsError = error as? CredentialsError
            XCTAssertEqual(credentialsError?.isNotSignedIn, true, "\(error)")
            XCTAssertEqual(credentialsError?.disposition, .discard)
        }
        await assertThrowsAsync({ try await tokenProvider.accessToken() }) { error in
            let credentialsError = error as? CredentialsError
            XCTAssertEqual(credentialsError?.isNotSignedIn, true, "\(error)")
            XCTAssertEqual(credentialsError?.disposition, .discard)
        }
        XCTAssertEqual(harness.engine(for: work)?.refreshCalls, [])
    }

    // MARK: fetchAuthSession

    /// A purged session is a signed-out one: with guest access it becomes a guest, with no user.
    ///
    /// - Given: a live client whose session is purged, with an identity pool that allows guests
    /// - When: its session is fetched
    /// - Then:
    ///    - the user fields are `nil`, guest credentials are fetched once, and the state is `.guest`, never the
    ///      purged user
    func testFetchAuthSessionAfterAPurgeIsAGuestWhenTheIdentityPoolAllowsIt() async throws {
        let client = try await purgedClient(work)
        let engine = try XCTUnwrap(harness.engine(for: work))

        let session = try await client.fetchAuthSession()

        XCTAssertNil(session.userSub)
        XCTAssertNil(session.userPoolTokens)
        XCTAssertEqual(session.identityId, "us-east-1:guest")
        XCTAssertEqual(engine.guestFetchCount, 1)
        XCTAssertEqual(engine.refreshCalls, [])
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .guest)
    }

    /// - Given: a live client whose session is purged, with an identity pool that allows no guests
    /// - When: its session is fetched
    /// - Then:
    ///    - it throws `notSignedIn`, as a signed-out session's does; the state stays `.signedOut` and no record
    ///      is written
    func testFetchAuthSessionAfterAPurgeThrowsNotSignedInWithoutGuestAccess() async throws {
        let client = try await purgedClient(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        engine.scriptGuestCredentials { _ in throw SessionEngineError.notSignedIn }

        await assertNotSignedIn({ try await client.fetchAuthSession() }, "fetchAuthSession")

        XCTAssertEqual(engine.refreshCalls, [])
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedOut)
        XCTAssertNil(try harness.storedRecord(work))
    }

    // MARK: Every handle

    /// Two clients with one session ID are two handles onto one session, so a purge reaches both.
    ///
    /// - Given: two live clients for the same signed-in session, the second subscribed to its events
    /// - When: the session is purged
    /// - Then:
    ///    - both are `.signedOut`, the second's provider throws `notSignedIn`, and the second heard `.signedOut`
    ///      once, from the one session both share
    func testEveryHandleOnThePurgedSessionIsSignedOut() async throws {
        try harness.signIn(work, .signedIn("alice"))
        let first = try harness.client(work)
        let second = try harness.client(work)
        _ = await first.currentSessionState()
        let events = StreamRecorder(second.listenToAuthEvents())

        try await Self.purge(work, dependencies: harness.dependencies)

        let firstState = await first.currentSessionState()
        let secondState = await second.currentSessionState()
        XCTAssertEqual(firstState, .signedOut)
        XCTAssertEqual(secondState, .signedOut)
        await assertThrowsAsync({ try await second.credentialsProvider.resolve() }) { error in
            XCTAssertEqual((error as? CredentialsError)?.isNotSignedIn, true, "\(error)")
        }
        await events.waitFor(1)
        XCTAssertEqual(events.received, [.signedOut])
        XCTAssertEqual(harness.engines.count, 1, "one session, so one engine")
    }

    // MARK: A purge racing a refresh

    /// A refresh in flight can't bring a purged record back: the refresh holds the record's gate, so the purge
    /// waits for it and then deletes what it saved.
    ///
    /// - Given: a live session whose credentials need a refresh, with the refresh held open and one caller
    ///   waiting on it
    /// - When: the session is purged while the refresh is held, and, once the purge is waiting on the record's
    ///   gate, the refresh is let go
    /// - Then:
    ///    - the waiting caller gets the refreshed credentials, which the refresh saved first
    ///    - the purge then completes: the record is gone, the state is `.signedOut`, and the next call throws
    ///      `notSignedIn` without another refresh
    func testAPurgeDuringARefreshNeverResurrectsTheRecord() async throws {
        try harness.signIn(work, .signedIn("alice", stale: true))
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        _ = await client.currentSessionState()
        let latch = Gate()
        engine.holdRefreshes(on: latch)
        let provider = client.credentialsProvider
        let dependencies = harness.dependencies
        let work = work

        let inFlight = Task { try await provider.resolve().accessKeyId }
        await latch.waitForArrivals(1)
        // The type by name: Xcode 26's compiler rejects `Self` captured in a `Task` here.
        let purge = Task { try await PurgedLiveSessionTests.purge(work, dependencies: dependencies) }
        let namespace = SessionStorageNamespace(pools: ClientFixtures.configuration.poolNamespace, accessGroup: nil)
        let gate = harness.gates.gate(for: namespace, sessionId: work)
        await waitUntil("the purge waits on the record's gate") { await gate.waiterCount == 1 }
        await latch.open()
        try await purge.value

        let refreshed = try await inFlight.value
        XCTAssertFalse(refreshed.isEmpty)
        XCTAssertEqual(try harness.store().read(work), .absent)
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedOut)
        await assertThrowsAsync({ try await provider.resolve() }) { error in
            XCTAssertEqual((error as? CredentialsError)?.isNotSignedIn, true, "\(error)")
        }
        XCTAssertEqual(engine.refreshCalls.count, 1)
    }

    // MARK: Signing in again

    /// A purged session is usable again, and starts clean.
    ///
    /// - Given: a live, labelled, signed-in client whose session is purged
    /// - When: the user signs in again through it
    /// - Then:
    ///    - a new record is saved for the user, without the purged row's label, and the client is signed in
    func testSigningInAgainAfterAPurgeStartsAFreshRow() async throws {
        try harness.signIn(work, .signedIn("alice"), label: "Work")
        let client = try harness.client(work)
        _ = await client.currentSessionState()
        try await Self.purge(work, dependencies: harness.dependencies)

        _ = try await client.signInForTest()

        let record = try XCTUnwrap(harness.storedRecord(work))
        XCTAssertNil(record.label)
        XCTAssertEqual(record.username, "alice")
        XCTAssertFalse(record.isSignedOut)
        let state = await client.currentSessionState()
        guard case .signedIn = state else {
            return XCTFail("\(state)")
        }
    }

    // MARK: Listing and the default session

    /// - Given: a live client whose session is purged
    /// - When: saved sessions are listed, signed-out rows included
    /// - Then:
    ///    - the purged session isn't listed: its row is gone, not signed out
    func testAPurgedSessionIsNotListed() async throws {
        let client = try await purgedClient(work)

        let rows = try await AmplifyCognitoClient.storedSessions(
            configuration: ClientFixtures.configuration,
            accessGroup: nil,
            includingSignedOut: true,
            dependencies: harness.dependencies
        )

        XCTAssertFalse(rows.contains { $0.sessionId == work }, "\(rows)")
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedOut)
    }

    /// - Given: a live client on `.default`, which reads and writes the Auth plugin's saved login
    /// - When: `.default` is purged through the static call
    /// - Then:
    ///    - the plugin's record is gone, the client is `.signedOut`, and its provider throws `notSignedIn`
    func testPurgingTheDefaultSessionWithALiveClient() async throws {
        let client = try await purgedClient(.default)

        XCTAssertNil(harness.keychain.value(pluginAccount))
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedOut)
        await assertThrowsAsync({ try await client.credentialsProvider.resolve() }) { error in
            XCTAssertEqual((error as? CredentialsError)?.isNotSignedIn, true, "\(error)")
        }
    }

    // MARK: Refused

    /// A live client owns its session's record, so a purge under another configuration can't delete it.
    ///
    /// - Given: a live, signed-in client for `"work"` built with a user-pool-only configuration
    /// - When: `"work"` is purged with a configuration that adds an identity pool
    /// - Then:
    ///    - the purge throws `sessionConfigurationMismatch` naming the session, and the live client is untouched
    func testAPurgeUnderAnotherConfigurationThanTheLiveClientsIsRefused() async throws {
        let configuration = ClientFixtures.userPoolOnlyConfiguration
        let client = try harness.client(work, configuration: configuration)
        _ = try await client.signInForTest()
        let before = await client.currentSessionState()
        let dependencies = harness.dependencies
        let work = work

        await assertThrowsAsync({ try await Self.purge(work, dependencies: dependencies) }) { error in
            guard case .sessionConfigurationMismatch(let sessionId)? = (error as? AuthClientError)?.kind else {
                return XCTFail("\(error)")
            }
            XCTAssertEqual(sessionId, work)
        }

        let after = await client.currentSessionState()
        XCTAssertEqual(after, before)
        XCTAssertNotEqual(after, .signedOut)
    }
}
