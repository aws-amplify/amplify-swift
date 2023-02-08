//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import XCTest
@testable import Amplify
@testable import AWSCognitoAuthPlugin

class AWSCognitoAuthUserBehaviorTests: XCTestCase {

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

    override func tearDown() {
        Amplify.reset()
        authenticationProvider = nil
        authorizationProvider = nil
        userService = nil
        deviceService = nil
        hubEventHandler = nil
        plugin = nil
    }

    /// Test fetchUserAttributes operation can be invoked
    ///
    /// - Given: Given a configured auth plugin
    /// - When: It receives a `fetchUserAttributes` message with options
    /// - Then: The operation is delegated to the user service's `fetchAttributes(request:completionHandler:)` method
    ///
    func testFetchUserAttributesRequest() {
        let options = AuthFetchUserAttributesRequest.Options()
        let operation = plugin.fetchUserAttributes(options: options)
        XCTAssertNotNil(operation)

        operation.waitUntilFinished()

        XCTAssertEqual(authenticationProvider.interactions, [])
        XCTAssertEqual(authorizationProvider.interactions, [])
        XCTAssertEqual(userService.interactions, ["fetchAttributes(request:completionHandler:)"])
        XCTAssertEqual(deviceService.interactions, [])
        XCTAssertEqual(hubEventHandler.interactions, [])
    }

    /// Test fetchDevices operation can be invoked without options
    ///
    /// - Given: Given a configured auth plugin
    /// - When: It receives a `fetchUserAttributes` message without any options
    /// - Then: The operation is delegated to the user service's `fetchAttributes(request:completionHandler:)` method
    ///
    func testFetchUserAttributesRequestWithoutOptions() {
        let operation = plugin.fetchUserAttributes()
        XCTAssertNotNil(operation)

        operation.waitUntilFinished()

        XCTAssertEqual(authenticationProvider.interactions, [])
        XCTAssertEqual(authorizationProvider.interactions, [])
        XCTAssertEqual(userService.interactions, ["fetchAttributes(request:completionHandler:)"])
        XCTAssertEqual(deviceService.interactions, [])
        XCTAssertEqual(hubEventHandler.interactions, [])
    }

    /// Test update(userAttribute:) operation can be invoked
    ///
    /// - Given: Given a configured auth plugin
    /// - When: It receives an `update(userAttribute:)` message with an email attribute and options
    /// - Then: The operation is delegated to the user service's `updateAttribute(request:completionHandler:)`
    ///        (singular) method
    ///
    func testUpdateUserAttributeRequest() {
        let emailAttribute = AuthUserAttribute(.email, value: "email")
        let pluginOptions = AWSUpdateUserAttributeOptions(metadata: ["key": "value"])
        let options = AuthUpdateUserAttributeRequest.Options(pluginOptions: pluginOptions)
        let operation = plugin.update(userAttribute: emailAttribute, options: options)
        XCTAssertNotNil(operation)

        operation.waitUntilFinished()

        XCTAssertEqual(authenticationProvider.interactions, [])
        XCTAssertEqual(authorizationProvider.interactions, [])
        XCTAssertEqual(userService.interactions, ["updateAttribute(request:completionHandler:)"])
        XCTAssertEqual(deviceService.interactions, [])
        XCTAssertEqual(hubEventHandler.interactions, [])
    }

    /// Test update(userAttribute:) operation can be invoked without options
    ///
    /// - Given: Given a configured auth plugin
    /// - When: It receives an `update(userAttribute:)` message with an email attribute and without options
    /// - Then: The operation is delegated to the user service's `updateAttribute(request:completionHandler:)`
    ///        (singular) method
    ///
    func testUpdateUserAttributeRequestWithoutOptions() {
        let emailAttribute = AuthUserAttribute(.email, value: "email")
        let operation = plugin.update(userAttribute: emailAttribute)
        XCTAssertNotNil(operation)

        operation.waitUntilFinished()

        XCTAssertEqual(authenticationProvider.interactions, [])
        XCTAssertEqual(authorizationProvider.interactions, [])
        XCTAssertEqual(userService.interactions, ["updateAttribute(request:completionHandler:)"])
        XCTAssertEqual(deviceService.interactions, [])
        XCTAssertEqual(hubEventHandler.interactions, [])
    }

