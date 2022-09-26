//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AWSCognitoAuthPlugin

class AWSCognitoAuthPluginConfigTests: XCTestCase {

    override func tearDown() {
        Amplify.reset()
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

        let categoryConfig = AuthCategoryConfiguration(plugins: ["NonExistentPlugin": true])
        let amplifyConfig = AmplifyConfiguration(auth: categoryConfig)
        do {
            try Amplify.configure(amplifyConfig)
            XCTFail("Should have thrown a pluginConfigurationError if not supplied with a plugin-specific config.")
        } catch {
            guard case PluginError.pluginConfigurationError = error else {
                XCTFail("Should have thrown a pluginConfigurationError if not supplied with a plugin-specific config.")
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
                    "AppClientSecret": "xx",
                    "Endpoint": "example.org"]]
            ]
        ])
        let amplifyConfig = AmplifyConfiguration(auth: categoryConfig)
        do {
            try Amplify.configure(amplifyConfig)
        } catch {
            XCTFail("Should not throw error. \(error)")
        }
    }

    /// Test Auth configuration with valid config for only identity pool
    ///
    /// - Given: Given valid config for only identity pool
    /// - When:
    ///    - I configure auth with the given configuration
    /// - Then:
    ///    - I should not get any error while configuring auth
    ///
    func testConfigWithOnlyIdentityPool() throws {
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

        let categoryConfig = AuthCategoryConfiguration(plugins: [
            "awsCognitoAuthPlugin": [
                "CognitoUserPool": ["Default": [
                    "PoolId": "xx",
                    "Region": "us-east-1",
                    "AppClientId": "xx",
                    "AppClientSecret": "xx",
                    "Endpoint": "example.org"]]
            ]
        ])
        let amplifyConfig = AmplifyConfiguration(auth: categoryConfig)
        do {
            try Amplify.configure(amplifyConfig)
        } catch {
            XCTFail("Should not throw error. \(error)")
        }
    }

    /// Test Auth configuration with invalid config for user pool and identity pool
    ///
    /// - Given: Given invalid config for user pool and identity pool
    /// - When:
    ///    - I configure auth with the given configuration
    /// - Then:
    ///    - I should get an exception.
    ///
    func testConfigWithInvalidUserPoolAndIdentityPool() throws {
        let plugin = AWSCognitoAuthPlugin()
        try Amplify.add(plugin: plugin)

        let categoryConfig = AuthCategoryConfiguration(plugins: [
            "awsCognitoAuthPlugin": [
                "CredentialsProvider": ["CognitoIdentity": ["Default":
                    ["xx": "xx",
                     "xx2": "us-east-1"]
                    ]],
                "CognitoUserPool": ["Default": [
                    "xx": "xx",
                    "xx2": "us-east-1"
                    ]]
            ]
        ])
        let amplifyConfig = AmplifyConfiguration(auth: categoryConfig)
        do {
            try Amplify.configure(amplifyConfig)
            XCTFail("Should have thrown a AuthError.configuration error if both cognito service config are invalid")
        } catch {
            guard case AuthError.configuration = error else {
                XCTFail("Should have thrown a AuthError.configuration error if both cognito service config are invalid")
                return
            }
        }
    }

    /// Test Auth configuration with endpoint url containing scheme for user pool
    ///
    /// - Given: Given invalid config with endpoint url containing scheme for user pool
    /// - When:
    ///    - I configure auth with the given configuration
    /// - Then:
    ///    - I should get an exception.
    ///
    func testConfigWithInvalidUserPoolEndpointWithScheme() throws {
        let plugin = AWSCognitoAuthPlugin()
        try Amplify.add(plugin: plugin)

        let categoryConfig = AuthCategoryConfiguration(plugins: [
            "awsCognitoAuthPlugin": [
                "CognitoUserPool": ["Default": [
                    "PoolId": "xx",
                    "Region": "us-east-1",
                    "AppClientId": "xx",
                    "AppClientSecret": "xx",
                    "Endpoint": "https://example.org"]]
            ]
        ])

        let amplifyConfig = AmplifyConfiguration(auth: categoryConfig)
        do {
            try Amplify.configure(amplifyConfig)
            XCTFail("Should have thrown a AuthError.configuration error for invalid endpoint url")
        } catch {
            guard case AuthError.configuration = error else {
                XCTFail("Should have thrown a AuthError.configuration error for invalid endpoint url")
                return
            }
        }
    }

    /// Test Auth configuration with endpoint url containing path for user pool
    ///
    /// - Given: Given invalid config with endpoint url containing path for user pool
    /// - When:
    ///    - I configure auth with the given configuration
    /// - Then:
    ///    - I should get an exception.
    ///
    func testConfigWithInvalidUserPoolEndpointWithPath() throws {
        let plugin = AWSCognitoAuthPlugin()
        try Amplify.add(plugin: plugin)

        let categoryConfig = AuthCategoryConfiguration(plugins: [
            "awsCognitoAuthPlugin": [
                "CognitoUserPool": ["Default": [
                    "PoolId": "xx",
                    "Region": "us-east-1",
                    "AppClientId": "xx",
                    "AppClientSecret": "xx",
                    "Endpoint": "example.org/path"]]
            ]
        ])

        let amplifyConfig = AmplifyConfiguration(auth: categoryConfig)
        do {
            try Amplify.configure(amplifyConfig)
            XCTFail("Should have thrown a AuthError.configuration error for invalid endpoint url")
        } catch {
            guard case AuthError.configuration = error else {
                XCTFail("Should have thrown a AuthError.configuration error for invalid endpoint url")
                return
            }
        }
    }

    /// Test Auth configuration with nil value
    ///
    /// - Given: Given a nil config for user pool and identity pool
    /// - When:
    ///    - I configure auth with the given configuration
    /// - Then:
    ///    - I should get an exception.
    ///
    func testConfigureFailureForNilConfiguration() throws {
        let plugin = AWSCognitoAuthPlugin()
        do {
            try plugin.configure(using: nil)
            XCTFail("Auth configuration should not succeed")
        } catch {
            guard let pluginError = error as? PluginError,
                case .pluginConfigurationError = pluginError else {
                    XCTFail("Should throw invalidConfiguration exception. But received \(error) ")
                    return
            }
        }
    }

    /// Test Auth configuration order of execution of apis
    ///
    /// - Given: Given valid config for user pool and identity pool
    /// - When:
    ///    - I call different auth apis after configuration
    /// - Then:
    ///    - I should get the result back based on the order in which the calls where made.
    ///
    func testAPIExecutionOrder() throws {
        let plugin = AWSCognitoAuthPlugin()
        try Amplify.add(plugin: plugin)

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
                    "AppClientSecret": "xx",
                    "Endpoint": "example.org"]]
            ]
        ])
        let amplifyConfig = AmplifyConfiguration(auth: categoryConfig)
        do {
            try Amplify.configure(amplifyConfig)
        } catch {
            XCTFail("Should not throw error. \(error)")
        }

        let signUpExpectation = expectation(description: "Should receive a result")
        _ = plugin.signUp(username: "mockUsername", password: "", options: nil) { _ in
            signUpExpectation.fulfill()
        }

        var expectationList = [signUpExpectation]

        for _ in 1 ... 50 {
            let fetchSessionExpectation = expectation(description: "Should receive a result")
            _ = plugin.fetchAuthSession(options: nil) { _ in
                fetchSessionExpectation.fulfill()
            }
            expectationList.append(fetchSessionExpectation)
        }

        let signUpExpectation2 = expectation(description: "Should receive a result")
        DispatchQueue.global().async {

            _ = plugin.signUp(username: "mockUsername", password: "", options: nil) { _ in
                signUpExpectation2.fulfill()
            }
        }
        expectationList.append(signUpExpectation2)
        wait(for: expectationList, timeout: 10, enforceOrder: true)
    }
    
    func testUserNetworkPreferencesForIdentityPoolService() throws {
        let networkPreferences = AWSCognitoNetworkPreferences(maxRetryCount: 0,
                                                              timeoutIntervalForRequest: 30,
                                                              timeoutIntervalForResource: 30)
        let plugin = AWSCognitoAuthPlugin(networkPreferences: networkPreferences)

        let json = JSONValue(dictionaryLiteral: ("CredentialsProvider",
                                                  .init(dictionaryLiteral: ("CognitoIdentity",
                                                                            .init(dictionaryLiteral: ("Default",
                                                                                                      .init(dictionaryLiteral: ("Region", "us-east-1"))))))))
        let identityPoolConfig = plugin.identityPoolServiceConfiguration(from: json)

        XCTAssertEqual(identityPoolConfig?.maxRetryCount, networkPreferences.maxRetryCount)
        XCTAssertEqual(identityPoolConfig?.timeoutIntervalForResource, networkPreferences.timeoutIntervalForResource)
        XCTAssertEqual(identityPoolConfig?.timeoutIntervalForRequest, networkPreferences.timeoutIntervalForRequest)
    }
    
    func testUserNetworkPreferencesForUserPoolService() throws {
        let networkPreferences = AWSCognitoNetworkPreferences(maxRetryCount: 0,
                                                              timeoutIntervalForRequest: 30,
                                                              timeoutIntervalForResource: 30)
        let plugin = AWSCognitoAuthPlugin(networkPreferences: networkPreferences)
        
        let json = JSONValue(dictionaryLiteral: ("CognitoUserPool",
                                                 .init(dictionaryLiteral: ("Default",
                                                                           .init(dictionaryLiteral: ("Region", "us-east-1"))))))
        let identityPoolConfig = try plugin.userPoolServiceConfiguration(from: json)

        XCTAssertEqual(identityPoolConfig?.maxRetryCount, networkPreferences.maxRetryCount)
        XCTAssertEqual(identityPoolConfig?.timeoutIntervalForResource, networkPreferences.timeoutIntervalForResource)
        XCTAssertEqual(identityPoolConfig?.timeoutIntervalForRequest, networkPreferences.timeoutIntervalForRequest)
    }
    
    func testNoUserPreferences() throws {
        let plugin = AWSCognitoAuthPlugin()
        XCTAssertNil(plugin.networkPreferences)
    }
}
