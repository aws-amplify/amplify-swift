//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyFoundation
import Security
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// The per-session event and state streams, and the publishing rule.
final class SessionStreamsTests: XCTestCase {

    private var harness: ClientHarness!
    private let work = ClientFixtures.id("work")
    private let home = ClientFixtures.id("home")
    private let alice = AuthClientUser(username: "alice", userId: "sub-alice")

    override func setUp() {
        harness = ClientHarness()
    }

    override func tearDown() async throws {
        harness.keychain.clearFailures()
        await harness.waitForBaseline()
        harness = nil
    }

    private func purge(_ sessionId: SessionID) async throws {
        try await AmplifyCognitoClient.purgeStoredSession(
            sessionId: sessionId,
            configuration: ClientFixtures.configuration,
            accessGroup: nil,
            dependencies: harness.dependencies
        )
    }

    /// - Given: a signed-in session with two event subscribers and two state subscribers
    /// - When: it is purged through a static call, which routes to the live session
    /// - Then:
    ///    - both event subscribers receive `.signedOut`, and both state subscribers the restored state
    ///      and then `.signedOut`
    func testEverySubscriberReceives() async throws {
        try harness.signIn(work, .signedIn("alice"))
        let client = try harness.client(work)
        let events = [StreamRecorder(client.listenToAuthEvents()), StreamRecorder(client.listenToAuthEvents())]
        let states = [
            StreamRecorder(client.listenToSessionStateChanges()),
            StreamRecorder(client.listenToSessionStateChanges())
        ]
        _ = await client.currentSessionState()

        try await purge(work)

        for recorder in events {
            await recorder.waitFor(1)
            XCTAssertEqual(recorder.received, [.signedOut])
        }
        for recorder in states {
            await recorder.waitFor(2)
            XCTAssertEqual(recorder.received, [.signedIn(alice), .signedOut])
        }
    }

    /// - Given: a session that has already restored and published its state
    /// - When: a subscriber attaches afterwards, and then the state changes
    /// - Then:
    ///    - the subscriber receives only the change, with nothing replayed
    func testNoReplay() async throws {
        try harness.signIn(work, .signedIn("alice"))
        let client = try harness.client(work)
        _ = await client.currentSessionState()
        let late = StreamRecorder(client.listenToSessionStateChanges())
        let lateEvents = StreamRecorder(client.listenToAuthEvents())

        await client.core.setPendingChallenge(.confirmSignInWithTOTPCode)

        await late.waitFor(1)
        XCTAssertEqual(late.received, [.awaitingChallenge(.confirmSignInWithTOTPCode)])
        XCTAssertEqual(lateEvents.received, [])
    }

    /// - Given: a subscriber attached right after construction, before any restore
    /// - When: the session restores
    /// - Then:
    ///    - the subscriber receives the restored state
    func testSubscriberBeforeRestoreSeesTheRestoredState() async throws {
        try harness.signIn(work, .signedIn("alice"))
        let client = try harness.client(work)
        let states = StreamRecorder(client.listenToSessionStateChanges())

        _ = await client.currentSessionState()

        await states.waitFor(1)
        XCTAssertEqual(states.received, [.signedIn(alice)])
    }

    /// - Given: a failed restore, then a successful one once storage recovers
    /// - When: a state subscriber watches
    /// - Then:
    ///    - it sees `.unavailable(.locked)` and then the user — never `.signedOut`
    func testFailedRestorePublishesUnavailableThenRecovery() async throws {
        try harness.signIn(work, .signedIn("alice"))
        let client = try harness.client(work)
        let states = StreamRecorder(client.listenToSessionStateChanges())
        harness.keychain.failing(.read, with: errSecInteractionNotAllowed)
        _ = await client.currentSessionState()

        harness.keychain.clearFailures()
        _ = await client.currentSessionState()

        await states.waitFor(2)
        XCTAssertEqual(states.received, [.unavailable(.locked), .signedIn(alice)])
    }

