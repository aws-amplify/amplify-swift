//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AWSAPIPlugin

class AWSAPICategoryPluginConfigureTests: AWSAPICategoryPluginTestBase {

    func testPluginKey() {
        XCTAssertEqual(apiPlugin.key, "awsAPIPlugin")
    }

    func testExplicitConfiguration() throws {
        let configuration = AWSAPIPluginConfiguration(
            .init(apiName: "Test",
                  endpoint: "http://www.example.com",
                  endpointType: .rest,
                  region: "us-east-1",
                  authorizationType: .apiKey,
                  apiKey: "key"),
            .init(apiName: "TEST2",
                  endpoint: "http://www.example.com",
                  endpointType: .graphQL,
                  region: "us-east-2",
                  authorizationType: .amazonCognitoUserPools))
        
        let apiPlugin = AWSAPIPlugin(configuration: configuration)

        do {
            try apiPlugin.configure(using: nil)
        } catch {
            XCTFail("Failed to configure api plugin: \(error)")
        }
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
        do {
            try plugin.configure(using: nil)
            XCTFail("Api configuration should not succeed")
        } catch {
            guard let apiError = error as? PluginError,
                case .pluginConfigurationError = apiError else {
                    XCTFail("Should throw invalidConfiguration exception. But received \(error) ")
                    return
            }
        }
    }

}
