//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import Foundation
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// One engine under the seam's sign-in contract: the contract suite shared with the fake runs against the
/// live engine. Each driver scripts the same scenarios its own way: the fake with
/// its scripts, the live engine with scripted Cognito.
protocol SeamContractDriver: AnyObject {
    var engine: any SessionEngine { get }
    /// The next `signIn` stops on a new-password challenge.
    func scriptNewPasswordChallenge() throws
    /// The next answer is rejected as an invalid new password (retryable); the one after it finishes.
    func scriptRetryableRejectionThenDone()
    /// The next answer fails terminally: the challenge session has expired.
    func scriptExpiredSession()
    /// The next `signIn` finishes at once for `username`.
    func scriptSignInDone(_ username: String)
    /// The next `signIn` waits on `gate` for Cognito, then stops on a new-password challenge.
    func scriptNewPasswordChallenge(heldOn gate: Gate) throws
    /// The next answer waits on `gate` for Cognito, then stops on a TOTP challenge.
    func scriptAnswerThenTOTPChallenge(heldOn gate: Gate)
}

/// The contract's cases, run over any driver. Every case uses `alice`, a new-password challenge, and the
/// seam's own vocabulary (`EngineStepResult`, `pendingChallenge`, `AuthClientError`).
enum SeamContractCases {

    static let request = EngineSignInRequest(username: "alice", password: "password", authFlowType: nil, clientMetadata: [:])

    static func answer(_ response: String) -> EngineConfirmSignInRequest {
        EngineConfirmSignInRequest(challengeResponse: response, userAttributes: [:], clientMetadata: [:], friendlyDeviceName: nil)
    }

    /// A saved TOTP challenge, as a restore hands it to `resumeSignIn`.
    static func savedChallenge() -> ChallengeRecord.State? {
        .fake(.confirmSignInWithTOTPCode)
    }

    static func isNewPassword(_ step: AuthClientSignInStep?) -> Bool {
        if case .confirmSignInWithNewPassword = step {
            return true
        }
        return false
    }

    /// A confirmation with nothing pending is `invalidState("There is no sign-in in progress …")`.
    static func nothingPendingIsInvalidState(_ driver: SeamContractDriver) async {
        await assertThrowsAsync({ try await driver.engine.confirmSignIn(answer("x"), current: nil) }) { error in
            guard case .invalidState(let description, _, _) = error as? AuthClientError else {
                return XCTFail("expected invalidState, got \(error)")
            }
            XCTAssertEqual(description, "There is no sign-in in progress for this session")
        }
    }

    /// A challenge is returned, retained, and reported by `pendingChallenge`.
    static func aChallengeIsRetained(_ driver: SeamContractDriver) async throws {
        try driver.scriptNewPasswordChallenge()

        let result = try await driver.engine.signIn(request, current: nil)

        guard case .challenge(let step) = result, isNewPassword(step) else {
            return XCTFail("expected a new-password challenge, got \(result)")
        }
        let pending = await driver.engine.pendingChallenge
        XCTAssertTrue(isNewPassword(pending), "\(String(describing: pending))")
    }

    /// A retryable rejection keeps the attempt; the retry finishes, and nothing is pending after.
    static func aRetryableRejectionKeepsTheAttempt(_ driver: SeamContractDriver) async throws {
        try driver.scriptNewPasswordChallenge()
        driver.scriptRetryableRejectionThenDone()
        _ = try await driver.engine.signIn(request, current: nil)

        await assertThrowsAsync({ try await driver.engine.confirmSignIn(answer("weak"), current: nil) }) { error in
            guard case .service(.invalidPassword?, _, _, _) = error as? AuthClientError else {
                return XCTFail("expected .service(.invalidPassword), got \(error)")
            }
        }
        let kept = await driver.engine.pendingChallenge
        XCTAssertTrue(isNewPassword(kept), "a retryable rejection must keep the attempt")

        let retried = try await driver.engine.confirmSignIn(answer("Str0ng!Passw0rd"), current: nil)

        guard case .done = retried else {
            return XCTFail("expected .done, got \(retried)")
        }
        let after = await driver.engine.pendingChallenge
        XCTAssertNil(after)
    }

    /// An expired challenge session is `challengeExpired`, drops the attempt, and a later answer is
    /// `invalidState`.
    static func anExpiredSessionDropsTheAttempt(_ driver: SeamContractDriver) async throws {
        try driver.scriptNewPasswordChallenge()
        driver.scriptExpiredSession()
        _ = try await driver.engine.signIn(request, current: nil)

        await assertThrowsAsync({ try await driver.engine.confirmSignIn(answer("Str0ng!Passw0rd"), current: nil) }) { error in
            guard case .challengeExpired = error as? AuthClientError else {
                return XCTFail("expected challengeExpired, got \(error)")
            }
        }
        let pending = await driver.engine.pendingChallenge
        XCTAssertNil(pending)
        await nothingPendingIsInvalidState(driver)
    }

