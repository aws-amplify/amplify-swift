//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AWSCognitoAuthPlugin

class AWSCognitoAuthDeviceBehaviorTests: XCTestCase {

    var plugin: AWSCognitoAuthPlugin!

    override func setUp() {
        Amplify.reset()
        wait(for: 1)

        plugin = AWSCognitoAuthPlugin()
        plugin.configure(authenticationProvider: MockAuthenticationProviderBehavior(),
                         authorizationProvider: MockAuthorizationProviderBehavior(),
                         userService: MockAuthUserServiceBehavior(),
                         deviceService: MockAuthDeviceServiceBehavior(),
                         hubEventHandler: MockAuthHubEventBehavior())
    }

    /// Test fetchDevices operation can be invoked
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call fetchDevices operation
    /// - Then:
    ///    - I should get a valid operation object
    ///
    func testFetchDevicesRequest() {
        let options = AuthFetchDevicesRequest.Options()
        let operation = plugin.fetchDevices(options: options)
        XCTAssertNotNil(operation)
    }

    /// Test fetchDevices operation can be invoked without options
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call fetchDevices operation
    /// - Then:
    ///    - I should get a valid operation object
    ///
    func testFetchDevicesRequestWithoutOptions() {
        let operation = plugin.fetchDevices()
        XCTAssertNotNil(operation)
    }

    /// Test forgetDevice operation can be invoked
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call forgetDevice operation
    /// - Then:
    ///    - I should get a valid operation object
    ///
    func testForgetDeviceRequest() {
        let options = AuthForgetDeviceRequest.Options()
        let operation = plugin.forgetDevice(options: options)
        XCTAssertNotNil(operation)
    }

    /// Test forgetDevice operation can be invoked without options
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call forgetDevice operation
    /// - Then:
    ///    - I should get a valid operation object
    ///
    func testForgetDeviceRequestWithoutOptions() {
        let operation = plugin.forgetDevice()
        XCTAssertNotNil(operation)
    }

    /// Test rememberDevice operation can be invoked
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call rememberDevice operation
    /// - Then:
    ///    - I should get a valid operation object
    ///
    func testRememberDeviceRequest() {
        let options = AuthRememberDeviceRequest.Options()
        let operation = plugin.rememberDevice(options: options)
        XCTAssertNotNil(operation)
    }

    /// Test rememberDevice operation can be invoked without options
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call rememberDevice operation
    /// - Then:
    ///    - I should get a valid operation object
    ///
    func testRememberDeviceRequestWithoutOptions() {
        let operation = plugin.rememberDevice()
        XCTAssertNotNil(operation)
    }
}
