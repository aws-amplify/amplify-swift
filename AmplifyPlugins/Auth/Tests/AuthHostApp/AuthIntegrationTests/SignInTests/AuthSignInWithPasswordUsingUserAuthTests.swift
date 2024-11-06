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

class AuthSignInWithPasswordUsingUserAuthTests: AWSAuthBaseTest {

    override func setUp() async throws {
        // Use a custom configuration these tests
        amplifyConfigurationFile = "testconfiguration/AWSCognitoPluginPasswordlessIntegrationTests-amplifyconfiguration"

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

    /// Test successful signIn of a valid user
    ///
    /// - Given: A user registered in Cognito user pool
    /// - When:
    ///    - I invoke Amplify.Auth.signIn with the username and password, using userAuth flow by setting `password`as the preferred factor
    /// - Then:
    ///    - I should get a completed signIn flow.
    ///
    func testSuccessfulSignInWithPasswordAsPreferred() async throws {

        subscribeToOTPCreation()

        let username = "integTest\(UUID().uuidString)"
        let password = "Pp123@\(UUID().uuidString)"
        let result = try await AuthSignInHelper.signUpUserReturningResult(
            username: username,
            password: password,
            email: randomEmail)

        guard case .confirmUser = result.nextStep else {
            XCTFail("Incorrect next step for sign up confirmation")
            return
        }

        // Retrieve the OTP sent to the email and confirm the sign-in
        guard let otp = try await otp(for: username) else {
            XCTFail("Failed to retrieve the OTP code")
            return
        }

        let confirmSignUpResult = try await Amplify.Auth.confirmSignUp(
            for: username, confirmationCode: otp)

        guard confirmSignUpResult.isSignUpComplete else {
            XCTFail("Failed confirmation of sign up")
            return
        }

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
}
