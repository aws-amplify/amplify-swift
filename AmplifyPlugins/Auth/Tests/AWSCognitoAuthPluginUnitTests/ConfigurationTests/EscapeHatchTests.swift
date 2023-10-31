//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import func AmplifyTestCommon.XCTAssertThrowFatalError
import enum Amplify.JSONValue
@testable import AWSCognitoAuthPlugin


class EscapeHatchTests: XCTestCase {
    /// Test escape hatch with valid config for user pool and identity pool
    ///
    /// - Given: A AWSCognitoAuthPlugin configured with User Pool and Identity Pool
    /// - When:
    ///    - I call getEscapeHatch
    /// - Then:
    ///    - I should get back both the User Pool and Identity Pool clients
    ///
    func testEscapeHatchWithUserPoolAndIdentityPool() throws {
        let configuration: JSONValue = [
            "CredentialsProvider": [
                "CognitoIdentity": [
                    "Default": [
                        "PoolId": "xx",
                        "Region": "us-east-1"
                    ]
                ]
            ],
            "CognitoUserPool": [
                "Default": [
                    "PoolId": "xx",
                    "Region": "us-east-1",
                    "AppClientId": "xx",
                    "AppClientSecret": "xx"
                ]
            ]
        ]
        let plugin = AWSCognitoAuthPlugin()
        try plugin.configure(using: configuration)
        let escapeHatch = plugin.getEscapeHatch()
        guard case .userPoolAndIdentityPool = escapeHatch else {
            XCTFail("Expected .userPoolAndIdentityPool, got \(escapeHatch)")
            return
        }
    }

    /// Test escape hatch with valid config for only identity pool
    ///
    /// - Given: A AWSCognitoAuthPlugin configured with only Identity Pool
    /// - When:
    ///    - I call getEscapeHatch
    /// - Then:
    ///    - I should get back only the Identity Pool client
    ///
    func testEscapeHatchWithOnlyIdentityPool() throws {
        let configuration: JSONValue = [
            "CredentialsProvider": [
                "CognitoIdentity": [
                    "Default": [
                        "PoolId": "xx",
                        "Region": "us-east-1"
                    ]
                ]
            ]
        ]
        let plugin = AWSCognitoAuthPlugin()
        try plugin.configure(using: configuration)
        let escapeHatch = plugin.getEscapeHatch()
        guard case .identityPool = escapeHatch else {
            XCTFail("Expected .identityPool, got \(escapeHatch)")
            return
        }
    }

    /// Test escape hatch with valid config for only user pool
    ///
    /// - Given: A AWSCognitoAuthPlugin configured with only User Pool
    /// - When:
    ///    - I call getEscapeHatch
    /// - Then:
    ///    - I should get only the User Pool client
    ///
    func testEscapeHatchWithOnlyUserPool() throws {
        let configuration: JSONValue = [
            "CognitoUserPool": [
                "Default": [
                    "PoolId": "xx",
                    "Region": "us-east-1",
                    "AppClientId": "xx",
                    "AppClientSecret": "xx"
                ]
            ]
        ]
        let plugin = AWSCognitoAuthPlugin()
        try plugin.configure(using: configuration)
        let escapeHatch = plugin.getEscapeHatch()
        guard case .userPool = escapeHatch else {
            XCTFail("Expected .userPool, got \(escapeHatch)")
            return
        }
    }
    
    /// Test escape hatch without a valid configuration
    ///
    /// - Given: A AWSCognitoAuthPlugin plugin without being configured
    /// - When:
    ///    - I call getEscapeHatch
    /// - Then:
    ///    - A fatalError is thrown
    ///
    func testEscapeHatchWithoutConfiguration() throws {
        let plugin = AWSCognitoAuthPlugin()
        try XCTAssertThrowFatalError {
            _ = plugin.getEscapeHatch()
        }
    }
}
