//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
import AWSCognitoAuthPlugin
import AWSAPIPlugin

/// This class contains integration tests for the sign-in functionality using various authentication flows.
/// It tests the sign-in process with different preferred factors such as password, passwordSRP, email OTP, and SMS OTP.
/// The tests ensure that the sign-in process completes successfully for valid users registered in the Cognito user pool.
class PasswordlessSignInTests: AWSAuthBaseTest {

    override func setUp() async throws {

        // Only run these tests with Gen2 configuration
        onlyUseGen2Configuration = true

        // Use a custom configuration these tests
        amplifyOutputsFile = "testconfiguration/AWSCognitoPluginPasswordlessIntegrationTests-amplify_outputs"

        // Add API plugin to Amplify
        let awsApiPlugin = AWSAPIPlugin()
        try Amplify.add(plugin: awsApiPlugin)

        try await super.setUp()
        AuthSessionHelper.clearSession()

        await subscribeToOTPCreation()
    }

    override func tearDown() async throws {
        try await super.tearDown()
        AuthSessionHelper.clearSession()
    }

    private func signUp(username: String, password: String) async throws {

        let result = try await AuthSignInHelper.signUpUserReturningResult(
            username: username,
            password: password,
            email: randomEmail,
            phoneNumber: randomPhoneNumber
        )

        // Retrieve the OTP sent to the email and confirm the sign-in
        guard let otp = try await otp(for: username) else {
            XCTFail("Failed to retrieve the OTP code")
            return
        }

        guard case .confirmUser = result.nextStep else {
            XCTFail("Incorrect next step for sign up confirmation")
            return
        }

        let confirmSignUpResult = try await Amplify.Auth.confirmSignUp(
            for: username, confirmationCode: otp)

        guard confirmSignUpResult.isSignUpComplete else {
            XCTFail("Failed confirmation of sign up")
            return
        }
    }

    /// Test successful signIn of a valid user
    ///
    /// - Given: A user registered in Cognito user pool
    /// - When:
    ///    - I invoke Amplify.Auth.signIn with the username and password, using userAuth flow by setting `password` as the preferred factor
    /// - Then:
    ///    - I should get a completed signIn flow.
    ///
    func testSignInWithPasswordAsPreferred_givenValidUser_expectCompletedSignIn() async throws {

        let username = "integTest\(UUID().uuidString)"
        let password = "Pp123@\(UUID().uuidString)"

        try await signUp(username: username, password: password)

        do {
            let pluginOptions = AWSAuthSignInOptions(
                authFlowType: .userAuth(preferredFirstFactor: .password))
            let signInResult = try await Amplify.Auth.signIn(
                username: username,
                password: password,
                options: .init(pluginOptions: pluginOptions))
            XCTAssertTrue(signInResult.isSignedIn, "SignIn should be complete")
        } catch {
            XCTFail("SignIn with a valid username/password should not fail \(error)")
        }
    }

    /// Test successful signIn of a valid user
    ///
    /// - Given: A user registered in Cognito user pool
    /// - When:
    ///    - I invoke Amplify.Auth.signIn with the username and password, using userAuth flow by setting `passwordSRP` as the preferred factor
    /// - Then:
    ///    - I should get a completed signIn flow.
    ///
    func testSignInWithPasswordSRPAsPreferred_givenValidUser_expectCompletedSignIn() async throws {

        let username = "integTest\(UUID().uuidString)"
        let password = "Pp123@\(UUID().uuidString)"

        try await signUp(username: username, password: password)

        do {
            let pluginOptions = AWSAuthSignInOptions(
                authFlowType: .userAuth(preferredFirstFactor: .passwordSRP))
            let signInResult = try await Amplify.Auth.signIn(
                username: username,
                password: password,
                options: .init(pluginOptions: pluginOptions))
            XCTAssertTrue(signInResult.isSignedIn, "SignIn should be complete")
        } catch {
            XCTFail("SignIn with a valid username/password should not fail \(error)")
        }
    }

