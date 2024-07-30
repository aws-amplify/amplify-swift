//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSAPIPlugin

class GraphQLSubscribeTests: OperationTestBase {

    // Setup expectations
    var onSubscribeInvoked: XCTestExpectation!

    // Callback expectations
    var receivedCompletionFinish: XCTestExpectation!
    var receivedCompletionFailure: XCTestExpectation!

    // Subscription lifefycle expectations
    var receivedConnected: XCTestExpectation!
    var receivedDisconnected: XCTestExpectation!

    // Subscription item expectations
    var receivedSubscriptionEventData: XCTestExpectation!
    var receivedSubscriptionEventError: XCTestExpectation!

    var mockAppSyncRealTimeClient: MockAppSyncRealTimeClient!

    override func setUp() async throws {
        try await super.setUp()

        onSubscribeInvoked = expectation(description: "onSubscribeInvoked")

        receivedCompletionFinish = expectation(description: "receivedCompletionFinish")
        receivedCompletionFailure = expectation(description: "receivedCompletionFailure")

        receivedConnected = expectation(description: "receivedConnected")
        receivedDisconnected = expectation(description: "receivedDisconnected")

        receivedSubscriptionEventData = expectation(description: "receivedSubscriptionEventData")
        receivedSubscriptionEventError = expectation(description: "receivedSubscriptionEventError")

        try setUpMocksAndSubscriptionItems()
    }

    override func tearDown() async throws {
        onSubscribeInvoked = nil
        receivedCompletionFinish = nil
        receivedCompletionFailure = nil
        receivedConnected = nil
        receivedDisconnected = nil
        receivedSubscriptionEventData = nil
        receivedSubscriptionEventError = nil

        mockAppSyncRealTimeClient = nil
        try await super.tearDown()
    }

    private func waitForExpectations(timeout: TimeInterval) async {
        await fulfillment(of: [
            receivedCompletionFinish,
            receivedCompletionFailure,
            receivedConnected,
            receivedDisconnected,
            receivedSubscriptionEventData,
            receivedSubscriptionEventError
        ], timeout: timeout)
    }

    /// Lifecycle test
    ///
    /// When:
    /// - Successfully connect
    /// - Successfully send valid data
    /// - Disconnect normally
    ///
    /// Then:
    /// - The value handler is invoked with a successful connection message
    /// - The value handler is invoked with a successfully decoded value
    /// - The value handler is invoked with a disconnection message
    /// - The completion handler is invoked with a normal termination
    func testHappyPath() async throws {
        let testJSON: JSONValue = ["foo": true]
        let testData: JSONValue = [
            "data": [ "foo": true ]
        ]
        receivedCompletionFinish.shouldTrigger = true
        receivedCompletionFailure.shouldTrigger = false
        receivedConnected.shouldTrigger = true
        receivedDisconnected.shouldTrigger = true
        receivedSubscriptionEventData.shouldTrigger = true
        receivedSubscriptionEventError.shouldTrigger = false

        subscribe(expecting: testJSON)
        await fulfillment(of: [onSubscribeInvoked], timeout: 0.05)

        try await MockAppSyncRealTimeClient.waitForSubscirbing()
        try await MockAppSyncRealTimeClient.waitForSubscirbed()
        mockAppSyncRealTimeClient.triggerEvent(.data(testData))
        mockAppSyncRealTimeClient.triggerEvent(.unsubscribed)

        await fulfillment(of: [receivedCompletionFinish, 
                               receivedCompletionFailure,
                               receivedConnected,
                               receivedDisconnected,
                               receivedSubscriptionEventData,
                               receivedSubscriptionEventError
                              ],
                          timeout: 0.05)
    }

