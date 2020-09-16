//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

import AmplifyPlugins
import AWSPluginsCore

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStoreCategoryPlugin

@available(iOS 13.0, *)
class DataStoreHubEventTests: HubEventsIntegrationTestBase {

    /// - Given:
    ///    - registered two models from `TestModelRegistration`
    ///    - no pending MutationEvents in MutationEvent database
    /// - When:
    ///    - DataStore's remote sync engine is initialized
    /// - Then:
    ///    - subscriptionEstablished received, payload should be nil
    ///    - syncQueriesStarted received, payload should be: {models: ["Post", "Comment"]}
    ///    - outboxStatus received, payload should be {isEmpty: true}
    func testDataStoreConfiguredDispatchesHubEvents() throws {

        let subscriptionsEstablishedReceived = expectation(description: "subscriptionsEstablished received")
        let syncQueriesStartedReceived = expectation(description: "syncQueriesStarted received")
        let outboxStatusReceived = expectation(description: "outboxStatus received")

        let hubListener = Amplify.Hub.listen(to: .dataStore) { payload in
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

        guard try HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }

        waitForExpectations(timeout: networkTimeout, handler: nil)
        Amplify.Hub.removeListener(hubListener)
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

        let hubListener = Amplify.Hub.listen(to: .dataStore) { payload in
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

        guard try HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }

        Amplify.DataStore.save(post) { _ in }

        waitForExpectations(timeout: networkTimeout, handler: nil)
        Amplify.Hub.removeListener(hubListener)
    }
}
