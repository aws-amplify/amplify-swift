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
class AWSDataStoreCategoryPluginIntegrationTests: XCTestCase {
    static let networkTimeout = TimeInterval(180)

    override func setUp() {
        super.setUp()

        Amplify.reset()
        Amplify.Logging.logLevel = .verbose

        ModelRegistry.register(modelType: AmplifyTestCommon.Post.self)
        ModelRegistry.register(modelType: AmplifyTestCommon.Comment.self)

        // TODO: Move this to an integ test config file
        let apiConfig = APICategoryConfiguration(plugins: [
            "awsAPICategoryPlugin": [
                "Default": [
                    "endpoint": "https://ldm7yqjfjngrjckbziumz5fxbe.appsync-api.us-west-2.amazonaws.com/graphql",
                    "region": "us-west-2",
                    "authorizationType": "API_KEY",
                    "apiKey": "da2-7jhi34lssbbmjclftlykznhw5m",
                    "endpointType": "GraphQL"
                ]
            ]
        ])

        let dataStoreConfig = DataStoreCategoryConfiguration(plugins: [
            "awsDataStoreCategoryPlugin": true
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

    /// - Given: An API-connected DataStore
    /// - When:
    ///    - I create a new model
    /// - Then:
    ///    - The DataStore dispatches an event to Hub
    func testCreateDispatchesToHub() throws {
        let content = "Original post content as of \(Date())"

        let originalPost = Post(title: "Test post from integration test",
                                content: content)

        let saveSyncResultReceived = expectation(description: "Sync result from save received")

        var token: UnsubscribeToken!
        token = Amplify.Hub.listen(
            to: .dataStore,
            eventName: HubPayload.EventName.DataStore.mutationSyncReceived
        ) { payload in
            defer {
                saveSyncResultReceived.fulfill()
            }

            guard let anyPost = payload.data as? AnyModel else {
                XCTFail("Can't cast payload data to AnyModel: \(payload)")
                return
            }

            XCTAssertEqual(anyPost["id"] as? String, originalPost.id)
            XCTAssertEqual(anyPost["title"] as? String, originalPost.title)
            XCTAssertEqual(anyPost["content"] as? String, originalPost.content)

            Amplify.Hub.removeListener(token)
        }

        guard try HubListenerTestUtilities.waitForListener(with: token, timeout: 5.0) else {
            XCTFail("Hub Listener not registered")
            return
        }

        Amplify.DataStore.save(originalPost) { _ in }

        wait(for: [saveSyncResultReceived],
             timeout: AWSDataStoreCategoryPluginIntegrationTests.networkTimeout)

    }

    /// - Given: An API-connected DataStore
    /// - When:
    ///    - I update an existing model
    /// - Then:
    ///    - The DataStore dispatches an event to Hub
    func testUpdateDispatchesToHub() throws {
        let originalContent = "Original post content as of \(Date())"
        let newContent = "Updated post content as of \(Date())"

        let saveSyncResultReceived = expectation(description: "Sync result from save received")
        let updateSyncResultReceived = expectation(description: "Sync result from update received")
        var token: UnsubscribeToken!
        token = Amplify.Hub.listen(
            to: .dataStore,
            eventName: HubPayload.EventName.DataStore.mutationSyncReceived
        ) { payload in
            guard let anyPost = payload.data as? AnyModel else {
                XCTFail("Could not cast payload.data to AnyModel: \(String(describing: payload.data))")
                return
            }

            if anyPost["content"] as? String == originalContent {
                saveSyncResultReceived.fulfill()
                XCTAssertEqual(anyPost["_version"] as? Int, 1)
            } else if anyPost["content"] as? String == newContent {
                updateSyncResultReceived.fulfill()
                XCTAssertEqual(anyPost["_version"] as? Int, 2)
            }
        }

        guard try HubListenerTestUtilities.waitForListener(with: token, timeout: 5.0) else {
            XCTFail("Hub Listener not registered")
            return
        }

        let originalPost = Post(title: "Test post from integration test",
                                content: originalContent)

        Amplify.DataStore.save(originalPost) { _ in }

        wait(for: [saveSyncResultReceived],
             timeout: AWSDataStoreCategoryPluginIntegrationTests.networkTimeout)

        // Technically we'd pull the version from the sync metadata store, but for this test, we'll hardcode it to 1
        let updatedPost = Post(id: originalPost.id,
                               title: originalPost.title,
                               content: newContent,
                               createdAt: originalPost.createdAt,
                               updatedAt: originalPost.updatedAt,
                               rating: originalPost.rating,
                               draft: originalPost.draft,
                               _version: 1)

        Amplify.DataStore.save(updatedPost) { _ in }

        wait(for: [updateSyncResultReceived],
             timeout: AWSDataStoreCategoryPluginIntegrationTests.networkTimeout)

        Amplify.Hub.removeListener(token)
    }

}
