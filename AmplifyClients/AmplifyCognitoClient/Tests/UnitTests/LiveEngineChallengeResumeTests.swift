//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import Foundation
import InternalAWSCognitoAuth
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// The live engine's challenge-record hooks over the real state machines and scripted Cognito: the
/// pending attempt's saved form, and a second engine (a relaunched app) resuming it and answering Cognito exactly
/// as the first would have.
final class LiveEngineChallengeResumeTests: XCTestCase {

    private var harness: LiveEngineHarness!
    private let password = "Correct-Horse-Battery-Staple-1"

    override func setUp() {
        harness = LiveEngineHarness()
    }

    override func tearDown() {
        harness = nil
    }

    /// The saved form, through the stored bytes, as a relaunch reads it back.
    private func savedAndReadBack(_ engine: LiveSessionEngine) async throws -> ChallengeRecord.State {
        let pending = await engine.pendingChallengeState
        let state = try XCTUnwrap(pending, "the attempt should have a saved form")
        let bytes = try ChallengeRecord(createdAt: Date(), state: state).encoded()
        XCTAssertNil(bytes.range(of: Data(password.utf8)), "no stored byte contains the password")
        guard case .record(let record) = ChallengeRecord.decode(bytes) else {
            throw FixtureError(description: "the saved form did not read back")
        }
        return record.state
    }

    /// - Given: engine A's SRP sign-in stopped on `SMS_MFA`, saved; a fresh engine B
    /// - When: B resumes the saved form, and answers the code
    /// - Then:
    ///    - the saved form holds the challenge, its session and alice, and never the password
    ///    - B reports the same step, and `RespondToAuthChallenge` goes out with the saved session, alice and the code
    ///    - the sign-in finishes `.done`, and nothing is pending on B
    func testAResumedSMSChallengeIsAnsweredAsTheOriginalWouldBe() async throws {
        let first = try harness.engine()
        harness.scriptSRP(then: LiveEngineFixtures.challenge(.smsMfa, parameters: LiveEngineFixtures.smsParameters, session: "sms-session"))
        let started = try await first.signIn(.srp(password: password), current: nil)
        guard case .challenge(let step) = started else {
            return XCTFail("expected a challenge, got \(started)")
        }
        let saved = try await savedAndReadBack(first)
        guard case .challenge(let challenge) = saved else {
            return XCTFail("expected a saved challenge, got \(saved)")
        }
        XCTAssertEqual(challenge.challengeName, "SMS_MFA")
        XCTAssertEqual(challenge.session, "sms-session")
        XCTAssertEqual(challenge.username, "alice")
        XCTAssertEqual(challenge.signInMethod, .init(authFlow: "userSRP"))

        let second = try harness.engine()
        let resumed = await second.resumeSignIn(from: saved, epoch: 0)
        XCTAssertEqual(resumed, step)
        let pending = await second.pendingChallenge
        XCTAssertEqual(pending, step)

        harness.cognito.once("RespondToAuthChallenge") { (_: RespondToAuthChallengeInput) in LiveEngineFixtures.signedIn() }
        harness.scriptIdentityPool()
        let done = try await second.confirmSignIn(.answer("123456"), current: nil)

        guard case .done = done else {
            return XCTFail("expected .done, got \(done)")
        }
        let answer = try XCTUnwrap(harness.cognito.inputs("RespondToAuthChallenge", as: RespondToAuthChallengeInput.self).last)
        XCTAssertEqual(answer.session, "sms-session")
        XCTAssertEqual(answer.challengeName, .smsMfa)
        XCTAssertEqual(answer.challengeResponses?["USERNAME"], "alice")
        XCTAssertEqual(answer.challengeResponses?["SMS_MFA_CODE"], "123456")
        let after = await second.pendingChallenge
        XCTAssertNil(after)
    }

