//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SQLite
import XCTest

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStorePlugin
class StorageEnginePublisherTests: StorageEngineTestsBase {

    override func setUp() {
        super.setUp()
        let validAPIPluginKey = "MockAPICategoryPlugin"
        let validAuthPluginKey = "MockAuthCategoryPlugin"
        do {
            connection = try Connection(.inMemory)
            storageAdapter = try SQLiteStorageEngineAdapter(connection: connection)
            try storageAdapter.setUp(modelSchemas: StorageEngine.systemModelSchemas)
            syncEngine = MockRemoteSyncEngine()
            storageEngine = StorageEngine(storageAdapter: storageAdapter,
                                          dataStoreConfiguration: .default,
                                          syncEngine: syncEngine,
                                          validAPIPluginKey: validAPIPluginKey,
                                          validAuthPluginKey: validAuthPluginKey)
        } catch {
            XCTFail(String(describing: error))
            return
        }
    }

    func testStorageEnginePublisherEvents() {
        let modelSyncedEvent = ModelSyncedEvent(modelName: "",
                                                isFullSync: true,
                                                isDeltaSync: false,
                                                added: 1,
                                                updated: 1,
                                                deleted: 1)
        let mutationEvent = MutationEvent(id: "",
                                          modelId: "",
                                          modelName: "",
                                          json: "",
                                          mutationType: .create,
                                          createdAt: .now())
        let receivedMutationEvent = expectation(description: "Received mutationEvent event")
        let receivedModelSyncedEvent = expectation(description: "Received ModelSynced event")
        let receivedSyncQueriesReadyEvent = expectation(description: "Received syncQueries event")
        let receivedReadyEvent = expectation(description: "Received ready event")
        let sink = storageEngine.publisher.sink { _ in
        } receiveValue: { event in
            switch event {
            case .mutationEvent(let mutationEventPayload):
                XCTAssertEqual(mutationEventPayload, mutationEvent)
                receivedMutationEvent.fulfill()
            case .modelSyncedEvent(let modelSyncedEventPayload):
                XCTAssertEqual(modelSyncedEventPayload, modelSyncedEvent)
                receivedModelSyncedEvent.fulfill()
            case .syncQueriesReadyEvent:
                receivedSyncQueriesReadyEvent.fulfill()
            case .readyEvent:
                receivedReadyEvent.fulfill()
            case .started:
                XCTFail("Unexpected event received")
            }
        }

        storageEngine.onReceive(receiveValue: .mutationEvent(mutationEvent))
        storageEngine.onReceive(receiveValue: .modelSyncedEvent(modelSyncedEvent))
        storageEngine.onReceive(receiveValue: .syncQueriesReadyEvent)
        storageEngine.onReceive(receiveValue: .readyEvent)
        storageEngine.onReceive(receiveValue: .storageAdapterAvailable)
        storageEngine.onReceive(receiveValue: .subscriptionsPaused)
        storageEngine.onReceive(receiveValue: .mutationsPaused)
        storageEngine.onReceive(receiveValue: .clearedStateOutgoingMutations)
        storageEngine.onReceive(receiveValue: .subscriptionsInitialized)
        storageEngine.onReceive(receiveValue: .performedInitialSync)
        storageEngine.onReceive(receiveValue: .subscriptionsActivated)
        storageEngine.onReceive(receiveValue: .mutationQueueStarted)
        storageEngine.onReceive(receiveValue: .syncStarted)
        storageEngine.onReceive(receiveValue: .cleanedUp)
        storageEngine.onReceive(receiveValue: .cleanedUpForTermination)
        wait(for: [receivedMutationEvent,
                   receivedModelSyncedEvent,
                   receivedSyncQueriesReadyEvent,
                   receivedReadyEvent],
                timeout: 1)
        sink.cancel()
    }
}