    /// Test successful signIn of a valid user
    ///
    /// - Given: A user registered in Cognito user pool
    /// - When:
    ///    - I invoke Amplify.Auth.signIn with the username and password, using userAuth flow
    /// - Then:
    ///    - I should get a completed signIn flow.
    ///
    func testSignInWithPasswordSRP_givenValidUser_expectCompletedSignIn() async throws {

        let username = "integTest\(UUID().uuidString)"
        let password = "Pp123@\(UUID().uuidString)"

        try await signUp(username: username, password: password)

        do {
            let pluginOptions = AWSAuthSignInOptions(
                authFlowType: .userAuth)
            let signInResult = try await Amplify.Auth.signIn(
                username: username,
                password: password,
                options: .init(pluginOptions: pluginOptions))
            guard case .continueSignInWithFirstFactorSelection(let availableFactors) = signInResult.nextStep else {
                XCTFail("SignIn should return a .continueSignInWithFirstFactorSelection")
                return
            }
            XCTAssert(availableFactors.contains(.passwordSRP))
            var confirmSignInResult = try await Amplify.Auth.confirmSignIn(
                challengeResponse: AuthFactorType.passwordSRP.challengeResponse)

            guard case .confirmSignInWithPassword = confirmSignInResult.nextStep else {
                XCTFail("ConfirmSignIn should return a .confirmSignInWithPassword")
                return
            }

            confirmSignInResult = try await Amplify.Auth.confirmSignIn(
                challengeResponse: password)

            XCTAssertTrue(confirmSignInResult.isSignedIn, "SignIn should be complete")
        } catch {
            XCTFail("SignIn with a valid username/password should not fail \(error)")
        }
    }

    /// Test successful signIn of a valid user
    ///
    /// - Given: A user registered in Cognito user pool
    /// - When:
    ///    - I invoke Amplify.Auth.signIn with the username and password, using userAuth flow
    ///    - Retry confirm sign in after a wrong password attempt is not supposed to work in `userAuth` flow. Cognito doesn't support this flow.
    ///    - Re-initiation of sign in should work correctly after a incorrect attempt
    /// - Then:
    ///    - I should get a completed signIn flow.
    ///
    func testSignInWithPasswordSRP_givenValidUser_expectErrorOnWrongPassword() async throws {

        let username = "integTest\(UUID().uuidString)"
        let password = "Pp123@\(UUID().uuidString)"

        try await signUp(username: username, password: password)

        do {
            let pluginOptions = AWSAuthSignInOptions(
                authFlowType: .userAuth)
            var signInResult = try await Amplify.Auth.signIn(
                username: username,
                password: password,
                options: .init(pluginOptions: pluginOptions))
            guard case .continueSignInWithFirstFactorSelection(let availableFactors) = signInResult.nextStep else {
                XCTFail("SignIn should return a .continueSignInWithFirstFactorSelection")
                return
            }
            XCTAssert(availableFactors.contains(.passwordSRP))
            var confirmSignInResult = try await Amplify.Auth.confirmSignIn(
                challengeResponse: AuthFactorType.passwordSRP.challengeResponse)

            guard case .confirmSignInWithPassword = confirmSignInResult.nextStep else {
                XCTFail("ConfirmSignIn should return a .confirmSignInWithPassword")
                return
            }

            // Try confirming with wrong password and it should fail

            do {
                confirmSignInResult = try await Amplify.Auth.confirmSignIn(
                    challengeResponse: "wrong-password")
            } catch {
                guard let error = error as? AuthError else {
                    XCTFail("Error should be of type AuthError instead got: \(error)")
                    return
                }
                guard case .notAuthorized = error else {
                    XCTFail("Error should be .notAuthorized instead got: \(error)")
                    return
                }
            }

            // Try confirming with password again and it should fail saying that re-initiation is needed

            do {
                confirmSignInResult = try await Amplify.Auth.confirmSignIn(
                    challengeResponse: password)
            } catch {
                guard let error = error as? AuthError else {
                    XCTFail("Error should be of type AuthError instead got: \(error)")
                    return
                }
                guard case .invalidState = error else {
                    XCTFail("Error should be .invalidState instead got: \(error)")
                    return
                }
            }

            // After all the errors re-initiation of sign in should work

            // Sign in
            _ = try await Amplify.Auth.signIn(
                username: username,
                password: password,
                options: .init(pluginOptions: pluginOptions))
            // Select passwordSRP
            _ = try await Amplify.Auth.confirmSignIn(
                challengeResponse: AuthFactorType.passwordSRP.challengeResponse)
            // Complete sign in
            confirmSignInResult = try await Amplify.Auth.confirmSignIn(
                challengeResponse: password)

            XCTAssertTrue(confirmSignInResult.isSignedIn, "SignIn should be complete")
        } catch {
            XCTFail("SignIn with a valid username/password should not fail \(error)")
        }
    }

