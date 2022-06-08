//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import SQLite

import Combine
@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStorePlugin

/// Tests that DataStore invokes proper API methods to fulfill remote sync
class RemoteSyncAPIInvocationTests: XCTestCase {

    /// Convenience property to get easy access to the mock API plugin
    var apiPlugin: MockAPICategoryPlugin!

    /// Configured in `setUp`, but not actually passed to `Amplify.configure` since we are asserting startup behavior
    /// and so we need to wait to configure during the actual test.
    var amplifyConfig: AmplifyConfiguration!

    override func setUp() {
        super.setUp()

        // Allows any previously-running API calls to finish up before unconfiguring the category
        sleep(2)
        Amplify.reset()
        Amplify.Logging.logLevel = .warn

        apiPlugin = MockAPICategoryPlugin()

        let storageAdapter: SQLiteStorageEngineAdapter
        let storageEngine: StorageEngine
        let validAPIPluginKey = "MockAPICategoryPlugin"
        let validAuthPluginKey = "MockAuthCategoryPlugin"
        do {
            let connection = try Connection(.inMemory)
            storageAdapter = try SQLiteStorageEngineAdapter(connection: connection)
            try storageAdapter.setUp(modelSchemas: StorageEngine.systemModelSchemas)

            let syncEngine = try RemoteSyncEngine(storageAdapter: storageAdapter,
                                                  dataStoreConfiguration: .default)
            storageEngine = StorageEngine(storageAdapter: storageAdapter,
                                          dataStoreConfiguration: .default,
                                          syncEngine: syncEngine,
                                          validAPIPluginKey: validAPIPluginKey,
                                          validAuthPluginKey: validAuthPluginKey)
        } catch {
            XCTFail(String(describing: error))
            return
        }
        let storageEngineBehaviorFactory: StorageEngineBehaviorFactory = {_, _, _, _, _, _  throws in
            return storageEngine
        }
        let dataStorePublisher = DataStorePublisher()
        let dataStorePlugin = AWSDataStorePlugin(modelRegistration: TestModelRegistration(),
                                                 storageEngineBehaviorFactory: storageEngineBehaviorFactory,
                                                 dataStorePublisher: dataStorePublisher,
                                                 validAPIPluginKey: validAPIPluginKey,
                                                 validAuthPluginKey: validAuthPluginKey)

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
            guard message.contains("subscribe(request:listener:)") else {
                return
            }

            if message.contains("onCreatePost ") {
                createSubscriptionStarted.fulfill()
            } else if message.contains("onUpdatePost ") {
                updateSubscriptionStarted.fulfill()
            } else if message.contains("onDeletePost ") {
                deleteSubscriptionStarted.fulfill()
            }
        }

        try Amplify.configure(amplifyConfig)
        Amplify.DataStore.start(completion: {_ in})
        waitForExpectations(timeout: 1.0)
    }
    // TODO: Implement the test below

    /// - Given: Amplify configured with an API
    /// - When:
    ///    - API receives an `onCreate` subscription to a model
    /// - Then:
    ///    - The listener is notified
    func testOnCreateNotifiesListener() throws {
        // throw XCTSkip("Not yet implemented")
    }

    /// - Given: Amplify configured with an API
    /// - When:
    ///    - API receives an `onCreate` subscription to a model
    /// - Then:
    ///    - The listener is notified
    func testOnCreateUpdatesLocalStore() throws {
        // throw XCTSkip("Not yet implemented")
    }

    /// - Given: Amplify configured with an API
    /// - When:
    ///    - API receives an `onUpdate` subscription to a model
    /// - Then:
    ///    - The listener is notified
    func testOnUpdateNotifiesListener() throws {
        // throw XCTSkip("Not yet implemented")
    }

    /// - Given: Amplify configured with an API
    /// - When:
    ///    - API receives an `onUpdate` subscription to a model
    /// - Then:
    ///    - The listener is notified
    func testOnUpdateUpdatesLocalStore() throws {
        // throw XCTSkip("Not yet implemented")
    }

    /// - Given: Amplify configured with an API
    /// - When:
    ///    - API receives an `onDelete` subscription to a model
    /// - Then:
    ///    - The listener is notified
    func testOnDeleteNotifiesListener() throws {
        // throw XCTSkip("Not yet implemented")
    }

    /// - Given: Amplify configured with an API
    /// - When:
    ///    - API receives an `onDelete` subscription to a model
    /// - Then:
    ///    - The listener is notified
    func testOnDeleteUpdatesLocalStore() throws {
       // throw XCTSkip("Not yet implemented")
    }

}
