//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AWSAPICategoryPlugin

class AWSAPICategoryPluginConfigureTests: AWSAPICategoryPluginTestBase {

    func testPluginKey() {
        XCTAssertEqual(apiPlugin.key, "AWSAPICategoryPlugin")
    }

    func testConfigureSuccess() throws {
        let apiPlugin = AWSAPICategoryPlugin()
        let apiPluginConfig: JSONValue = [
            "Test": [
                "Endpoint": "http://www.example.com",
                "AuthorizationType": "API_KEY",
                "ApiKey": "SpecialApiKey33"
            ],
            "Test2": [
                "Endpoint": "http://www.example.com",
                "AuthorizationType": "AMAZON_COGNITO_USER_POOLS"
            ]
        ]

        do {
            try apiPlugin.configure(using: apiPluginConfig)
        } catch {
            XCTFail("Failed to configure storage plugin: \(error)")
        }
    }

}
