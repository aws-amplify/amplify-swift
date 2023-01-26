//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AWSCognitoAuthPlugin
import Combine

// swiftlint:disable file_length type_body_length
final class AWSCognitoAuthClientBehaviorTests: XCTestCase {

    var plugin: AWSCognitoAuthPlugin!
    var authenticationProvider: MockAuthenticationProviderBehavior!
    var authorizationProvider: MockAuthorizationProviderBehavior!
    var userService: MockAuthUserServiceBehavior!
    var deviceService: MockAuthDeviceServiceBehavior!
    var hubEventHandler: MockAuthHubEventBehavior!

    override func setUpWithError() throws {
        authenticationProvider = MockAuthenticationProviderBehavior()
        authorizationProvider = MockAuthorizationProviderBehavior()
        userService = MockAuthUserServiceBehavior()
        deviceService = MockAuthDeviceServiceBehavior()
        hubEventHandler = MockAuthHubEventBehavior()
        plugin = AWSCognitoAuthPlugin()
        plugin.configure(authenticationProvider: authenticationProvider,
                         authorizationProvider: authorizationProvider,
                         userService: userService,
                         deviceService: deviceService,
                         hubEventHandler: hubEventHandler)
        try Amplify.configure(AmplifyConfiguration())
    }

    override func tearDownWithError() throws {
        Amplify.reset()
        authenticationProvider = nil
        authorizationProvider = nil
        userService = nil
        deviceService = nil
        hubEventHandler = nil
        plugin = nil
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

        operation.waitUntilFinished()

        XCTAssertEqual(authenticationProvider.interactions, ["signUp(request:completionHandler:)"])
        XCTAssertEqual(authorizationProvider.interactions, [])
        XCTAssertEqual(userService.interactions, [])
        XCTAssertEqual(deviceService.interactions, [])
        XCTAssertEqual(hubEventHandler.interactions, [])
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

        operation.waitUntilFinished()

        XCTAssertEqual(authenticationProvider.interactions, ["signUp(request:completionHandler:)"])
        XCTAssertEqual(authorizationProvider.interactions, [])
        XCTAssertEqual(userService.interactions, [])
        XCTAssertEqual(deviceService.interactions, [])
        XCTAssertEqual(hubEventHandler.interactions, [])
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

        operation.waitUntilFinished()

        XCTAssertEqual(authenticationProvider.interactions, ["confirmSignUp(request:completionHandler:)"])
        XCTAssertEqual(authorizationProvider.interactions, [])
        XCTAssertEqual(userService.interactions, [])
        XCTAssertEqual(deviceService.interactions, [])
        XCTAssertEqual(hubEventHandler.interactions, [])
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

        operation.waitUntilFinished()

        XCTAssertEqual(authenticationProvider.interactions, ["confirmSignUp(request:completionHandler:)"])
        XCTAssertEqual(authorizationProvider.interactions, [])
        XCTAssertEqual(userService.interactions, [])
        XCTAssertEqual(deviceService.interactions, [])
        XCTAssertEqual(hubEventHandler.interactions, [])
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

        operation.waitUntilFinished()

        XCTAssertEqual(authenticationProvider.interactions, ["resendSignUpCode(request:completionHandler:)"])
        XCTAssertEqual(authorizationProvider.interactions, [])
        XCTAssertEqual(userService.interactions, [])
        XCTAssertEqual(deviceService.interactions, [])
        XCTAssertEqual(hubEventHandler.interactions, [])
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

        operation.waitUntilFinished()

        XCTAssertEqual(authenticationProvider.interactions, ["resendSignUpCode(request:completionHandler:)"])
        XCTAssertEqual(authorizationProvider.interactions, [])
        XCTAssertEqual(userService.interactions, [])
        XCTAssertEqual(deviceService.interactions, [])
        XCTAssertEqual(hubEventHandler.interactions, [])
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

        operation.waitUntilFinished()

        XCTAssertEqual(authenticationProvider.interactions, ["signIn(request:completionHandler:)"])
        XCTAssertEqual(authorizationProvider.interactions, [])
        XCTAssertEqual(userService.interactions, [])
        XCTAssertEqual(deviceService.interactions, [])
        XCTAssertEqual(hubEventHandler.interactions, [])
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

        operation.waitUntilFinished()

        XCTAssertEqual(authenticationProvider.interactions, ["signIn(request:completionHandler:)"])
        XCTAssertEqual(authorizationProvider.interactions, [])
        XCTAssertEqual(userService.interactions, [])
        XCTAssertEqual(deviceService.interactions, [])
        XCTAssertEqual(hubEventHandler.interactions, [])
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

        operation.waitUntilFinished()

        XCTAssertEqual(authenticationProvider.interactions, ["signInWithWebUI(request:completionHandler:)"])
        XCTAssertEqual(authorizationProvider.interactions, [])
        XCTAssertEqual(userService.interactions, [])
        XCTAssertEqual(deviceService.interactions, [])
        XCTAssertEqual(hubEventHandler.interactions, [])
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

        operation.waitUntilFinished()

        XCTAssertEqual(authenticationProvider.interactions, ["signInWithWebUI(request:completionHandler:)"])
        XCTAssertEqual(authorizationProvider.interactions, [])
        XCTAssertEqual(userService.interactions, [])
        XCTAssertEqual(deviceService.interactions, [])
        XCTAssertEqual(hubEventHandler.interactions, [])
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

        operation.waitUntilFinished()

        XCTAssertEqual(authenticationProvider.interactions, ["signInWithWebUI(request:completionHandler:)"])
        XCTAssertEqual(authorizationProvider.interactions, [])
        XCTAssertEqual(userService.interactions, [])
        XCTAssertEqual(deviceService.interactions, [])
        XCTAssertEqual(hubEventHandler.interactions, [])
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

        operation.waitUntilFinished()

        XCTAssertEqual(authenticationProvider.interactions, ["signInWithWebUI(request:completionHandler:)"])
        XCTAssertEqual(authorizationProvider.interactions, [])
        XCTAssertEqual(userService.interactions, [])
        XCTAssertEqual(deviceService.interactions, [])
        XCTAssertEqual(hubEventHandler.interactions, [])
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

        operation.waitUntilFinished()

        XCTAssertEqual(authenticationProvider.interactions, ["confirmSignIn(request:completionHandler:)"])
        XCTAssertEqual(authorizationProvider.interactions, [])
        XCTAssertEqual(userService.interactions, [])
        XCTAssertEqual(deviceService.interactions, [])
        XCTAssertEqual(hubEventHandler.interactions, [])
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

        operation.waitUntilFinished()

        XCTAssertEqual(authenticationProvider.interactions, ["confirmSignIn(request:completionHandler:)"])
        XCTAssertEqual(authorizationProvider.interactions, [])
        XCTAssertEqual(userService.interactions, [])
        XCTAssertEqual(deviceService.interactions, [])
        XCTAssertEqual(hubEventHandler.interactions, [])
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

        operation.waitUntilFinished()

        XCTAssertEqual(authenticationProvider.interactions, ["signOut(request:completionHandler:)"])
        XCTAssertEqual(authorizationProvider.interactions, [])
        XCTAssertEqual(userService.interactions, [])
        XCTAssertEqual(deviceService.interactions, [])
        XCTAssertEqual(hubEventHandler.interactions, [])
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

        operation.waitUntilFinished()

        XCTAssertEqual(authenticationProvider.interactions, ["signOut(request:completionHandler:)"])
        XCTAssertEqual(authorizationProvider.interactions, [])
        XCTAssertEqual(userService.interactions, [])
        XCTAssertEqual(deviceService.interactions, [])
        XCTAssertEqual(hubEventHandler.interactions, [])
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

        operation.waitUntilFinished()

        XCTAssertEqual(authenticationProvider.interactions, [])
        XCTAssertEqual(authorizationProvider.interactions, ["fetchSession(request:completionHandler:)"])
        XCTAssertEqual(userService.interactions, [])
        XCTAssertEqual(deviceService.interactions, [])
        XCTAssertEqual(hubEventHandler.interactions, [])
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

        operation.waitUntilFinished()

        XCTAssertEqual(authenticationProvider.interactions, [])
        XCTAssertEqual(authorizationProvider.interactions, ["fetchSession(request:completionHandler:)"])
        XCTAssertEqual(userService.interactions, [])
        XCTAssertEqual(deviceService.interactions, [])
        XCTAssertEqual(hubEventHandler.interactions, [])
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

        operation.waitUntilFinished()

        XCTAssertEqual(authenticationProvider.interactions, ["resetPassword(request:completionHandler:)"])
        XCTAssertEqual(authorizationProvider.interactions, [])
        XCTAssertEqual(userService.interactions, [])
        XCTAssertEqual(deviceService.interactions, [])
        XCTAssertEqual(hubEventHandler.interactions, [])
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

        operation.waitUntilFinished()

        XCTAssertEqual(authenticationProvider.interactions, ["resetPassword(request:completionHandler:)"])
        XCTAssertEqual(authorizationProvider.interactions, [])
        XCTAssertEqual(userService.interactions, [])
        XCTAssertEqual(deviceService.interactions, [])
        XCTAssertEqual(hubEventHandler.interactions, [])
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

        operation.waitUntilFinished()

        XCTAssertEqual(authenticationProvider.interactions, ["confirmResetPassword(request:completionHandler:)"])
        XCTAssertEqual(authorizationProvider.interactions, [])
        XCTAssertEqual(userService.interactions, [])
        XCTAssertEqual(deviceService.interactions, [])
        XCTAssertEqual(hubEventHandler.interactions, [])
    }

    /// Test confirmResetPassword operation can be invoked without options
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call confirmResetPassword operation
    /// - Then:
    ///    - I should get a valid operation object
    ///
    func testConfirmResetPasswordRequestWithoutOptions() throws {
        let operation = plugin.confirmResetPassword(for: "username", with: "password", confirmationCode: "code")
        XCTAssertNotNil(operation)

        operation.waitUntilFinished()

        XCTAssertEqual(authenticationProvider.interactions, ["confirmResetPassword(request:completionHandler:)"])
        XCTAssertEqual(authorizationProvider.interactions, [])
        XCTAssertEqual(userService.interactions, [])
        XCTAssertEqual(deviceService.interactions, [])
        XCTAssertEqual(hubEventHandler.interactions, [])
    }
}
