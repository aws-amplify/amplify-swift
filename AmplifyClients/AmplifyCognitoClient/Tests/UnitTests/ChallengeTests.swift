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

/// The pending challenge and `confirmSignIn`: set on a challenge, published on both
/// streams, retried after a wrong answer, superseded by a new sign-in, cleared on completion, expiry and
/// sign-out, and per session.
final class ChallengeTests: XCTestCase {

    private var harness: ClientHarness!
    private let work = ClientFixtures.id("work")
    private let home = ClientFixtures.id("home")
    private let alice = AuthClientUser(username: "alice", userId: "sub-alice")
    private let smsCode = AuthClientSignInStep.confirmSignInWithSMSMFACode(
        AuthClientCodeDeliveryDetails(destination: .sms("+1***"), attributeKey: .phoneNumber),
        nil
    )

    override func setUp() {
        harness = ClientHarness()
    }

    override func tearDown() async throws {
        await harness.waitForBaseline()
        harness = nil
    }

    private func challengedClient(
        _ sessionId: SessionID,
        step: AuthClientSignInStep = .confirmSignInWithTOTPCode
    ) async throws -> (AmplifyCognitoClient, FakeSessionEngine) {
        let client = try harness.client(sessionId)
        let engine = try XCTUnwrap(harness.engine(for: sessionId))
        engine.scriptSignIn { _, _ in .challenge(step) }
        let result = try await client.signInForTest("alice")
        XCTAssertEqual(result.nextStep, step)
        return (client, engine)
    }

    /// - Given: a sign-in that stops on a TOTP challenge
    /// - When: the state is read, and the user answers
    /// - Then:
    ///    - the result is the step and not signed in; the state is `.awaitingChallenge(step)` on both the
    ///      accessor and the stream; no event is sent for the challenge
    ///    - the answer completes the sign-in: `.signedIn` is sent, the state is `.signedIn(user)`, and the
    ///      engine received the answer
    func testAChallengeIsPublishedThenConfirmed() async throws {
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        engine.scriptSignIn { _, _ in .challenge(.confirmSignInWithTOTPCode) }
        _ = await client.currentSessionState()
        let states = StreamRecorder(client.listenToSessionStateChanges())
        let events = StreamRecorder(client.listenToAuthEvents())

        let first = try await client.signInForTest("alice")
        let waiting = await client.currentSessionState()
        let done = try await client.confirmSignIn(challengeResponse: "123456")

        XCTAssertNotEqual(first.nextStep, .done)
        XCTAssertEqual(waiting, .awaitingChallenge(.confirmSignInWithTOTPCode))
        XCTAssertEqual(done.nextStep, .done)
        XCTAssertEqual(engine.confirmSignInCalls.map(\.challengeResponse), ["123456"])
        await states.waitFor(2)
        XCTAssertEqual(states.received, [.awaitingChallenge(.confirmSignInWithTOTPCode), .signedIn(alice)])
        await events.waitFor(1)
        XCTAssertEqual(events.received, [.signedIn])
    }

    /// - Given: a pending new-password challenge
    /// - When: it is answered with attributes, metadata and a device name
    /// - Then:
    ///    - the engine receives the attributes under their Cognito names, and the rest verbatim
    func testConfirmationPassesItsOptionsToTheEngine() async throws {
        let (client, engine) = try await challengedClient(work, step: .confirmSignInWithNewPassword(nil))

        _ = try await client.confirmSignIn(
            challengeResponse: "new-password",
            options: .init(
                userAttributes: [.init(.email, value: "a@example.com"), .init(.custom("team"), value: "blue")],
                clientMetadata: ["k": "v"],
                friendlyDeviceName: "Phone"
            )
        )

        XCTAssertEqual(engine.confirmSignInCalls, [EngineConfirmSignInRequest(
            challengeResponse: "new-password",
            userAttributes: ["email": "a@example.com", "custom:team": "blue"],
            clientMetadata: ["k": "v"],
            friendlyDeviceName: "Phone",
            webAuthn: Self.confirmationCeremony
        )])
        #if os(iOS) || os(macOS) || os(visionOS)
        XCTAssertNotNil(engine.confirmSignInCalls.first?.webAuthn)
        #else
        XCTAssertNil(engine.confirmSignInCalls.first?.webAuthn)
        #endif
    }

