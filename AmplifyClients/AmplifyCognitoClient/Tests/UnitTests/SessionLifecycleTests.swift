//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// Isolation between sessions and lifetime across operations. Every scenario ends with the
/// registry and the gate table back at their baseline.
final class SessionLifecycleTests: XCTestCase {

    private var harness: ClientHarness!
    private let work = ClientFixtures.id("work")
    private let home = ClientFixtures.id("home")

    override func setUp() {
        harness = ClientHarness()
    }

    override func tearDown() async throws {
        await harness.waitForBaseline()
        harness = nil
    }

    /// The isolation matrix: acting on A changes nothing about B — its state, events, record or provider.
    ///
    /// - Given: two signed-in sessions A and B, with subscribers on B
    /// - When: A's label is set, A is signed out through the static call, and then A is purged
    /// - Then:
    ///    - B's state is still its user, B received no state or event, B's record is unchanged, and B's
    ///      provider still vends B's credentials
    func testActingOnOneSessionLeavesAnotherUntouched() async throws {
        let bob = FakePayload.signedIn("bob")
        try harness.signIn(work, .signedIn("alice"))
        let homeRecord = try harness.signIn(home, bob)
        let homeBytes = harness.storedBytes(home)
        let clientA = try harness.client(work)
        let clientB = try harness.client(home)
        _ = await clientA.currentSessionState()
        _ = await clientB.currentSessionState()
        let statesB = StreamRecorder(clientB.listenToSessionStateChanges())
        let eventsB = StreamRecorder(clientB.listenToAuthEvents())

        try await clientA.setSessionLabel("A")
        _ = await AmplifyCognitoClient.signOutStoredSession(
            sessionId: work,
            configuration: ClientFixtures.configuration,
            accessGroup: nil,
            dependencies: harness.dependencies
        )
        try await AmplifyCognitoClient.purgeStoredSession(
            sessionId: work,
            configuration: ClientFixtures.configuration,
            accessGroup: nil,
            dependencies: harness.dependencies
        )

        let stateA = await clientA.currentSessionState()
        let stateB = await clientB.currentSessionState()
        XCTAssertEqual(stateA, .signedOut)
        XCTAssertEqual(stateB, .signedIn(AuthClientUser(username: "bob", userId: "sub-bob")))
        XCTAssertEqual(statesB.received, [])
        XCTAssertEqual(eventsB.received, [])
        guard case .record(let stored) = try harness.store().read(home) else {
            return XCTFail("B's record is gone")
        }
        XCTAssertEqual(stored, homeRecord)
        XCTAssertEqual(harness.storedBytes(home), homeBytes)
        let credentialsB = try await clientB.credentialsProvider.resolve()
        XCTAssertEqual(credentialsB as? CognitoAWSCredentials, bob.awsCredentials)
        XCTAssertEqual(harness.engine(for: home)?.revokeCalls, [])
    }

