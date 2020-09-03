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
    }
}
