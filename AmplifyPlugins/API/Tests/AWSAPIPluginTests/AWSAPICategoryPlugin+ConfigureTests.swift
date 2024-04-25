//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@_spi(InternalAmplifyConfiguration) @testable import Amplify
@testable import AWSAPIPlugin

class AWSAPICategoryPluginConfigureTests: AWSAPICategoryPluginTestBase {

    func testPluginKey() {
        XCTAssertEqual(apiPlugin.key, "awsAPIPlugin")
    }

    func testConfigureSuccess() throws {
        let apiPlugin = AWSAPIPlugin()
        let apiPluginConfig: JSONValue = [
            "Test": [
                "endpoint": "http://www.example.com",
                "authorizationType": "API_KEY",
                "apiKey": "SpecialApiKey33",
                "endpointType": "REST"
            ],
            "Test2": [
                "endpoint": "http://www.example.com",
                "authorizationType": "AMAZON_COGNITO_USER_POOLS",
                "endpointType": "GraphQL"
            ]
        ]

        do {
            try apiPlugin.configure(using: apiPluginConfig)
        } catch {
            XCTFail("Failed to configure api plugin: \(error)")
        }
    }

    func testConfigureFailureForNilConfiguration() throws {
        let plugin = AWSAPIPlugin()
        XCTAssertThrowsError(try plugin.configure(using: nil)) { error in
            guard let apiError = error as? PluginError,
                case .pluginConfigurationError = apiError else {
                    XCTFail("Should throw invalidConfiguration exception. But received \(error) ")
                    return
            }
        }
    }

    /// Configure with data category and assert expected endpoint configured.
    func testConfigureAmplifyOutputs() throws {
        let config = AmplifyOutputsData(data: .init(
            awsRegion: "us-east-1",
            url: "http://www.example.com",
            modelIntrospection: nil,
            apiKey: "apiKey123",
            defaultAuthorizationType: .amazonCognitoUserPools,
            authorizationTypes: [.apiKey, .awsIAM]))

        let plugin = AWSAPIPlugin()
        try plugin.configure(using: config)
        guard let endpoint = plugin.pluginConfig.endpoints.first else {
            XCTFail("Missing endpoint configuration")
            return
        }
        XCTAssertEqual(endpoint.key, AWSAPIPlugin.defaultGraphQLAPI)
        XCTAssertEqual(endpoint.value.name, AWSAPIPlugin.defaultGraphQLAPI)
        XCTAssertEqual(endpoint.value.endpointType, .graphQL)
        XCTAssertEqual(endpoint.value.apiKey, "apiKey123")
        XCTAssertEqual(endpoint.value.baseURL, URL(string: "http://www.example.com"))
        XCTAssertEqual(endpoint.value.region, "us-east-1")
        XCTAssertEqual(endpoint.value.authorizationType, .amazonCognitoUserPools)
    }

    /// Configure with missing data category and throws plugin configuration error.
    func testConfigureAmplifyOutputs_DataCategoryMissing() throws {
        let config = AmplifyOutputsData(data: nil)

        let plugin = AWSAPIPlugin()
        XCTAssertThrowsError(try plugin.configure(using: config)) { error in
            guard let apiError = error as? PluginError,
                case .pluginConfigurationError = apiError else {
                    XCTFail("Should throw invalidConfiguration exception. But received \(error) ")
                    return
            }
        }
    }

    /// Configuring `.apiKey` auth without the `apiKey` value will fail.
    func testConfigureAmplifyOutputs_APIKeyMissing() throws {
        let config = AmplifyOutputsData(data: .init(
            awsRegion: "us-east-1",
            url: "http://www.example.com",
            modelIntrospection: nil,
            apiKey: nil,
            defaultAuthorizationType: .apiKey,
            authorizationTypes: []))

        let plugin = AWSAPIPlugin()
        XCTAssertThrowsError(try plugin.configure(using: config)) { error in
            guard let apiError = error as? PluginError,
                case .pluginConfigurationError = apiError else {
                    XCTFail("Should throw invalidConfiguration exception. But received \(error) ")
                    return
            }
        }
    }
}