    /// Lifecycle test
    ///
    /// When:
    /// - Successfully connect
    /// - Successfully disconnect
    ///
    /// Then:
    /// - The value handler is invoked with a successful connection message
    /// - The value handler is not invoked with with a data value
    /// - The value handler is invoked with a disconnection message
    /// - The completion handler is invoked with a normal termination
    func testConnectionWithNoData() async throws {
        receivedCompletionFinish.shouldTrigger = true
        receivedCompletionFailure.shouldTrigger = false
        receivedConnected.shouldTrigger = true
        receivedDisconnected.shouldTrigger = true
        receivedSubscriptionEventData.shouldTrigger = false
        receivedSubscriptionEventError.shouldTrigger = false

        subscribe()
        await fulfillment(of: [onSubscribeInvoked], timeout: 0.05)

        try await MockAppSyncRealTimeClient.waitForSubscirbing()
        try await MockAppSyncRealTimeClient.waitForSubscirbed()
        mockAppSyncRealTimeClient.triggerEvent(.unsubscribed)

        await fulfillment(of: [receivedCompletionFinish,
                               receivedCompletionFailure,
                               receivedConnected,
                               receivedDisconnected,
                               receivedSubscriptionEventData,
                               receivedSubscriptionEventError
                              ],
                          timeout: 0.05)
    }

    /// Lifecycle test
    ///
    /// When:
    /// - Connect with error
    ///
    /// Then:
    /// - The value handler is not invoked with a successful connection message
    /// - The value handler is not invoked with with a data value
    /// - The value handler is invoked with a disconnection message
    /// - The completion handler is invoked with an error termination
    func testConnectionError() async throws {
        receivedCompletionFinish.shouldTrigger = false
        receivedCompletionFailure.shouldTrigger = true
        receivedConnected.shouldTrigger = false
        receivedDisconnected.shouldTrigger = false
        receivedSubscriptionEventData.shouldTrigger = false
        receivedSubscriptionEventError.shouldTrigger = false

        subscribe()
        await fulfillment(of: [onSubscribeInvoked], timeout: 0.05)

        try await MockAppSyncRealTimeClient.waitForSubscirbing()
        mockAppSyncRealTimeClient.triggerEvent(.error(["Error"]))

        await fulfillment(of: [receivedCompletionFinish,
                               receivedCompletionFailure,
                               receivedConnected,
                               receivedDisconnected,
                               receivedSubscriptionEventData,
                               receivedSubscriptionEventError
                              ],
                          timeout: 0.05)
    }

    /// Lifecycle test
    ///
    /// When:
    /// - Successfully connect
    /// - Send invalid data
    /// - Disconnect normally
    ///
    /// Then:
    /// - The value handler is invoked with a successful connection message
    /// - The value handler is invoked with an error
    /// - The value handler is invoked with a disconnection message
    /// - The completion handler is invoked with a normal termination
    func testDecodingError() async throws {
        let testData: JSONValue = [
            "data": [ "foo": true ],
            "errors": [ ]
        ]
        receivedCompletionFinish.shouldTrigger = true
        receivedCompletionFailure.shouldTrigger = false
        receivedConnected.shouldTrigger = true
        receivedDisconnected.shouldTrigger = true
        receivedSubscriptionEventData.shouldTrigger = false
        receivedSubscriptionEventError.shouldTrigger = true

        subscribe()
        await fulfillment(of: [onSubscribeInvoked], timeout: 0.05)

        try await MockAppSyncRealTimeClient.waitForSubscirbing()
        try await MockAppSyncRealTimeClient.waitForSubscirbed()
        mockAppSyncRealTimeClient.triggerEvent(.data(testData))
        mockAppSyncRealTimeClient.triggerEvent(.unsubscribed)

        await fulfillment(of: [receivedCompletionFinish,
                               receivedCompletionFailure,
                               receivedConnected,
                               receivedDisconnected,
                               receivedSubscriptionEventData,
                               receivedSubscriptionEventError
                              ],
                          timeout: 0.05)
    }

    func testMultipleSuccessValues() async throws {
        let testJSON: JSONValue = ["foo": true]
        let testData: JSONValue = [
            "data": [
                "foo": true
            ]
        ]
        receivedCompletionFinish.shouldTrigger = true
        receivedCompletionFailure.shouldTrigger = false
        receivedConnected.shouldTrigger = true
        receivedDisconnected.shouldTrigger = true
        receivedSubscriptionEventData.shouldTrigger = true
        receivedSubscriptionEventData.expectedFulfillmentCount = 2
        receivedSubscriptionEventError.shouldTrigger = false

        subscribe(expecting: testJSON)
        await fulfillment(of: [onSubscribeInvoked], timeout: 0.05)

        try await MockAppSyncRealTimeClient.waitForSubscirbing()
        try await MockAppSyncRealTimeClient.waitForSubscirbed()
        mockAppSyncRealTimeClient.triggerEvent(.data(testData))
        mockAppSyncRealTimeClient.triggerEvent(.data(testData))
        mockAppSyncRealTimeClient.triggerEvent(.unsubscribed)

        await fulfillment(of: [receivedCompletionFinish,
                               receivedCompletionFailure,
                               receivedConnected,
                               receivedDisconnected,
                               receivedSubscriptionEventData,
                               receivedSubscriptionEventError
                              ],
                          timeout: 0.05)
    }

