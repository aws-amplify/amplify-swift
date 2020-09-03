//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import XCTest

import AmplifyPlugins
import AWSPluginsCore

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStoreCategoryPlugin

@available(iOS 13.0, *)
class DataStoreHubEventTests: HubEventsIntegrationTestBase {

    func testEventsThatDataStoreStartTriggers() throws {

        let outboxStatusReceived = expectation(description: "outboxStatus received")
        let subscriptionsEstablishedReceived = expectation(description: "subscriptionsEstablished received")
        let syncQueriesStartedReceived = expectation(description: "syncQueriesStarted received")

        let hubListener = Amplify.Hub.listen(to: .dataStore) { payload in
            if payload.eventName == HubPayload.EventName.DataStore.outboxStatus {
                outboxStatusReceived.fulfill()
            }

            if payload.eventName == HubPayload.EventName.DataStore.subscriptionsEstablished {
                subscriptionsEstablishedReceived.fulfill()
            }

            if payload.eventName == HubPayload.EventName.DataStore.syncQueriesStarted {
                syncQueriesStartedReceived.fulfill()
            }
        }

        guard try HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }

        wait(for: [outboxStatusReceived], timeout: networkTimeout)
        wait(for: [subscriptionsEstablishedReceived], timeout: networkTimeout)
        wait(for: [syncQueriesStartedReceived], timeout: networkTimeout)
    }
}
