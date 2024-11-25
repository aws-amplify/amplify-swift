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

class PasswordlessSignUpTests: AWSAuthBaseTest {

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
    
    /// Test if user registration is successful.
    ///
    /// - Given: A username that is not present in the system
    /// - When:
    ///    - I invoke Amplify.Auth.signUp with username and no password
    /// - Then:
    ///    - I should get a `.confirmUser` as the result next step.
    ///
    func testSuccessfulPasswordlessRegisterUser() async throws {
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
    }
    
    /// Test if multiple user registration is successful.
    ///
    /// - Given: Usernames that are not present in the system
    /// - When:
    ///    - I invoke Amplify.Auth.signUp with username and no password, multiple times
    /// - Then:
    ///    - I should get a `.confirmUser` as the result next step for each attempt
    ///
    func testSuccessfulMultiplePasswordlessSignUps() async throws {

        let signUpExpectation = expectation(description: "Next step should be .confirmUser")
        signUpExpectation.expectedFulfillmentCount = 2

        for _ in 0..<signUpExpectation.expectedFulfillmentCount {

            Task {
                do {
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
                } catch {
                    XCTFail("Failed to sign up user: \(error)")
                }
                signUpExpectation.fulfill()
            }
        }
        await fulfillment(of: [signUpExpectation], timeout: 5, enforceOrder: false)
    }
    
    /// Test for failure when invalid username is given
    ///
    /// - Given: An invalid input to signUp like empty username
    /// - When:
    ///    - I invoke signUp with empty username and no password
    /// - Then:
    ///    - I should get validation error.
    ///
    func testFailureRegisterUserEmptyUsername() async throws {
        let username = ""
        let options = AuthSignUpRequest.Options(
            userAttributes: [ AuthUserAttribute(.email, value: randomEmail)])
        
        // sign up
        do {
            let _ = try await Amplify.Auth.signUp(username: username, options: options)
            XCTFail("Sign up should not be successfult")
        } catch (let error) {
            XCTAssertNotNil(error)
            guard case AuthError.validation = error else {
                XCTFail("Should return validation error")
                return
            }
        }
    }
    
    /// Test if registering an already existing user gives `.usernameExists` error
    ///
    /// - Given: An already registered user
    /// - When:
    ///    - I call Amplify.Auth.signUp using the existing username
    /// - Then:
    ///    - I should get a `.usernameExists`
    ///
    func testFailureRegisterExistingUser()  async throws {
        let username = "integTest\(UUID().uuidString)"
        let options = AuthSignUpRequest.Options(
            userAttributes: [ AuthUserAttribute(.email, value: randomEmail)])
        
        // sign up
        let signUpResult = try await Amplify.Auth.signUp(username: username, options: options)
        guard case .confirmUser = signUpResult.nextStep else {
            XCTFail("Incorrect next step for sign up confirmation")
            return
        }

        // sign up again
        do {
            let _ = try await Amplify.Auth.signUp(username: username, options: options)
            XCTFail("SignUp with an already registered user should not succeed")
        } catch {
            guard 
                let authError = error as? AuthError,
                let cognitoError = authError.underlyingError as? AWSCognitoAuthError,
                case .usernameExists = cognitoError else {
                XCTFail("Should return .usernameExists")
                return
            }
        }
    }
}
