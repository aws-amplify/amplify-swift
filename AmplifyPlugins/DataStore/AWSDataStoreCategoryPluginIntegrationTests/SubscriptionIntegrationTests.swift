//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

import AWSAPICategoryPlugin
import AWSMobileClient

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStoreCategoryPlugin

// TODO: Delete mutation events from the database so that this can be run multiple times without having to remove the
// app from the device/simulator
// swiftlint:disable:next type_name
class SubscriptionIntegrationTests: XCTestCase {
    static let networkTimeout = TimeInterval(180)

    override func setUp() {
        super.setUp()

        Amplify.reset()
        Amplify.Logging.logLevel = .verbose

        ModelRegistry.register(modelType: AmplifyTestCommon.Post.self)
        ModelRegistry.register(modelType: AmplifyTestCommon.Comment.self)

        // TODO: Move this to an integ test config file
        let apiConfig = APICategoryConfiguration(plugins: [
            "AWSAPICategoryPlugin": [
                "Default": [
                    "Endpoint": "https://ldm7yqjfjngrjckbziumz5fxbe.appsync-api.us-west-2.amazonaws.com/graphql",
                    "Region": "us-west-2",
                    "AuthorizationType": "API_KEY",
                    "ApiKey": "da2-7jhi34lssbbmjclftlykznhw5m",
                    "EndpointType": "GraphQL"
                ]
            ]
        ])

        let dataStoreConfig = DataStoreCategoryConfiguration(plugins: [
            "AWSDataStoreCategoryPlugin": true
        ])

        let amplifyConfig = AmplifyConfiguration(api: apiConfig, dataStore: dataStoreConfig)

        do {
            try Amplify.add(plugin: AWSAPICategoryPlugin())
            try Amplify.add(plugin: AWSDataStoreCategoryPlugin())
            try Amplify.configure(amplifyConfig)
        } catch {
            XCTFail(String(describing: error))
            return
        }
    }

    override func tearDown() {
        Amplify.reset()
    }

    func testSubscribeAtStartup() throws {
    }

}
