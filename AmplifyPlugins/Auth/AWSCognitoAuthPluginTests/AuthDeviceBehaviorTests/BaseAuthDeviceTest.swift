//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import XCTest
@testable import Amplify
@testable import AWSCognitoAuthPlugin
@testable import AWSMobileClient

class BaseAuthDeviceTest: XCTestCase {

    let apiTimeout = 2.0
    var deviceService: AuthDeviceServiceAdapter!
    var mockAWSMobileClient: MockAWSMobileClient!
    var plugin: AWSCognitoAuthPlugin!

    override func setUp() {
        mockAWSMobileClient = MockAWSMobileClient()
        deviceService = AuthDeviceServiceAdapter(awsMobileClient: mockAWSMobileClient)

        plugin = AWSCognitoAuthPlugin()
        plugin?.configure(authenticationProvider: MockAuthenticationProviderBehavior(),
                         authorizationProvider: MockAuthorizationProviderBehavior(),
                         userService: MockAuthUserServiceBehavior(),
                         deviceService: deviceService,
                         hubEventHandler: MockAuthHubEventBehavior())
    }

    override func tearDown() {
        plugin = nil
        mockAWSMobileClient = nil
        deviceService = nil
    }
}
