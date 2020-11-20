//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AWSCognitoAuthPlugin

class AWSCognitoAuthClientBehaviorTests: XCTestCase {

    var plugin: AWSCognitoAuthPlugin!

    override func setUp() {
        plugin = AWSCognitoAuthPlugin()
        plugin.configure(authenticationProvider: MockAuthenticationProviderBehavior(),
                         authorizationProvider: MockAuthorizationProviderBehavior(),
                         userService: MockAuthUserServiceBehavior(),
                         deviceService: MockAuthDeviceServiceBehavior(),
                         hubEventHandler: MockAuthHubEventBehavior())
    }

    override func tearDown() {
        Amplify.reset()
    }

    /// Test signup operation can be invoked
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call signup operation
    /// - Then:
    ///    - I should get a valid operation object
    ///
    func testSignUpRequest() {
        let emailAttribute = AuthUserAttribute(.email, value: "email")
        let pluginOptions = AWSAuthSignUpOptions(validationData: ["somekey": "somevalue"],
                                                 metadata: ["somekey": "somevalue"])
        let options = AuthSignUpRequest.Options(userAttributes: [emailAttribute], pluginOptions: pluginOptions)
        let operation = plugin.signUp(username: "userName", password: "password", options: options)
        XCTAssertNotNil(operation)
    }

    /// Test signup operation can be invoked without options
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call signup operation without any options
    /// - Then:
    ///    - I should get a valid operation object
    ///
    func testSignUpRequestWithoutOptions() {
        let operation = plugin.signUp(username: "userName", password: "password")
        XCTAssertNotNil(operation)
    }

    /// Test confirmSignup operation can be invoked
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call confirmSignup operation
    /// - Then:
    ///    - I should get a valid operation object
    ///
    func testConfirmSignUpRequest() {
        let pluginOptions = AWSAuthConfirmSignUpOptions(validationData: ["somekey": "somevalue"],
                                                 metadata: ["somekey": "somevalue"])
        let options = AuthConfirmSignUpRequest.Options(pluginOptions: pluginOptions)
        let operation = plugin.confirmSignUp(for: "username", confirmationCode: "code", options: options)
        XCTAssertNotNil(operation)
    }

    /// Test confirmSignup operation can be invoked without options
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call confirmSignup operation
    /// - Then:
    ///    - I should get a valid operation object
    ///
    func testConfirmSignUpRequestWithoutOptions() {
        let operation = plugin.confirmSignUp(for: "username", confirmationCode: "code")
        XCTAssertNotNil(operation)
    }

    /// Test resendSignUpCode operation can be invoked
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call resendSignUpCode operation
    /// - Then:
    ///    - I should get a valid operation object
    ///
    func testResendSignupCodeRequest() {
        let pluginOptions = AWSAuthResendSignUpCodeOptions(metadata: ["somekey": "somevalue"])
        let options = AuthResendSignUpCodeRequest.Options(pluginOptions: pluginOptions)
        let operation = plugin.resendSignUpCode(for: "username", options: options)
        XCTAssertNotNil(operation)
    }

    /// Test resendSignUpCode operation can be invoked without options
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call resendSignUpCode operation
    /// - Then:
    ///    - I should get a valid operation object
    ///
    func testResendSignupCodeRequestWithoutOptions() {
        let operation = plugin.resendSignUpCode(for: "username")
        XCTAssertNotNil(operation)
    }

    /// Test signIn operation can be invoked
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call signIn operation
    /// - Then:
    ///    - I should get a valid operation object
    ///
    func testSigninRequest() {
        let pluginOptions = AWSAuthSignInOptions(validationData: ["somekey": "somevalue"],
                                                 metadata: ["somekey": "somevalue"])
        let options = AuthSignInRequest.Options(pluginOptions: pluginOptions)
        let operation = plugin.signIn(username: "username", password: "password", options: options)
        XCTAssertNotNil(operation)
    }

    /// Test signIn operation can be invoked without options
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call signIn operation
    /// - Then:
    ///    - I should get a valid operation object
    ///
    func testSigninRequestWithoutOptions() {
        let operation = plugin.signIn(username: "username", password: "password")
        XCTAssertNotNil(operation)
    }

    /// Test signInWithWebUI operation can be invoked
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call signInWithWebUI operation
    /// - Then:
    ///    - I should get a valid operation object
    ///
    func testSigninWithWebUIRequest() {
        let pluginOptions = AWSAuthWebUISignInOptions(idpIdentifier: "id",
                                                      federationProviderName: "provider")
        let options = AuthWebUISignInRequest.Options(scopes: ["email"],
                                                     signInQueryParameters: ["key": "value"],
                                                     signOutQueryParameters: ["key": "value"],
                                                     tokenQueryParameters: ["key": "value"],
                                                     pluginOptions: pluginOptions)
        let operation = plugin.signInWithWebUI(presentationAnchor: UIWindow(), options: options)
        XCTAssertNotNil(operation)
    }

    /// Test signInWithWebUI operation can be invoked without options
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call signInWithWebUI operation
    /// - Then:
    ///    - I should get a valid operation object
    ///
    func testSigninWithWebUIRequestWithoutOptions() {
        let operation = plugin.signInWithWebUI(presentationAnchor: UIWindow())
        XCTAssertNotNil(operation)
    }

