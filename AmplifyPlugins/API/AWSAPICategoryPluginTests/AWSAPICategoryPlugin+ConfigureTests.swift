//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AWSAPICategoryPlugin

class AWSAPICategoryPluginConfigureTests {

    func testPluginKey() {
        let apiPlugin = AWSAPIPlugin()
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
