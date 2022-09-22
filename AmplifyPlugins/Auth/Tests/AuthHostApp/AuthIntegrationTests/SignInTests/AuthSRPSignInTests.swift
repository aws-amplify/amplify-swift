//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
import AWSCognitoAuthPlugin

class AuthSRPSignInTests: AWSAuthBaseTest {

    override func setUp() async throws {
        try await super.setUp()
        AuthSessionHelper.clearSession()
    }

    override func tearDown() async throws {
        try await super.tearDown()
        AuthSessionHelper.clearSession()
    }

    /// Test successful signIn of a valid user
    ///
    /// - Given: A user registered in Cognito user pool
    /// - When:
    ///    - I invoke Amplify.Auth.signIn with the username and password
    /// - Then:
    ///    - I should get a completed signIn flow.
    ///
    func testSuccessfulSignIn() async throws {

        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"

        let didSucceed = try await AuthSignInHelper.signUpUser(username: username,
                                    password: password,
                                    email: defaultTestEmail)
        XCTAssertTrue(didSucceed, "Signup operation failed")
        do {
            let signInResult = try await Amplify.Auth.signIn(username: username, password: password)
            XCTAssertTrue(signInResult.isSignedIn, "SignIn should be complete")
        } catch {
            XCTFail("SignIn with a valid username/password should not fail \(error)")
        }
    }

