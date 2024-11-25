//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSCognitoIdentity
@testable import Amplify
@testable import AWSCognitoAuthPlugin
import AWSCognitoIdentityProvider
import AWSClientRuntime

class EmailMFATests: BasePluginTest {

    override var initialState: AuthState {
        AuthState.configured(.signedOut(.init(lastKnownUserName: nil)), .configured, .notStarted)
    }

    /// Test a signIn with valid inputs getting continueSignInWithMFASetupSelection challenge
    ///
    /// - Given: Given an auth plugin with mocked service.
    ///
    /// - When:
    ///    - I invoke signIn with valid values
    /// - Then:
    ///    - I should get a .continueSignInWithMFASetupSelection response
    ///
    func testSuccessfulMFASetupSelectionStep() async {
        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { input in
            return InitiateAuthOutput(
                authenticationResult: .none,
                challengeName: .passwordVerifier,
                challengeParameters: InitiateAuthOutput.validChalengeParams,
                session: "someSession")
        }, mockRespondToAuthChallengeResponse: { input in
            return .testData(
                challenge: .mfaSetup,
                challengeParameters: ["MFAS_CAN_SETUP": "[\"SMS_MFA\",\"SOFTWARE_TOKEN_MFA\",\"EMAIL_OTP\"]"])
        })
        let options = AuthSignInRequest.Options()

