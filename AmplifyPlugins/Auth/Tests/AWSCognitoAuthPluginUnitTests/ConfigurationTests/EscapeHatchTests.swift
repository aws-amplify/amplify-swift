//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AWSCognitoAuthPlugin

class EscapeHatchTests: XCTestCase {

    override func tearDown() {
        Amplify.reset()
    }

    /// Test escape hatch with valid config for user pool and identity pool
    ///
    /// - Given: Given valid config for user pool and identity pool
    /// - When:
    ///    - I configure auth with the given configuration and call getEscapeHatch
    /// - Then:
    ///    - I should get back user pool and identity pool clients
    ///
    func testEscapeHatchWithUserPoolAndIdentityPool() throws {
        throw XCTSkip("TODO: Update this test")
        let plugin = AWSCognitoAuthPlugin()
        try Amplify.add(plugin: plugin)

        let expectation = expectation(description: "Should get service")
        let categoryConfig = AuthCategoryConfiguration(plugins: [
            "awsCognitoAuthPlugin": [
                "CredentialsProvider": ["CognitoIdentity": ["Default":
                    ["PoolId": "xx",
                     "Region": "us-east-1"]
                    ]],
                "CognitoUserPool": ["Default": [
                    "PoolId": "xx",
                    "Region": "us-east-1",
                    "AppClientId": "xx",
                    "AppClientSecret": "xx"]]
            ]
        ])
        let amplifyConfig = AmplifyConfiguration(auth: categoryConfig)
        try Amplify.configure(amplifyConfig)
        let internalPlugin = try Amplify.Auth.getPlugin(
            for: "awsCognitoAuthPlugin"
        ) as! AWSCognitoAuthPlugin
        let service = internalPlugin.getEscapeHatch()
        switch service {
        case .userPool:
            XCTFail("Should return userPoolAndIdentityPool")
        case .identityPool:
            XCTFail("Should return userPoolAndIdentityPool")
        case .userPoolAndIdentityPool:
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
    }

    /// Test escape hatch with valid config for only identity pool
    ///
    /// - Given: Given valid config for only identity pool
    /// - When:
    ///    - I configure auth with the given configuration and invoke getEscapeHatch
    /// - Then:
    ///    - I should get back only identity pool client
    ///
    func testEscapeHatchWithOnlyIdentityPool() throws {
        throw XCTSkip("TODO: Update this test")
        let plugin = AWSCognitoAuthPlugin()
        try Amplify.add(plugin: plugin)

        let categoryConfig = AuthCategoryConfiguration(plugins: [
            "awsCognitoAuthPlugin": [
                "CredentialsProvider": ["CognitoIdentity": ["Default":
                    ["PoolId": "cc",
                     "Region": "us-east-1"]
                    ]]
            ]
        ])
        let amplifyConfig = AmplifyConfiguration(auth: categoryConfig)
        try Amplify.configure(amplifyConfig)
        let internalPlugin = try Amplify.Auth.getPlugin(
            for: "awsCognitoAuthPlugin"
        ) as! AWSCognitoAuthPlugin
        let service = internalPlugin.getEscapeHatch()
        switch service {
        case .userPool:
            XCTFail("Should return identityPool")
        case .userPoolAndIdentityPool:
            XCTFail("Should return identityPool")
        case .identityPool:
            print("")
        }
    }

    /// Test escape hatch with valid config for only user pool
    ///
    /// - Given: Given valid config for only user pool
    /// - When:
    ///    - I configure auth with the given configuration and invoke getEscapeHatch
    /// - Then:
    ///    - I should get the Cognito User pool client
    ///
    func testEscapeHatchWithOnlyUserPool() throws {
        throw XCTSkip("TODO: Update this test")
        let plugin = AWSCognitoAuthPlugin()
        try Amplify.add(plugin: plugin)

        let categoryConfig = AuthCategoryConfiguration(plugins: [
            "awsCognitoAuthPlugin": [
                "CognitoUserPool": ["Default": [
                    "PoolId": "xx",
                    "Region": "us-east-1",
                    "AppClientId": "xx",
                    "AppClientSecret": "xx"]]
            ]
        ])
        let amplifyConfig = AmplifyConfiguration(auth: categoryConfig)
        try Amplify.configure(amplifyConfig)
        let internalPlugin = try Amplify.Auth.getPlugin(
            for: "awsCognitoAuthPlugin"
        ) as! AWSCognitoAuthPlugin
        let service = internalPlugin.getEscapeHatch()
        switch service {
        case .userPool:
            break
        case .identityPool:
            XCTFail("Should return userPool")
        case .userPoolAndIdentityPool:
            XCTFail("Should return userPool")
        }
    }

}
