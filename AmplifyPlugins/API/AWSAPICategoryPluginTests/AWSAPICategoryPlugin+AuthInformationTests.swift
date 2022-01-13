//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AWSAPIPlugin

class AWSAPICategoryPluginAuthInformationTests: AWSAPICategoryPluginTestBase {

    func testDefaultAuthTypeForApiName() throws {
        let apiPlugin = AWSAPIPlugin()
        let apiPluginConfig: JSONValue = [
            "api1": [
                "endpoint": "http://www.example.com",
                "authorizationType": "API_KEY",
                "apiKey": "SpecialApiKey33",
                "endpointType": "REST"
            ],
            "api2": [
                "endpoint": "http://www.example.com",
                "authorizationType": "AMAZON_COGNITO_USER_POOLS",
                "endpointType": "GraphQL"
            ]
        ]

        try apiPlugin.configure(using: apiPluginConfig)
        let authType1 = try apiPlugin.defaultAuthType(for: "api1")
        XCTAssertEqual(authType1, .apiKey)
        let authTypeFromDefault = try apiPlugin.defaultAuthType()
        XCTAssertEqual(authTypeFromDefault, .amazonCognitoUserPools)
        let authType2 = try apiPlugin.defaultAuthType(for: "api2")
        XCTAssertEqual(authType2, .amazonCognitoUserPools)
    }

    func testDefaultAuthType() throws {
        let apiPlugin = AWSAPIPlugin()
        let apiPluginConfig: JSONValue = [
            "api1": [
                "endpoint": "http://www.example.com",
                "authorizationType": "API_KEY",
                "apiKey": "SpecialApiKey33",
                "endpointType": "REST"
            ]
        ]

        try apiPlugin.configure(using: apiPluginConfig)
        let authType = try apiPlugin.defaultAuthType()
        XCTAssertEqual(authType, .apiKey)
    }
}