    /// Test successful signIn of a valid user
    ///
    /// - Given: A user registered in Cognito user pool
    /// - When:
    ///    - I invoke Amplify.Auth.signIn with the username and password, using userAuth flow
    /// - Then:
    ///    - I should get a completed signIn flow.
    ///
    func testSignInWithPassword_givenValidUser_expectCompletedSignIn() async throws {
        let username = "integTest\(UUID().uuidString)"
        let password = "Pp123@\(UUID().uuidString)"

        try await signUp(username: username, password: password)

        do {
            let pluginOptions = AWSAuthSignInOptions(
                authFlowType: .userAuth)
            let signInResult = try await Amplify.Auth.signIn(
                username: username,
                password: password,
                options: .init(pluginOptions: pluginOptions))
            guard case .continueSignInWithFirstFactorSelection(let availableFactors) = signInResult.nextStep else {
                XCTFail("SignIn should return a .continueSignInWithFirstFactorSelection")
                return
            }
            XCTAssert(availableFactors.contains(.password))
            var confirmSignInResult = try await Amplify.Auth.confirmSignIn(
                challengeResponse: AuthFactorType.password.challengeResponse)

            guard case .confirmSignInWithPassword = confirmSignInResult.nextStep else {
                XCTFail("ConfirmSignIn should return a .confirmSignInWithPassword")
                return
            }

            confirmSignInResult = try await Amplify.Auth.confirmSignIn(
                challengeResponse: password)

            XCTAssertTrue(confirmSignInResult.isSignedIn, "SignIn should be complete")
        } catch {
            XCTFail("SignIn with a valid username/password should not fail \(error)")
        }
    }


    /// Test successful signIn of a valid user
    ///
    /// - Given: A user registered in Cognito user pool
    /// - When:
    ///    - I invoke Amplify.Auth.signIn with the username and password, using userAuth flow by setting `emailOTP` as the preferred factor
    /// - Then:
    ///    - I should get a completed signIn flow.
    ///
    func testSignInWithEmailOTPAsPreferred_givenValidUser_expectCompletedSignIn() async throws {

        let username = "integTest\(UUID().uuidString)"
        let password = "Pp123@\(UUID().uuidString)"

        try await signUp(username: username, password: password)

        do {
            let pluginOptions = AWSAuthSignInOptions(
                authFlowType: .userAuth(preferredFirstFactor: .emailOTP))
            let signInResult = try await Amplify.Auth.signIn(
                username: username,
                options: .init(pluginOptions: pluginOptions))

            // Retrieve the OTP sent to the email and confirm the sign-in
            guard let otp = try await otp(for: username) else {
                XCTFail("Failed to retrieve the OTP code")
                return
            }

            guard case .confirmSignInWithOTP(let codeDeliverDetails) = signInResult.nextStep else {
                XCTFail("SignIn should return a .confirmSignInWithOTP")
                return
            }

            guard case .email = codeDeliverDetails.destination else {
                XCTFail("destination should be email")
                return
            }

            let confirmSignInResult = try await Amplify.Auth.confirmSignIn(
                challengeResponse: otp)
            
            XCTAssertTrue(confirmSignInResult.isSignedIn, "SignIn should be complete")
        } catch {
            XCTFail("SignIn with a valid username/password should not fail \(error)")
        }
    }

    /// Test successful signIn of a valid user
    ///
    /// - Given: A user registered in Cognito user pool
    /// - When:
    ///    - I invoke Amplify.Auth.signIn with the username and password, using userAuth flow by setting `smsOTP` as the preferred factor
    /// - Then:
    ///    - I should get a completed signIn flow.
    ///
    func testSignInWithSMSOTPAsPreferred_givenValidUser_expectCompletedSignIn() async throws {

        let username = "integTest\(UUID().uuidString)"
        let password = "Pp123@\(UUID().uuidString)"

        try await signUp(username: username, password: password)

        do {
            let pluginOptions = AWSAuthSignInOptions(
                authFlowType: .userAuth(preferredFirstFactor: .smsOTP))
            let signInResult = try await Amplify.Auth.signIn(
                username: username,
                options: .init(pluginOptions: pluginOptions))

            // Retrieve the OTP sent to the email and confirm the sign-in
            guard let otp = try await otp(for: username) else {
                XCTFail("Failed to retrieve the OTP code")
                return
            }

            guard case .confirmSignInWithOTP(let codeDeliverDetails) = signInResult.nextStep else {
                XCTFail("SignIn should return a .confirmSignInWithOTP")
                return
            }

            guard case .sms = codeDeliverDetails.destination else {
                XCTFail("destination should be sms")
                return
            }

            let confirmSignInResult = try await Amplify.Auth.confirmSignIn(
                challengeResponse: otp)

            XCTAssertTrue(confirmSignInResult.isSignedIn, "SignIn should be complete")
        } catch {
            XCTFail("SignIn with a valid username/password should not fail \(error)")
        }
    }

