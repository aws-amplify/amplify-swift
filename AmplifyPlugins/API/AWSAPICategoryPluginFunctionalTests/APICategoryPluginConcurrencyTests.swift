//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSAPICategoryPlugin

class APICategoryPluginConcurrencyTests: XCTestCase {

    override func setUp() {
        Amplify.reset()
        Amplify.Logging.logLevel = .verbose
        ModelRegistry.register(modelType: AmplifyTestCommon.Post.self)
        ModelRegistry.register(modelType: AmplifyTestCommon.Comment.self)

        let apiConfig = APICategoryConfiguration(plugins: [
            "awsAPICategoryPlugin": [
                "default": [
                    "endpoint": "https://xxx.appsync-api.us-west-2.amazonaws.com/graphql",
                    "region": "us-west-2",
                    "authorizationType": "API_KEY",
                    "apiKey": "da2-xxx",
                    "endpointType": "GraphQL"
                ]
            ]
        ])

        let amplifyConfig = AmplifyConfiguration(api: apiConfig)
        do {
            try Amplify.add(plugin: AWSAPIPlugin())
            try Amplify.configure(amplifyConfig)
        } catch {
            XCTFail("Error during setup: \(error)")
        }
    }

    /// This test should ensure the plugin provides a stable platform for establishing multiple subscriptions
    /// concurrently on separate queues. It should also be run with Thread Sanitizer enabled to test for Data Race
    /// conditions.
    func testConcurrentSubscriptions() {
        XCTFail("Not yet implemented")
    }
}
