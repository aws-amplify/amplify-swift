//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

import AWSPluginsCore

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStorePlugin

@available(iOS 13.0, *)
class DataStoreHubEventTests: HubEventsIntegrationTestBase {

    struct TestModelRegistration: AmplifyModelRegistration {
        func registerModels(registry: ModelRegistry.Type) {
            registry.register(modelType: Post.self)
            registry.register(modelType: Comment.self)
        }

        let version: String = "1"
    }

    /// - Given:
    ///    - registered two models from `TestModelRegistration`
    ///    - no pending MutationEvents in MutationEvent database
    /// - When:
    ///    - DataStore's remote sync engine is initialized
    /// - Then:
    ///    - networkStatus received, payload should be: {active: false}, followed by {active: true}
    ///    - subscriptionEstablished received, payload should be nil
    ///    - syncQueriesStarted received, payload should be: {models: ["Post", "Comment"]}
    ///    - outboxStatus received, payload should be {isEmpty: true}
    ///    - modelSynced received, payload should be:
    ///      {modelName: "Some Model name", isFullSync: true/false, isDeltaSync: false/true, createCount: #, updateCount: #, deleteCount: #}
    ///    - syncQueriesReady received, payload should be nil
    func testDataStoreConfiguredDispatchesHubEvents() throws {

        let networkStatusReceived = expectation(description: "networkStatus received")
        networkStatusReceived.expectedFulfillmentCount = 2
        var networkStatusActive = false
        let subscriptionsEstablishedReceived = expectation(description: "subscriptionsEstablished received")
        let syncQueriesStartedReceived = expectation(description: "syncQueriesStarted received")
        let outboxStatusReceived = expectation(description: "outboxStatus received")

        let hubListener = Amplify.Hub.publisher(for: .dataStore).sink { payload in
            if payload.eventName == HubPayload.EventName.DataStore.networkStatus {
                guard let networkStatusEvent = payload.data as? NetworkStatusEvent else {
                    XCTFail("Failed to cast payload data as NetworkStatusEvent")
                    return
                }
                XCTAssertEqual(networkStatusEvent.active, networkStatusActive)
                if !networkStatusActive {
                    networkStatusActive = true
                }
                networkStatusReceived.fulfill()
            }

            if payload.eventName == HubPayload.EventName.DataStore.subscriptionsEstablished {
                XCTAssertNil(payload.data)
                subscriptionsEstablishedReceived.fulfill()
            }

            if payload.eventName == HubPayload.EventName.DataStore.syncQueriesStarted {
                guard let syncQueriesStartedEvent = payload.data as? SyncQueriesStartedEvent else {
                    XCTFail("Failed to cast payload data as SyncQueriesStartedEvent")
                    return
                }
                XCTAssertEqual(syncQueriesStartedEvent.models.count, 2)
                syncQueriesStartedReceived.fulfill()
            }

            if payload.eventName == HubPayload.EventName.DataStore.outboxStatus {
                guard let outboxStatusEvent = payload.data as? OutboxStatusEvent else {
                    XCTFail("Failed to cast payload data as OutboxStatusEvent")
                    return
                }
                XCTAssertTrue(outboxStatusEvent.isEmpty)
                outboxStatusReceived.fulfill()
            }
        }

        startAmplify(withModels: TestModelRegistration())

        waitForExpectations(timeout: networkTimeout)
        hubListener.cancel()
    }