    /// Test successful signIn of a valid user
    ///
    /// - Given: A user registered in Cognito user pool
    /// - When:
    ///    - I invoke Amplify.Auth.signIn with the username and password, using userAuth flow without setting `emailOTP` as the preferred factor
    /// - Then:
    ///    - I should get a completed signIn flow.
    func testSignInWithoutEmailOTPAsPreferred_givenValidUser_expectCompletedSignIn() async throws {

        let username = "integTest\(UUID().uuidString)"
        let password = "Pp123@\(UUID().uuidString)"

        try await signUp(username: username, password: password)

        do {
            let pluginOptions = AWSAuthSignInOptions(
                authFlowType: .userAuth)
            let signInResult = try await Amplify.Auth.signIn(
                username: username,
                password: password,
                options: .init(pluginOptions: pluginOptions))

            guard case .continueSignInWithFirstFactorSelection(let availableFactors) = signInResult.nextStep else {
                XCTFail("SignIn should return a .continueSignInWithFirstFactorSelection")
                return
            }
            XCTAssert(availableFactors.contains(.emailOTP))
            
            // Select emailOTP as the factor
            var confirmSignInResult = try await Amplify.Auth.confirmSignIn(
                challengeResponse: AuthFactorType.emailOTP.challengeResponse)

            // Retrieve the OTP sent to the email and confirm the sign-in
            guard let otp = try await otp(for: username) else {
                XCTFail("Failed to retrieve the OTP code")
                return
            }

            guard case .confirmSignInWithOTP(let codeDeliverDetails) = confirmSignInResult.nextStep else {
                XCTFail("ConfirmSignIn should return a .confirmSignInWithOTP")
                return
            }

            guard case .email = codeDeliverDetails.destination else {
                XCTFail("destination should be email")
                return
            }

            confirmSignInResult = try await Amplify.Auth.confirmSignIn(
                challengeResponse: otp)

            XCTAssertTrue(confirmSignInResult.isSignedIn, "SignIn should be complete")
        } catch {
            XCTFail("SignIn with a valid username/password should not fail \(error)")
        }
    }

    /// Test successful signIn of a valid user
    ///
    /// - Given: A user registered in Cognito user pool
    /// - When:
    ///    - I invoke Amplify.Auth.signIn with the username and password, using userAuth flow without setting `smsOTP` as the preferred factor
    /// - Then:
    ///    - I should get a completed signIn flow.
    func testSignInWithoutSMSOTPAsPreferred_givenValidUser_expectCompletedSignIn() async throws {

        let username = "integTest\(UUID().uuidString)"
        let password = "Pp123@\(UUID().uuidString)"

        try await signUp(username: username, password: password)

        do {
            let pluginOptions = AWSAuthSignInOptions(
                authFlowType: .userAuth)
            let signInResult = try await Amplify.Auth.signIn(
                username: username,
                password: password,
                options: .init(pluginOptions: pluginOptions))

            guard case .continueSignInWithFirstFactorSelection(let availableFactors) = signInResult.nextStep else {
                XCTFail("SignIn should return a .continueSignInWithFirstFactorSelection")
                return
            }
            XCTAssert(availableFactors.contains(.smsOTP))
            
            // Select smsOTP as the factor
            var confirmSignInResult = try await Amplify.Auth.confirmSignIn(
                challengeResponse: AuthFactorType.smsOTP.challengeResponse)

            // Retrieve the OTP sent to the email and confirm the sign-in
            guard let otp = try await otp(for: username) else {
                XCTFail("Failed to retrieve the OTP code")
                return
            }

            guard case .confirmSignInWithOTP(let codeDeliverDetails) = confirmSignInResult.nextStep else {
                XCTFail("ConfirmSignIn should return a .confirmSignInWithOTP")
                return
            }

            guard case .sms = codeDeliverDetails.destination else {
                XCTFail("destination should be sms")
                return
            }

            confirmSignInResult = try await Amplify.Auth.confirmSignIn(
                challengeResponse: otp)

            XCTAssertTrue(confirmSignInResult.isSignedIn, "SignIn should be complete")
        } catch {
            XCTFail("SignIn with a valid username/password should not fail \(error)")
        }
    }

    /// Test signIn with no preferred factor shows SELECT_CHALLENGE
    ///
    /// - Given: A user registered in Cognito user pool
    /// - When:
    ///    - I invoke Amplify.Auth.signIn with the username and password, using userAuth flow without setting any preferred factor
    /// - Then:
    ///    - I should get a SELECT_CHALLENGE step.
    func testSignInWithNoPreference_givenValidUser_expectSelectChallenge() async throws {
        let username = "integTest\(UUID().uuidString)"
        let password = "Pp123@\(UUID().uuidString)"

        try await signUp(username: username, password: password)

        do {
            let pluginOptions = AWSAuthSignInOptions(authFlowType: .userAuth)
            let signInResult = try await Amplify.Auth.signIn(
                username: username,
                password: password,
                options: .init(pluginOptions: pluginOptions))

            guard case .continueSignInWithFirstFactorSelection = signInResult.nextStep else {
                XCTFail("SignIn should return a .continueSignInWithFirstFactorSelection")
                return
            }
        } catch {
            XCTFail("SignIn with a valid username/password should not fail \(error)")
        }
    }

