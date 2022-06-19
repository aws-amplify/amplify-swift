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

    override func setUp() {
        super.setUp()
        initializeAmplify()
        AuthSessionHelper.clearSession()
    }

    override func tearDown() {
        super.tearDown()
        await Amplify.reset()
        AuthSessionHelper.clearSession()
        sleep(2)
    }

    /// Test successful signIn of a valid user
    ///
    /// - Given: A user registered in Cognito user pool
    /// - When:
    ///    - I invoke Amplify.Auth.signIn with the username and password
    /// - Then:
    ///    - I should get a completed signIn flow.
    ///
    func testSuccessfulSignIn() {

        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"

        let signUpExpectation = expectation(description: "SignUp operation should complete")
        AuthSignInHelper.signUpUser(username: username,
                                    password: password,
                                    email: defaultTestEmail) { didSucceed, error in
            signUpExpectation.fulfill()
            XCTAssertTrue(didSucceed, "Signup operation failed - \(String(describing: error))")
        }
        wait(for: [signUpExpectation], timeout: networkTimeout)

        let operationExpectation = expectation(description: "Operation should complete")
        let operation = Amplify.Auth.signIn(username: username, password: password) { result in
            defer {
                operationExpectation.fulfill()
            }
            switch result {
            case .success(let signInResult):
                XCTAssertTrue(signInResult.isSignedIn, "SignIn should be complete")
            case .failure(let error):
                XCTFail("SignIn with a valid username/password should not fail \(error)")
            }
        }
        XCTAssertNotNil(operation, "SignIn operation should not be nil")
        wait(for: [operationExpectation], timeout: networkTimeout)
    }

    /// Test signIn with empty username password
    ///
    /// - Given: A configured auth plugin
    /// - When:
    ///    - I invoke Amplify.Auth.signIn with empty username and password twice
    /// - Then:
    ///    - I should get a invalid error one each api call
    ///
    func testSignInFailWithEmptyUsername() {

        let username = ""
        let password = ""

        let operationExpectation1 = expectation(description: "Operation should complete")
        let operation1 = Amplify.Auth.signIn(username: username, password: password) { result in
            defer {
                operationExpectation1.fulfill()
            }
            switch result {
            case .success:
                XCTFail("SignIn with a empty username/password should fail")
            case .failure(let error):
                guard case .validation = error else {
                    XCTFail("Should throw validation error")
                    return
                }

            }
        }
        XCTAssertNotNil(operation1, "SignIn operation should not be nil")
        wait(for: [operationExpectation1], timeout: networkTimeout)

        // Test once more to verify that the state machine recovered from the previous error
        let operationExpectation2 = expectation(description: "Operation should complete")
        let operation2 = Amplify.Auth.signIn(username: username, password: password) { result in
            defer {
                operationExpectation2.fulfill()
            }
            switch result {
            case .success:
                XCTFail("SignIn with a empty username/password should fail")
            case .failure(let error):
                guard case .validation = error else {
                    XCTFail("Should throw validation error instead got: \(error)")
                    return
                }

            }
        }
        XCTAssertNotNil(operation2, "SignIn operation should not be nil")
        wait(for: [operationExpectation2], timeout: networkTimeout)
    }

    //
    //    /// Test successful signIn of a valid user
    //    /// Internally, Two Cognito APIs will be called, Cognito's `InitiateAuth` and `RespondToAuthChallenge` API.
    //    ///
    //    /// `InitiateAuth` will trigger the Pre signup, Pre authentication, and User migration lambdas. Passed in metadata
    //    /// will be used as client metadata to Cognito's API, and passed to the the lambda as validationData.
    //    /// See https://docs.aws.amazon.com/cognito-user-identity-pools/latest/APIReference/API_InitiateAuth.html for more
    //    /// details.
    //    ///
    //    /// `RespondToAuthChallenge` will trigger the Post authentication, Pre token generation, Define auth challenge,
    //    /// Create auth challenge, and Verify auth challenge lambdas. Passed in metadata will be used as client metadata to
    //    /// Cognito's API, and passed to the lambda as clientMetadata.
    //    /// See https://docs.aws.amazon.com/cognito-user-identity-pools/latest/APIReference/API_RespondToAuthChallenge.html
    //    /// for more details
    //    ///
    //    /// - Given: A user registered in Cognito user pool
    //    /// - When:
    //    ///    - I invoke Amplify.Auth.signIn with the username, password and AWSAuthSignInOptions
    //    /// - Then:
    //    ///    - I should get a completed signIn flow.
    //    ///
    //    func testSignInWithSignInOptions() {
    //
    //        let username = "integTest\(UUID().uuidString)"
    //        let password = "P123@\(UUID().uuidString)"
    //
    //        let signUpExpectation = expectation(description: "SignUp operation should complete")
    //        AuthSignInHelper.signUpUser(username: username, password: password,
    //                                    email: email) { didSucceed, error in
    //            signUpExpectation.fulfill()
    //            XCTAssertTrue(didSucceed, "Signup operation failed - \(String(describing: error))")
    //        }
    //        wait(for: [signUpExpectation], timeout: networkTimeout)
    //
    //        let operationExpectation = expectation(description: "Operation should complete")
    //        let awsAuthSignInOptions = AWSAuthSignInOptions(metadata: ["mySignInData": "myvalue"])
    //        let options = AuthSignInOperation.Request.Options(pluginOptions: awsAuthSignInOptions)
    //        let operation = Amplify.Auth.signIn(username: username, password: password, options: options) { result in
    //            defer {
    //                operationExpectation.fulfill()
    //            }
    //            switch result {
    //            case .success(let signInResult):
    //                XCTAssertTrue(signInResult.isSignedIn, "SignIn should be complete")
    //            case .failure(let error):
    //                XCTFail("SignIn with a valid username/password should not fail \(error)")
    //            }
    //        }
    //        XCTAssertNotNil(operation, "SignIn operation should not be nil")
    //        wait(for: [operationExpectation], timeout: networkTimeout)
    //    }
    //

    /// Test if user not found error is returned for signIn with unknown user
    ///
    /// - Given: Amplify Auth plugin in signedout state
    /// - When:
    ///    - I try to signIn with an unknown user
    /// - Then:
    ///    - I should get a user not found error
    ///
    func testSignInWithInvalidUser() {
        let operationExpectation = expectation(description: "Operation should complete")
        let operation = Amplify.Auth.signIn(username: "username-doesnot-exist", password: "password") { result in
            defer {
                operationExpectation.fulfill()
            }
            switch result {
            case .success:
                XCTFail("SignIn with unknown user should not succeed")
            case .failure(let error):
                guard let cognitoError = error.underlyingError as? AWSCognitoAuthError,
                      case .userNotFound = cognitoError
                else {
                          XCTFail("Should return userNotFound error")
                          return
                      }
            }
        }
        XCTAssertNotNil(operation, "SignIn operation should not be nil")
        wait(for: [operationExpectation], timeout: networkTimeout)
    }

    //
    //    /// Test if signIn to an already signedIn session returns error
    //    ///
    //    /// - Given: Amplify Auth plugin in signedIn state
    //    /// - When:
    //    ///    - I try to signIn again
    //    /// - Then:
    //    ///    - I should get a invalid state error
    //    ///
    //    func testSignInWhenAlreadySignedIn() {
    //        let username = "integTest\(UUID().uuidString)"
    //        let password = "P123@\(UUID().uuidString)"
    //
    //        let firstSignInExpectation = expectation(description: "SignIn operation should complete")
    //        AuthSignInHelper.registerAndSignInUser(username: username, password: password,
    //                                               email: email) { didSucceed, error in
    //            firstSignInExpectation.fulfill()
    //            XCTAssertTrue(didSucceed, "SignIn operation failed - \(String(describing: error))")
    //        }
    //        wait(for: [firstSignInExpectation], timeout: networkTimeout)
    //
    //        let secondSignInExpectation = expectation(description: "SignIn operation should complete")
    //        AuthSignInHelper.signInUser(username: username, password: password) { didSucceed, error in
    //            defer {
    //                secondSignInExpectation.fulfill()
    //            }
    //            XCTAssertFalse(didSucceed, "Second signIn should fail")
    //            guard case .invalidState = error else {
    //                XCTFail("Should return invalid state \(String(describing: error))")
    //                return
    //            }
    //
    //        }
    //        wait(for: [secondSignInExpectation], timeout: networkTimeout)
    //    }
    //

    /// Test if signIn return validation error
    ///
    /// - Given: An invalid input to signIn like empty username
    /// - When:
    ///    - I invoke signIn with empty username
    /// - Then:
    ///    - I should get validation error.
    ///
    func testSignInValidation() {
        let operationExpectation = expectation(description: "Operation should complete")
        let operation = Amplify.Auth.signIn(username: "", password: "password") { result in
            defer {
                operationExpectation.fulfill()
            }
            switch result {
            case .success:
                XCTFail("SignIn with empty user should not succeed")
            case .failure(let error):
                guard case .validation = error else {
                    XCTFail("Should return validation error")
                    return
                }
            }
        }
        XCTAssertNotNil(operation, "SignIn operation should not be nil")
        wait(for: [operationExpectation], timeout: networkTimeout)
    }

    //
    //    /// Calling cancel in signIn operation should cancel
    //    ///
    //    /// - Given: A valid username and password
    //    /// - When:
    //    ///    - I invoke signIn with the username password and then call cancel
    //    /// - Then:
    //    ///    - I should not get any result back
    //    ///
    //    func testCancelSignInOperation() {
    //        let username = "integTest\(UUID().uuidString)"
    //        let password = "P123@\(UUID().uuidString)"
    //        let operationExpectation = expectation(description: "Operation should not complete")
    //        operationExpectation.isInverted = true
    //        let operation = Amplify.Auth.signIn(username: username, password: password) { result in
    //            XCTFail("Received result \(result)")
    //            operationExpectation.fulfill()
    //        }
    //        XCTAssertNotNil(operation, "signIn operations should not be nil")
    //        operation.cancel()
    //        wait(for: [operationExpectation], timeout: networkTimeout)
    //    }

}