    /// Test signInWithWebUI operation can be invoked
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call signInWithWebUI operation
    /// - Then:
    ///    - I should get a valid operation object
    ///
    func testSigninWithSocialWebUIRequest() {
        let pluginOptions = AWSAuthWebUISignInOptions(idpIdentifier: "id",
                                                      federationProviderName: "provider")
        let options = AuthWebUISignInRequest.Options(scopes: ["email"],
                                                     signInQueryParameters: ["key": "value"],
                                                     signOutQueryParameters: ["key": "value"],
                                                     tokenQueryParameters: ["key": "value"],
                                                     pluginOptions: pluginOptions)
        let operation = plugin.signInWithWebUI(for: .amazon, presentationAnchor: UIWindow(), options: options)
        XCTAssertNotNil(operation)
    }

    /// Test signInWithWebUI operation can be invoked without options
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call signInWithWebUI operation
    /// - Then:
    ///    - I should get a valid operation object
    ///
    func testSigninWithSocialWebUIRequestWithoutOptions() {
        let operation = plugin.signInWithWebUI(for: .amazon, presentationAnchor: UIWindow())
        XCTAssertNotNil(operation)
    }

    /// Test confirmSignIn operation can be invoked
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call confirmSignIn operation
    /// - Then:
    ///    - I should get a valid operation object
    ///
    func testConfirmSigninRequest() {
        let emailAttribute = AuthUserAttribute(.email, value: "email")
        let pluginOptions = AWSAuthConfirmSignInOptions(userAttributes: [emailAttribute],
                                                        metadata: ["key": "value"])
        let options = AuthConfirmSignInRequest.Options(pluginOptions: pluginOptions)
        let operation = plugin.confirmSignIn(challengeResponse: "reponse", options: options)
        XCTAssertNotNil(operation)
    }

    /// Test confirmSignIn operation can be invoked without options
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call confirmSignIn operation
    /// - Then:
    ///    - I should get a valid operation object
    ///
    func testConfirmSigninRequestWithoutOptions() {
        let operation = plugin.confirmSignIn(challengeResponse: "reponse")
        XCTAssertNotNil(operation)
    }

    /// Test signOut operation can be invoked
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call signOut operation
    /// - Then:
    ///    - I should get a valid operation object
    ///
    func testSignoutRequest() {
        let options = AuthSignOutRequest.Options(globalSignOut: true)
        let operation = plugin.signOut(options: options)
        XCTAssertNotNil(operation)
    }

    /// Test signOut operation can be invoked without options
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call signOut operation
    /// - Then:
    ///    - I should get a valid operation object
    ///
    func testSignoutRequestWithoutOptions() {
        let operation = plugin.signOut()
        XCTAssertNotNil(operation)
    }

    /// Test fetchAuthSession operation can be invoked
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call fetchAuthSession operation
    /// - Then:
    ///    - I should get a valid operation object
    ///
    func testfetchAuthSessionRequest() {
        let options = AuthFetchSessionRequest.Options()
        let operation = plugin.fetchAuthSession(options: options)
        XCTAssertNotNil(operation)
    }

    /// Test fetchAuthSession operation can be invoked without options
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call fetchAuthSession operation
    /// - Then:
    ///    - I should get a valid operation object
    ///
    func testfetchAuthSessionWithoutOptions() {
        let operation = plugin.fetchAuthSession()
        XCTAssertNotNil(operation)
    }

    /// Test resetPassword operation can be invoked
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call resetPassword operation
    /// - Then:
    ///    - I should get a valid operation object
    ///
    func testResetPasswordRequest() {
        let pluginOptions = AWSAuthResetPasswordOptions(metadata: ["key": "value"])
        let options = AuthResetPasswordRequest.Options(pluginOptions: pluginOptions)
        let operation = plugin.resetPassword(for: "username", options: options)
        XCTAssertNotNil(operation)
    }

    /// Test resetPassword operation can be invoked without options
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call resetPassword operation
    /// - Then:
    ///    - I should get a valid operation object
    ///
    func testResetPasswordRequestWithoutOptions() {
        let operation = plugin.resetPassword(for: "username")
        XCTAssertNotNil(operation)
    }

    /// Test confirmResetPassword operation can be invoked
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call confirmResetPassword operation
    /// - Then:
    ///    - I should get a valid operation object
    ///
    func testConfirmResetPasswordRequest() {
        let pluginOptions = AWSAuthConfirmResetPasswordOptions(metadata: ["key": "value"])
        let options = AuthConfirmResetPasswordRequest.Options(pluginOptions: pluginOptions)
        let operation = plugin.confirmResetPassword(for: "username",
                                                    with: "password",
                                                    confirmationCode: "code",
                                                    options: options)
        XCTAssertNotNil(operation)
    }

    /// Test confirmResetPassword operation can be invoked without options
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call confirmResetPassword operation
    /// - Then:
    ///    - I should get a valid operation object
    ///
    func testConfirmResetPasswordRequestWithoutOptions() {
        let operation = plugin.confirmResetPassword(for: "username", with: "password", confirmationCode: "code")
        XCTAssertNotNil(operation)
    }
}