    /// Test signIn with unsupported preferred factor shows SELECT_CHALLENGE
    ///
    /// - Given: A user registered in Cognito user pool
    /// - When:
    ///    - I invoke Amplify.Auth.signIn with the username and password, using userAuth flow with an unsupported preferred factor
    /// - Then:
    ///    - I should get a SELECT_CHALLENGE step.
#if os(iOS) || os(macOS) || os(visionOS)
    @available(iOS 17.4, macOS 13.5, visionOS 1.0, *)
    func testSignInWithUnsupportedPreference_givenValidUser_expectSelectChallenge() async throws {
        let username = "integTest\(UUID().uuidString)"
        let password = "Pp123@\(UUID().uuidString)"

        try await signUp(username: username, password: password)

        do {
            let pluginOptions = AWSAuthSignInOptions(authFlowType: .userAuth(preferredFirstFactor: .webAuthn))
            let signInResult = try await Amplify.Auth.signIn(
                username: username,
                password: password,
                options: .init(pluginOptions: pluginOptions))

            guard case .continueSignInWithFirstFactorSelection = signInResult.nextStep else {
                XCTFail("SignIn should return a .continueSignInWithFirstFactorSelection")
                return
            }
        } catch {
            XCTFail("SignIn with a valid username/password should not fail \(error)")
        }
    }
#endif
    /// Test signIn with EMAIL_OTP preference triggers Confirm OTP flow
    ///
    /// - Given: A user registered in Cognito user pool
    /// - When:
    ///    - I invoke Amplify.Auth.signIn with the username and password, using userAuth flow with EMAIL_OTP as the preferred factor
    /// - Then:
    ///    - I should get a Confirm OTP flow.
    func testSignInWithEmailOTPPreference_givenValidUser_expectConfirmOTPFlow() async throws {
        let username = "integTest\(UUID().uuidString)"
        let password = "Pp123@\(UUID().uuidString)"

        try await signUp(username: username, password: password)

        do {
            let pluginOptions = AWSAuthSignInOptions(authFlowType: .userAuth(preferredFirstFactor: .emailOTP))
            let signInResult = try await Amplify.Auth.signIn(
                username: username,
                options: .init(pluginOptions: pluginOptions))

            guard case .confirmSignInWithOTP = signInResult.nextStep else {
                XCTFail("SignIn should return a .confirmSignInWithOTP")
                return
            }
        } catch {
            XCTFail("SignIn with a valid username/password should not fail \(error)")
        }
    }

    /// Test signIn with SMS_OTP preference triggers Confirm OTP flow
    ///
    /// - Given: A user registered in Cognito user pool
    /// - When:
    ///    - I invoke Amplify.Auth.signIn with the username and password, using userAuth flow with SMS_OTP as the preferred factor
    /// - Then:
    ///    - I should get a Confirm OTP flow.
    func testSignInWithSMSOTPPreference_givenValidUser_expectConfirmOTPFlow() async throws {
        let username = "integTest\(UUID().uuidString)"
        let password = "Pp123@\(UUID().uuidString)"

        try await signUp(username: username, password: password)

        do {
            let pluginOptions = AWSAuthSignInOptions(authFlowType: .userAuth(preferredFirstFactor: .smsOTP))
            let signInResult = try await Amplify.Auth.signIn(
                username: username,
                options: .init(pluginOptions: pluginOptions))

            guard case .confirmSignInWithOTP = signInResult.nextStep else {
                XCTFail("SignIn should return a .confirmSignInWithOTP")
                return
            }
        } catch {
            XCTFail("SignIn with a valid username/password should not fail \(error)")
        }
    }

    /// Test signIn with PASSWORD as preferred factor with incorrect password fails
    ///
    /// - Given: A user registered in Cognito user pool
    /// - When:
    ///    - I invoke Amplify.Auth.signIn with the username and incorrect password, using userAuth flow with PASSWORD as the preferred factor
    /// - Then:
    ///    - I should get a failed signIn flow.
    func testSignInWithPasswordAsPreferred_givenInvalidPassword_expectFailedSignIn() async throws {
        let username = "integTest\(UUID().uuidString)"
        let password = "Pp123@\(UUID().uuidString)"
        let incorrectPassword = "WrongPassword123"

        try await signUp(username: username, password: password)

        do {
            let pluginOptions = AWSAuthSignInOptions(authFlowType: .userAuth(preferredFirstFactor: .password))
            _ = try await Amplify.Auth.signIn(
                username: username,
                password: incorrectPassword,
                options: .init(pluginOptions: pluginOptions))
            XCTFail("SignIn with an incorrect password should fail")
        } catch {
            // Expected failure
        }
    }

