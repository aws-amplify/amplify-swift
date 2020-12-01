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

class BaseAuthorizationProviderTest: XCTestCase {

    let apiTimeout = 2.0
    var authorizationProvider: AuthorizationProviderAdapter!
    var mockAWSMobileClient: MockAWSMobileClient!
    var plugin: AWSCognitoAuthPlugin!

    override func setUp() {
        mockAWSMobileClient = MockAWSMobileClient()
        authorizationProvider = AuthorizationProviderAdapter(awsMobileClient: mockAWSMobileClient!)
        plugin = AWSCognitoAuthPlugin()
        plugin?.configure(authenticationProvider: MockAuthenticationProviderBehavior(),
                         authorizationProvider: authorizationProvider,
                         userService: MockAuthUserServiceBehavior(),
                         deviceService: MockAuthDeviceServiceBehavior(),
                         hubEventHandler: MockAuthHubEventBehavior())
    }

    func mockAWSCredentials() {
        let mockAWSCredentials = AWSCredentials(accessKey: "mockAccess",
                                                secretKey: "mockSecret",
                                                sessionKey: "mockSession",
                                                expiration: Date())
        mockAWSMobileClient.awsCredentialsMockResult = .success(mockAWSCredentials)
    }

    func mockCognitoTokens() {
        let mockSessionToken = SessionToken(tokenString: "mockToken")
        let tokens = Tokens(idToken: mockSessionToken,
                            accessToken: mockSessionToken,
                            refreshToken: mockSessionToken,
                            expiration: Date())
        mockAWSMobileClient.tokensMockResult = .success(tokens)
    }

    func mockIdentityId() {
        mockAWSMobileClient.getIdentityIdMockResult = AWSTask(result: "identityId")
    }
}