    /// - Given:
    ///    - registered two models from `TestModelRegistration`
    ///    - no pending MutationEvents in MutationEvent database
    /// - When:
    ///    - Call `Amplify.DataStore.save()` to save a Post model
    /// - Then:
    ///    - outboxMutationEnqueued received, payload should be:
    ///      {modelName: "Post", element: {id: #, content: "some content"}}
    ///    - outboxMutationProcessed received, payload should be:
    ///      {modelName: "Post", element: {model: {id: #, content: "some content"}, version: 1, deleted: false, lastChangedAt: "some time"}}
    func testOutboxMutationEvents() throws {

        let post = Post(title: "title", content: "content", createdAt: .now())

        let outboxMutationEnqueuedReceived = expectation(description: "outboxMutationEnqueued received")
        let outboxMutationProcessedReceived = expectation(description: "outboxMutationProcessed received")

        let hubListener = Amplify.Hub.publisher(for: .dataStore).sink { payload in
            if payload.eventName == HubPayload.EventName.DataStore.outboxMutationEnqueued {
                guard let outboxMutationEnqueuedEvent = payload.data as? OutboxMutationEvent else {
                    XCTFail("Failed to cast payload data as OutboxMutationEvent")
                    return
                }
                XCTAssertEqual(outboxMutationEnqueuedEvent.modelName, "Post")
                XCTAssertEqual(outboxMutationEnqueuedEvent.element.model.modelName, "Post")
                XCTAssertNil(outboxMutationEnqueuedEvent.element.version)
                XCTAssertNil(outboxMutationEnqueuedEvent.element.lastChangedAt)
                XCTAssertNil(outboxMutationEnqueuedEvent.element.deleted)
                outboxMutationEnqueuedReceived.fulfill()
            }

            if payload.eventName == HubPayload.EventName.DataStore.outboxMutationProcessed {
                guard let outboxMutationProcessedEvent = payload.data as? OutboxMutationEvent else {
                    XCTFail("Failed to cast payload data as OutboxMutationEvent")
                    return
                }
                XCTAssertEqual(outboxMutationProcessedEvent.modelName, "Post")
                XCTAssertEqual(outboxMutationProcessedEvent.element.model.modelName, "Post")
                XCTAssertEqual(outboxMutationProcessedEvent.element.version, 1)
                XCTAssertNotNil(outboxMutationProcessedEvent.element.lastChangedAt)
                XCTAssertEqual(outboxMutationProcessedEvent.element.deleted, false)
                outboxMutationProcessedReceived.fulfill()
            }
        }

        startAmplify(withModels: TestModelRegistration())
        Amplify.DataStore.save(post) { _ in }

        waitForExpectations(timeout: networkTimeout)
        hubListener.cancel()
    }

    func testModelSyncedAndSyncQueriesReady() throws {
        let modelSyncedReceived = expectation(description: "outboxMutationEnqueued received")
        modelSyncedReceived.assertForOverFulfill = false
        let syncQueriesReadyReceived = expectation(description: "outboxMutationProcessed received")

        let expectedSyncedModelNames = ["Post", "Comment"]
        var modelSyncedEvents = [ModelSyncedEvent]()

        let hubListener = Amplify.Hub.publisher(for: .dataStore).sink { payload in
            if payload.eventName == HubPayload.EventName.DataStore.modelSynced {
                guard let modelSyncedEvent = payload.data as? ModelSyncedEvent else {
                    XCTFail("Failed to cast payload data as ModelSyncedEvent")
                    return
                }

                if expectedSyncedModelNames.contains(modelSyncedEvent.modelName) {
                    modelSyncedEvents.append(modelSyncedEvent)
                }

                if modelSyncedEvents.count == 2 {
                    guard let postModelSyncedEvent = modelSyncedEvents.first(where: { $0.modelName == "Post" }),
                            let commentModelSyncedEvent = modelSyncedEvents.first(where: { $0.modelName == "Comment" }) else {
                        XCTFail("Could not get modelSyncedEvent for Post and Comment")
                        return
                    }

                    XCTAssertTrue(postModelSyncedEvent.isFullSync)
                    XCTAssertFalse(postModelSyncedEvent.isDeltaSync)
                    XCTAssertTrue(commentModelSyncedEvent.isFullSync)
                    XCTAssertFalse(commentModelSyncedEvent.isDeltaSync)
                    modelSyncedReceived.fulfill()
                }
            }

            if payload.eventName == HubPayload.EventName.DataStore.syncQueriesReady {
                syncQueriesReadyReceived.fulfill()
            }
        }

        startAmplify(withModels: TestModelRegistration())

        waitForExpectations(timeout: networkTimeout)
        hubListener.cancel()
    }
}
