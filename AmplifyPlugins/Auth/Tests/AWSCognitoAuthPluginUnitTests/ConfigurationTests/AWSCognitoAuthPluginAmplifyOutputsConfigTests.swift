//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@_spi(InternalAmplifyConfiguration) @testable import Amplify
@testable import AWSCognitoAuthPlugin

class AWSCognitoAuthPluginAmplifyOutputsConfigTests: XCTestCase {

    override func tearDown() async throws {
        await Amplify.reset()
    }

    /// Test Auth configuration with invalid config for auth
    ///
    /// - Given: Given an invalid auth config
    /// - When:
    ///    - I configure auth with the invalid configuration
    /// - Then:
    ///    - I should get an exception.
    ///
    func testThrowsOnMissingConfig() throws {
        let plugin = AWSCognitoAuthPlugin()
        try Amplify.add(plugin: plugin)

        let amplifyConfig = AmplifyOutputsData()

        do {
            try Amplify.configure(amplifyConfig)
        } catch {
            guard case AuthError.configuration = error else {
                XCTFail("Should have thrown an AuthError.configuration if not supplied with auth config.")
                return
            }
        }
    }

    /// Test Auth configuration with valid config for user pool and identity pool
    ///
    /// - Given: Given valid config for user pool and identity pool
    /// - When:
    ///    - I configure auth with the given configuration
    /// - Then:
    ///    - I should not get any error while configuring auth
    ///
    func testConfigWithUserPoolAndIdentityPool() throws {
        let plugin = AWSCognitoAuthPlugin()
        try Amplify.add(plugin: plugin)

        let amplifyConfig = AmplifyOutputsData(auth: .init(
                awsRegion: "us-east-1",
                userPoolId: "xx",
                userPoolClientId: "xx",
                identityPoolId: "xx"))
        do {
            try Amplify.configure(amplifyConfig)
        } catch {
            XCTFail("Should not throw error. \(error)")
        }
    }

    /// Test Auth configuration with valid config for only user pool
    ///
    /// - Given: Given valid config for only user pool
    /// - When:
    ///    - I configure auth with the given configuration
    /// - Then:
    ///    - I should not get any error while configuring auth
    ///
    func testConfigWithOnlyUserPool() throws {
        let plugin = AWSCognitoAuthPlugin()
        try Amplify.add(plugin: plugin)

        let amplifyConfig = AmplifyOutputsData(auth: .init(
                awsRegion: "us-east-1",
                userPoolId: "xx",
                userPoolClientId: "xx"))
        do {
            try Amplify.configure(amplifyConfig)
        } catch {
            XCTFail("Should not throw error. \(error)")
        }
    }

    /// Test Auth configuration with valid config for user pool and identity pool, with network preferences
    ///
    /// - Given: Given valid config for user pool and identity pool, and network preferences
    /// - When:
    ///    - I configure auth with the given configuration and network preferences
    /// - Then:
    ///    - I should not get any error while configuring auth
    ///
    func testConfigWithUserPoolAndIdentityPoolWithNetworkPreferences() throws {
        let plugin = AWSCognitoAuthPlugin(
            networkPreferences: .init(
                maxRetryCount: 2,
                timeoutIntervalForRequest: 60,
                timeoutIntervalForResource: 60))
        try Amplify.add(plugin: plugin)

        let amplifyConfig = AmplifyOutputsData(auth: .init(
                awsRegion: "us-east-1",
                userPoolId: "xx",
                userPoolClientId: "xx",
                identityPoolId: "xx"))

        do {
            try Amplify.configure(amplifyConfig)

            let escapeHatch = plugin.getEscapeHatch()
            guard case .userPoolAndIdentityPool(let userPoolClient, let identityPoolClient) = escapeHatch else {
                XCTFail("Expected .userPool, got \(escapeHatch)")
                return
            }
            XCTAssertNotNil(userPoolClient)
            XCTAssertNotNil(identityPoolClient)

        } catch {
            XCTFail("Should not throw error. \(error)")
        }
    }
    
    /// Test Auth configuration with valid config for user pool and identity pool, with secure storage preferences
    ///
    /// - Given: Given valid config for user pool and identity pool with secure storage preferences
    /// - When:
    ///    - I configure auth with the given configuration and secure storage preferences
    /// - Then:
    ///    - I should not get any error while configuring auth
    ///
    func testConfigWithUserPoolAndIdentityPoolWithSecureStoragePreferences() throws {
        let plugin = AWSCognitoAuthPlugin(
            secureStoragePreferences: .init(
                accessGroup: AccessGroup(name: "xx")
            )
        )
        try Amplify.add(plugin: plugin)

        let amplifyConfig = AmplifyOutputsData(auth: .init(
                awsRegion: "us-east-1",
                userPoolId: "xx",
                userPoolClientId: "xx",
                identityPoolId: "xx"))

        do {
            try Amplify.configure(amplifyConfig)

            let escapeHatch = plugin.getEscapeHatch()
            guard case .userPoolAndIdentityPool(let userPoolClient, let identityPoolClient) = escapeHatch else {
                XCTFail("Expected .userPool, got \(escapeHatch)")
                return
            }
            XCTAssertNotNil(userPoolClient)
            XCTAssertNotNil(identityPoolClient)

        } catch {
            XCTFail("Should not throw error. \(error)")
        }
    }
    
    /// Test Auth configuration with valid config for user pool and identity pool, with network preferences and secure storage preferences
    ///
    /// - Given: Given valid config for user pool and identity pool, network preferences, and secure storage preferences
    /// - When:
    ///    - I configure auth with the given configuration, network preferences, and secure storage preferences
    /// - Then:
    ///    - I should not get any error while configuring auth
    ///
    func testConfigWithUserPoolAndIdentityPoolWithNetworkPreferencesAndSecureStoragePreferences() throws {
        let plugin = AWSCognitoAuthPlugin(
            networkPreferences: .init(
                maxRetryCount: 2,
                timeoutIntervalForRequest: 60,
                timeoutIntervalForResource: 60),
            secureStoragePreferences: .init(
                accessGroup: AccessGroup(name: "xx")
            )
        )
        try Amplify.add(plugin: plugin)

        let amplifyConfig = AmplifyOutputsData(auth: .init(
                awsRegion: "us-east-1",
                userPoolId: "xx",
                userPoolClientId: "xx",
                identityPoolId: "xx"))

        do {
            try Amplify.configure(amplifyConfig)

            let escapeHatch = plugin.getEscapeHatch()
            guard case .userPoolAndIdentityPool(let userPoolClient, let identityPoolClient) = escapeHatch else {
                XCTFail("Expected .userPool, got \(escapeHatch)")
                return
            }
            XCTAssertNotNil(userPoolClient)
            XCTAssertNotNil(identityPoolClient)

        } catch {
            XCTFail("Should not throw error. \(error)")
        }
    }
}
