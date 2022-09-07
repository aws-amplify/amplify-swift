//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
import AWSCognitoAuthPlugin

class AuthSignUpTests: AWSAuthBaseTest {

    override func setUp() async throws {
        try await super.setUp()
        initializeAmplify()
        _ = await Amplify.Auth.signOut()
    }

    override func tearDown() async throws {
        try await super.tearDown()
        await Amplify.reset()
        sleep(2)
    }

    /// Test if user registration is successful.
    ///
    /// - Given: A username that is not present in the system
    /// - When:
    ///    - I invoke Amplify.Auth.signUp with the username and a random password
    /// - Then:
    ///    - I should get a signup complete step.
    ///
    func testSuccessfulRegisterUser() async throws {
        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"
        let options = AuthSignUpRequest.Options(userAttributes: [
            AuthUserAttribute(.email, value: defaultTestEmail)])
        let signUpResult = try await Amplify.Auth.signUp(username: username,
                                            password: password,
                                            options: options)
        XCTAssertTrue(signUpResult.isSignUpComplete, "Signup should be complete")

    }

    //    /// Test if user registration is successful.
    //    /// Internally, Cognito's `SignUp` API will be called, and will trigger the Pre sign-up, Custom message, and Post
    //    /// confirmation lambdas with clientMetadata from the passed in metadata.
    //    /// See https://docs.aws.amazon.com/cognito-user-identity-pools/latest/APIReference/API_SignUp.html for more
    //    /// details.
    //    ///
    //    /// - Given: A username that is not present in the system
    //    /// - When:
    //    ///    - I invoke Amplify.Auth.signUp with the username, a random password and AWSAuthSignUpOptions containing
    //    ///    validation data and metadata
    //    /// - Then:
    //    ///    - I should get a signup complete step.
    //    ///    - Configured lambda triggers should have the validationData and clientMetadata.
    //    ///
    //    func testRegisterUserWithSignUpOptions() {
    //        let username = "integTest\(UUID().uuidString)"
    //        let password = "P123@\(UUID().uuidString)"
    //
    //        let operationExpectation = expectation(description: "Operation should complete")
    //        let awsAuthSignUpOptions = AWSAuthSignUpOptions(validationData: ["myValidationData": "myvalue"],
    //                                                        metadata: ["myClientMetadata": "myvalue"])
    //        let options = AuthSignUpOperation.Request.Options(userAttributes: [
    //            AuthUserAttribute(.email, value: defaultTestUsername)],
    //                                                          pluginOptions: awsAuthSignUpOptions)
    //        let operation = Amplify.Auth.signUp(username: username, password: password, options: options) { result in
    //            defer {
    //                operationExpectation.fulfill()
    //            }
    //            switch result {
    //            case .success(let signUpResult):
    //                XCTAssertTrue(signUpResult.isSignupComplete, "Signup should be complete")
    //            case .failure(let error):
    //                XCTFail("SignUp a new user should not fail \(error)")
    //            }
    //        }
    //        XCTAssertNotNil(operation, "SignUp operations should not be nil")
    //        wait(for: [operationExpectation], timeout: networkTimeout)
    //    }

    /// Test is signUp return validation error
    ///
    /// - Given: An invalid input to signUp like empty username
    /// - When:
    ///    - I invoke signUp with empty username
    /// - Then:
    ///    - I should get validation error.
    ///
    func testRegisterUserValidation() async throws {
        let username = ""
        let password = "P123@\(UUID().uuidString)"

        do {
            _ = try await Amplify.Auth.signUp(username: username, password: password)
            XCTFail("SignUp with validation error should not succeed")
        } catch {
            guard case AuthError.validation = error else {
                XCTFail("Should return validation error")
                return
            }
        }
    }

    /// Test if registering an already existing user gives userexists error
    ///
    /// - Given: Already registered user
    /// - When:
    ///    - I signUp using the existing user
    /// - Then:
    ///    - I should get a user exists error
    ///
    func testRegisterExistingUser()  async throws{
        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"

        let success = try await AuthSignInHelper.signUpUser(username: username, password: password, email: defaultTestEmail)
        XCTAssertTrue(success, "SignUp operation should succeed, but failed")

        let options = AuthSignUpRequest.Options(userAttributes: [AuthUserAttribute(.email, value: defaultTestEmail)])

        do {
            _ = try await Amplify.Auth.signUp(username: username, password: password, options: options)
            XCTFail("SignUp with an already registered user should not succeed")
        } catch {
            guard let authError = error as? AuthError, let cognitoError = authError.underlyingError as? AWSCognitoAuthError,
                  case .usernameExists = cognitoError else {
                      XCTFail("Should return usernameExists")
                      return
                  }
        }
    }
}
