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

class PasswordlessConfirmSignUpTests: AWSAuthBaseTest {

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
    }

    override func tearDown() async throws {
        try await super.tearDown()
        AuthSessionHelper.clearSession()
    }
    
    /// Test if confirmSignUp returns `.userNotFound` error for a non existing user
    ///
    /// - Given: A user which is not registered to the configured user pool
    /// - When:
    ///    - I invoke confirmSignUp with the user
    /// - Then:
    ///    - I should get a userNotFound error. (Gen1 - PreventUserExistenceErrors disabled)
    ///    - I should get a codeMismatch error. (Gen2 - PreventUserExistenceErrors enabled)
    /// (https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-pool-managing-errors.html#cognito-user-pool-managing-errors-password-reset)
    ///
    func testFailurePasswordlessConfirmSignUpUserNotFound() async throws {
        let username = "integTest\(UUID().uuidString)"
        do {
            let confirmSignUpResult = try await Amplify.Auth.confirmSignUp(
                for: username,
                confirmationCode: "123456",
                options: AuthConfirmSignUpRequest.Options()
            )
            XCTFail("Confirm sign up call should not succeed")
        } catch (let error) {
            XCTAssertNotNil(error)
            guard 
                let authError = error as? AuthError,
                let cognitoError = authError.underlyingError as? AWSCognitoAuthError else {
                XCTFail("Should return cognitoAuthError")
                return
            }

            switch cognitoError {
            case .userNotFound, .codeMismatch, .codeExpired:
                return
            default:
                XCTFail("Error should be either `.userNotFound` or `.codeMismatch` or `.codeExpired`")
            }
        }
    }
    
    /// Test if confirmSignUp returns validation error
    ///
    /// - Given: An invalid input to confirmSignUp like empty code
    /// - When:
    ///    - I invoke confirmSignUp with empty code
    /// - Then:
    ///    - I should get validation error.
    ///
    func testFailurePasswordlessConfirmSignUpEmptyCode() async throws {
        let username = "integTest\(UUID().uuidString)"
        do {
            _ = try await Amplify.Auth.confirmSignUp(
                for: username,
                confirmationCode: "",
                options: AuthConfirmSignUpRequest.Options())
            XCTFail("confirmSignUp with validation error should not succeed")
        } catch {
            guard case AuthError.validation = error else {
                XCTFail("Should return validation error")
                return
            }
        }
    }
    
    /// Test if confirmSignUp returns validation error
    ///
    /// - Given: An invalid input to confirmSignUp like empty username
    /// - When:
    ///    - I invoke confirmSignUp with empty username
    /// - Then:
    ///    - I should get validation error.
    ///
    func testFailurePasswordlessConfirmSignUpEmptyUsername() async throws {
        let username = ""
        do {
            _ = try await Amplify.Auth.confirmSignUp(
                for: username,
                confirmationCode: "123456",
                options: AuthConfirmSignUpRequest.Options())
            XCTFail("confirmSignUp with validation error should not succeed")
        } catch {
            guard case AuthError.validation = error else {
                XCTFail("Should return validation error")
                return
            }
        }
    }
    
    /// Test successful sign up and confirm sign up of a user
    ///
    /// - Given: A Cognito user pool configured with passwordless user auth
    /// - When:
    ///    - I invoke Amplify.Auth.signUp, Amplify.Auth.confirmSignUp with the username and email
    /// - Then:
    ///    - I should get a completed sign up flow
    ///
    func testSuccessfulPasswordlessSignUpAndConfirmSignUpEndtoEnd() async throws {

        await subscribeToOTPCreation()

        let username = "integTest\(UUID().uuidString)"
        let options = AuthSignUpRequest.Options(
            userAttributes: [ AuthUserAttribute(.email, value: randomEmail)])
        
        // sign up
        let signUpResult = try await Amplify.Auth.signUp(username: username, options: options)
        guard case .confirmUser = signUpResult.nextStep else {
            XCTFail("Incorrect next step for sign up confirmation")
            return
        }
        XCTAssertFalse(signUpResult.isSignUpComplete)

        // wait for otp
        guard let otp = try await otp(for: username) else {
            XCTFail("Failed to retrieve the OTP code")
            return
        }

        // confirm sign up
        let confirmSignUpResult = try await Amplify.Auth.confirmSignUp(
            for: username, 
            confirmationCode: otp,
            options: AuthConfirmSignUpRequest.Options())
        guard case .completeAutoSignIn(let session) = confirmSignUpResult.nextStep else {
            XCTFail("Result should be .done for next step")
            return
        }
        XCTAssertTrue(confirmSignUpResult.isSignUpComplete, "Confirm Sign up result should be complete")
        XCTAssertFalse(session.isEmpty)
    }
}
