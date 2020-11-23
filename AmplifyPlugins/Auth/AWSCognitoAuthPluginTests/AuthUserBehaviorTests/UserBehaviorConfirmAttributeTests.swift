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

class UserBehaviorConfirmAttributeTests: XCTestCase {

    var authenticationProvider: AuthenticationProviderAdapter!
    var mockAWSMobileClient: MockAWSMobileClient!
    var plugin: AWSCognitoAuthPlugin!

    override func setUp() {
        mockAWSMobileClient = MockAWSMobileClient()
        authenticationProvider = AuthenticationProviderAdapter(awsMobileClient: mockAWSMobileClient!)
        plugin = AWSCognitoAuthPlugin()
        plugin?.configure(authenticationProvider: authenticationProvider,
                         authorizationProvider: MockAuthorizationProviderBehavior(),
                         userService: MockAuthUserServiceBehavior(),
                         deviceService: MockAuthDeviceServiceBehavior(),
                         hubEventHandler: MockAuthHubEventBehavior())
    }
}