    /// Test update(userAttributes:) operation can be invoked
    ///
    /// - Given: Given a configured auth plugin
    /// - When: It receives an `update(userAttribute:)` message with email and phone number attributes and options
    /// - Then: The operation is delegated to the user service's `updateAttributes(request:completionHandler:)`
    ///        (plural) method
    ///
    func testUpdateUserAttributesRequest() {
        let emailAttribute = AuthUserAttribute(.email, value: "email")
        let phoneAttribute = AuthUserAttribute(.phoneNumber, value: "123213")
        let pluginOptions = AWSUpdateUserAttributesOptions(metadata: ["key": "value"])
        let options = AuthUpdateUserAttributesRequest.Options(pluginOptions: pluginOptions)
        let operation = plugin.update(userAttributes: [emailAttribute, phoneAttribute], options: options)
        XCTAssertNotNil(operation)

        operation.waitUntilFinished()

        XCTAssertEqual(authenticationProvider.interactions, [])
        XCTAssertEqual(authorizationProvider.interactions, [])
        XCTAssertEqual(userService.interactions, ["updateAttributes(request:completionHandler:)"])
        XCTAssertEqual(deviceService.interactions, [])
        XCTAssertEqual(hubEventHandler.interactions, [])
    }

    /// Test update(userAttributes:) operation can be invoked without options
    ///
    /// - Given: Given a configured auth plugin
    /// - When: It receives an `update(userAttribute:)` message with email and phone number attributes and no options
    /// - Then: The operation is delegated to the user service's `updateAttributes(request:completionHandler:)`
    ///        (plural) method
    ///
    func testUpdateUserAttributesRequestWithoutOptions() {
        let emailAttribute = AuthUserAttribute(.email, value: "email")
        let phoneAttribute = AuthUserAttribute(.phoneNumber, value: "123213")
        let operation = plugin.update(userAttributes: [emailAttribute, phoneAttribute])
        XCTAssertNotNil(operation)

        operation.waitUntilFinished()

        XCTAssertEqual(authenticationProvider.interactions, [])
        XCTAssertEqual(authorizationProvider.interactions, [])
        XCTAssertEqual(userService.interactions, ["updateAttributes(request:completionHandler:)"])
        XCTAssertEqual(deviceService.interactions, [])
        XCTAssertEqual(hubEventHandler.interactions, [])
    }

    /// Test resendConfirmationCode(for:) operation can be invoked
    ///
    /// - Given: Given a configured auth plugin
    /// - When: It receives an `resendConfirmationCode(for:)` message with options
    /// - Then: The operation is delegated to the user service's
    ///        `resendAttributeConfirmationCode(request:completionHandler:)` method
    ///
    func testResendConfirmationCodeAttributeRequest() {
        let pluginOptions = AWSAttributeResendConfirmationCodeOptions(metadata: ["key": "value"])
        let options = AuthAttributeResendConfirmationCodeRequest.Options(pluginOptions: pluginOptions)
        let operation = plugin.resendConfirmationCode(for: .email, options: options)
        XCTAssertNotNil(operation)

        operation.waitUntilFinished()

        XCTAssertEqual(authenticationProvider.interactions, [])
        XCTAssertEqual(authorizationProvider.interactions, [])
        XCTAssertEqual(userService.interactions, ["resendAttributeConfirmationCode(request:completionHandler:)"])
        XCTAssertEqual(deviceService.interactions, [])
        XCTAssertEqual(hubEventHandler.interactions, [])
    }

    /// Test resendConfirmationCode(for:)  operation can be invoked without options
    ///
    /// - Given: Given a configured auth plugin
    /// - When: It receives an `resendConfirmationCode(for:)` message without any options
    /// - Then: The operation is delegated to the user service's
    ///        `resendAttributeConfirmationCode(request:completionHandler:)` method
    ///
    func testResendConfirmationCodeAttributeRequestWithoutOptions() {
        let operation = plugin.resendConfirmationCode(for: .email)
        XCTAssertNotNil(operation)

        operation.waitUntilFinished()

        XCTAssertEqual(authenticationProvider.interactions, [])
        XCTAssertEqual(authorizationProvider.interactions, [])
        XCTAssertEqual(userService.interactions, ["resendAttributeConfirmationCode(request:completionHandler:)"])
        XCTAssertEqual(deviceService.interactions, [])
        XCTAssertEqual(hubEventHandler.interactions, [])
    }