    /// A new sign-in supersedes the pending one.
    static func aNewSignInSupersedes(_ driver: SeamContractDriver) async throws {
        try driver.scriptNewPasswordChallenge()
        _ = try await driver.engine.signIn(request, current: nil)
        driver.scriptSignInDone("bob")

        let result = try await driver.engine.signIn(
            EngineSignInRequest(username: "bob", password: "password", authFlowType: nil, clientMetadata: [:]),
            current: nil
        )

        guard case .done(let payload) = result else {
            return XCTFail("expected .done, got \(result)")
        }
        XCTAssertEqual(try driver.engine.describe(payload).username, "bob")
        let pending = await driver.engine.pendingChallenge
        XCTAssertNil(pending)
    }

    /// A cancel drops the pending challenge; a later answer is `invalidState`.
    static func aCancelDropsTheAttempt(_ driver: SeamContractDriver) async throws {
        try driver.scriptNewPasswordChallenge()
        _ = try await driver.engine.signIn(request, current: nil)

        await driver.engine.cancelPendingSignIn()

        let pending = await driver.engine.pendingChallenge
        XCTAssertNil(pending)
        await nothingPendingIsInvalidState(driver)
    }

    /// An answer at a later epoch than the pending attempt's is `invalidState`, and drops the attempt: it
    /// belongs to a sign-in a sign-out has ended, whose cancel has not reached the engine yet. Not even an
    /// answer at the attempt's own epoch reaches it after that.
    static func anEarlierEpochAttemptIsRefusedAndDropped(_ driver: SeamContractDriver) async throws {
        try driver.scriptNewPasswordChallenge()
        _ = try await driver.engine.signIn(request, current: nil, epoch: 1)

        await assertThrowsAsync({ try await driver.engine.confirmSignIn(answer("Str0ng!Passw0rd"), current: nil, epoch: 2) }) { error in
            guard case .invalidState(let description, _, _) = error as? AuthClientError else {
                return XCTFail("expected invalidState, got \(error)")
            }
            XCTAssertEqual(description, "There is no sign-in in progress for this session")
        }
        let pending = await driver.engine.pendingChallenge
        XCTAssertNil(pending, "an earlier epoch's attempt must be dropped, not kept")
        await assertThrowsAsync({ try await driver.engine.confirmSignIn(answer("Str0ng!Passw0rd"), current: nil, epoch: 1) }) { error in
            guard case .invalidState(let description, _, _) = error as? AuthClientError else {
                return XCTFail("expected invalidState, got \(error)")
            }
            XCTAssertEqual(description, "There is no sign-in in progress for this session")
        }
    }

    /// `autoSignIn` with no auto-sign-in session ends the pending attempt before it refuses, as every new
    /// sign-in does, so no attempt from before its epoch outlives it.
    static func anAutoSignInWithoutASessionEndsAnEarlierAttempt(_ driver: SeamContractDriver) async throws {
        try driver.scriptNewPasswordChallenge()
        _ = try await driver.engine.signIn(request, current: nil, epoch: 1)

        await assertThrowsAsync({ try await driver.engine.autoSignIn(current: nil, epoch: 2) }) { error in
            guard case .invalidState(let description, _, _) = error as? AuthClientError else {
                return XCTFail("expected invalidState, got \(error)")
            }
            XCTAssertEqual(description, SessionCore.notSignedUp().errorDescription)
        }
        let pending = await driver.engine.pendingChallenge
        XCTAssertNil(pending, "the earlier attempt must be ended before the refusal")
    }

    /// A step a cancel ended never becomes the pending attempt: an answer Cognito meets with a further
    /// challenge after the cancel throws `CancellationError`, and nothing is pending.
    static func aCancelledStepNeverReturnsAChallenge(_ driver: SeamContractDriver) async throws {
        try driver.scriptNewPasswordChallenge()
        _ = try await driver.engine.signIn(request, current: nil)
        let gate = Gate()
        driver.scriptAnswerThenTOTPChallenge(heldOn: gate)
        let engine = driver.engine
        let response = answer("Str0ng!Passw0rd")
        let confirm = Task { try await engine.confirmSignIn(response, current: nil) }
        await gate.waitForArrivals(1)

        await engine.cancelPendingSignIn()
        await gate.open()
        let result = await confirm.result

        guard case .failure(let error) = result, error is CancellationError else {
            return XCTFail("expected CancellationError, got \(result)")
        }
        let pending = await engine.pendingChallenge
        XCTAssertNil(pending)
    }

