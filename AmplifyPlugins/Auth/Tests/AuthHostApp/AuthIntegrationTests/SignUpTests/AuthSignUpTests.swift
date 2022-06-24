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

    override func setUp() {
        super.setUp()
        initializeAmplify()
        Amplify.Auth.signOut { _ in }
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
    func testSuccessfulRegisterUser() {
        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"
        let options = AuthSignUpRequest.Options(userAttributes: [
            AuthUserAttribute(.email, value: defaultTestEmail)])
        let operationExpectation = expectation(description: "Operation should complete")
        let operation = Amplify.Auth.signUp(username: username,
                                            password: password,
                                            options: options) { result in
            defer {
                operationExpectation.fulfill()
            }
            switch result {
            case .success(let signUpResult):
                XCTAssertTrue(signUpResult.isSignUpComplete, "Signup should be complete")
            case .failure(let error):
                XCTFail("SignUp a new user should not fail \(error)")
            }
        }
        XCTAssertNotNil(operation, "SignUp operations should not be nil")
        wait(for: [operationExpectation], timeout: networkTimeout)
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
    func testRegisterUserValidation() {
        let username = ""
        let password = "P123@\(UUID().uuidString)"

        let operationExpectation = expectation(description: "Operation should complete")
        let operation = Amplify.Auth.signUp(username: username, password: password) { result in
            defer {
                operationExpectation.fulfill()
            }
            switch result {
            case .success:
                XCTFail("SignUp with validation error should not succeed")
            case .failure(let error):
                guard case .validation = error else {
                    XCTFail("Should return validation error")
                    return
                }
            }
        }
        XCTAssertNotNil(operation, "SignUp operations should not be nil")
        wait(for: [operationExpectation], timeout: networkTimeout)
    }

    /// Test if registering an already existing user gives userexists error
    ///
    /// - Given: Already registered user
    /// - When:
    ///    - I signUp using the existing user
    /// - Then:
    ///    - I should get a user exists error
    ///
    func testRegisterExistingUser() {
        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"

        let firstSignUpOperation = expectation(description: "Operation should complete")
        AuthSignInHelper.signUpUser(username: username, password: password, email: defaultTestEmail) { success, error in
            XCTAssertTrue(success, "SignUp operation should succeed. But failed \(String(describing: error))")
            firstSignUpOperation.fulfill()
        }
        wait(for: [firstSignUpOperation], timeout: networkTimeout)

        let operationExpectation = expectation(description: "Operation should complete")
        let options = AuthSignUpRequest.Options(userAttributes: [AuthUserAttribute(.email, value: defaultTestEmail)])

        let operation = Amplify.Auth.signUp(username: username, password: password, options: options) { result in
            defer {
                operationExpectation.fulfill()
            }
            switch result {
            case .success:
                XCTFail("SignUp with an already registered user should not succeed")
            case .failure(let error):
                guard let cognitoError = error.underlyingError as? AWSCognitoAuthError,
                      case .usernameExists = cognitoError else {
                          XCTFail("Should return usernameExists")
                          return
                      }
            }
        }
        XCTAssertNotNil(operation, "SignUp operations should not be nil")
        wait(for: [operationExpectation], timeout: 50)
    }

    /// Calling cancel in signUp operation should cancel
    ///
    /// - Given: A valid username and password
    /// - When:
    ///    - I invoke signUp with the username password and then call cancel
    /// - Then:
    ///    - I should not get any result back
    ///
    func testCancelSignUpOperation() {
        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"

        let operationExpectation = expectation(description: "Operation should not complete")
        operationExpectation.isInverted = true
        let operation = Amplify.Auth.signUp(username: username, password: password) { result in
            XCTFail("Received result \(result)")
            operationExpectation.fulfill()
        }
        XCTAssertNotNil(operation, "SignUp operations should not be nil")
        operation.cancel()
        wait(for: [operationExpectation], timeout: networkTimeout)
    }
}
