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

    /// Mock used to listen for API calls; this is how we assert that syncEngine is delivering events to the API
    var apiPlugin: MockAPICategoryPlugin!

    /// Used for DB manipulation to mock starting data for tests
    var storageAdapter: SQLiteStorageEngineAdapter!

    /// Populated during setUp, used in each test during `Amplify.configure()`
    var amplifyConfig: AmplifyConfiguration!

    /// Tests in this class inject values into the database early in startup, so test setUp is broken into chunks
    override func setUp() {
        Amplify.reset()
        Amplify.Logging.logLevel = .verbose

        let apiConfig = APICategoryConfiguration(plugins: [
            "MockAPICategoryPlugin": true
        ])

        let dataStoreConfig = DataStoreCategoryConfiguration(plugins: [
            "awsDataStoreCategoryPlugin": true
        ])

        amplifyConfig = AmplifyConfiguration(api: apiConfig, dataStore: dataStoreConfig)

        apiPlugin = MockAPICategoryPlugin()
        tryOrFail {
            try Amplify.add(plugin: apiPlugin)
        }
    }

    /// Sets up a StorageAdapter backed by an in-memory SQLite database
    func setUpStorageAdapter() {
        tryOrFail {
            let connection = try Connection(.inMemory)
            storageAdapter = try SQLiteStorageEngineAdapter(connection: connection)
            try storageAdapter.setUp(models: StorageEngine.systemModels)
        }
    }

    func setUpDataStore() {
        tryOrFail {
            let syncEngine = try CloudSyncEngine(storageAdapter: storageAdapter)
            let storageEngine = StorageEngine(storageAdapter: storageAdapter,
                                              syncEngine: syncEngine,
                                              isSyncEnabled: true)

            let publisher = DataStorePublisher()
            let dataStorePlugin = AWSDataStoreCategoryPlugin(modelRegistration: TestModelRegistration(),
                                                             storageEngine: storageEngine,
                                                             dataStorePublisher: publisher)

            try Amplify.add(plugin: dataStorePlugin)
        }
    }

    func startAmplify() {
        tryOrFail {
            try Amplify.configure(amplifyConfig)
        }
    }

    /// - Given: A sync-configured DataStore
    /// - When:
    ///    - I invoke DataStore.save() for a new model
    /// - Then:
    ///    - The outgoing mutation queue sends a create mutation
    func testMutationQueueCreateSendsSync() throws {
        continueAfterFailure = false

        setUpStorageAdapter()
        setUpDataStore()
        startAmplify()

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
            if message == "mutate(ofAnyModel:Post-\(post.id),type:create,listener:)" {
                createMutationSent.fulfill()
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
    ///    - I start syncing with mutation events already in the database
    /// - Then:
    ///    - The mutation queue delivers previously loaded events
    func testMutationQueueLoadsPendingMutations() throws {
        continueAfterFailure = false

        setUpStorageAdapter()

        // pre-load the MutationEvent table with mutation data
        let mutationEventSaved = expectation(description: "Preloaded mutation event saved")
        mutationEventSaved.expectedFulfillmentCount = 3
        for id in 1 ... 3 {
            let pendingPost = Post(id: "pendingPost-\(id)",
                title: "pendingPost-\(id) title",
                content: "pendingPost-\(id) content",
                createdAt: Date())

            let pendingPostJSON = try pendingPost.toJSON()
            let event = MutationEvent(id: "mutation-\(id)",
                modelName: Post.modelName,
                data: pendingPostJSON,
                mutationType: .create,
                createdAt: Date())

            storageAdapter.save(event) { result in
                switch result {
                case .failure(let dataStoreError):
                    XCTFail(String(describing: dataStoreError))
                case .success:
                    mutationEventSaved.fulfill()
                }
            }

        }

        wait(for: [mutationEventSaved], timeout: 1.0)

        let mutation1Sent = expectation(description: "Create mutation 1 sent to API category")
        let mutation2Sent = expectation(description: "Create mutation 2 sent to API category")
        let mutation3Sent = expectation(description: "Create mutation 3 sent to API category")
        apiPlugin.listeners.append { message in
            switch message {
            case "mutate(ofAnyModel:Post-pendingPost-1,type:create,listener:)":
                mutation1Sent.fulfill()
            case "mutate(ofAnyModel:Post-pendingPost-2,type:create,listener:)":
                mutation2Sent.fulfill()
            case "mutate(ofAnyModel:Post-pendingPost-3,type:create,listener:)":
                mutation3Sent.fulfill()
            default:
                break
            }
        }

        setUpDataStore()
        startAmplify()

        waitForExpectations(timeout: 5.0, handler: nil)
    }

    /// - Given: A sync-configured DataStore
    /// - When:
    ///    - I start syncing with mutation events already in the database
    ///    - I add mutations before the pending mutations have been processed
    /// - Then:
    ///    - The mutation queue delivers events in FIFO order
    func testMutationQueueDeliversPendingMutationsFirst() throws {
        continueAfterFailure = false

        setUpStorageAdapter()

        // pre-load the MutationEvent table with mutation data
        let mutationEventSaved = expectation(description: "Preloaded mutation event saved")
        for id in 1 ... 1 {
            let pendingPost = Post(id: "pendingPost-\(id)",
                title: "pendingPost-\(id) title",
                content: "pendingPost-\(id) content",
                createdAt: Date())

            let pendingPostJSON = try pendingPost.toJSON()
            let event = MutationEvent(id: "mutation-\(id)",
                modelName: Post.modelName,
                data: pendingPostJSON,
                mutationType: .create,
                createdAt: Date())

            storageAdapter.save(event) { result in
                switch result {
                case .failure(let dataStoreError):
                    XCTFail(String(describing: dataStoreError))
                case .success:
                    mutationEventSaved.fulfill()
                }
            }

        }

        wait(for: [mutationEventSaved], timeout: 1.0)

        let pendingPostMutationSent =
            expectation(description: "Create mutation for pending post sent to API category")

        let newPostMutationSent =
            expectation(description: "Create mutation for newly-created post sent to API category")

        apiPlugin.listeners.append { message in
            switch message {
            case "mutate(ofAnyModel:Post-pendingPost-1,type:create,listener:)":
                pendingPostMutationSent.fulfill()
            case "mutate(ofAnyModel:Post-newPost-1,type:create,listener:)":
                newPostMutationSent.fulfill()
            default:
                break
            }
        }

        setUpDataStore()

        let syncStarted = expectation(description: "Sync started")
        let syncStartedToken = Amplify.Hub.listen(to: .dataStore,
                                                  eventName: HubPayload.EventName.DataStore.syncStarted) { _ in
                                                    syncStarted.fulfill()
        }

        guard try HubListenerTestUtilities.waitForListener(with: syncStartedToken, timeout: 5.0) else {
            XCTFail("Didn't register token for sync started")
            return
        }

        startAmplify()

        wait(for: [syncStarted], timeout: 5.0)

        let newPost = Post(id: "newPost-1",
                           title: "newPost title",
                           content: "newPost content",
                           createdAt: Date())

        Amplify.DataStore.save(newPost) { _ in }

        wait(for: [pendingPostMutationSent, newPostMutationSent], timeout: 5.0, enforceOrder: true)
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

// TOOD: Figure out how to move this to AmplifyTestCommon. Last time I tried, I wasn't able to `import XCTest` in the
// extension file, presumably because AmplifyTestCommon isn't a test target?
extension XCTestCase {
    /// Execute `block` inside a do/catch block, and fail the test with an XCTFail if the block throws an error
    func tryOrFail(block: () throws -> Void) {
        do {
            try block()
        } catch {
            XCTFail(String(describing: error))
        }
    }
}
