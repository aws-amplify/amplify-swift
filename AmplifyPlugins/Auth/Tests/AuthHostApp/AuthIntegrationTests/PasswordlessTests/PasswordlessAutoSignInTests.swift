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

class PasswordlessAutoSignInTests: AWSAuthBaseTest {

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
    
    /// Test for failure when auto sign in is done without sign up
    ///
    /// - Given: An initialized Amplify backend with auth plugin in `.signedOut` state
    /// - When:
    ///    - I invoke Amplify.Auth.autoSignIn
    /// - Then:
    ///    - I should get an `.invalidState` error
    ///
    func testFailureAutoSignInWithoutSignUp() async throws {
        // auto sign in
        do {
            let _ = try await Amplify.Auth.autoSignIn()
            XCTFail("Auto sign in should not succeed")
        } catch (let error) {
            XCTAssertNotNil(error)
            guard case AuthError.invalidState = error else {
                XCTFail("Should return invalidState error")
                return
            }
        }
    }
    
    /// Test successful sign up, confirm sign up and auto sign of a user
    ///
    /// - Given: A Cognito user pool configured with passwordless user auth
    /// - When:
    ///    - I invoke Amplify.Auth.signUp, Amplify.Auth.confirmSignUp with the username and email
    ///    followed by Amplify.Auth.autoSignIn
    /// - Then:
    ///    - I should get a completed sign in flow
    ///
    func testSuccessfulPasswordlessSignUpAndAutoSignInEndtoEnd() async throws {

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
            for: username, confirmationCode: otp)
        guard case .completeAutoSignIn(let session) = confirmSignUpResult.nextStep else {
            XCTFail("Result should be .done for next step")
            return
        }
        XCTAssertTrue(confirmSignUpResult.isSignUpComplete, "Confirm Sign up result should be complete")
        XCTAssertFalse(session.isEmpty)

        // auto sign in
        let autoSignInResult = try await Amplify.Auth.autoSignIn()
        guard case .done = autoSignInResult.nextStep else {
            XCTFail("Result should be .done for next step")
            return
        }
        XCTAssertTrue(autoSignInResult.isSignedIn, "Signin result should be complete")
    }
    
    /// Test for failure when auto sign in is invoked multiple times
    ///
    /// - Given: An initialized Amplify backend with auth plugin in `.signedOut` state
    /// - When:
    ///    - I invoke Amplify.Auth.autoSignIn with a cached auto sign in session
    /// - Then:
    ///    - I should get a `.notAuthorized` error
    ///
    func testFailureMultipleAutoSignInWithSameSession() async throws {
        
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
            for: username, confirmationCode: otp)
        guard case .completeAutoSignIn(let session) = confirmSignUpResult.nextStep else {
            XCTFail("Result should be .done for next step")
            return
        }
        XCTAssertTrue(confirmSignUpResult.isSignUpComplete, "Confirm Sign up result should be complete")
        XCTAssertFalse(session.isEmpty)

        // auto sign in
        let autoSignInResult = try await Amplify.Auth.autoSignIn()
        guard case .done = autoSignInResult.nextStep else {
            XCTFail("Result should be .done for next step")
            return
        }
        XCTAssertTrue(autoSignInResult.isSignedIn, "Signin result should be complete")
        
        // sign out
        let _ = await Amplify.Auth.signOut(options: .init(globalSignOut: true))
        
        // auto sign in again using the same session
        do {
            let _ = try await Amplify.Auth.autoSignIn()
            XCTFail("Multiple auto sign in with same session should not succeed")
        } catch (let error) {
            XCTAssertNotNil(error)
            guard case AuthError.notAuthorized = error else {
                XCTFail("Should return .notAuthorized error")
                return
            }
        }
        
    }
}
