//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Combine

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStorePlugin

class AWSDataStorePluginBaseBehaviorTests: BaseDataStoreTests {

    func testDispatchModelSyncedEventToHub() {

        let modelSyncedEvent = ModelSyncedEvent(modelName: Post.modelName,
                                                isFullSync: true,
                                                isDeltaSync: false,
                                                added: 10,
                                                updated: 1,
                                                deleted: 1)
        let modelSyncedReceivedFromHub = expectation(description: "modelSynced received from Hub")
        let listener = Amplify.Hub.publisher(for: .dataStore).sink { payload in
            switch payload.eventName {
            case HubPayload.EventName.DataStore.modelSynced:
                guard let modelSyncedEventPayload = payload.data as? ModelSyncedEvent else {
                    XCTFail("Couldn't cast payload data as ModelSyncedEvent")
                    return
                }
                XCTAssertEqual(modelSyncedEventPayload, modelSyncedEvent)
                modelSyncedReceivedFromHub.fulfill()
            default:
                break
            }
        }

        guard let dispatchedModelSyncedEvent = dataStorePlugin.dispatchedModelSyncedEvents[Post.modelName] else {
            XCTFail("Missing `dispatchedModelSyncedEvent` for `Post` model")
            return
        }
        XCTAssertFalse(dispatchedModelSyncedEvent.get())

        dataStorePlugin.onReceiveValue(receiveValue: .modelSyncedEvent(modelSyncedEvent))
        XCTAssertTrue(dispatchedModelSyncedEvent.get())
        wait(for: [modelSyncedReceivedFromHub], timeout: 1)
        listener.cancel()
    }

    func testDispatchedModelSyncedEventFalseAfterStop() throws {
        let modelSyncedEvent = ModelSyncedEvent(modelName: Post.modelName,
                                                isFullSync: true,
                                                isDeltaSync: false,
                                                added: 10,
                                                updated: 1,
                                                deleted: 1)
        guard let dispatchedModelSyncedEvent = dataStorePlugin.dispatchedModelSyncedEvents[Post.modelName] else {
            XCTFail("Missing `dispatchedModelSyncedEvent` for `Post` model")
            return
        }
        XCTAssertFalse(dispatchedModelSyncedEvent.get())
        dataStorePlugin.onReceiveValue(receiveValue: .modelSyncedEvent(modelSyncedEvent))
        XCTAssertTrue(dispatchedModelSyncedEvent.get())

        let dataStoreStopSuccess = expectation(description: "Stop successfully")
        dataStorePlugin.stop { result in
            switch result {
            case .success:
                dataStoreStopSuccess.fulfill()
            case .failure(let error):
                XCTFail("\(error.localizedDescription)")
            }
        }

        wait(for: [dataStoreStopSuccess], timeout: 1)
        XCTAssertFalse(dispatchedModelSyncedEvent.get())
    }

    func testDispatchReadyEventToHub() {
        let readyReceivedFromHub = expectation(description: "ready event received from Hub")
        let syncQueriesReadyFromHub = expectation(description: "ready event received from Hub")
        let listener = Amplify.Hub.publisher(for: .dataStore).sink { payload in
            switch payload.eventName {
            case HubPayload.EventName.DataStore.ready:
                readyReceivedFromHub.fulfill()
            case HubPayload.EventName.DataStore.syncQueriesReady:
                syncQueriesReadyFromHub.fulfill()
            default:
                break
            }
        }

        dataStorePlugin.onReceiveValue(receiveValue: .syncQueriesReadyEvent)
        dataStorePlugin.onReceiveValue(receiveValue: .readyEvent)

        wait(for: [syncQueriesReadyFromHub, readyReceivedFromHub], timeout: 1)
        listener.cancel()
    }
}