        do {
            let result = try await plugin.signIn(
                username: "username",
                password: "password",
                options: options)
            guard case .continueSignInWithMFASetupSelection(let mfaTypes) = result.nextStep else {
                XCTFail("Result should be .continueSignInWithMFASetupSelection for next step")
                return
            }
            XCTAssertTrue(mfaTypes.contains(.totp))
            XCTAssertTrue(mfaTypes.contains(.email))
            XCTAssertFalse(mfaTypes.contains(.sms))
            XCTAssertFalse(result.isSignedIn, "Signin result should be complete")
        } catch {
            XCTFail("Received failure with error \(error)")
        }
    }

    /// Test a signIn with valid inputs getting continueSignInWithEmailMFASetup challenge
    ///
    /// - Given: Given an auth plugin with mocked service.
    ///
    /// - When:
    ///    - I invoke signIn with valid values
    /// - Then:
    ///    - I should get a .continueSignInWithEmailMFASetup response
    ///
    func testSuccessfulEmailMFASetupStep() async {
        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { input in
            return InitiateAuthOutput(
                authenticationResult: .none,
                challengeName: .passwordVerifier,
                challengeParameters: InitiateAuthOutput.validChalengeParams,
                session: "someSession")
        }, mockRespondToAuthChallengeResponse: { input in
            return .testData(
                challenge: .mfaSetup,
                challengeParameters: ["MFAS_CAN_SETUP": "[\"SMS_MFA\",\"EMAIL_OTP\"]"])
        })
        let options = AuthSignInRequest.Options()

        do {
            let result = try await plugin.signIn(
                username: "username",
                password: "password",
                options: options)
            guard case .continueSignInWithEmailMFASetup = result.nextStep else {
                XCTFail("Result should be .continueSignInWithEmailMFASetup for next step, instead got: \(result.nextStep)")
                return
            }
            XCTAssertFalse(result.isSignedIn, "Signin result should be complete")
        } catch {
            XCTFail("Received failure with error \(error)")
        }
    }

    /// Test a signIn with valid inputs getting confirmSignInWithOTP challenge
    ///
    /// - Given: Given an auth plugin with mocked service.
    ///
    /// - When:
    ///    - I invoke signIn with valid values
    /// - Then:
    ///    - I should get a .confirmSignInWithOTP response
    ///
    func testSuccessfulEmailMFACodeStep() async {
        var signInStepIterator = 0
        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { input in
            return InitiateAuthOutput(
                authenticationResult: .none,
                challengeName: .passwordVerifier,
                challengeParameters: InitiateAuthOutput.validChalengeParams,
                session: "someSession")
        }, mockRespondToAuthChallengeResponse: { input in
            if signInStepIterator == 0 {
                return .testData(
                    challenge: .emailOtp,
                    challengeParameters: [
                        "CODE_DELIVERY_DELIVERY_MEDIUM": "EMAIL",
                        "CODE_DELIVERY_DESTINATION": "test@test.com"])
            } else if signInStepIterator == 1 {
                XCTAssertEqual(input.challengeResponses?["EMAIL_OTP_CODE"], "123456")
                XCTAssertEqual(input.session, "session")
                return .testData()
            }
            fatalError("not supported code path")
        })

        do {
            let result = try await plugin.signIn(
                username: "username",
                password: "password",
                options: AuthSignInRequest.Options())
            guard case .confirmSignInWithOTP(let codeDetails) = result.nextStep else {
                XCTFail("Result should be .confirmSignInWithOTP for next step, instead got: \(result.nextStep)")
                return
            }
            if case .email(let destination) = codeDetails.destination {
                XCTAssertEqual(destination, "test@test.com")
            } else {
                XCTFail("Destination should be email")
            }
            XCTAssertFalse(result.isSignedIn, "Signin result should be complete")

            // step 2: confirm sign in
            signInStepIterator = 1
            let confirmSignInResult = try await plugin.confirmSignIn(
                challengeResponse: "123456",
                options: .init())
            guard case .done = confirmSignInResult.nextStep else {
                XCTFail("Result should be .done for next step")
                return
            }
            XCTAssertTrue(confirmSignInResult.isSignedIn, "Signin result should NOT be complete")
        } catch {
            XCTFail("Received failure with error \(error)")
        }
    }



    /// Test a signIn with valid inputs getting continueSignInWithMFASetupSelection challenge
    ///
    /// - Given: Given an auth plugin with mocked service.
    ///
    /// - When:
    ///    - I invoke signIn with valid values
    /// - Then:
    ///    - I should get a .continueSignInWithMFASetupSelection response
    ///
    func testConfirmSignInForEmailMFASetupSelectionStep() async {
        var signInStepIterator = 0
        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { input in
            return InitiateAuthOutput(
                authenticationResult: .none,
                challengeName: .passwordVerifier,
                challengeParameters: InitiateAuthOutput.validChalengeParams,
                session: "session0")
        }, mockRespondToAuthChallengeResponse: { input in
            switch signInStepIterator {
            case 0:
                XCTAssertEqual(input.session, "session0")
                return .testData(
                    challenge: .mfaSetup,
                    challengeParameters: ["MFAS_CAN_SETUP": "[\"SMS_MFA\",\"SOFTWARE_TOKEN_MFA\",\"EMAIL_OTP\"]"],
                    session: "session1")
            case 1:
                XCTAssertEqual(input.challengeResponses?["EMAIL"], "test@test.com")
                XCTAssertEqual(input.session, "session1")
                return .testData(
                    challenge: .emailOtp,
                    challengeParameters: [
                        "CODE_DELIVERY_DELIVERY_MEDIUM": "EMAIL",
                        "CODE_DELIVERY_DESTINATION": "test@test.com"],
                    session: "session2")
            case 2:
                XCTAssertEqual(input.challengeResponses?["EMAIL_OTP_CODE"], "123456")
                XCTAssertEqual(input.session, "session2")
                return .testData()
            default: fatalError("unsupported path")
            }

        })

        do {
            // Step 1: initiate sign in
            let result = try await plugin.signIn(
                username: "username",
                password: "password",
                options: AuthSignInRequest.Options())
            guard case .continueSignInWithMFASetupSelection(let mfaTypes) = result.nextStep else {
                XCTFail("Result should be .continueSignInWithMFASetupSelection for next step")
                return
            }
            XCTAssertTrue(mfaTypes.contains(.totp))
            XCTAssertTrue(mfaTypes.contains(.email))
            XCTAssertFalse(mfaTypes.contains(.sms))
            XCTAssertFalse(result.isSignedIn, "Signin result should be complete")

            // Step 2: select email to continue setting up
            var confirmSignInResult = try await plugin.confirmSignIn(
                challengeResponse: MFAType.email.challengeResponse)
            guard case .continueSignInWithEmailMFASetup = confirmSignInResult.nextStep else {
                XCTFail("Result should be .continueSignInWithEmailMFASetup but got: \(confirmSignInResult.nextStep)")
                return
            }

            // Step 3: pass an email to setup
            signInStepIterator = 1
            confirmSignInResult = try await plugin.confirmSignIn(
                challengeResponse: "test@test.com")
            guard case .confirmSignInWithOTP(let deliveryDetails) = confirmSignInResult.nextStep else {
                XCTFail("Result should be .continueSignInWithEmailMFASetup but got: \(confirmSignInResult.nextStep)")
                return
            }
            if case .email(let destination) = deliveryDetails.destination {
                XCTAssertEqual(destination, "test@test.com")
            } else {
                XCTFail("Destination should be email")
            }

            XCTAssertFalse(result.isSignedIn, "Signin result should be complete")

            // step 4: confirm sign in
            signInStepIterator = 2
            confirmSignInResult = try await plugin.confirmSignIn(
                challengeResponse: "123456",
                options: .init())
            guard case .done = confirmSignInResult.nextStep else {
                XCTFail("Result should be .done for next step")
                return
            }
            XCTAssertTrue(confirmSignInResult.isSignedIn, "Signin result should NOT be complete")

        } catch {
            XCTFail("Received failure with error \(error)")
        }
    }

    /// Test a signIn with valid inputs getting continueSignInWithMFASetupSelection challenge
    ///
    /// - Given: Given an auth plugin with mocked service.
    ///
    /// - When:
    ///    - I invoke signIn with valid values
    /// - Then:
    ///    - I should get a .continueSignInWithMFASetupSelection response
    ///
    func testConfirmSignInForTOTPMFASetupSelectionStep() async {
        var completeSignIn = false
        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { input in
            return InitiateAuthOutput(
                authenticationResult: .none,
                challengeName: .passwordVerifier,
                challengeParameters: InitiateAuthOutput.validChalengeParams,
                session: "someSession")
        }, mockRespondToAuthChallengeResponse: { input in
            if completeSignIn {
                XCTAssertEqual(input.session, "verifiedSession")
                return .testData()
            }

            return .testData(
                challenge: .mfaSetup,
                challengeParameters: ["MFAS_CAN_SETUP": "[\"SMS_MFA\",\"SOFTWARE_TOKEN_MFA\",\"EMAIL_OTP\"]"])


        }, mockAssociateSoftwareTokenResponse: { input in
            return .init(secretCode: "sharedSecret", session: "newSession")
        }, mockVerifySoftwareTokenResponse: { request in
            XCTAssertEqual(request.session, "newSession")
            XCTAssertEqual(request.userCode, "123456")
            XCTAssertEqual(request.friendlyDeviceName, "device")
            return .init(session: "verifiedSession", status: .success)
        })

        do {
            // Step 1: initiate sign in
            let result = try await plugin.signIn(
                username: "username",
                password: "password",
                options: AuthSignInRequest.Options())
            guard case .continueSignInWithMFASetupSelection(let mfaTypes) = result.nextStep else {
                XCTFail("Result should be .continueSignInWithMFASetupSelection for next step")
                return
            }
            XCTAssertTrue(mfaTypes.contains(.totp))
            XCTAssertTrue(mfaTypes.contains(.email))
            XCTAssertFalse(mfaTypes.contains(.sms))
            XCTAssertFalse(result.isSignedIn, "Signin result should be complete")

            // Step 2: continue sign in by selecting TOTP for set up
            var confirmSignInResult = try await plugin.confirmSignIn(
                challengeResponse: MFAType.totp.challengeResponse)
            guard case .continueSignInWithTOTPSetup(let totpDetails) = confirmSignInResult.nextStep else {
                XCTFail("Result should be .continueSignInWithEmailMFASetup but got: \(confirmSignInResult.nextStep)")
                return
            }
            XCTAssertEqual(totpDetails.sharedSecret, "sharedSecret")
            XCTAssertEqual(totpDetails.username, "royji2")
            XCTAssertFalse(result.isSignedIn, "Signin result should be complete")

            // Step 3: complete sign in by verifying TOTP set up
            completeSignIn = true
            let pluginOptions = AWSAuthConfirmSignInOptions(friendlyDeviceName: "device")
            confirmSignInResult = try await plugin.confirmSignIn(
                challengeResponse: "123456",
                options: .init(pluginOptions: pluginOptions))
            guard case .done = confirmSignInResult.nextStep else {
                XCTFail("Result should be .done for next step")
                return
            }
            XCTAssertTrue(confirmSignInResult.isSignedIn, "Signin result should NOT be complete")

        } catch {
            XCTFail("Received failure with error \(error)")
        }
    }
}
