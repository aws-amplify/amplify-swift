//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import SQLite

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStorePlugin

class AWSMutationEventIngesterTests: XCTestCase {
    // Used by tests to assert that the MutationEvent table is being updated
    var storageAdapter: SQLiteStorageEngineAdapter!

    override func setUp() async throws {
        await Amplify.reset()

        let apiConfig = APICategoryConfiguration(plugins: [
            "MockAPICategoryPlugin": true
        ])

        let dataStoreConfig = DataStoreCategoryConfiguration(plugins: [
            "awsDataStorePlugin": true
        ])

        let amplifyConfig = AmplifyConfiguration(api: apiConfig, dataStore: dataStoreConfig)

        let apiPlugin = MockAPICategoryPlugin()

        do {
            let connection = try Connection(.inMemory)
            storageAdapter = try SQLiteStorageEngineAdapter(connection: connection)
            try storageAdapter.setUp(modelSchemas: StorageEngine.systemModelSchemas)

            let syncEngine = try RemoteSyncEngine(storageAdapter: storageAdapter,
                                                  dataStoreConfiguration: .default)

            let validAPIPluginKey = "MockAPICategoryPlugin"
            let validAuthPluginKey = "MockAuthCategoryPlugin"
            let storageEngine = StorageEngine(storageAdapter: storageAdapter,
                                              dataStoreConfiguration: .default,
                                              syncEngine: syncEngine,
                                              validAPIPluginKey: validAPIPluginKey,
                                              validAuthPluginKey: validAuthPluginKey)

            let storageEngineBehaviorFactory: StorageEngineBehaviorFactory = {_, _, _, _, _, _  throws in
                return storageEngine
            }
            let publisher = DataStorePublisher()
            let dataStorePlugin = AWSDataStorePlugin(modelRegistration: TestModelRegistration(),
                                                     storageEngineBehaviorFactory: storageEngineBehaviorFactory,
                                                     dataStorePublisher: publisher,
                                                     validAPIPluginKey: validAPIPluginKey,
                                                     validAuthPluginKey: validAuthPluginKey)

            try Amplify.add(plugin: apiPlugin)
            try Amplify.add(plugin: dataStorePlugin)
            try Amplify.configure(amplifyConfig)
        } catch {
            XCTFail(String(describing: error))
        }
    }

    /// - Given: A sync-configured DataStore
    /// - When:
    ///    - I invoke DataStore.save()
    /// - Then:
    ///    - The mutation queue writes events
    func testMutationQueueWritesSaveEvents() async throws {
        let post = Post(title: "Post title",
                        content: "Post content",
                        createdAt: .now())

        _ = try await Amplify.DataStore.save(post)

        let mutationEventQueryCompleted = expectation(description: "Mutation event query completed")
        storageAdapter.query(MutationEvent.self) { result in
            defer {
                mutationEventQueryCompleted.fulfill()
            }

            let mutationEvents: [MutationEvent]
            switch result {
            case .failure(let dataStoreError):
                XCTFail(String(describing: dataStoreError))
                return
            case .success(let eventsFromResult):
                mutationEvents = eventsFromResult
            }

            XCTAssert(!mutationEvents.isEmpty)
            XCTAssert(mutationEvents.first?.json.contains(post.id) ?? false)
        }

        wait(for: [mutationEventQueryCompleted], timeout: 1.0)

    }

    /// - Given: A sync-configured DataStore
    /// - When:
    ///    - I invoke `save()`
    ///    - The MutationIngester encounters an error
    /// - Then:
    ///    - The entire `save()` operation fails
    func testMutationQueueFailureCausesSaveFailure() throws {
        throw XCTSkip("Not yet implemented")
    }
}
