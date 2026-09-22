//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Combine
import Foundation
import SQLite
import XCTest

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStorePlugin
@testable import AWSPluginsCore

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class ReadyEventEmitterTests: XCTestCase, @unchecked Sendable {
    var stateMachine: MockStateMachine<RemoteSyncEngine.State, RemoteSyncEngine.Action>!
    var readyEventEmitter: ReadyEventEmitter?
    var readyEventSink: AnyCancellable?

    override func setUp() {
        super.setUp()
    }

    func testReadyEventReceived() throws {
        let readyReceived = expectation(description: "ready received")
        readyReceived.assertForOverFulfill = false

        let remoteSyncTopicPublisher = PassthroughSubject<RemoteSyncEngineEvent, DataStoreError>()
        readyEventEmitter =
            ReadyEventEmitter(remoteSyncEnginePublisher: remoteSyncTopicPublisher.eraseToAnyPublisher())
        readyEventSink = readyEventEmitter?.publisher.sink(receiveCompletion: { _ in
            XCTFail("Should not receive completion")
        }, receiveValue: { event in
            switch event {
            case .readyEvent:
                readyReceived.fulfill()
            }
        })
        remoteSyncTopicPublisher.send(.syncStarted)
        let syncQueriesReadyEventPayload = HubPayload(eventName: HubPayload.EventName.DataStore.syncQueriesReady)
        Amplify.Hub.dispatch(to: .dataStore, payload: syncQueriesReadyEventPayload)

        wait(for: [readyReceived], timeout: 1)
        readyEventSink?.cancel()
    }

}
