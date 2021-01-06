//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AWSCognitoAuthPlugin
@testable import AWSMobileClient

class BaseUserBehaviorTest: XCTestCase {

    let apiTimeout = 2.0
    var authUserService: AuthUserServiceAdapter!
    var mockAWSMobileClient: MockAWSMobileClient!
    var plugin: AWSCognitoAuthPlugin!

    override func setUp() {
        mockAWSMobileClient = MockAWSMobileClient()
        authUserService = AuthUserServiceAdapter(awsMobileClient: mockAWSMobileClient!)
        plugin = AWSCognitoAuthPlugin()
        plugin?.configure(authenticationProvider: MockAuthenticationProviderBehavior(),
                         authorizationProvider: MockAuthorizationProviderBehavior(),
                         userService: authUserService,
                         deviceService: MockAuthDeviceServiceBehavior(),
                         hubEventHandler: MockAuthHubEventBehavior())
    }

    override func tearDown() {
        plugin = nil
        mockAWSMobileClient = nil
        authUserService = nil
    }
}
