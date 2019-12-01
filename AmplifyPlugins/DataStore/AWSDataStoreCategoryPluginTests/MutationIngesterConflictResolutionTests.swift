//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SQLite
import XCTest

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStoreCategoryPlugin

/// Tests in this class have a naming convention of `test_<existing>_<ingesting>`, which is to say: given that the
/// mutation queue has an existing record of type `<existing>`, assert the behavior when ingesting a mutation of
/// type `<ingesting>`.
class MutationIngesterConflictResolutionTests: XCTestCase {

    /// Mock used to listen for API calls; this is how we assert that syncEngine is delivering events to the API
    var apiPlugin: MockAPICategoryPlugin!

    /// Used for DB manipulation to mock starting data for tests
    var storageAdapter: SQLiteStorageEngineAdapter!

    /// Populated during setUp, used in each test during `Amplify.configure()`
    var amplifyConfig: AmplifyConfiguration!

    override func setUp() {
        continueAfterFailure = false

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

    func test_create_create() throws {
        setUpStorageAdapter()

        let post = Post(id: "post-1",
                        title: "title",
                        content: "content",
                        createdAt: Date())
        try saveMutationEvent(of: .create, for: post)

        try startAmplifyAndWaitForSync()

        let saveResultReceived = expectation(description: "Save result received")
        Amplify.DataStore.save(post) { result in
            switch result {
            case .failure(let dataStoreError):
                XCTAssertNotNil(dataStoreError)
            case .success(let post):
                XCTAssertNil(post)
            }
        }

        wait(for: [saveResultReceived], timeout: 1.0)
    }

    // MARK: - Helpers

    func saveMutationEvent(of mutationType: MutationEvent.MutationType,
                           for post: Post,
                           version: Int? = nil) throws {
        let mutationEvent = try MutationEvent(modelName: post.modelName,
                                              data: post.toJSON(),
                                              mutationType: mutationType,
                                              createdAt: Date(),
                                              version: version)

        let mutationEventSaved = expectation(description: "Preloaded mutation event saved")
        storageAdapter.save(mutationEvent) { result in
            switch result {
            case .failure(let dataStoreError):
                XCTFail(String(describing: dataStoreError))
            case .success:
                mutationEventSaved.fulfill()
            }
        }
        wait(for: [mutationEventSaved], timeout: 1.0)
    }

    func startAmplifyAndWaitForSync() throws {
        setUpDataStore()

        let syncStarted = expectation(description: "Sync started")
        let token = Amplify.Hub.listen(to: .dataStore,
                                       eventName: HubPayload.EventName.DataStore.syncStarted) { _ in
                                        syncStarted.fulfill()
        }

        guard try HubListenerTestUtilities.waitForListener(with: token, timeout: 5.0) else {
            XCTFail("Never registered listener for sync started")
            return
        }

        startAmplify()

        wait(for: [syncStarted], timeout: 5.0)
        Amplify.Hub.removeListener(token)
    }
}