    /// What a confirmation without a window carries: on the platforms with a passkey sheet, a ceremony context of
    /// its own, which compares by its window only, so any context without one; elsewhere none.
    private static var confirmationCeremony: EngineCeremonyContext? {
        #if os(iOS) || os(macOS) || os(visionOS)
        EngineCeremonyContext(anchor: nil) { body in try await body() }
        #else
        nil
        #endif
    }

    /// - Given: a pending SMS code challenge
    /// - When: a wrong code is answered, then the right one
    /// - Then:
    ///    - the wrong code throws `service(.codeMismatch)` and the challenge stays pending, in the state too
    ///    - the retry completes the sign-in
    func testAWrongAnswerKeepsTheChallengeForARetry() async throws {
        let (client, engine) = try await challengedClient(work, step: smsCode)
        engine.scriptConfirmSignIn { request in
            guard request.challengeResponse == "111111" else {
                throw FakeRetryable(error: AuthClientError.service(.codeMismatch, "wrong code", "retry"))
            }
            return .done(payload: FakePayload.signedIn("alice").data)
        }

        let wrong = await authClientError { try await client.confirmSignIn(challengeResponse: "000000") }
        let stillWaiting = await client.currentSessionState()
        let retried = try await client.confirmSignIn(challengeResponse: "111111")

        XCTAssertEqual(wrong?.kind, .service(.codeMismatch))
        XCTAssertEqual(stillWaiting, .awaitingChallenge(smsCode))
        XCTAssertEqual(retried.nextStep, .done)
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedIn(alice))
    }

    /// - Given: a sign-in that asks for TOTP setup, then a TOTP code
    /// - When: each step is answered
    /// - Then:
    ///    - a newer step replaces the older one, and both publish
    func testANewerStepReplacesTheOlderOne() async throws {
        let setup = AuthClientSignInStep.continueSignInWithTOTPSetup(.init(sharedSecret: "S", username: "alice"))
        let (client, engine) = try await challengedClient(work, step: setup)
        let states = StreamRecorder(client.listenToSessionStateChanges())
        engine.scriptConfirmSignIn { _ in .challenge(.confirmSignInWithTOTPCode) }

        let next = try await client.confirmSignIn(challengeResponse: "123456")

        XCTAssertEqual(next.nextStep, .confirmSignInWithTOTPCode)
        await states.waitFor(1)
        XCTAssertEqual(states.received, [.awaitingChallenge(.confirmSignInWithTOTPCode)])
    }

    /// - Given: a pending challenge whose Cognito session has expired
    /// - When: it is answered
    /// - Then:
    ///    - it throws `challengeExpired`; the challenge is dropped and the session is signed out again, and
    ///      a further answer throws `invalidState`
    func testAnExpiredChallengeIsDropped() async throws {
        let (client, engine) = try await challengedClient(work)
        engine.scriptConfirmSignIn { _ in
            throw AuthClientError.challengeExpired("The sign-in challenge has expired.", "Sign in again.")
        }

        let expired = await authClientError { try await client.confirmSignIn(challengeResponse: "123456") }
        let state = await client.currentSessionState()
        let again = await authClientError { try await client.confirmSignIn(challengeResponse: "123456") }

        XCTAssertEqual(expired?.kind, .challengeExpired)
        XCTAssertEqual(state, .signedOut)
        XCTAssertEqual(again?.kind, .invalidState)
    }

    /// - Given: a session with no sign-in in progress
    /// - When: `confirmSignIn` is called, and called with an empty answer
    /// - Then:
    ///    - it throws `invalidState`; the empty answer throws `validation(field: "challengeResponse")`
    ///      without reaching the engine
    func testConfirmationWithoutAPendingSignInIsInvalidState() async throws {
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))

        let none = await authClientError { try await client.confirmSignIn(challengeResponse: "123456") }
        let empty = await authClientError { try await client.confirmSignIn(challengeResponse: "") }

        XCTAssertEqual(none?.kind, .invalidState)
        XCTAssertEqual(none?.errorDescription, "There is no sign-in in progress for this session")
        XCTAssertEqual(empty?.kind, .validation(field: "challengeResponse"))
        XCTAssertEqual(empty?.errorDescription, "challengeResponse is required to confirmSignIn")
        XCTAssertEqual(engine.confirmSignInCalls.count, 1)
    }

    /// - Given: a session waiting on a challenge
    /// - When: a new sign-in starts, which completes
    /// - Then:
    ///    - the new sign-in is not refused; the engine supersedes the pending attempt; the challenge is
    ///      cleared and the session is signed in as the new user
    func testANewSignInSupersedesThePendingChallenge() async throws {
        let (client, engine) = try await challengedClient(work)
        engine.scriptSignIn { request, _ in .done(payload: FakePayload.signedIn(request.username).data) }

        try await client.signInForTest("carol")

        XCTAssertEqual(engine.supersededCount, 1)
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedIn(AuthClientUser(username: "carol", userId: "sub-carol")))
        let pending = await engine.pendingChallenge
        XCTAssertNil(pending)
    }

    /// - Given: a session waiting on a challenge
    /// - When: a new sign-in fails
    /// - Then:
    ///    - the old challenge is gone too, since the engine dropped it, and the state is signed out
    func testAFailedSupersedingSignInLeavesNothingPending() async throws {
        let (client, engine) = try await challengedClient(work)
        engine.scriptSignIn { _, _ in throw AuthClientError.notAuthorized("Incorrect username or password.", "Check them.") }

        _ = await authClientError { try await client.signInForTest("carol") }

        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedOut)
    }

    /// - Given: a session waiting on a challenge
    /// - When: it signs out
    /// - Then:
    ///    - the pending sign-in is cancelled in the engine; the state is signed out; answering throws
    ///      `invalidState`
    func testSignOutCancelsThePendingChallenge() async throws {
        let (client, engine) = try await challengedClient(work)

        let result = await client.signOut()
        let answer = await authClientError { try await client.confirmSignIn(challengeResponse: "123456") }

        XCTAssertEqual(result, .complete)
        XCTAssertEqual(engine.cancelPendingSignInCount, 1)
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedOut)
        XCTAssertEqual(answer?.kind, .invalidState)
    }

    /// Design §5: a challenge belongs to one session.
    ///
    /// - Given: `work` waiting on a challenge
    /// - When: `home` is read, and answers a challenge
    /// - Then:
    ///    - `home` is signed out and has nothing to confirm; `work` still waits
    func testAChallengeIsPerSession() async throws {
        let (workClient, _) = try await challengedClient(work)
        let homeClient = try harness.client(home)

        let homeState = await homeClient.currentSessionState()
        let homeAnswer = await authClientError { try await homeClient.confirmSignIn(challengeResponse: "123456") }
        let workState = await workClient.currentSessionState()

        XCTAssertEqual(homeState, .signedOut)
        XCTAssertEqual(homeAnswer?.kind, .invalidState)
        XCTAssertEqual(workState, .awaitingChallenge(.confirmSignInWithTOTPCode))
    }

    /// `getCurrentUser` answers as the plugin's does while a sign-in is in progress.
    ///
    /// - Given: a session waiting on a challenge
    /// - When: its providers are asked, and `getCurrentUser`
    /// - Then:
    ///    - the providers throw `notSignedIn`: a pending sign-in is not a signed-in user
    ///    - `getCurrentUser` throws `invalidState` with the plugin's message
    func testAPendingChallengeIsNotSignedIn() async throws {
        let (client, _) = try await challengedClient(work)

        let user = await authClientError { try await client.getCurrentUser() }

        XCTAssertEqual(user?.kind, .invalidState)
        XCTAssertEqual(user?.errorDescription, "Auth State not in a valid state")
        XCTAssertEqual(user?.recoverySuggestion, "Operation performed is not a valid operation for the current auth state")
        do {
            _ = try await client.userPoolTokenProvider.accessToken()
            XCTFail("expected an error")
        } catch let error as CredentialsError {
            XCTAssertTrue(error.isNotSignedIn)
        }
    }

    /// Cognito accepted the answer, so the engine has nothing pending, but the tokens
    /// could not be saved.
    ///
    /// - Given: a pending challenge, and a keychain that refuses writes
    /// - When: the answer completes the sign-in
    /// - Then:
    ///    - it throws `storageUnavailable`; the challenge is cleared, so the state is `.signedOut` rather than
    ///      a stale `.awaitingChallenge`; the fresh tokens are revoked; no `.signedIn` is sent
    func testAConfirmationWhoseCommitFailsClearsTheChallenge() async throws {
        let (client, engine) = try await challengedClient(work)
        let events = StreamRecorder(client.listenToAuthEvents())
        harness.keychain.failing(.write, with: errSecInteractionNotAllowed)

        let error = await authClientError { try await client.confirmSignIn(challengeResponse: "123456") }
        harness.keychain.clearFailures()

        XCTAssertEqual(error?.kind, .storageUnavailable(.locked))
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedOut)
        XCTAssertEqual(engine.revokeCalls, [FakePayload.signedIn("alice").data])
        XCTAssertEqual(events.received, [])
    }

    /// Design §4.4's guest-to-user continuity holds even when the session only becomes a guest
    /// while its sign-in waits on a challenge.
    ///
    /// - Given: a signed-out session waiting on a challenge, which then acquires guest credentials
    /// - When: the challenge is answered
    /// - Then:
    ///    - the signed-in session keeps the guest's identity ID
    func testAGuestAcquiredDuringAChallengeKeepsItsIdentity() async throws {
        let (client, _) = try await challengedClient(work)
        let guest = try await client.fetchAuthSession()
        XCTAssertEqual(try guest.identityIdResult.get(), "us-east-1:guest")
        let guestPayload = try harness.storedRecord(work)?.credentials

        _ = try await client.confirmSignIn(challengeResponse: "123456")

        let session = try await client.fetchAuthSession()
        XCTAssertEqual(try session.identityIdResult.get(), "us-east-1:guest")
        XCTAssertEqual(try session.userSubResult.get(), "sub-alice")
        XCTAssertEqual(harness.engine(for: work)?.confirmSignInCurrents, [guestPayload])
    }

    // MARK: Which confirmation failures keep the attempt

    /// The plugin validates an MFA selection before sending it (`AWSAuthConfirmSignInTask.swift:167-177`),
    /// and the attempt survives.
    ///
    /// - Given: a sign-in waiting on an MFA selection
    /// - When: it is answered with something that is not an MFA type, then with `sms_mfa`
    /// - Then:
    ///    - the first throws `validation(field: "challengeResponse")` naming all three Cognito MFA values
    ///      (EMAIL_OTP included) and the client's `AuthClientMFAType.<type>.challengeResponse`, without
    ///      reaching the engine, and the challenge is still pending; the second (case-insensitive) is sent
    func testABadMFASelectionIsRefusedBeforeItIsSent() async throws {
        let step = AuthClientSignInStep.continueSignInWithMFASelection([.sms, .totp])
        let (client, engine) = try await challengedClient(work, step: step)

        let bad = await authClientError { try await client.confirmSignIn(challengeResponse: "sms") }
        let state = await client.currentSessionState()
        _ = try await client.confirmSignIn(challengeResponse: "sms_mfa")

        XCTAssertEqual(bad?.kind, .validation(field: "challengeResponse"))
        XCTAssertEqual(
            bad?.errorDescription,
            "challengeResponse for MFA selection can only be SMS_MFA, SOFTWARE_TOKEN_MFA or EMAIL_OTP."
        )
        XCTAssertEqual(bad?.recoverySuggestion, """
        Make sure that a valid challenge response is passed for confirmSignIn.
        Try using `AuthClientMFAType.<type>.challengeResponse` as the challenge response.
        """)
        XCTAssertFalse(bad?.recoverySuggestion.contains("MFAType.totp") ?? true, "names the plugin's type")
        XCTAssertEqual(state, .awaitingChallenge(step))
        XCTAssertEqual(engine.confirmSignInCalls.map(\.challengeResponse), ["sms_mfa"])
    }

    /// The plugin validates a first-factor selection before sending it
    /// (`AWSAuthConfirmSignInTask.swift:179-190`), and the attempt survives.
    ///
    /// - Given: a sign-in waiting on a first-factor selection
    /// - When: it is answered with something that is not a factor, then with `EMAIL_OTP`
    /// - Then:
    ///    - the first throws `validation(field: "challengeResponse")` with the plugin's strings, naming the
    ///      client's `AuthClientFactorType.<type>.challengeResponse` instead of Amplify's type, without
    ///      reaching the engine; the second is sent
    func testABadFactorSelectionIsRefusedBeforeItIsSent() async throws {
        let step = AuthClientSignInStep.continueSignInWithFirstFactorSelection([.password, .emailOTP])
        let (client, engine) = try await challengedClient(work, step: step)

        let bad = await authClientError { try await client.confirmSignIn(challengeResponse: "emailOTP") }
        let state = await client.currentSessionState()
        _ = try await client.confirmSignIn(challengeResponse: "EMAIL_OTP")

        XCTAssertEqual(bad?.kind, .validation(field: "challengeResponse"))
        XCTAssertEqual(
            bad?.errorDescription,
            "challengeResponse for factor selection can only be one of the `AuthClientFactorType` values."
        )
        XCTAssertTrue(bad?.recoverySuggestion.contains("`AuthClientFactorType.<type>.challengeResponse`") == true)
        XCTAssertEqual(state, .awaitingChallenge(step))
        XCTAssertEqual(engine.confirmSignInCalls.map(\.challengeResponse), ["EMAIL_OTP"])
    }

    /// WebAuthn needs a presentation anchor.
    ///
    /// - Given: a sign-in, made without a window, waiting on a first-factor selection; and a signed-out session
    /// - When: the selection is answered with `WEB_AUTHN` without a window, and a sign-in asks for a WebAuthn
    ///   first factor through the overload without one
    /// - Then:
    ///    - both throw `.validation(field: "presentationAnchor")`; the selection is refused by the engine
    ///      before any ceremony, and stays pending; the sign-in never reaches the engine
    func testWebAuthnWithoutAPresentationAnchorIsRefused() async throws {
        let step = AuthClientSignInStep.continueSignInWithFirstFactorSelection([.password, .emailOTP])
        let (client, engine) = try await challengedClient(work, step: step)
        let other = try harness.client(home)

        let selection = await authClientError { try await client.confirmSignIn(challengeResponse: "WEB_AUTHN") }
        let state = await client.currentSessionState()
        XCTAssertEqual(selection?.kind, .validation(field: "presentationAnchor"))
        XCTAssertEqual(state, .awaitingChallenge(step))
        XCTAssertEqual(engine.ceremonyAnchorCalls.count, 0)

        #if os(iOS) || os(macOS) || os(visionOS)
        if #available(iOS 17.4, macOS 13.5, visionOS 1.0, *) {
            let firstFactor = await authClientError {
                try await other.signIn(
                    username: "bob",
                    options: .init(authFlowType: .userAuth(preferredFirstFactor: .webAuthn))
                )
            }
            XCTAssertEqual(firstFactor?.kind, .validation(field: "presentationAnchor"))
            XCTAssertEqual(harness.engine(for: home)?.signInCalls.count, 0)
        }
        #endif
    }

    /// - Given: a pending challenge, and an engine that rejects an answer with `validation`
    /// - When: it is answered
    /// - Then:
    ///    - the validation error is thrown and the attempt is kept, as the contract requires
    func testAnEngineValidationFailureKeepsTheAttempt() async throws {
        let (client, engine) = try await challengedClient(work, step: .confirmSignInWithNewPassword(nil))
        engine.scriptConfirmSignIn { _ in
            throw AuthClientError.validation(field: "password", "The password does not meet the policy.", "Choose another.")
        }

        let error = await authClientError { try await client.confirmSignIn(challengeResponse: "short") }
        let state = await client.currentSessionState()

        XCTAssertEqual(error?.kind, .validation(field: "password"))
        XCTAssertEqual(state, .awaitingChallenge(.confirmSignInWithNewPassword(nil)))
    }

    // MARK: The challenge mirror never publishes a stale step

    /// - Given: a pending challenge, and a wrong answer whose challenge re-read is overtaken by a sign-out
    /// - When: the sign-out lands while the core is reading the engine's challenge after the failure
    /// - Then:
    ///    - the session ends `.signedOut`, not `.awaitingChallenge`, and a further answer is `invalidState`
    func testASignOutDuringTheChallengeReadLeavesNoStaleChallenge() async throws {
        let (client, engine) = try await challengedClient(work)
        engine.scriptConfirmSignIn { _ in
            throw FakeRetryable(error: AuthClientError.service(.codeMismatch, "wrong code", "retry"))
        }
        let reads = CallCounter()
        engine.duringPendingChallengeRead {
            guard reads.count < 1 else { return }
            reads.increment()
            _ = await client.signOut()
        }

        let wrong = await authClientError { try await client.confirmSignIn(challengeResponse: "000000") }
        engine.duringPendingChallengeRead(nil)
        let state = await client.currentSessionState()
        let again = await authClientError { try await client.confirmSignIn(challengeResponse: "111111") }

        XCTAssertEqual(wrong?.kind, .service(.codeMismatch))
        XCTAssertEqual(reads.count, 1)
        XCTAssertEqual(state, .signedOut)
        XCTAssertEqual(again?.kind, .invalidState)
    }

    /// - Given: a signed-out session; alice's sign-in completes only when let go, and bob's would stop on a
    ///   challenge
    /// - When: bob's sign-in starts while alice's is in flight, then alice's completes, then bob's is let go
    /// - Then:
    ///    - bob's sign-in waits for alice's, is then refused as the session is signed in, and never reaches
    ///      the engine; alice's session carries no challenge
    func testASignInQueuedBehindAnotherIsRefusedOnceThatOneSignsIn() async throws {
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        _ = await client.currentSessionState()
        let aliceLatch = Gate()
        let bobLatch = Gate()
        engine.scriptSignIn { request, _ in
            if request.username == "alice" {
                await aliceLatch.pass()
                return .done(payload: FakePayload.signedIn("alice").data)
            }
            await bobLatch.pass()
            return .challenge(.confirmSignInWithTOTPCode)
        }

        let aliceSignIn = Task { try await client.signInForTest("alice") }
        await aliceLatch.waitForArrivals(1)
        let bobSignIn = Task { try await client.signInForTest("bob") }
        await waitUntil("bob queues behind alice, or reaches the engine") {
            let queued = await client.core.signInLock.waiterCount == 1
            return queued || engine.signInCalls.count == 2
        }
        await aliceLatch.open()
        _ = try await aliceSignIn.value
        await bobLatch.open()
        let bob = await authClientError { try await bobSignIn.value }

        XCTAssertEqual(bob?.kind, .invalidState)
        XCTAssertEqual(engine.signInCalls.map(\.request.username), ["alice"])
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedIn(alice))
    }

    // MARK: A queued sign-in is still the caller's to cancel, and a sign-out ends it

    /// - Given: alice's sign-in held in the engine, and bob's queued behind it
    /// - When: bob's caller cancels, the session signs out, and alice's sign-in is let go
    /// - Then:
    ///    - bob's call throws `CancellationError` and never reaches the engine; alice's throws `invalidState`;
    ///      the session ends signed out
    func testACancelledQueuedSignInNeverRuns() async throws {
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        _ = await client.currentSessionState()
        let latch = Gate()
        engine.holdSignIns(on: latch)

        let aliceSignIn = Task { try await client.signInForTest("alice") }
        await latch.waitForArrivals(1)
        let bobSignIn = Task { try await client.signInForTest("bob") }
        await waitUntil("bob queues behind alice") { await client.core.signInLock.waiterCount == 1 }
        bobSignIn.cancel()
        await waitUntil("bob leaves the queue") { await client.core.signInLock.waiterCount == 0 }
        let signOut = await client.signOut()
        await latch.open()
        let alice = await authClientError { try await aliceSignIn.value }
        let bob: Error?
        do {
            _ = try await bobSignIn.value
            bob = nil
        } catch {
            bob = error
        }

        XCTAssertEqual(signOut, .complete)
        XCTAssertEqual(alice?.kind, .invalidState)
        XCTAssertTrue(bob is CancellationError, "\(String(describing: bob))")
        XCTAssertEqual(engine.signInCalls.map(\.request.username), ["alice"])
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedOut)
    }

    /// - Given: alice's sign-in held in the engine, and bob's queued behind it, not cancelled
    /// - When: the session signs out, and alice's sign-in is let go
    /// - Then:
    ///    - bob's queued sign-in, issued before the sign-out, never runs: it throws `invalidState` and never
    ///      reaches the engine; the session ends signed out
    func testASignOutEndsASignInQueuedBeforeIt() async throws {
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        _ = await client.currentSessionState()
        let latch = Gate()
        engine.holdSignIns(on: latch)

        let aliceSignIn = Task { try await client.signInForTest("alice") }
        await latch.waitForArrivals(1)
        let bobSignIn = Task { try await client.signInForTest("bob") }
        await waitUntil("bob queues behind alice") { await client.core.signInLock.waiterCount == 1 }
        _ = await client.signOut()
        await latch.open()
        let alice = await authClientError { try await aliceSignIn.value }
        let bob = await authClientError { try await bobSignIn.value }

        XCTAssertEqual(alice?.kind, .invalidState)
        XCTAssertEqual(bob?.kind, .invalidState)
        XCTAssertEqual(engine.signInCalls.map(\.request.username), ["alice"])
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedOut)
    }

    /// An engine whose `RespondToAuthChallenge` had already succeeded when the cancel
    /// arrived returns the tokens, which the core must refuse and revoke rather than let leak.
    ///
    /// - Given: a pending challenge, and a confirmation held in an engine that returns issued tokens after
    ///   a cancel
    /// - When: the session signs out while it is held, then it is let go
    /// - Then:
    ///    - the engine returned `.done`, yet nothing is committed: the confirmation throws `invalidState`,
    ///      the tokens are revoked, the session stays signed out and no `.signedIn` is sent
    func testTokensReturnedAfterACancelAreRevokedNotCommitted() async throws {
        let (client, engine) = try await challengedClient(work)
        let latch = Gate()
        engine.holdSignIns(on: latch, afterCancel: .returnIssuedTokens)
        let events = StreamRecorder(client.listenToAuthEvents())

        let confirm = Task { try await client.confirmSignIn(challengeResponse: "123456") }
        await latch.waitForArrivals(1)
        _ = await client.signOut()
        await latch.open()
        let error = await authClientError { try await confirm.value }

        XCTAssertEqual(error?.kind, .invalidState)
        XCTAssertEqual(engine.revokeCalls, [FakePayload.signedIn("alice").data])
        XCTAssertNil(try harness.storedRecord(work))
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedOut)
        XCTAssertEqual(events.received, [])
    }

    /// - Given: a sign-in held before the engine starts it, in an engine that still reaches a challenge
    ///   after a cancel (a sign-out landing between the core's epoch capture and the engine step)
    /// - When: the session signs out while it is held, then it is let go, and the challenge is answered
    /// - Then:
    ///    - the sign-in throws `invalidState`, and the engine's attempt is cancelled, so nothing is pending
    ///    - answering afterwards throws `invalidState` and never signs the session in
    func testAChallengeReachedAfterASignOutIsCancelledNotKept() async throws {
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let step = smsCode
        engine.scriptSignIn { _, _ in .challenge(step) }
        let latch = Gate()
        engine.holdSignIns(on: latch, afterCancel: .returnIssuedTokens)

        let signIn = Task { try await client.signInForTest("alice") }
        await latch.waitForArrivals(1)
        _ = await client.signOut()
        await latch.open()
        let error = await authClientError { try await signIn.value }

        XCTAssertEqual(error?.kind, .invalidState)
        let pending = await engine.pendingChallenge
        XCTAssertNil(pending, "the engine must not keep a challenge the session has signed out of")
        let confirmError = await authClientError { try await client.confirmSignIn(challengeResponse: "123456") }
        XCTAssertEqual(confirmError?.kind, .invalidState)
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedOut)
    }

    // MARK: A sign-in in flight across a sign-out, purge or deletion

    /// - Given: a pending challenge, and a confirmation that the engine completes only after a sign-out
    /// - When: the session signs out while the confirmation is in flight, then the engine returns `.done`
    /// - Then:
    ///    - the confirmation throws `invalidState` and commits nothing; the fresh tokens are revoked; the
    ///      session stays signed out and no `.signedIn` is sent
    func testASignOutDuringAConfirmationWins() async throws {
        let (client, engine) = try await challengedClient(work)
        let latch = Gate()
        engine.scriptConfirmSignIn { _ in
            await latch.pass()
            return .done(payload: FakePayload.signedIn("alice").data)
        }
        let events = StreamRecorder(client.listenToAuthEvents())

        let confirm = Task { try await client.confirmSignIn(challengeResponse: "123456") }
        await latch.waitForArrivals(1)
        let signOut = await client.signOut()
        await latch.open()
        let error = await authClientError { try await confirm.value }

        XCTAssertEqual(signOut, .complete)
        XCTAssertEqual(error?.kind, .invalidState)
        XCTAssertNil(try harness.storedRecord(work))
        XCTAssertEqual(engine.revokeCalls, [FakePayload.signedIn("alice").data])
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedOut)
        XCTAssertEqual(events.received, [])
    }

    /// - Given: a pending challenge, and a confirmation held inside an engine that stops it when the
    ///   pending sign-in is cancelled
    /// - When: the session's stored record is purged while it is held, then it is let go
    /// - Then:
    ///    - the confirmation throws `invalidState` (not a bare `CancellationError`, which the caller did not
    ///      cause); nothing is written back and the session stays signed out
    func testAPurgeDuringAConfirmationWins() async throws {
        let (client, engine) = try await challengedClient(work)
        let latch = Gate()
        engine.holdSignIns(on: latch)

        let confirm = Task { try await client.confirmSignIn(challengeResponse: "123456") }
        await latch.waitForArrivals(1)
        try await AmplifyCognitoClient.purgeStoredSession(
            sessionId: work,
            configuration: ClientFixtures.configuration,
            accessGroup: nil,
            dependencies: harness.dependencies
        )
        await latch.open()
        let error = await authClientError { try await confirm.value }

        XCTAssertEqual(error?.kind, .invalidState)
        XCTAssertEqual(try harness.store().read(work), .absent)
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedOut)
    }

    /// Another process signs alice in while bob's sign-in is in flight here; alice is then deleted.
    ///
    /// - Given: a signed-out session whose sign-in (bob) the engine completes only when let go, and another
    ///   writer that stores alice, which the session adopts
    /// - When: alice is deleted, then bob's sign-in returns `.done`
    /// - Then:
    ///    - bob's sign-in throws `invalidState` and writes no row for a deleted session; bob's fresh tokens
    ///      are revoked; only `.userDeleted` is sent
    func testADeletionDuringASignInWins() async throws {
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        _ = await client.currentSessionState()
        let latch = Gate()
        engine.scriptSignIn { request, _ in
            await latch.pass()
            return .done(payload: FakePayload.signedIn(request.username).data)
        }
        let events = StreamRecorder(client.listenToAuthEvents())

        let signIn = Task { try await client.signInForTest("bob") }
        await latch.waitForArrivals(1)
        try harness.store().write(FakePayload.signedIn("alice").record(), for: work, expecting: nil)
        try await client.setSessionLabel(nil)
        try await client.deleteUser()
        await latch.open()
        let error = await authClientError { try await signIn.value }

        XCTAssertEqual(error?.kind, .invalidState)
        XCTAssertEqual(try harness.store().read(work), .absent)
        XCTAssertEqual(engine.revokeCalls, [FakePayload.signedIn("bob").data])
        await events.waitFor(1)
        XCTAssertEqual(events.received, [.userDeleted])
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedOut)
    }

    /// - Given: a pending challenge, and a confirmation held in the engine
    /// - When: the state is read while it is held, then it completes
    /// - Then:
    ///    - the state still reports the challenge while the answer is in flight, and signed in afterwards
    func testAHeldConfirmationKeepsTheChallengeUntilItCompletes() async throws {
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        engine.scriptSignIn { _, _ in .challenge(.confirmSignInWithTOTPCode) }
        _ = try await client.signInForTest("alice")
        let latch = Gate()
        engine.holdSignIns(on: latch)

        let confirm = Task { try await client.confirmSignIn(challengeResponse: "123456") }
        await latch.waitForArrivals(1)
        let during = await client.currentSessionState()
        await latch.open()
        let result = try await confirm.value

        XCTAssertEqual(during, .awaitingChallenge(.confirmSignInWithTOTPCode))
        XCTAssertEqual(result.nextStep, .done)
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedIn(alice))
    }
}
