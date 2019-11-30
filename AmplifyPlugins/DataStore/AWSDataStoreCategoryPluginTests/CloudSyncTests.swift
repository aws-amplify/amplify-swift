//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import SQLite

import Combine
@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStoreCategoryPlugin

/// Tests that DataStore invokes proper API methods to fulfill cloud sync
class CloudSyncTests: XCTestCase {

    /// Convenience property to get easy access to the mock API plugin
    var apiPlugin: MockAPICategoryPlugin!

    /// Configured in `setUp`, but not actually passed to `Amplify.configure` since we are asserting startup behavior
    /// and so we need to wait to configure during the actual test.
    var amplifyConfig: AmplifyConfiguration!

    override func setUp() {
        super.setUp()

        Amplify.reset()
        Amplify.Logging.logLevel = .verbose

        apiPlugin = MockAPICategoryPlugin()

        let storageAdapter: SQLiteStorageEngineAdapter
        let storageEngine: StorageEngine
        do {
            let connection = try Connection(.inMemory)
            storageAdapter = try SQLiteStorageEngineAdapter(connection: connection)
            try storageAdapter.setUp(models: StorageEngine.systemModels)

            let syncEngine = try CloudSyncEngine(storageAdapter: storageAdapter)
            storageEngine = StorageEngine(storageAdapter: storageAdapter,
                                          syncEngine: syncEngine,
                                          isSyncEnabled: true)
        } catch {
            XCTFail(String(describing: error))
            return
        }

        let dataStorePublisher = DataStorePublisher()
        let dataStorePlugin = AWSDataStoreCategoryPlugin(modelRegistration: TestModelRegistration(),
                                                         storageEngine: storageEngine,
                                                         dataStorePublisher: dataStorePublisher)

        let apiConfig = APICategoryConfiguration(plugins: [apiPlugin.key: true])
        let dataStoreConfig = DataStoreCategoryConfiguration(plugins: [dataStorePlugin.key: true])
        amplifyConfig = AmplifyConfiguration(api: apiConfig, dataStore: dataStoreConfig)

        do {
            try Amplify.add(plugin: apiPlugin)
            try Amplify.add(plugin: dataStorePlugin)
        } catch {
            XCTFail(String(describing: error))
            return
        }
    }

    /// Tests that DataStore subscribes at startup. Test knows about the internals of the subscription--e.g., that
    /// DataStore sends 3 subscriptions for each model: one each for create, update, and delete.
    ///
    /// - Given: Amplify configured with an API
    /// - When:
    ///    - Amplify starts up
    /// - Then:
    ///    - The DataStore category starts subscriptions for each model
    func testDataStoreSubscribesAtStartup() throws {

        // Expect 3 subscriptions (create, update, delete) for each registered syncable model
        let createSubscriptionStarted = expectation(description: "Create subscription started")
        let updateSubscriptionStarted = expectation(description: "Update subscription started")
        let deleteSubscriptionStarted = expectation(description: "Delete subscription started")

        apiPlugin.listeners.append { message in
            switch message {
            case "subscribe(toAnyModelType:Post,subscriptionType:onCreate,listener:)":
                createSubscriptionStarted.fulfill()
            case "subscribe(toAnyModelType:Post,subscriptionType:onUpdate,listener:)":
                updateSubscriptionStarted.fulfill()
            case "subscribe(toAnyModelType:Post,subscriptionType:onDelete,listener:)":
                deleteSubscriptionStarted.fulfill()
            default:
                break
            }
        }

        try Amplify.configure(amplifyConfig)

        waitForExpectations(timeout: 1.0)
    }

    /// - Given: Amplify configured with an API
    /// - When:
    ///    - API receives an `onCreate` subscription to a model
    /// - Then:
    ///    - The listener is notified
    func testOnCreateNotifiesListener() throws {
        XCTFail("Not yet implemented")
    }

    /// - Given: Amplify configured with an API
    /// - When:
    ///    - API receives an `onCreate` subscription to a model
    /// - Then:
    ///    - The listener is notified
    func testOnCreateUpdatesLocalStore() throws {
        XCTFail("Not yet implemented")
    }

    /// - Given: Amplify configured with an API
    /// - When:
    ///    - API receives an `onUpdate` subscription to a model
    /// - Then:
    ///    - The listener is notified
    func testOnUpdateNotifiesListener() throws {
        XCTFail("Not yet implemented")
    }

    /// - Given: Amplify configured with an API
    /// - When:
    ///    - API receives an `onUpdate` subscription to a model
    /// - Then:
    ///    - The listener is notified
    func testOnUpdateUpdatesLocalStore() throws {
        XCTFail("Not yet implemented")
    }

    /// - Given: Amplify configured with an API
    /// - When:
    ///    - API receives an `onDelete` subscription to a model
    /// - Then:
    ///    - The listener is notified
    func testOnDeleteNotifiesListener() throws {
        XCTFail("Not yet implemented")
    }

    /// - Given: Amplify configured with an API
    /// - When:
    ///    - API receives an `onDelete` subscription to a model
    /// - Then:
    ///    - The listener is notified
    func testOnDeleteUpdatesLocalStore() throws {
        XCTFail("Not yet implemented")
    }

}
