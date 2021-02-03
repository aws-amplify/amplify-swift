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
@testable import AWSMobileClient

class BaseAuthenticationProviderTest: XCTestCase {

    let apiTimeout = 2.0
    var authenticationProvider: AuthenticationProviderAdapter!
    var mockAWSMobileClient: MockAWSMobileClient!
    var mockUserDefault: MockUserDefaults!
    var plugin: AWSCognitoAuthPlugin!

    override func setUp() {
        mockAWSMobileClient = MockAWSMobileClient()
        mockUserDefault = MockUserDefaults()
        authenticationProvider = AuthenticationProviderAdapter(awsMobileClient: mockAWSMobileClient!,
                                                               userdefaults: mockUserDefault)
        plugin = AWSCognitoAuthPlugin()
        plugin?.configure(authenticationProvider: authenticationProvider,
                         authorizationProvider: MockAuthorizationProviderBehavior(),
                         userService: MockAuthUserServiceBehavior(),
                         deviceService: MockAuthDeviceServiceBehavior(),
                         hubEventHandler: MockAuthHubEventBehavior())
    }

    override func tearDown() {
        mockUserDefault = nil
        plugin = nil
        mockAWSMobileClient = nil
        authenticationProvider = nil
    }
}