    /// Test signIn with PASSWORD as preferred factor with incorrect password fails and subsequent sign in with correct password succeeds
    ///
    /// - Given: A user registered in Cognito user pool
    /// - When:
    ///    - I invoke Amplify.Auth.signIn with the username and incorrect password, using userAuth flow with PASSWORD as the preferred factor
    ///    - Then I invoke Amplify.Auth.signIn with the username and correct password
    /// - Then:
    ///    - I should get a failed signIn flow for the first attempt and a completed signIn flow for the second attempt.
    func testSignInWithPasswordAsPreferred_givenInvalidPasswordThenValidPassword_expectFailedThenCompletedSignIn() async throws {
        let username = "integTest\(UUID().uuidString)"
        let password = "Pp123@\(UUID().uuidString)"
        let incorrectPassword = "WrongPassword123"

        try await signUp(username: username, password: password)

        do {
            let pluginOptions = AWSAuthSignInOptions(authFlowType: .userAuth(preferredFirstFactor: .password))
            _ = try await Amplify.Auth.signIn(
                username: username,
                password: incorrectPassword,
                options: .init(pluginOptions: pluginOptions))
            XCTFail("SignIn with an incorrect password should fail")
        } catch {
            // Expected failure
        }

        do {
            let pluginOptions = AWSAuthSignInOptions(authFlowType: .userAuth(preferredFirstFactor: .password))
            let signInResult = try await Amplify.Auth.signIn(
                username: username,
                password: password,
                options: .init(pluginOptions: pluginOptions))
            XCTAssertTrue(signInResult.isSignedIn, "SignIn should be complete")
        } catch {
            XCTFail("SignIn with a valid username/password should not fail \(error)")
        }
    }

    /// Test signIn with PASSWORD_SRP as preferred factor with incorrect password fails
    ///
    /// - Given: A user registered in Cognito user pool
    /// - When:
    ///    - I invoke Amplify.Auth.signIn with the username and incorrect password, using userAuth flow with PASSWORD_SRP as the preferred factor
    /// - Then:
    ///    - I should get a failed signIn flow.
    func testSignInWithPasswordSRPAsPreferred_givenInvalidPassword_expectFailedSignIn() async throws {
        let username = "integTest\(UUID().uuidString)"
        let password = "Pp123@\(UUID().uuidString)"
        let incorrectPassword = "WrongPassword123"

        try await signUp(username: username, password: password)

        do {
            let pluginOptions = AWSAuthSignInOptions(authFlowType: .userAuth(preferredFirstFactor: .passwordSRP))
            _ = try await Amplify.Auth.signIn(
                username: username,
                password: incorrectPassword,
                options: .init(pluginOptions: pluginOptions))
            XCTFail("SignIn with an incorrect password should fail")
        } catch {
            // Expected failure
        }
    }

    /// Test signIn with PASSWORD_SRP as preferred factor with incorrect password fails and subsequent sign in with correct password succeeds
    ///
    /// - Given: A user registered in Cognito user pool
    /// - When:
    ///    - I invoke Amplify.Auth.signIn with the username and incorrect password, using userAuth flow with PASSWORD_SRP as the preferred factor
    ///    - Then I invoke Amplify.Auth.signIn with the username and correct password
    /// - Then:
    ///    - I should get a failed signIn flow for the first attempt and a completed signIn flow for the second attempt.
    func testSignInWithPasswordSRPAsPreferred_givenInvalidPasswordThenValidPassword_expectFailedThenCompletedSignIn() async throws {
        let username = "integTest\(UUID().uuidString)"
        let password = "Pp123@\(UUID().uuidString)"
        let incorrectPassword = "WrongPassword123"

        try await signUp(username: username, password: password)

        do {
            let pluginOptions = AWSAuthSignInOptions(authFlowType: .userAuth(preferredFirstFactor: .passwordSRP))
            _ = try await Amplify.Auth.signIn(
                username: username,
                password: incorrectPassword,
                options: .init(pluginOptions: pluginOptions))
            XCTFail("SignIn with an incorrect password should fail")
        } catch {
            // Expected failure
        }

        do {
            let pluginOptions = AWSAuthSignInOptions(authFlowType: .userAuth(preferredFirstFactor: .passwordSRP))
            let signInResult = try await Amplify.Auth.signIn(
                username: username,
                password: password,
                options: .init(pluginOptions: pluginOptions))
            XCTAssertTrue(signInResult.isSignedIn, "SignIn should be complete")
        } catch {
            XCTFail("SignIn with a valid username/password should not fail \(error)")
        }
    }