    /// `resumeSignIn` is refused while a sign-in step is in flight, which is newer than any saved record; it
    /// resumes the same record once nothing is live.
    static func aResumeIsRefusedWhileAStepIsInFlight(_ driver: SeamContractDriver) async throws {
        let saved = try XCTUnwrap(savedChallenge())
        let engine = driver.engine
        let idle = await engine.resumeSignIn(from: saved, epoch: 0)
        XCTAssertEqual(idle, .confirmSignInWithTOTPCode, "the saved record resumes on an idle engine")
        await engine.cancelPendingSignIn()
        let gate = Gate()
        try driver.scriptNewPasswordChallenge(heldOn: gate)
        let signInRequest = request
        let signIn = Task { try await engine.signIn(signInRequest, current: nil) }
        await gate.waitForArrivals(1)

        let resumed = await engine.resumeSignIn(from: saved, epoch: 0)
        await gate.open()
        let result = try await signIn.value

        XCTAssertNil(resumed, "a step in flight is newer than a saved record")
        guard case .challenge(let step) = result, isNewPassword(step) else {
            return XCTFail("expected the sign-in's own challenge, got \(result)")
        }
        let pending = await engine.pendingChallenge
        XCTAssertTrue(isNewPassword(pending), "\(String(describing: pending))")
    }
}

/// The contract over `FakeSessionEngine`.
final class FakeSeamContractDriver: SeamContractDriver {

    let fake: FakeSessionEngine
    var engine: any SessionEngine { fake }
    private let confirmations = Counter()

    init() throws {
        let clients = try CognitoServiceClients(configuration: ClientFixtures.configuration, configureUserPoolClient: nil)
        self.fake = FakeSessionEngine(context: SessionEngineContext(
            sessionId: .default,
            configuration: ClientFixtures.configuration,
            namespace: StorageFixtures.namespace,
            clients: clients
        ))
    }

    func scriptNewPasswordChallenge() throws {
        fake.scriptSignIn { _, _ in .challenge(.confirmSignInWithNewPassword(nil)) }
    }

    func scriptRetryableRejectionThenDone() {
        let confirmations = confirmations
        fake.scriptConfirmSignIn { _ in
            if await confirmations.increment() == 1 {
                throw FakeRetryable(error: AuthClientError.service(.invalidPassword, "Password does not conform to policy", "s"))
            }
            return .done(payload: FakePayload.signedIn("alice").data)
        }
    }

    func scriptExpiredSession() {
        fake.scriptConfirmSignIn { _ in
            throw AuthClientError.challengeExpired("Invalid session for the user, session is expired.", "s")
        }
    }

    func scriptSignInDone(_ username: String) {
        fake.scriptSignIn { request, _ in .done(payload: FakePayload.signedIn(request.username).data) }
    }

    func scriptNewPasswordChallenge(heldOn gate: Gate) throws {
        fake.scriptSignIn { _, _ in
            await gate.pass()
            return .challenge(.confirmSignInWithNewPassword(nil))
        }
    }

    func scriptAnswerThenTOTPChallenge(heldOn gate: Gate) {
        fake.scriptConfirmSignIn { _ in
            await gate.pass()
            return .challenge(.confirmSignInWithTOTPCode)
        }
    }
}

/// The contract over the live engine and scripted Cognito.
final class LiveSeamContractDriver: SeamContractDriver {

    let harness = LiveEngineHarness()
    let live: LiveSessionEngine
    var engine: any SessionEngine { live }

    init() throws {
        self.live = try harness.engine()
        harness.scriptIdentityPool()
    }

    func scriptNewPasswordChallenge() throws {
        harness.scriptSRP(then: LiveEngineFixtures.challenge(.newPasswordRequired, parameters: ["requiredAttributes": "[]"]))
    }

    func scriptRetryableRejectionThenDone() {
        harness.cognito.once("RespondToAuthChallenge") { (_: RespondToAuthChallengeInput) -> RespondToAuthChallengeOutput in
            throw InvalidPasswordException(message: "Password does not conform to policy")
        }
        harness.cognito.once("RespondToAuthChallenge") { (_: RespondToAuthChallengeInput) in LiveEngineFixtures.signedIn() }
    }

    func scriptExpiredSession() {
        harness.cognito.once("RespondToAuthChallenge") { (_: RespondToAuthChallengeInput) -> RespondToAuthChallengeOutput in
            throw AWSCognitoIdentityProvider.NotAuthorizedException(message: "Invalid session for the user, session is expired.")
        }
    }

    func scriptSignInDone(_ username: String) {
        harness.scriptSRP(username)
    }

    func scriptNewPasswordChallenge(heldOn gate: Gate) throws {
        harness.cognito.once("InitiateAuth") { (_: InitiateAuthInput) in
            await gate.pass()
            return LiveEngineFixtures.passwordVerifier()
        }
        let challenge = LiveEngineFixtures.challenge(.newPasswordRequired, parameters: ["requiredAttributes": "[]"])
        harness.cognito.once("RespondToAuthChallenge") { (_: RespondToAuthChallengeInput) in challenge }
    }

    func scriptAnswerThenTOTPChallenge(heldOn gate: Gate) {
        harness.cognito.once("RespondToAuthChallenge") { (_: RespondToAuthChallengeInput) in
            await gate.pass()
            return LiveEngineFixtures.challenge(.softwareTokenMfa)
        }
    }
}