    /// Test confirm(userAttribute: ) operation can be invoked
    ///
    /// - Given: Given a configured auth plugin
    /// - When: It receives a `confirm(userAttribute:)` message with options
    /// - Then: The operation is delegated to the user service's `confirmAttribute(request:completionHandler:)` method
    ///
    func testConfirmUserAttributeRequest() {
        let options = AuthConfirmUserAttributeRequest.Options()
        let operation = plugin.confirm(userAttribute: .email, confirmationCode: "code", options: options)
        XCTAssertNotNil(operation)

        operation.waitUntilFinished()

        XCTAssertEqual(authenticationProvider.interactions, [])
        XCTAssertEqual(authorizationProvider.interactions, [])
        XCTAssertEqual(userService.interactions, ["confirmAttribute(request:completionHandler:)"])
        XCTAssertEqual(deviceService.interactions, [])
        XCTAssertEqual(hubEventHandler.interactions, [])
    }

    /// Test confirm(userAttribute: )  operation can be invoked without options
    ///
    /// - Given: Given a configured auth plugin
    /// - When: It receives a `confirm(userAttribute:)` message without any options
    /// - Then: The operation is delegated to the user service's `confirmAttribute(request:completionHandler:)` method
    ///
    func testConfirmUserAttributeRequestWithoutOptions() {
        let operation = plugin.confirm(userAttribute: .email, confirmationCode: "code")
        XCTAssertNotNil(operation)

        operation.waitUntilFinished()

        XCTAssertEqual(authenticationProvider.interactions, [])
        XCTAssertEqual(authorizationProvider.interactions, [])
        XCTAssertEqual(userService.interactions, ["confirmAttribute(request:completionHandler:)"])
        XCTAssertEqual(deviceService.interactions, [])
        XCTAssertEqual(hubEventHandler.interactions, [])
    }

    /// Test update(oldPassword:to: ) operation can be invoked
    ///
    /// - Given: Given a configured auth plugin
    /// - When: It receives an `update(oldPassword:to:)` message with options
    /// - Then: The operation is delegated to the user service's `changePassword(request:completionHandler:)` method
    ///
    func testUpdatePasswordRequest() {
        let options = AuthChangePasswordRequest.Options(metadata: ["key": "value"])
        let operation = plugin.update(oldPassword: "oldpwd", to: "newpwd", options: options)
        XCTAssertNotNil(operation)

        operation.waitUntilFinished()

        XCTAssertEqual(authenticationProvider.interactions, [])
        XCTAssertEqual(authorizationProvider.interactions, [])
        XCTAssertEqual(userService.interactions, ["changePassword(request:completionHandler:)"])
        XCTAssertEqual(deviceService.interactions, [])
        XCTAssertEqual(hubEventHandler.interactions, [])
    }

    /// Test update(oldPassword:to: )  operation can be invoked without options
    ///
    /// - Given: Given a configured auth plugin
    /// - When: It receives an `update(oldPassword:to:)` message with options
    /// - Then: The operation is delegated to the user service's `changePassword(request:completionHandler:)` method
    ///
    func testUpdatePasswordRequestWithoutOptions() {
        let operation = plugin.update(oldPassword: "oldpwd", to: "newpwd")
        XCTAssertNotNil(operation)

        operation.waitUntilFinished()

        XCTAssertEqual(authenticationProvider.interactions, [])
        XCTAssertEqual(authorizationProvider.interactions, [])
        XCTAssertEqual(userService.interactions, ["changePassword(request:completionHandler:)"])
        XCTAssertEqual(deviceService.interactions, [])
        XCTAssertEqual(hubEventHandler.interactions, [])
    }
}