    /// A TOTP setup is saved, with its secret and without the password, and resumes.
    ///
    /// - Given: engine A's sign-in stopped on a TOTP setup (`AssociateSoftwareToken` answered a secret), saved
    /// - When: engine B resumes it, and answers the code with a device name
    /// - Then:
    ///    - the saved form holds the secret, the setup's session and alice, and never the password
    ///    - B reports `.continueSignInWithTOTPSetup` with the secret; `VerifySoftwareToken` goes out with the setup's
    ///      session and the code, then `MFA_SETUP` is answered, and the sign-in finishes
    func testAResumedTOTPSetupCompletes() async throws {
        let first = try harness.engine()
        harness.scriptSRP(then: LiveEngineFixtures.challenge(.mfaSetup, parameters: ["MFAS_CAN_SETUP": #"["SOFTWARE_TOKEN_MFA"]"#]))
        harness.cognito.once("AssociateSoftwareToken") { (_: AssociateSoftwareTokenInput) in
            AssociateSoftwareTokenOutput(secretCode: "SHARED-SECRET", session: "setup-session")
        }
        _ = try await first.signIn(.srp(password: password), current: nil)
        let saved = try await savedAndReadBack(first)
        XCTAssertEqual(saved, .totpSetup(ChallengeRecord.TOTPSetup(
            secretCode: "SHARED-SECRET",
            session: "setup-session",
            username: "alice",
            signInUsername: "alice",
            signInMethod: .init(authFlow: "userSRP")
        )))

        let second = try harness.engine()
        let resumed = await second.resumeSignIn(from: saved, epoch: 0)
        XCTAssertEqual(resumed, .continueSignInWithTOTPSetup(AuthClientTOTPSetupDetails(sharedSecret: "SHARED-SECRET", username: "alice")))

        harness.cognito.once("VerifySoftwareToken") { (_: VerifySoftwareTokenInput) in
            VerifySoftwareTokenOutput(session: "verified-session", status: .success)
        }
        harness.cognito.once("RespondToAuthChallenge") { (_: RespondToAuthChallengeInput) in LiveEngineFixtures.signedIn() }
        harness.scriptIdentityPool()
        let done = try await second.confirmSignIn(.answer("123456", friendlyDeviceName: "phone"), current: nil)

        guard case .done = done else {
            return XCTFail("expected .done, got \(done)")
        }
        let verify = try XCTUnwrap(harness.cognito.inputs("VerifySoftwareToken", as: VerifySoftwareTokenInput.self).last)
        XCTAssertEqual(verify.session, "setup-session")
        XCTAssertEqual(verify.userCode, "123456")
        XCTAssertEqual(verify.friendlyDeviceName, "phone")
        let setupAnswer = try XCTUnwrap(harness.cognito.inputs("RespondToAuthChallenge", as: RespondToAuthChallengeInput.self).last)
        XCTAssertEqual(setupAnswer.challengeName, .mfaSetup)
        XCTAssertEqual(setupAnswer.session, "verified-session")
    }

    /// A wrong code's error state is saved as waiting for an answer, with the same session.
    ///
    /// - Given: a sign-in on `SMS_MFA`, and a wrong code (`CodeMismatchException`), which keeps the attempt
    /// - When: the saved form is read before and after the wrong code
    /// - Then:
    ///    - they are equal: resumed, the user simply answers again
    func testAWrongCodeSavesTheSameChallenge() async throws {
        let engine = try harness.engine()
        harness.scriptSRP(then: LiveEngineFixtures.challenge(.smsMfa, parameters: LiveEngineFixtures.smsParameters))
        harness.cognito.once("RespondToAuthChallenge") { (_: RespondToAuthChallengeInput) -> RespondToAuthChallengeOutput in
            throw CodeMismatchException(message: "Invalid code provided, please try again.")
        }
        _ = try await engine.signIn(.srp(), current: nil)
        let before = await engine.pendingChallengeState

        await assertThrowsAsync { try await engine.confirmSignIn(.answer("000000"), current: nil) }

        let after = await engine.pendingChallengeState
        XCTAssertNotNil(before)
        XCTAssertEqual(after, before)
    }

    /// - Given: engines with nothing pending, and one stopped on the `confirmSignUp` step (an SRP error)
    /// - When: their saved forms are read
    /// - Then:
    ///    - both are `nil`: neither can be answered by `confirmSignIn`
    func testNothingAnswerableHasNoSavedForm() async throws {
        let idle = try harness.engine()
        let unconfirmed = try harness.engine()
        harness.cognito.once("InitiateAuth") { (_: InitiateAuthInput) -> InitiateAuthOutput in
            throw UserNotConfirmedException(message: "User is not confirmed.")
        }
        let result = try await unconfirmed.signIn(.srp(), current: nil)
        XCTAssertEqual(result, .challenge(.confirmSignUp(nil)))

        let idleState = await idle.pendingChallengeState
        let unconfirmedState = await unconfirmed.pendingChallengeState
        XCTAssertNil(idleState)
        XCTAssertNil(unconfirmedState)
    }

    /// - Given: engine B already waiting on a challenge of its own, and a saved form from elsewhere
    /// - When: B is asked to resume the saved form
    /// - Then:
    ///    - it refuses (`nil`), and keeps its own attempt: a live one is newer
    func testAResumeNeverReplacesALiveAttempt() async throws {
        let engine = try harness.engine()
        harness.scriptSRP(then: LiveEngineFixtures.challenge(.smsMfa, parameters: LiveEngineFixtures.smsParameters))
        _ = try await engine.signIn(.srp(), current: nil)
        let own = await engine.pendingChallenge
        let other = try XCTUnwrap(ChallengeRecord.State.fake(.confirmSignInWithTOTPCode))

        let resumed = await engine.resumeSignIn(from: other, epoch: 0)

        XCTAssertNil(resumed)
        let pending = await engine.pendingChallenge
        XCTAssertEqual(pending, own)
    }

    /// An expired challenge session fails the resumed answer cleanly (§4.11).
    ///
    /// - Given: a resumed `SMS_MFA` challenge, and Cognito answering the expired-session `NotAuthorizedException`
    /// - When: the code is answered
    /// - Then:
    ///    - `challengeExpired` is thrown, and nothing is pending
    func testAnExpiredResumedChallengeIsChallengeExpired() async throws {
        let first = try harness.engine()
        harness.scriptSRP(then: LiveEngineFixtures.challenge(.smsMfa, parameters: LiveEngineFixtures.smsParameters))
        _ = try await first.signIn(.srp(), current: nil)
        let saved = try await savedAndReadBack(first)
        let second = try harness.engine()
        _ = await second.resumeSignIn(from: saved, epoch: 0)
        harness.cognito.once("RespondToAuthChallenge") { (_: RespondToAuthChallengeInput) -> RespondToAuthChallengeOutput in
            throw AWSCognitoIdentityProvider.NotAuthorizedException(message: "Invalid session for the user, session is expired.")
        }

        await assertThrowsAsync({ try await second.confirmSignIn(.answer("123456"), current: nil) }) { error in
            guard case .challengeExpired = authError(error) else {
                return XCTFail("expected challengeExpired, got \(error)")
            }
        }
        let pending = await second.pendingChallenge
        XCTAssertNil(pending)
    }

    /// Every answerable step round-trips through its saved form.
    ///
    /// - Given: each step a challenge state can wait on
    /// - When: it is saved and read back
    /// - Then:
    ///    - it is the same step; the steps no challenge state waits on have no saved form
    func testEveryAnswerableStepRoundTrips() {
        let delivery = EngineCodeDeliveryDetails(destination: .email("a***@example.com"), attributeKey: "email")
        var steps: [EngineSignInStep] = [
            .confirmSignInWithSMSMFACode(delivery, ["k": "v"]),
            .confirmSignInWithCustomChallenge(["q": "a"]),
            .confirmSignInWithNewPassword(["requiredAttributes": "[]"]),
            .confirmSignInWithPassword,
            .confirmSignInWithTOTPCode,
            .continueSignInWithMFASelection([.sms, .totp, .email]),
            .continueSignInWithEmailMFASetup,
            .continueSignInWithMFASetupSelection([.email, .totp]),
            .confirmSignInWithOTP(EngineCodeDeliveryDetails(destination: .sms("+1***"))),
            .continueSignInWithFirstFactorSelection([.password, .passwordSRP, .emailOTP, .smsOTP])
        ]
        #if os(iOS) || os(macOS) || os(visionOS)
        if #available(iOS 17.4, macOS 13.5, visionOS 1.0, *) {
            steps.append(.continueSignInWithFirstFactorSelection([.webAuthn, .password]))
        }
        #endif
        for step in steps {
            let saved = ChallengeRecord.Step(step)
            XCTAssertNotNil(saved, "\(step)")
            XCTAssertEqual(saved.flatMap(EngineSignInStep.init), step)
        }
        let unsaved: [EngineSignInStep] = [
            .continueSignInWithTOTPSetup(EngineTOTPSetupDetails(sharedSecret: "S", username: "u")),
            .resetPassword(nil),
            .confirmSignUp(nil),
            .done
        ]
        for step in unsaved {
            XCTAssertNil(ChallengeRecord.Step(step), "\(step)")
        }
    }

    /// Every API sign-in method round-trips through its saved form; a spelling this build does not know is refused.
    ///
    /// - Given: each flow, with and without a preferred first factor
    /// - When: it is saved and read back
    /// - Then:
    ///    - it is the same method; an unknown flow or factor spelling reads as `nil`
    func testEverySignInMethodRoundTrips() {
        let flows: [EngineAuthFlowType] = [
            .userSRP, .custom, .customWithSRP, .customWithoutSRP, .userPassword,
            .userAuth(preferredFirstFactor: nil), .userAuth(preferredFirstFactor: .emailOTP)
        ]
        for flow in flows {
            let saved = ChallengeRecord.SignInMethod(.apiBased(flow))
            XCTAssertEqual(saved.flatMap(SignInMethod.init), .apiBased(flow), "\(flow)")
        }
        XCTAssertNil(SignInMethod(ChallengeRecord.SignInMethod(authFlow: "passkeyOnly")))
        XCTAssertNil(SignInMethod(ChallengeRecord.SignInMethod(authFlow: "userAuth", preferredFirstFactor: "TELEPATHY")))
    }
}
