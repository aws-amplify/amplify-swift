//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
import AWSCognitoAuthPlugin

class AuthCustomSignInTests: AWSAuthBaseTest {

    override func setUp() {
        super.setUp()
        initializeAmplify()
        AuthSessionHelper.clearSession()
    }

    override func tearDown() async throws {
        try await super.tearDown()
        await Amplify.reset()
        AuthSessionHelper.clearSession()
        sleep(2)
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
    func testSuccessfulSignInWithCustomAuthSRP() {

        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"

        let signUpExpectation = expectation(description: "SignUp operation should complete")
        AuthSignInHelper.signUpUser(username: username, password: password,
                                    email: defaultTestEmail) { didSucceed, error in
            signUpExpectation.fulfill()
            XCTAssertTrue(didSucceed, "Signup operation failed - \(String(describing: error))")
        }
        wait(for: [signUpExpectation], timeout: networkTimeout)

        var confirmationCodeForValidation = ""

        let operationExpectation = expectation(description: "Operation should complete")
        let option = AWSAuthSignInOptions(authFlowType: .customWithSRP)
        let operation = Amplify.Auth.signIn(
            username: username,
            password: password,
            options: .init(pluginOptions: option)) { result in
                switch result {
                case .success(let data):
                    if case .confirmSignInWithCustomChallenge(let additionalInfo) = data.nextStep {
                        confirmationCodeForValidation = additionalInfo?["code"] ?? ""
                    }
                    operationExpectation.fulfill()
                case .failure:
                    XCTFail("SignIn with invalid auth flow should not succeed")
                }
            }
        XCTAssertNotNil(operation, "SignIn operation should not be nil")
        wait(for: [operationExpectation], timeout: networkTimeout)

        let confirmSignInOperationExpectation = expectation(description: "Confirm Sign in operation should complete")
        let confirmSignInOperation = Amplify.Auth.confirmSignIn(challengeResponse: confirmationCodeForValidation) { result in
            switch result {
            case .success(let confirmSignInResult):
                if case .done = confirmSignInResult.nextStep, confirmSignInResult.isSignedIn {
                    confirmSignInOperationExpectation.fulfill()
                }
            case .failure:
                XCTFail("Sign In confirmation failed")
            }
        }

        XCTAssertNotNil(confirmSignInOperation, "Confirm SignIn operation should not be nil")
        wait(for: [confirmSignInOperationExpectation], timeout: networkTimeout)
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
    func testRuntimeAuthFlowSwitch() {

        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"

        let signUpExpectation = expectation(description: "SignUp operation should complete")
        AuthSignInHelper.signUpUser(username: username, password: password,
                                    email: defaultTestEmail) { didSucceed, error in
            signUpExpectation.fulfill()
            XCTAssertTrue(didSucceed, "Signup operation failed - \(String(describing: error))")
        }
        wait(for: [signUpExpectation], timeout: networkTimeout)

        let operationExpectation = expectation(description: "Operation should complete")
        let option = AWSAuthSignInOptions(authFlowType: .customWithSRP)
        let operation = Amplify.Auth.signIn(username: username,
                                            password: password,
                                            options: .init(pluginOptions: option)) { result in
            switch result {
            case .success:
                operationExpectation.fulfill()
            case .failure:
                XCTFail("Should successfully login")
            }
        }
        XCTAssertNotNil(operation, "SignIn operation should not be nil")
        wait(for: [operationExpectation], timeout: networkTimeout)

        let signOutExpectation = expectation(description: "Sign out operation should complete")
        let signOutOperation = Amplify.Auth.signOut { result in
            switch result {
            case .success:
                signOutExpectation.fulfill()
            case .failure:
                XCTFail("Sign out should succeed")
            }
        }

        XCTAssertNotNil(signOutOperation, "SignIn operation should not be nil")
        wait(for: [signOutExpectation], timeout: networkTimeout)

        let srpOperationExpectation = expectation(description: "Operation should complete")
        let srpOption = AWSAuthSignInOptions(authFlowType: .userSRP)
        let srpOperation = Amplify.Auth.signIn(username: username,
                                            password: password,
                                            options: .init(pluginOptions: srpOption)) { result in
            defer {
                srpOperationExpectation.fulfill()
            }
            switch result {
            case .success(let signInResult):
                XCTAssertTrue(signInResult.isSignedIn, "SignIn should be complete")
            case .failure(let error):
                XCTFail("SignIn with a valid username/password should not fail \(error)")
            }
        }
        XCTAssertNotNil(srpOperation, "SignIn operation should not be nil")
        wait(for: [srpOperationExpectation], timeout: networkTimeout)
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
    func testSuccessfulSignInWithCustomAuth() {

        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"

        let signUpExpectation = expectation(description: "SignUp operation should complete")
        AuthSignInHelper.signUpUser(username: username, password: password,
                                    email: defaultTestEmail) { didSucceed, error in
            signUpExpectation.fulfill()
            XCTAssertTrue(didSucceed, "Signup operation failed - \(String(describing: error))")
        }
        wait(for: [signUpExpectation], timeout: networkTimeout)

        var confirmationCodeForValidation = ""

        let operationExpectation = expectation(description: "Operation should complete")
        let option = AWSAuthSignInOptions(authFlowType: .custom)
        let operation = Amplify.Auth.signIn(
            username: username,
            password: password,
            options: .init(pluginOptions: option)) { result in
                switch result {
                case .success(let data):
                    if case .confirmSignInWithCustomChallenge(let additionalInfo) = data.nextStep {
                        confirmationCodeForValidation = additionalInfo?["code"] ?? ""
                    }
                    operationExpectation.fulfill()
                case .failure:
                    XCTFail("SignIn with invalid auth flow should not succeed")
                }
            }
        XCTAssertNotNil(operation, "SignIn operation should not be nil")
        wait(for: [operationExpectation], timeout: networkTimeout)

        let confirmSignInOperationExpectation = expectation(description: "Confirm Sign in operation should complete")
        let confirmSignInOperation = Amplify.Auth.confirmSignIn(challengeResponse: confirmationCodeForValidation) { result in
            switch result {
            case .success(let confirmSignInResult):
                if case .done = confirmSignInResult.nextStep, confirmSignInResult.isSignedIn {
                    confirmSignInOperationExpectation.fulfill()
                }
            case .failure:
                XCTFail("Sign In confirmation failed")
            }
        }

        XCTAssertNotNil(confirmSignInOperation, "Confirm SignIn operation should not be nil")
        wait(for: [confirmSignInOperationExpectation], timeout: networkTimeout)
    }

}