    /// Each session has its own streams, so one session's events can neither reach nor be suppressed
    /// by another's.
    ///
    /// - Given: two signed-in sessions, each with subscribers
    /// - When: one of them is purged
    /// - Then:
    ///    - only its subscribers receive anything; the other session's receive nothing
    func testOneSessionsEventsNeverReachAnother() async throws {
        try harness.signIn(work, .signedIn("alice"))
        try harness.signIn(home, .signedIn("bob"))
        let workClient = try harness.client(work)
        let homeClient = try harness.client(home)
        _ = await workClient.currentSessionState()
        _ = await homeClient.currentSessionState()
        let workEvents = StreamRecorder(workClient.listenToAuthEvents())
        let homeEvents = StreamRecorder(homeClient.listenToAuthEvents())
        let homeStates = StreamRecorder(homeClient.listenToSessionStateChanges())

        try await purge(work)
        await workEvents.waitFor(1)

        XCTAssertEqual(workEvents.received, [.signedOut])
        XCTAssertEqual(homeEvents.received, [])
        XCTAssertEqual(homeStates.received, [])
        let homeState = await homeClient.currentSessionState()
        XCTAssertEqual(homeState, .signedIn(AuthClientUser(username: "bob", userId: "sub-bob")))
    }

    /// The state stream sends only changes, but two different challenge steps are two different states
    /// — the regression where a payload-blind comparison swallowed the second.
    ///
    /// - Given: a restored, signed-out session with a state subscriber
    /// - When: a challenge step is set, set again unchanged, then a different step, then cleared
    /// - Then:
    ///    - the subscriber receives the first step, the second step, and `.signedOut` — not the repeat
    func testDifferentChallengesBothPublishAndRepeatsDoNot() async throws {
        let client = try harness.client(work)
        _ = await client.currentSessionState()
        let states = StreamRecorder(client.listenToSessionStateChanges())

        await client.core.setPendingChallenge(.confirmSignInWithTOTPCode)
        await client.core.setPendingChallenge(.confirmSignInWithTOTPCode)
        await client.core.setPendingChallenge(.confirmSignInWithSMSMFACode(
            AuthClientCodeDeliveryDetails(destination: .sms("+1***"), attributeKey: nil),
            nil
        ))
        await client.core.setPendingChallenge(nil)

        await states.waitFor(3)
        XCTAssertEqual(states.received.count, 3)
        XCTAssertEqual(states.received.first, .awaitingChallenge(.confirmSignInWithTOTPCode))
        XCTAssertEqual(states.received.last, .signedOut)
    }

    /// - Given: a signed-in session with a state subscriber
    /// - When: its label is set
    /// - Then:
    ///    - no state is published and no event is sent: a label is not state
    func testLabelChangePublishesNothing() async throws {
        try harness.signIn(work, .signedIn("alice"))
        let client = try harness.client(work)
        _ = await client.currentSessionState()
        let states = StreamRecorder(client.listenToSessionStateChanges())
        let events = StreamRecorder(client.listenToAuthEvents())

        try await client.setSessionLabel("Work")
        await client.core.setPendingChallenge(.confirmSignInWithTOTPCode)

        await states.waitFor(1)
        XCTAssertEqual(states.received, [.awaitingChallenge(.confirmSignInWithTOTPCode)], "the label published nothing")
        XCTAssertEqual(events.received, [])
    }

    /// A subscription does not keep its session alive.
    ///
    /// - Given: a session with an event and a state subscriber, each iterated in a `for await` loop
    /// - When: its only handle is dropped
    /// - Then:
    ///    - the session is released, and both loops exit
    func testDroppingTheLastHandleEndsBothStreams() async throws {
        var client: AmplifyCognitoClient? = try harness.client(work)
        let events = StreamRecorder(try XCTUnwrap(client).listenToAuthEvents())
        let states = StreamRecorder(try XCTUnwrap(client).listenToSessionStateChanges())
        weak let probe = client?.core

        client = nil
        _ = client

        XCTAssertNil(probe)
        await events.waitForFinish()
        await states.waitForFinish()
    }
}
