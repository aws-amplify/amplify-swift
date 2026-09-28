//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// `autoSignIn()`'s route through the core: the plugin's order of checks,
/// the sign-in commit, and the auto-sign-in session being per session ID.
final class AutoSignInRoutingTests: XCTestCase {

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

    /// A sign-up whose result lets `autoSignIn()` complete it.
    private func signUpForAutoSignIn(
        _ client: AmplifyCognitoClient,
        engine: FakeSessionEngine,
        username: String = "carol"
    ) async throws {
        engine.scriptPhase5(.signUp) { _ in
            AuthClientSignUpResult(.completeAutoSignIn("session-\(username)"), userId: "sub-\(username)")
        }
        _ = try await client.signUp(username: username)
    }

    private static let notSignedUp =
        "Not in a signed up state. Please call signUp() and confirmSignUp() before calling autoSignIn()"

    /// The auto-sign-in session is per session ID, so a sign-up on `work` signs in `work` only.
    ///
    /// - Given: two signed-out sessions, and a sign-up on `work` ready for auto sign-in
    /// - When: `work`'s `autoSignIn()` completes, then `home`'s is called
    /// - Then:
    ///    - `work` is signed in as the signed-up user, its record is committed and `.signedIn` is sent;
    ///      `home` has no sign-up to complete, its engine is not asked to sign in, and it stays signed out
    func testAutoSignInCommitsOnItsOwnSessionOnly() async throws {
        let client = try harness.client(work)
        let homeClient = try harness.client(home)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let other = try XCTUnwrap(harness.engine(for: home))
        _ = await client.currentSessionState()
        let events = StreamRecorder(client.listenToAuthEvents())

        try await signUpForAutoSignIn(client, engine: engine)
        let result = try await client.autoSignIn()

        XCTAssertEqual(result, AuthClientSignInResult(nextStep: .done))
        XCTAssertEqual(engine.phase5Calls.map(\.operation), [.signUp, .autoSignIn])
        // The engine gets the core's epoch for the attempt, as `signIn` does.
        let epoch = await client.core.signInEpoch
        XCTAssertEqual(engine.phase5Calls.last, .autoSignIn(current: nil, epoch: epoch))
        XCTAssertEqual(try harness.storedRecord(work)?.username, "carol")
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedIn(AuthClientUser(username: "carol", userId: "sub-carol")))
        await events.waitFor(1)
        XCTAssertEqual(events.received, [.signedIn])
        await assertThrowsAsync({ try await homeClient.autoSignIn() }) { error in
            guard case .invalidState(let description, _, _) = authError(error) else {
                return XCTFail("\(error)")
            }
            XCTAssertEqual(description, Self.notSignedUp)
        }
        XCTAssertEqual(other.phase5Calls, [])
        let homeState = await homeClient.currentSessionState()
        XCTAssertEqual(homeState, .signedOut)
    }

    /// The plugin checks its sign-up state before anything else (`AWSAuthAutoSignInTask.swift:71-92`).
    ///
    /// - Given: a signed-in session with no sign-up, and a session waiting on a challenge with no sign-up
    /// - When: `autoSignIn()` is called on each
    /// - Then:
    ///    - both throw "Not in a signed up state…" with the plugin's suggestion, the engine is not asked to
    ///      sign in, and the pending challenge is kept
    func testAutoSignInWithoutASignUpIsRefusedFirst() async throws {
        try harness.signIn(work, .signedIn("alice"))
        let signedIn = try harness.client(work)
        let pending = try harness.client(home)
        let homeEngine = try XCTUnwrap(harness.engine(for: home))
        homeEngine.scriptSignIn { _, _ in .challenge(.confirmSignInWithTOTPCode) }
        _ = try await pending.signIn(username: "bob", password: "password")

        for client in [signedIn, pending] {
            await assertThrowsAsync({ try await client.autoSignIn() }) { error in
                guard case .invalidState(let description, let suggestion, _) = authError(error) else {
                    return XCTFail("\(error)")
                }
                XCTAssertEqual(description, Self.notSignedUp)
                XCTAssertEqual(suggestion, "Operation performed is not a valid operation for the current auth state")
            }
        }
        XCTAssertEqual(harness.engine(for: work)?.phase5Calls, [])
        XCTAssertEqual(homeEngine.phase5Calls, [])
        XCTAssertEqual(homeEngine.supersededCount, 0)
        let state = await pending.currentSessionState()
        XCTAssertEqual(state, .awaitingChallenge(.confirmSignInWithTOTPCode))
    }

    /// - Given: a session already signed in, with a sign-up ready for auto sign-in
    /// - When: `autoSignIn()` is called
    /// - Then:
    ///    - it throws the plugin's "already signed in" `invalidState`, and the engine is not asked to sign in
    func testAutoSignInIsRefusedOnASignedInSession() async throws {
        try harness.signIn(work, .signedIn("alice"))
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        try await signUpForAutoSignIn(client, engine: engine)

        await assertThrowsAsync({ try await client.autoSignIn() }) { error in
            guard case .invalidState(let description, _, _) = authError(error) else {
                return XCTFail("\(error)")
            }
            XCTAssertEqual(description, "There is already a user in signedIn state. SignOut the user first before calling signIn")
        }
        XCTAssertEqual(engine.phase5Calls.map(\.operation), [.signUp])
    }

    /// - Given: a sign-up ready for auto sign-in, and an engine whose auto sign-in Cognito refuses
    /// - When: `autoSignIn()` is called
    /// - Then:
    ///    - the error reaches the caller, and nothing is committed
    func testAutoSignInFailureReachesTheCaller() async throws {
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        try await signUpForAutoSignIn(client, engine: engine)
        engine.scriptPhase5(.autoSignIn) { _ in
            throw AuthClientError.notAuthorized("Invalid session for the user.", "")
        }

        await assertThrowsAsync({ try await client.autoSignIn() }) { error in
            guard case .notAuthorized = authError(error) else {
                return XCTFail("\(error)")
            }
        }
        XCTAssertNil(try harness.storedRecord(work))
    }

    /// Only a `.completeAutoSignIn` result leaves an auto-sign-in session.
    ///
    /// - Given: a sign-up that returns `.confirmUser`, and one that throws
    /// - When: `autoSignIn()` is called after each
    /// - Then:
    ///    - both throw "Not in a signed up state…", and the engine is not asked to sign in
    func testOnlyACompleteAutoSignInResultLeavesASession() async throws {
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))

        engine.scriptPhase5(.signUp) { _ in AuthClientSignUpResult(.confirmUser()) }
        _ = try await client.signUp(username: "carol")
        await assertThrowsAsync({ try await client.autoSignIn() }) { error in
            XCTAssertEqual(authError(error)?.errorDescription, Self.notSignedUp)
        }

        engine.scriptPhase5(.signUp) { _ in throw AuthClientError.service(.usernameExists, "exists", "") }
        await assertThrowsAsync { try await client.signUp(username: "carol") }
        await assertThrowsAsync({ try await client.autoSignIn() }) { error in
            XCTAssertEqual(authError(error)?.errorDescription, Self.notSignedUp)
        }
        XCTAssertEqual(engine.phase5Calls.map(\.operation), [.signUp, .signUp])
    }

    /// As the plugin never resets its sign-up state, the auto-sign-in session outlives the sign-in it made
    /// and a sign-out, so a second `autoSignIn()` reaches Cognito again (AS-3).
    ///
    /// - Given: a confirmation ready for auto sign-in, and a completed `autoSignIn()`
    /// - When: the session signs out and calls `autoSignIn()` again
    /// - Then:
    ///    - the engine is asked to sign in a second time, and the session is signed in again
    func testTheAutoSignInSessionSurvivesSignInAndSignOut() async throws {
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        engine.scriptPhase5(.confirmSignUp) { _ in AuthClientSignUpResult(.completeAutoSignIn("session")) }
        _ = try await client.confirmSignUp(for: "carol", confirmationCode: "123456")

        _ = try await client.autoSignIn()
        try await client.signOut()
        let second = try await client.autoSignIn()

        XCTAssertEqual(second.nextStep, .done)
        XCTAssertEqual(engine.phase5Calls.map(\.operation), [.confirmSignUp, .autoSignIn, .autoSignIn])
        XCTAssertEqual(engine.cancelPendingSignInCount, 1)
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedIn(AuthClientUser(username: "carol", userId: "sub-carol")))
    }

    /// `autoSignIn` is a sign-in step: a sign-out while it waits on Cognito cancels it.
    ///
    /// - Given: a sign-up ready for auto sign-in, and an `autoSignIn()` held in the engine
    /// - When: the session signs out, then the step is released
    /// - Then:
    ///    - `autoSignIn()` throws the core's sign-in-cancelled `invalidState`, nothing is committed, and the
    ///      auto-sign-in session is still there
    func testSignOutCancelsAnAutoSignInInFlight() async throws {
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        try await signUpForAutoSignIn(client, engine: engine)
        let latch = Gate()
        engine.holdSignIns(on: latch)

        let pending = Task { try await client.autoSignIn() }
        await latch.waitForArrivals(1)
        try await client.signOut()
        await latch.open()

        await assertThrowsAsync({ try await pending.value }) { error in
            XCTAssertEqual(authError(error)?.errorDescription, SessionCore.signInCancelled().errorDescription)
        }
        XCTAssertNil(try harness.storedRecord(work)?.credentials)
        let held = await engine.hasAutoSignInSession
        XCTAssertTrue(held)
    }
}
