//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoAuthPlugin
import XCTest
@testable import Amplify

class AuthCustomSignInTests: AWSAuthBaseTest, @unchecked Sendable {

    override func setUp() async throws {
        try await super.setUp()
        AuthSessionHelper.clearSession()
    }

    override func tearDown() async throws {
        try await super.tearDown()
        AuthSessionHelper.clearSession()
    }

    /// Test  signIn with authflowtype as customAuthSRP
    ///
    /// - Given: A user registered in Cognito user pool
    /// - When:
    ///    - I invoke Amplify.Auth.signIn with a authflow not configured in user pool
    /// - Then:
    ///    - I should get a completed signIn flow
    ///
    /// - SETUP
    ///    For this test to work, cognito should be setup with custom auth lambda triggers
    ///    https://docs.amplify.aws/sdk/auth/custom-auth-flow/q/platform/ios/
    ///    https://docs.aws.amazon.com/cognito/latest/developerguide/user-pool-lambda-define-auth-challenge.html
    ///
    ///    Define Auth Challenge lambda trigger should look something like this
    ///
    ///     if (event.request.session.length == 1 && event.request.session[0].challengeName == 'SRP_A') {
    ///         event.response.issueTokens = false;
    ///         event.response.failAuthentication = false;
    ///         event.response.challengeName = 'PASSWORD_VERIFIER';
    ///     } else if (event.request.session.length == 2 && event.request.session[1].challengeName == 'PASSWORD_VERIFIER' && event.request.session[1].challengeResult == true) {
    ///         event.response.issueTokens = false;
    ///         event.response.failAuthentication = false;
    ///         event.response.challengeName = 'CUSTOM_CHALLENGE';
    ///     } else if (event.request.session.length == 3 && event.request.session[2].challengeName == 'CUSTOM_CHALLENGE' && event.request.session[2].challengeResult == true) {
    ///         event.response.issueTokens = true;
    ///         event.response.failAuthentication = false;
    ///     } else {
    ///         event.response.issueTokens = false;
    ///         event.response.failAuthentication = true;
    ///     }
    ///
    func testSuccessfulSignInWithCustomAuthSRP() async throws {
        let answer = try requireCustomChallengeAnswer()

        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"

        let isSignedUp = try await AuthSignInHelper.signUpUser(
            username: username,
            password: password,
            email: defaultTestEmail
        )
        XCTAssertTrue(isSignedUp)

        var confirmationCodeForValidation = ""
        let option = AWSAuthSignInOptions(authFlowType: .customWithSRP)
        do {
            let result = try await Amplify.Auth.signIn(username: username, password: password, options: AuthSignInRequest.Options(pluginOptions: option))
            if case .confirmSignInWithCustomChallenge = result.nextStep {
                confirmationCodeForValidation = answer
            } else {
                XCTFail("Expected a custom challenge, got \(result.nextStep)")
            }
        } catch {
            XCTFail("SignIn with invalid auth flow should not succeed")
        }

        do {
            let confirmSignInResult = try await Amplify.Auth.confirmSignIn(challengeResponse: confirmationCodeForValidation)
            XCTAssertTrue(confirmSignInResult.isSignedIn)
        } catch {
            XCTFail("Sign In confirmation failed")
        }
    }

