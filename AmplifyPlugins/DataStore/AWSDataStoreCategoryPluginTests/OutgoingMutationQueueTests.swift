//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import SQLite

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStoreCategoryPlugin

class OutgoingMutationQueueTests: XCTestCase {

    var apiPlugin: MockAPICategoryPlugin!

    override func setUp() {
        Amplify.reset()

        let apiConfig = APICategoryConfiguration(plugins: [
            "MockAPICategoryPlugin": true
        ])

        let dataStoreConfig = DataStoreCategoryConfiguration(plugins: [
            "awsDataStoreCategoryPlugin": true
        ])

        let amplifyConfig = AmplifyConfiguration(api: apiConfig, dataStore: dataStoreConfig)

        apiPlugin = MockAPICategoryPlugin()

        do {
            let connection = try Connection(.inMemory)
            let storageAdapter = SQLiteStorageEngineAdapter(connection: connection)

            let syncEngineFactory: CloudSyncEngineBehavior.Factory = { adapter in
                CloudSyncEngine(storageAdapter: adapter)
            }
            let storageEngine = StorageEngine(adapter: storageAdapter,
                                              syncEngineFactory: syncEngineFactory)

            let publisher = DataStorePublisher()
            let dataStorePlugin = AWSDataStoreCategoryPlugin(modelRegistration: TestModelRegistration(),
                                                             storageEngine: storageEngine,
                                                             dataStorePublisher: publisher)

            try Amplify.add(plugin: apiPlugin)
            try Amplify.add(plugin: dataStorePlugin)
            try Amplify.configure(amplifyConfig)
        } catch {
            XCTFail(String(describing: error))
        }
    }

    /// - Given: A sync-configured DataStore
    /// - When:
    ///    - I invoke DataStore.save() for a new model
    /// - Then:
    ///    - The outgoing mutation queue sends a create mutation
    func testMutationQueueCreateSendsSync() throws {
        let syncStarted = expectation(description: "Sync started")
        let token = Amplify.Hub.listen(to: .dataStore,
                                       eventName: HubPayload.EventName.DataStore.syncStarted) { _ in
                                        syncStarted.fulfill()
        }

        guard try HubListenerTestUtilities.waitForListener(with: token, timeout: 5.0) else {
            XCTFail("Never registered listener for sync started")
            return
        }

        wait(for: [syncStarted], timeout: 5.0)
        Amplify.Hub.removeListener(token)

        let post = Post(title: "Post title",
                        content: "Post content",
                        createdAt: Date())

        Amplify.DataStore.save(post) { _ in }

        let createMutationSent = expectation(description: "Create mutation sent to API category")
        apiPlugin.listeners.append { message in
            switch message {
            case "mutate(ofAnyModel:Post,type:create,listener:)":
                createMutationSent.fulfill()
            default:
                break
            }
        }

        wait(for: [createMutationSent], timeout: 1.0)
    }

    /// - Given: A sync-configured DataStore
    /// - When:
    ///    - I invoke DataStore.delete()
    /// - Then:
    ///    - The mutation queue writes events
    func testMutationQueueStoresDeleteEvents() {
        XCTFail("Not yet implemented")
    }

    /// - Given: A sync-configured DataStore
    /// - When:
    ///    - I restart the app
    /// - Then:
    ///    - The mutation queue processes previously loaded events
    func testMutationQueueLoadsPendingMutations() {
        XCTFail("Not yet implemented")
    }

    /// - Given: A sync-configured DataStore
    /// - When:
    ///    - I successfully process a mutation
    /// - Then:
    ///    - The mutation queue deletes the event from its persistent store
    func testMutationQueueDequeuesSavedEvents() {
        XCTFail("Not yet implemented")
    }

    /// - Given: A sync-configured DataStore
    /// - When:
    ///    - I successfully process a mutation
    /// - Then:
    ///    - The mutation listener is unsubscribed from Hub
    func testLocalMutationUnsubcsribesFromCloud() {
        XCTFail("Not yet implemented")
    }

}
