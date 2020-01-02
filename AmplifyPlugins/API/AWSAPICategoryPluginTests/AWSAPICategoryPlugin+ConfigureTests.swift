//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AWSAPICategoryPlugin

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
            XCTFail("Failed to configure storage plugin: \(error)")
        }
    }

}
