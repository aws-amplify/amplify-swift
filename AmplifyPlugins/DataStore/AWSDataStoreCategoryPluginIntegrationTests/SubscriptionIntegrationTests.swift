//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

import AmplifyPlugins
import AWSMobileClient

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStoreCategoryPlugin

// TODO: Delete mutation events from the database so that this can be run multiple times without having to remove the
// app from the device/simulator
// swiftlint:disable:next type_name
class SubscriptionIntegrationTests: XCTestCase {
    let networkTimeout = TimeInterval(180)

    var amplifyConfig: AmplifyConfiguration!

    // NOTE: This setUp does not invoke `Amplify.configure()`, to ensure the local tests have control over the time at
    // which sync startup happens.
    override func setUp() {
        super.setUp()

        Amplify.reset()
        Amplify.Logging.logLevel = .verbose

        ModelRegistry.register(modelType: Post.self)

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

        amplifyConfig = AmplifyConfiguration(api: apiConfig, dataStore: dataStoreConfig)

        do {
            try Amplify.add(plugin: AWSAPICategoryPlugin())
            try Amplify.add(plugin: AWSDataStoreCategoryPlugin())
        } catch {
            XCTFail(String(describing: error))
            return
        }
    }

    override func tearDown() {
        Amplify.reset()
    }

    /// - Given: An API-connected DataStore
    /// - When:
    ///    - I start Amplify
    /// - Then:
    ///    - I receive subscriptions from other systems for syncable models
    func testSubscribeAtStartup() throws {
        try Amplify.configure(amplifyConfig)

        let mutationReceived = expectation(description: "Mutation received")
        let sub = Amplify.DataStore.publisher(for: Post.self)
            .sink(receiveCompletion: { completion in
            }, receiveValue: { mutationEvent in
                mutationReceived.fulfill()
            })

        // Simulate another system by creating, updating, and deleting a model directly via the API
//        let createdViaAPI = expectation(description: "Post created")
//        let updatedViaAPI = expectation(description: "Post updated")
//        let deletedViaAPI = expectation(description: "Post deleted")

        wait(for: [mutationReceived], timeout: networkTimeout)
        sub.cancel()
    }

}