    func testMixedSuccessAndErrorValues() async throws {
        let successfulTestData: JSONValue = [
            "data": [
                "foo": true
            ]
        ]
        let invalidTestData: JSONValue = [
            "data": [
                "foo": true
            ],
            "errors": []
        ]
        receivedCompletionFinish.shouldTrigger = true
        receivedCompletionFailure.shouldTrigger = false
        receivedConnected.shouldTrigger = true
        receivedDisconnected.shouldTrigger = true
        receivedSubscriptionEventData.shouldTrigger = true
        receivedSubscriptionEventData.expectedFulfillmentCount = 2
        receivedSubscriptionEventError.shouldTrigger = true

        subscribe()
        await fulfillment(of: [onSubscribeInvoked], timeout: 0.05)

        try await MockAppSyncRealTimeClient.waitForSubscirbing()
        try await MockAppSyncRealTimeClient.waitForSubscirbed()
        mockAppSyncRealTimeClient.triggerEvent(.data(successfulTestData))
        mockAppSyncRealTimeClient.triggerEvent(.data(invalidTestData))
        mockAppSyncRealTimeClient.triggerEvent(.data(successfulTestData))
        mockAppSyncRealTimeClient.triggerEvent(.unsubscribed)

        await fulfillment(of: [receivedCompletionFinish,
                               receivedCompletionFailure,
                               receivedConnected,
                               receivedDisconnected,
                               receivedSubscriptionEventData,
                               receivedSubscriptionEventError
                              ],
                          timeout: 0.05)
    }

    // MARK: - Utilities

    /// Sets up test with a mock subscription connection handler that populates
    /// self.subscriptionItem and self.subscriptionEventHandler, then fulfills
    /// self.onSubscribeInvoked
    func setUpMocksAndSubscriptionItems() throws {
        defer { onSubscribeInvoked.fulfill() }
        let mockAppSyncRealTimeClient = MockAppSyncRealTimeClient()

        self.mockAppSyncRealTimeClient = mockAppSyncRealTimeClient
        try setUpPluginForSubscriptionResponse { _, _, _, _, _ in
            mockAppSyncRealTimeClient
        }
    }

    /// Calls `Amplify.API.subscribe` with a request made from a generic document, and returns
    /// the operation created from that subscription. If `expectedValue` is not nil, also asserts
    /// that the received value is equal to the expected value
    @discardableResult
    func subscribe(
        expecting expectedValue: JSONValue? = nil
    ) -> GraphQLSubscriptionOperation<JSONValue> {
        let testDocument = "subscribe { subscribeTodos { id name description }}"

        let request = GraphQLRequest(
            document: testDocument,
            variables: nil,
            responseType: JSONValue.self
        )

        let operation = apiPlugin.subscribe(
            request: request,
            valueListener: { value in
                switch value {
                case .connection(let connectionState):
                    switch connectionState {
                    case .connecting:
                        break
                    case .connected:
                        self.receivedConnected.fulfill()
                    case .disconnected:
                        self.receivedDisconnected.fulfill()
                    }
                case .data(let result):
                    switch result {
                    case .success(let actualValue):
                        if let expectedValue = expectedValue {
                            XCTAssertEqual(actualValue, expectedValue)
                        }
                        self.receivedSubscriptionEventData.fulfill()
                    case .failure:
                        self.receivedSubscriptionEventError.fulfill()
                    }
                }
        }, completionListener: { result in
            switch result {
            case .failure:
                self.receivedCompletionFailure.fulfill()
            case .success:
                self.receivedCompletionFinish.fulfill()
            }
        })

        return operation
    }
}