    /// Test confirm EMAIL_OTP with correct code succeeds
    ///
    /// - Given: A user registered in Cognito user pool
    /// - When:
    ///    - I invoke Amplify.Auth.confirmSignIn with the correct OTP code for EMAIL_OTP
    /// - Then:
    ///    - I should get a completed signIn flow.
    func testConfirmEmailOTPWithCorrectCode_givenValidUser_expectCompletedSignIn() async throws {
        let username = "integTest\(UUID().uuidString)"
        let password = "Pp123@\(UUID().uuidString)"

        try await signUp(username: username, password: password)

        do {
            let pluginOptions = AWSAuthSignInOptions(authFlowType: .userAuth(preferredFirstFactor: .emailOTP))
            let signInResult = try await Amplify.Auth.signIn(
                username: username,
                options: .init(pluginOptions: pluginOptions))

            // Retrieve the OTP sent to the email and confirm the sign-in
            guard let otp = try await otp(for: username) else {
                XCTFail("Failed to retrieve the OTP code")
                return
            }

            guard case .confirmSignInWithOTP = signInResult.nextStep else {
                XCTFail("SignIn should return a .confirmSignInWithOTP")
                return
            }

            let confirmSignInResult = try await Amplify.Auth.confirmSignIn(
                challengeResponse: otp)

            XCTAssertTrue(confirmSignInResult.isSignedIn, "SignIn should be complete")
        } catch {
            XCTFail("SignIn with a valid username/password should not fail \(error)")
        }
    }

    /// Test confirm EMAIL_OTP with incorrect code fails
    ///
    /// - Given: A user registered in Cognito user pool
    /// - When:
    ///    - I invoke Amplify.Auth.confirmSignIn with an incorrect OTP code for EMAIL_OTP
    /// - Then:
    ///    - I should get a failed signIn flow.
    func testConfirmEmailOTPWithIncorrectCode_givenValidUser_expectFailedSignIn() async throws {
        let username = "integTest\(UUID().uuidString)"
        let password = "Pp123@\(UUID().uuidString)"

        try await signUp(username: username, password: password)

        do {
            let pluginOptions = AWSAuthSignInOptions(authFlowType: .userAuth(preferredFirstFactor: .emailOTP))
            let signInResult = try await Amplify.Auth.signIn(
                username: username,
                options: .init(pluginOptions: pluginOptions))

            guard case .confirmSignInWithOTP = signInResult.nextStep else {
                XCTFail("SignIn should return a .confirmSignInWithOTP")
                return
            }

            let incorrectOTP = "123456"
            _ = try await Amplify.Auth.confirmSignIn(
                challengeResponse: incorrectOTP)
            XCTFail("ConfirmSignIn with an incorrect OTP should fail")
        } catch {
            // Expected failure
        }
    }

    /// Test confirm EMAIL_OTP with incorrect code fails and subsequent confirm with correct code succeeds
    ///
    /// - Given: A user registered in Cognito user pool
    /// - When:
    ///    - I invoke Amplify.Auth.confirmSignIn with an incorrect OTP code for EMAIL_OTP
    ///    - Then I invoke Amplify.Auth.confirmSignIn with the correct OTP code
    /// - Then:
    ///    - I should get a failed signIn flow for the first attempt and a completed signIn flow for the second attempt.
    func testConfirmEmailOTPWithIncorrectCodeThenCorrectCode_givenValidUser_expectFailedThenCompletedSignIn() async throws {
        let username = "integTest\(UUID().uuidString)"
        let password = "Pp123@\(UUID().uuidString)"

        try await signUp(username: username, password: password)

        var otpString: String = ""

        do {
            let pluginOptions = AWSAuthSignInOptions(authFlowType: .userAuth(preferredFirstFactor: .emailOTP))
            let signInResult = try await Amplify.Auth.signIn(
                username: username,
                options: .init(pluginOptions: pluginOptions))

            // Retrieve the correct OTP sent to the email and confirm the sign-in
            guard let otp = try await otp(for: username) else {
                XCTFail("Failed to retrieve the OTP code")
                return
            }
            otpString = otp

            guard case .confirmSignInWithOTP = signInResult.nextStep else {
                XCTFail("SignIn should return a .confirmSignInWithOTP")
                return
            }

            let incorrectOTP = "123456"
            _ = try await Amplify.Auth.confirmSignIn(
                challengeResponse: incorrectOTP)
            XCTFail("ConfirmSignIn with an incorrect OTP should fail")
        } catch {
            // Expected failure
        }

        do {
            let confirmSignInResult = try await Amplify.Auth.confirmSignIn(
                challengeResponse: otpString)
            XCTAssertTrue(confirmSignInResult.isSignedIn, "SignIn should be complete")
        } catch {
            XCTFail("ConfirmSignIn with a valid OTP should not fail \(error)")
        }
    }