    /// The isolation matrix, extended to every session operation.
    ///
    /// - Given: a signed-out session A and a signed-in session B, with subscribers on B
    /// - When: A fetches guest credentials, signs in through a challenge, force-refreshes, signs out
    ///   globally, signs in again and deletes its user
    /// - Then:
    ///    - A saw every transition; B's state, events, record, provider and engine are all untouched
    func testEverySessionOperationLeavesAnotherSessionUntouched() async throws {
        let bob = FakePayload.signedIn("bob")
        let homeRecord = try harness.signIn(home, bob)
        let homeBytes = harness.storedBytes(home)
        let clientA = try harness.client(work)
        let clientB = try harness.client(home)
        _ = await clientA.currentSessionState()
        _ = await clientB.currentSessionState()
        let eventsA = StreamRecorder(clientA.listenToAuthEvents())
        let statesB = StreamRecorder(clientB.listenToSessionStateChanges())
        let eventsB = StreamRecorder(clientB.listenToAuthEvents())
        let engineA = try XCTUnwrap(harness.engine(for: work))
        engineA.scriptSignIn { _, _ in .challenge(.confirmSignInWithTOTPCode) }

        _ = try await clientA.fetchAuthSession()
        _ = try await clientA.signInForTest("alice")
        _ = try await clientA.confirmSignIn(challengeResponse: "123456")
        _ = try await clientA.fetchAuthSession(options: .init(forceRefresh: true))
        _ = await clientA.signOut(options: .init(globalSignOut: true))
        engineA.scriptSignIn { request, _ in .done(payload: FakePayload.signedIn(request.username).data) }
        _ = try await clientA.signInForTest("alice")
        try await clientA.deleteUser()

        await eventsA.waitFor(4)
        XCTAssertEqual(eventsA.received, [.signedIn, .signedOut, .signedIn, .userDeleted])
        let stateB = await clientB.currentSessionState()
        XCTAssertEqual(stateB, .signedIn(AuthClientUser(username: "bob", userId: "sub-bob")))
        XCTAssertEqual(statesB.received, [])
        XCTAssertEqual(eventsB.received, [])
        XCTAssertEqual(try harness.store().read(home), .record(homeRecord))
        XCTAssertEqual(harness.storedBytes(home), homeBytes)
        let credentialsB = try await clientB.credentialsProvider.resolve()
        XCTAssertEqual(credentialsB as? CognitoAWSCredentials, bob.awsCredentials)
        let engineB = try XCTUnwrap(harness.engine(for: home))
        XCTAssertEqual(engineB.signInCalls.count, 0)
        XCTAssertEqual(engineB.confirmSignInCalls, [])
        XCTAssertEqual(engineB.refreshCalls, [])
        XCTAssertEqual(engineB.revokeCalls, [])
        XCTAssertEqual(engineB.deleteUserCalls, [])
        XCTAssertEqual(engineB.guestFetchCount, 0)
    }

    /// Work in flight keeps its session alive, independently of any handle or caller. The shared refresh
    /// runs in the session's single-flight task, so once the only caller has given up and every handle and
    /// provider is gone, that task alone must hold the session until the refresh has committed.
    ///
    /// - Given: a session needing a refresh, with the refresh held open, and one provider call waiting on it
    /// - When: the call is cancelled and has returned, every handle and provider is dropped, and then the
    ///   refresh is let go
    /// - Then:
    ///    - the session is still alive while the refresh is held, with nothing but the refresh holding it
    ///    - the refresh commits, and only afterwards is the session released
    func testWorkInFlightKeepsTheSessionAliveAfterEveryHandleAndCallerIsGone() async throws {
        let stale = FakePayload.signedIn("alice", stale: true)
        try harness.signIn(work, stale)
        var client: AmplifyCognitoClient? = try harness.client(work)
        weak let probe = client?.core
        let latch = Gate()
        try XCTUnwrap(harness.engine(for: work)).holdRefreshes(on: latch)
        var provider: CognitoCredentialsProvider? = client?.credentialsProvider
        var call: Task<CognitoAWSCredentials?, Error>? = Task { [provider] in
            try await provider?.resolve() as? CognitoAWSCredentials
        }
        await latch.waitForArrivals(1)

        call?.cancel()
        await assertThrowsAsync({ try await call?.value }) { error in
            XCTAssertTrue(error is CancellationError, "\(error)")
        }
        call = nil
        client = nil
        provider = nil
        _ = (client, provider, call)
        XCTAssertNotNil(probe, "the refresh in flight alone holds the session")
        await latch.open()

        let refreshed = stale.refreshed.data
        await waitUntil("the refresh commits") { (try? harness.storedRecord(work)?.credentials) == refreshed }
        await waitUntil("the session is released once the refresh is done") { probe == nil }
    }

    /// - Given: many sessions, each built, restored, used and dropped, some twice over
    /// - When: every handle is gone
    /// - Then:
    ///    - no session is live, and the registry and gate table are empty
    func testManySessionsReturnToBaseline() async throws {
        for round in 0 ..< 2 {
            var clients: [AmplifyCognitoClient] = []
            for index in 0 ..< 10 {
                let sessionId = ClientFixtures.id("session-\(index)")
                if round == 0 {
                    try harness.signIn(sessionId, .signedIn("user\(index)"))
                }
                clients.append(try harness.client(sessionId))
                clients.append(try harness.client(sessionId))
            }
            for client in clients {
                _ = await client.currentSessionState()
            }
            XCTAssertEqual(harness.registry.liveSessionIDs.count, 10)
            clients.removeAll()
            await harness.waitForBaseline()
        }
        XCTAssertEqual(harness.engines.count, 20)
    }
}