    /// Test successful signIn of a valid user with invalid password
    ///
    /// - Given: A user registered in Cognito user pool
    /// - When:
    ///    - I invoke Amplify.Auth.signIn with the username and password
    /// - Then:
    ///    - I should get a completed signIn flow.
    ///
    func testSignInWithWrongPassword() async throws {

        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"

        let didSucceed = try await AuthSignInHelper.signUpUser(username: username,
                                    password: password,
                                    email: defaultTestEmail)
        XCTAssertTrue(didSucceed, "Signup operation failed")

        do {
            _ = try await Amplify.Auth.signIn(username: username, password: "password")
            XCTFail("SignIn with an invalid username/password should fail")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    /// Test signIn with empty username password
    ///
    /// - Given: A configured auth plugin
    /// - When:
    ///    - I invoke Amplify.Auth.signIn with empty username and password twice
    /// - Then:
    ///    - I should get a invalid error one each api call
    ///
    func testSignInFailWithEmptyUsername() async {

        let username = ""
        let password = ""

        do {
            _ = try await Amplify.Auth.signIn(username: username, password: password)
            XCTFail("SignIn with a empty username/password should fail")
        } catch {
            guard case AuthError.validation = error else {
                XCTFail("Should throw validation error")
                return
            }
        }

        // Test once more to verify that the state machine recovered from the previous error
        do {
            _ = try await Amplify.Auth.signIn(username: username, password: password)
            XCTFail("SignIn with a empty username/password should fail")
        } catch {
            guard case AuthError.validation = error else {
                XCTFail("Should throw validation error")
                return
            }
        }
    }

    /// Test successful signIn of a valid user
    /// Internally, Two Cognito APIs will be called, Cognito's `InitiateAuth` and `RespondToAuthChallenge` API.
    ///
    /// `InitiateAuth` will trigger the Pre signup, Pre authentication, and User migration lambdas. Passed in metadata
    /// will be used as client metadata to Cognito's API, and passed to the the lambda as validationData.
    /// See https://docs.aws.amazon.com/cognito-user-identity-pools/latest/APIReference/API_InitiateAuth.html for more
    /// details.
    ///
    /// `RespondToAuthChallenge` will trigger the Post authentication, Pre token generation, Define auth challenge,
    /// Create auth challenge, and Verify auth challenge lambdas. Passed in metadata will be used as client metadata to
    /// Cognito's API, and passed to the lambda as clientMetadata.
    /// See https://docs.aws.amazon.com/cognito-user-identity-pools/latest/APIReference/API_RespondToAuthChallenge.html
    /// for more details
    ///
    /// - Given: A user registered in Cognito user pool
    /// - When:
    ///    - I invoke Amplify.Auth.signIn with the username, password and AWSAuthSignInOptions
    /// - Then:
    ///    - I should get a completed signIn flow.
    ///
    func testSignInWithSignInOptions() async throws {

        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"

        let didSucceed = try await AuthSignInHelper.signUpUser(username: username, password: password,
                                    email: defaultTestEmail)
        XCTAssertTrue(didSucceed, "Signup operation failed")

        let awsAuthSignInOptions = AWSAuthSignInOptions(metadata: ["mySignInData": "myvalue"])
        let options = AuthSignInRequest.Options(pluginOptions: awsAuthSignInOptions)
        do {
            let signInResult = try await Amplify.Auth.signIn(username: username, password: password, options: options)
            XCTAssertTrue(signInResult.isSignedIn, "SignIn should be complete")
        } catch {
            XCTFail("SignIn with a valid username/password should not fail \(error)")
        }
    }

    /// Test if user not found error is returned for signIn with unknown user
    ///
    /// - Given: Amplify Auth plugin in signedout state
    /// - When:
    ///    - I try to signIn with an unknown user
    /// - Then:
    ///    - I should get a user not found error
    ///
    func testSignInWithInvalidUser() async {
        do {
            _ = try await Amplify.Auth.signIn(username: "username-doesnot-exist", password: "password")
            XCTFail("SignIn with unknown user should not succeed")
        } catch {
            guard let authError = error as? AuthError, let cognitoError = authError.underlyingError as? AWSCognitoAuthError,
                  case .userNotFound = cognitoError
            else {
                      XCTFail("Should return userNotFound error")
                      return
                  }
        }
    }

    /// Test if signIn to an already signedIn session returns error
    ///
    /// - Given: Amplify Auth plugin in signedIn state
    /// - When:
    ///    - I try to signIn again
    /// - Then:
    ///    - I should get a invalid state error
    ///
    func testSignInWhenAlreadySignedIn() async throws {
        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"

        let didSucceed = try await AuthSignInHelper.registerAndSignInUser(username: username, password: password,
                                               email: defaultTestEmail)
        XCTAssertTrue(didSucceed, "SignIn operation failed")

        do {
            _ = try await AuthSignInHelper.signInUser(username: username, password: password)
            XCTFail("Second signIn should fail")
        } catch {
            guard case AuthError.invalidState = error else {
                XCTFail("Should return invalid state \(String(describing: error))")
                return
            }
        }
    }

    /// Test if signIn return validation error
    ///
    /// - Given: An invalid input to signIn like empty username
    /// - When:
    ///    - I invoke signIn with empty username
    /// - Then:
    ///    - I should get validation error.
    ///
    func testSignInValidation() async {
        do {
            _ = try await Amplify.Auth.signIn(username: "", password: "password")
            XCTFail("SignIn with empty user should not succeed")
        } catch {
            guard case AuthError.validation = error else {
                XCTFail("Should return validation error")
                return
            }
        }
    }

    ///  Test  signIn for a user created by admin with temporary password
    ///  The workflow will return a next step confirmSignInWithNewPassword, which should then work with confirm sign in
    ///
    /// - Given: A user created by admin with temporary password  in Cognito user pool
    /// - When:
    ///    - I invoke Amplify.Auth.signIn
    /// - Then:
    ///    - I should get next step as confirmSignInWithNewPassword
    ///   Then:
    ///      I should call Amplify.Auth.confirm signIn with the new password and required attributes,
    ///      which should succeed with next step as done
    ///
    /// - SETUP
    ///         Create new user in Cognito, only specify username and password, which should entered below in the test.
    ///         Make sure that you do not enter email and phone number, so that adding a new attribute could also be tested
    ///
    ///   DISABLED TEST, because it needs special setup
    func testNewPasswordRequired() async {

        let username = "YOUR USERNAME CREATED IN COGNITO FOR TESTING TEMP PASSWORD FLOW"
        let tempPassword = "YOUR TEMP PASSWORD THAT WAS SET"
        let newPassword = "@mplifyI$Awesom3"

        let operationExpectation = expectation(description: "Operation should complete")

        do {
            let result = try await Amplify.Auth.signIn(username: username, password: tempPassword, options: .none)
            if case .confirmSignInWithNewPassword = result.nextStep {
                operationExpectation.fulfill()
            }
        } catch {
            XCTFail("SignIn with invalid auth flow should not succeed: \(error)")
        }

        wait(for: [operationExpectation], timeout: networkTimeout)

        let confirmOperationExpectation = expectation(description: "Confirm new password should succeed")
        do {
            let result = try await Amplify.Auth.confirmSignIn(
                challengeResponse: newPassword,
                options: .init(
                    userAttributes: [
                        AuthUserAttribute(.email, value: defaultTestEmail)
                    ]))
            if case .done = result.nextStep {
                confirmOperationExpectation.fulfill()
            }
        } catch {
            XCTFail("Failed to confirm new password with error: \(error)")
        }

        wait(for: [confirmOperationExpectation], timeout: networkTimeout)

    }

}
