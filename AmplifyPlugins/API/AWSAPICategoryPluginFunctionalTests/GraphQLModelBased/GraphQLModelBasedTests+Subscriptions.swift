//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSMobileClient
@testable import AWSAPICategoryPlugin
@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSAPICategoryPluginTestCommon
@testable import AppSyncSubscriptionClient

/// Subscription related stress/load tests
extension GraphQLModelBasedTests {

    /// Ensure that the underlying websocket socket is disconnected when the number of subscriptions on the socket
    /// reaches zero. This test first creates multiple subscriptions, does a mutation to make sure data is flowing,
    /// cancel the operations, and makes sure the underlying socket is disconnected. Given this new state of the system
    /// where there is an existing connection provider, run a similar test by create a new subscription, which in turn
    /// uses the same connection provider instance but will create a new websocket connection.
    ///
    /// - Given: Connected subscriptions
    /// - When:
    ///    - All subscription operations are cancelled
    /// - Then:
    ///    - Underlying websocket is disconnected
    func testAllSubscriptionsCancelledShouldDisconnectTheWebsocket() {
        let connectedInvoked = expectation(description: "Connection established")
        connectedInvoked.expectedFulfillmentCount = 3
        let disconnectedInvoked = expectation(description: "Connection disconnected")
        disconnectedInvoked.expectedFulfillmentCount = 3
        let completedInvoked = expectation(description: "Completed invoked")
        completedInvoked.expectedFulfillmentCount = 3
        let progressInvoked = expectation(description: "progress invoked")
        progressInvoked.expectedFulfillmentCount = 3

        let operation1 = Amplify.API.subscribe(from: Post.self, type: .onCreate) { event in
            if case let .inProcess(response) = event, case let .connection(state) = response {
                if case .connected = state {
                    connectedInvoked.fulfill()
                }
                if case .disconnected = state {
                    disconnectedInvoked.fulfill()
                }
            }

            if case .completed = event {
                completedInvoked.fulfill()
            }

            if case let .inProcess(response) = event, case .data = response {
                progressInvoked.fulfill()
            }
        }
        let operation2 = Amplify.API.subscribe(from: Post.self, type: .onCreate) { event in
            if case let .inProcess(response) = event, case let .connection(state) = response {
                if case .connected = state {
                    connectedInvoked.fulfill()
                }
                if case .disconnected = state {
                    disconnectedInvoked.fulfill()
                }
            }

            if case .completed = event {
                completedInvoked.fulfill()
            }

            if case let .inProcess(response) = event, case .data = response {
                progressInvoked.fulfill()
            }
        }
        let operation3 = Amplify.API.subscribe(from: Post.self, type: .onCreate) { event in
            if case let .inProcess(response) = event, case let .connection(state) = response {
                if case .connected = state {
                    connectedInvoked.fulfill()
                }
                if case .disconnected = state {
                    disconnectedInvoked.fulfill()
                }
            }

            if case .completed = event {
                completedInvoked.fulfill()
            }

            if case let .inProcess(response) = event, case .data = response {
                progressInvoked.fulfill()
            }
        }

        XCTAssertNotNil(operation1)
        XCTAssertNotNil(operation2)
        XCTAssertNotNil(operation3)
        wait(for: [connectedInvoked], timeout: TestCommonConstants.networkTimeout)

        guard let awsOp = operation1 as? AWSGraphQLSubscriptionOperation,
            let factory = awsOp.subscriptionConnectionFactory as? AWSSubscriptionConnectionFactory,
            let singleConnectionProvider = factory.apiToConnectionProvider.first,
            let connectionProvider = singleConnectionProvider.value as? RealtimeConnectionProvider else {
                XCTFail("Failed to retrieve the underlying connection provider that interfaces with the websocket.")
                return
        }
        XCTAssertEqual(connectionProvider.status, .connected)

        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let title = testMethodName + "Title"

        guard createPost(id: uuid, title: title) != nil else {
            XCTFail("Failed to create post")
            return
        }
        wait(for: [progressInvoked], timeout: TestCommonConstants.networkTimeout)
        XCTAssertEqual(connectionProvider.status, .connected)

        operation1.cancel()
        operation2.cancel()
        operation3.cancel()

        wait(for: [disconnectedInvoked, completedInvoked], timeout: TestCommonConstants.networkTimeout)
        XCTAssertTrue(operation1.isFinished)
        XCTAssertTrue(operation2.isFinished)
        XCTAssertTrue(operation3.isFinished)
        XCTAssertEqual(connectionProvider.status, .notConnected)

        let newConnectedInvoked = expectation(description: "Connection established")
        let newDisconnectedInvoked = expectation(description: "Disconnected established")
        let newOperation = Amplify.API.subscribe(from: Post.self, type: .onCreate) { event in
            if case let .inProcess(response) = event, case let .connection(state) = response {
                if case .connected = state {
                    newConnectedInvoked.fulfill()
                }
                if case .disconnected = state {
                    newDisconnectedInvoked.fulfill()
                }
            }
        }
        wait(for: [newConnectedInvoked], timeout: TestCommonConstants.networkTimeout)
        XCTAssertEqual(connectionProvider.status, .connected)
        newOperation.cancel()
        wait(for: [newDisconnectedInvoked], timeout: TestCommonConstants.networkTimeout)
        XCTAssertTrue(newOperation.isFinished)
        XCTAssertEqual(connectionProvider.status, .notConnected)
    }
}