    /// Test confirm SMS_OTP with correct code succeeds
    ///
    /// - Given: A user registered in Cognito user pool
    /// - When:
    ///    - I invoke Amplify.Auth.confirmSignIn with the correct OTP code for SMS_OTP
    /// - Then:
    ///    - I should get a completed signIn flow.
    func testConfirmSMSOTPWithCorrectCode_givenValidUser_expectCompletedSignIn() async throws {
        let username = "integTest\(UUID().uuidString)"
        let password = "Pp123@\(UUID().uuidString)"

        try await signUp(username: username, password: password)

        do {
            let pluginOptions = AWSAuthSignInOptions(authFlowType: .userAuth(preferredFirstFactor: .smsOTP))
            let signInResult = try await Amplify.Auth.signIn(
                username: username,
                options: .init(pluginOptions: pluginOptions))

            // Retrieve the OTP sent to the phone and confirm the sign-in
            guard let otp = try await otp(for: username) else {
                XCTFail("Failed to retrieve the OTP code")
                return
            }

            guard case .confirmSignInWithOTP = signInResult.nextStep else {
                XCTFail("SignIn should return a .confirmSignInWithOTP")
                return
            }

            let confirmSignInResult = try await Amplify.Auth.confirmSignIn(
                challengeResponse: otp)

            XCTAssertTrue(confirmSignInResult.isSignedIn, "SignIn should be complete")
        } catch {
            XCTFail("SignIn with a valid username/password should not fail \(error)")
        }
    }

    /// Test confirm SMS OTP with incorrect code fails
    ///
    /// - Given: A user registered in Cognito user pool
    /// - When:
    ///    - I invoke Amplify.Auth.confirmSignIn with an incorrect SMS OTP code
    /// - Then:
    ///    - I should get a failed signIn flow.
    func testConfirmSMSOTPWithIncorrectCode_givenValidUser_expectFailedSignIn() async throws {
        let username = "integTest\(UUID().uuidString)"
        let password = "Pp123@\(UUID().uuidString)"

        try await signUp(username: username, password: password)

        do {
            let pluginOptions = AWSAuthSignInOptions(
                authFlowType: .userAuth(preferredFirstFactor: .smsOTP))
            let signInResult = try await Amplify.Auth.signIn(
                username: username,
                options: .init(pluginOptions: pluginOptions))

            guard case .confirmSignInWithOTP(let codeDeliverDetails) = signInResult.nextStep else {
                XCTFail("SignIn should return a .confirmSignInWithOTP")
                return
            }

            guard case .sms = codeDeliverDetails.destination else {
                XCTFail("destination should be sms")
                return
            }

            // Use an incorrect OTP code
            let incorrectOtp = "123456"

            _ = try await Amplify.Auth.confirmSignIn(
                challengeResponse: incorrectOtp)

            XCTFail("Should throw an invalid code error")
        } catch {
            guard case .service(_, _, let underlyingError) = error as? AuthError,
                  case .codeMismatch = underlyingError as? AWSCognitoAuthError else {
                XCTFail("Should throw a service error")
                return
            }
        }
    }

    /// Test confirm SMS OTP with incorrect code fails and subsequent confirm with correct code succeeds
    ///
    /// - Given: A user registered in Cognito user pool
    /// - When:
    ///    - I invoke Amplify.Auth.confirmSignIn with an incorrect SMS OTP code
    ///    - Then I invoke Amplify.Auth.confirmSignIn with the correct SMS OTP code
    /// - Then:
    ///    - I should get a completed signIn flow.
    func testConfirmSMSOTPWithIncorrectCodeThenCorrectCode_givenValidUser_expectCompletedSignIn() async throws {
        let username = "integTest\(UUID().uuidString)"
        let password = "Pp123@\(UUID().uuidString)"

        try await signUp(username: username, password: password)

        var otpString = ""

        do {
            let pluginOptions = AWSAuthSignInOptions(
                authFlowType: .userAuth(preferredFirstFactor: .smsOTP))
            let signInResult = try await Amplify.Auth.signIn(
                username: username,
                options: .init(pluginOptions: pluginOptions))

            // Retrieve the correct OTP sent to the email and confirm the sign-in
            guard let otp = try await otp(for: username) else {
                XCTFail("Failed to retrieve the OTP code")
                return
            }

            otpString = otp

            guard case .confirmSignInWithOTP(let codeDeliverDetails) = signInResult.nextStep else {
                XCTFail("SignIn should return a .confirmSignInWithOTP")
                return
            }

            guard case .sms = codeDeliverDetails.destination else {
                XCTFail("destination should be sms")
                return
            }

            // Use an incorrect OTP code
            let incorrectOtp = "123456"

            _ = try await Amplify.Auth.confirmSignIn(
                challengeResponse: incorrectOtp)

            XCTFail("Should throw an invalid code error")

        } catch {
            guard case .service(_, _, let underlyingError) = error as? AuthError,
                  case .codeMismatch = underlyingError as? AWSCognitoAuthError else {
                XCTFail("Should throw a service error")
                return
            }

            let confirmSignInResult = try await Amplify.Auth.confirmSignIn(
                challengeResponse: otpString)

            XCTAssertTrue(confirmSignInResult.isSignedIn, "SignIn should be complete with correct OTP")
        }
    }

}