    /// Test  signIn with different flow type in the same session
    ///
    /// - Given: A user registered in Cognito user pool
    /// - When:
    ///    - I invoke Amplify.Auth.signIn with a authflow as customAuthSRP
    ///    - I invoke sign out to clear previous sign in
    ///    - I invoke Amplify.Auth.signIn with a authflow as userSRP
    /// - Then:
    ///    - I should get a completed signIn flow without any errors
    ///
    /// - SETUP
    ///    For this test to work, cognito should be setup with custom auth lambda triggers
    ///    https://docs.amplify.aws/sdk/auth/custom-auth-flow/q/platform/ios/
    ///    https://docs.aws.amazon.com/cognito/latest/developerguide/user-pool-lambda-define-auth-challenge.html
    ///
    ///    Define Auth Challenge lambda trigger should look something like this
    ///
    ///     if (event.request.session.length == 1 && event.request.session[0].challengeName == 'SRP_A') {
    ///         event.response.issueTokens = false;
    ///         event.response.failAuthentication = false;
    ///         event.response.challengeName = 'PASSWORD_VERIFIER';
    ///     } else if (event.request.session.length == 2 && event.request.session[1].challengeName == 'PASSWORD_VERIFIER' && event.request.session[1].challengeResult == true) {
    ///         event.response.issueTokens = false;
    ///         event.response.failAuthentication = false;
    ///         event.response.challengeName = 'CUSTOM_CHALLENGE';
    ///     } else if (event.request.session.length == 3 && event.request.session[2].challengeName == 'CUSTOM_CHALLENGE' && event.request.session[2].challengeResult == true) {
    ///         event.response.issueTokens = true;
    ///         event.response.failAuthentication = false;
    ///     } else {
    ///         event.response.issueTokens = false;
    ///         event.response.failAuthentication = true;
    ///     }
    ///
    func testRuntimeAuthFlowSwitch() async throws {
        let answer = try requireCustomChallengeAnswer()

        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"

        let isSignedUp = try await AuthSignInHelper.signUpUser(
            username: username,
            password: password,
            email: defaultTestEmail
        )
        XCTAssertTrue(isSignedUp)

        let option = AWSAuthSignInOptions(authFlowType: .customWithSRP)
        do {
            let signInResult = try await Amplify.Auth.signIn(
                username: username,
                password: password,
                options: AuthSignInRequest.Options(pluginOptions: option)
            )
            // The backend's define-auth-challenge trigger adds a CUSTOM_CHALLENGE after the password.
            guard case .confirmSignInWithCustomChallenge = signInResult.nextStep else {
                XCTFail("Expected a custom challenge after the password, got \(signInResult.nextStep)")
                return
            }
            let confirmResult = try await Amplify.Auth.confirmSignIn(challengeResponse: answer)
            XCTAssertTrue(confirmResult.isSignedIn, "SignIn should be complete")
        } catch {
            XCTFail("Should successfully login: \(error)")
        }

        _ = await Amplify.Auth.signOut()

        let srpOption = AWSAuthSignInOptions(authFlowType: .userSRP)
        do {
            let signInResult = try await Amplify.Auth.signIn(
                username: username,
                password: password,
                options: AuthSignInRequest.Options(pluginOptions: srpOption)
            )
            XCTAssertTrue(signInResult.isSignedIn, "SignIn should be complete")
        } catch {
            XCTFail("SignIn with a valid username/password should not fail \(error)")
        }
    }

    /// Test  signIn with authflowtype as customAuth
    ///
    /// - Given: A user registered in Cognito user pool
    /// - When:
    ///    - I invoke Amplify.Auth.signIn with a authflow customAuth
    /// - Then:
    ///    - I should get a completed signIn flow
    ///
    /// - SETUP
    ///    For this test to work, cognito should be setup with custom auth lambda triggers
    ///    https://docs.amplify.aws/sdk/auth/custom-auth-flow/q/platform/ios/
    ///    https://docs.aws.amazon.com/cognito/latest/developerguide/user-pool-lambda-define-auth-challenge.html
    ///
    ///    Define Auth Challenge lambda trigger should look something like this
    ///    exports.handler = async event => {
    ///
    ///        if (event.request.session.length === 0) {
    ///            event.response.issueTokens = false;
    ///            event.response.failAuthentication = false;
    ///            event.response.challengeName = 'CUSTOM_CHALLENGE';
    ///        } else if (
    ///            event.request.session.length === 1 &&
    ///            event.request.session[0].challengeName === 'CUSTOM_CHALLENGE' &&
    ///            event.request.session[0].challengeResult === true ) {
    ///
    ///            event.response.issueTokens = true;
    ///            event.response.failAuthentication = false;
    ///        } else {
    ///            event.response.issueTokens = false;
    ///            event.response.failAuthentication = true;
    ///        }
    ///
    ///        return event;
    ///    };
    func testSuccessfulSignInWithCustomAuth() async throws {
        let answer = try requireCustomChallengeAnswer()

        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"

        let isSignedUp = try await AuthSignInHelper.signUpUser(username: username, password: password, email: defaultTestEmail)
        XCTAssertTrue(isSignedUp)

        var confirmationCodeForValidation = ""
        let option = AWSAuthSignInOptions(authFlowType: .custom)
        do {
            let signInResult = try await Amplify.Auth.signIn(
                username: username,
                password: password,
                options: AuthSignInRequest.Options(pluginOptions: option)
            )
            if case .confirmSignInWithCustomChallenge = signInResult.nextStep {
                confirmationCodeForValidation = answer
            } else {
                XCTFail("Expected a custom challenge, got \(signInResult.nextStep)")
            }
        } catch {
            XCTFail("SignIn with invalid auth flow should not succeed")
        }

        do {
            let confirmSignInResult = try await Amplify.Auth.confirmSignIn(challengeResponse: confirmationCodeForValidation)
            XCTAssertTrue(confirmSignInResult.isSignedIn)
        } catch {
            XCTFail("Sign In confirmation failed")
        }
    }


    /// The answer the backend's create/verify-auth-challenge triggers expect, from the credentials file.
    /// Backends without custom-auth triggers (and so without the key) skip these tests, as before.
    private func requireCustomChallengeAnswer() throws -> String {
        guard let customChallengeAnswer else {
            throw XCTSkip("Needs a backend with custom-auth triggers and `custom_challenge_answer` in the credentials file")
        }
        return customChallengeAnswer
    }

}
