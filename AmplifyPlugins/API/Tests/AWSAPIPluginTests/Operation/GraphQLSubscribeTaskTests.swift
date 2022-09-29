//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Combine
import XCTest

import Amplify
@testable import AmplifyTestCommon
@testable import AWSAPIPlugin
import AppSyncRealTimeClient

class GraphQLSubscribeTasksTests: OperationTestBase {

    // Setup expectations
    var onSubscribeInvoked: XCTestExpectation!
    var receivedCompletionSuccess: XCTestExpectation!
    var receivedCompletionFailure: XCTestExpectation!
    
    // Subscription state expectations
    var receivedStateValueConnecting: XCTestExpectation!
    var receivedStateValueConnected: XCTestExpectation!
    var receivedStateValueDisconnected: XCTestExpectation!

    // Subscription item expectations
    var receivedDataValueSuccess: XCTestExpectation!
    var receivedDataValueError: XCTestExpectation!

    // Handles to the subscription item and event handler used to make mock calls into the
    // subscription system
    var subscriptionItem: SubscriptionItem!
    var subscriptionEventHandler: SubscriptionEventHandler!

    var connectionStateSink: AnyCancellable?
    var subscriptionDataSink: AnyCancellable?

    override func setUp() async throws {
        try await super.setUp()
        onSubscribeInvoked = expectation(description: "onSubscribeInvoked")
        try setUpMocksAndSubscriptionItems()
    }


    func setupExpectations() {
        receivedCompletionSuccess = expectation(description: "receivedStateCompletionSuccess")
        receivedCompletionFailure = expectation(description: "receivedStateCompletionFailure")
        receivedStateValueConnecting = expectation(description: "receivedStateValueConnecting")
        receivedStateValueConnected = expectation(description: "receivedStateValueConnected")
        receivedStateValueDisconnected = expectation(description: "receivedStateValueDisconnected")

        receivedDataValueSuccess = expectation(description: "receivedDataValueSuccess")
        receivedDataValueError = expectation(description: "receivedDataValueError")
    }

    func testHappyPath() async throws {

        let testJSON: JSONValue = ["foo": true]
        let testData = #"{"data": {"foo": true}}"# .data(using: .utf8)!

        try await subscribe(expecting: testJSON)
        await waitForExpectations(timeout: 0.05)

        setupExpectations()
        receivedCompletionSuccess.isInverted = false
        receivedCompletionFailure.isInverted = true
        receivedStateValueConnecting.isInverted = false
        receivedStateValueConnected.isInverted = false
        receivedStateValueDisconnected.isInverted = false

        receivedDataValueSuccess.isInverted = false
        receivedDataValueError.isInverted = true

        subscriptionEventHandler(.connection(.connecting), subscriptionItem)
        subscriptionEventHandler(.connection(.connected), subscriptionItem)
        subscriptionEventHandler(.data(testData), subscriptionItem)
        subscriptionEventHandler(.connection(.disconnected), subscriptionItem)

        await waitForExpectations(timeout: 0.05)
    }

    func testConnectionWithNoData() async throws {

        try await subscribe()
        await waitForExpectations(timeout: 0.05)
        setupExpectations()

        receivedCompletionSuccess.isInverted = false
        receivedCompletionFailure.isInverted = true
        receivedStateValueConnecting.isInverted = false
        receivedStateValueConnected.isInverted = false
        receivedStateValueDisconnected.isInverted = false

        receivedDataValueSuccess.isInverted = true
        receivedDataValueError.isInverted = true

        subscriptionEventHandler(.connection(.connecting), subscriptionItem)
        subscriptionEventHandler(.connection(.connected), subscriptionItem)
        subscriptionEventHandler(.connection(.disconnected), subscriptionItem)

        await waitForExpectations(timeout: 0.05)
    }

    func testConnectionError() async throws {

        try await subscribe()
        await waitForExpectations(timeout: 0.05)
        setupExpectations()

        receivedCompletionSuccess.isInverted = true
        receivedCompletionFailure.isInverted = false
        receivedStateValueConnecting.isInverted = false
        receivedStateValueConnected.isInverted = true
        receivedStateValueDisconnected.isInverted = true

        receivedDataValueSuccess.isInverted = true
        receivedDataValueError.isInverted = true

        subscriptionEventHandler(.connection(.connecting), subscriptionItem)
        subscriptionEventHandler(.failed("Error"), subscriptionItem)

        await waitForExpectations(timeout: 0.05)
    }

    func testDecodingError() async throws {
        let testData = #"{"data": {"foo": true}, "errors": []}"# .data(using: .utf8)!

        try await subscribe()
        await waitForExpectations(timeout: 0.05)
        setupExpectations()

        receivedCompletionSuccess.isInverted = false
        receivedCompletionFailure.isInverted = true
        receivedStateValueConnecting.isInverted = false
        receivedStateValueConnected.isInverted = false
        receivedStateValueDisconnected.isInverted = false

        receivedDataValueSuccess.isInverted = true
        receivedDataValueError.isInverted = false

        subscriptionEventHandler(.connection(.connecting), subscriptionItem)
        subscriptionEventHandler(.connection(.connected), subscriptionItem)
        subscriptionEventHandler(.data(testData), subscriptionItem)
        subscriptionEventHandler(.connection(.disconnected), subscriptionItem)

        await waitForExpectations(timeout: 0.05)
    }

    func testMultipleSuccessValues() async throws {
        let testJSON: JSONValue = ["foo": true]
        let testData = #"{"data": {"foo": true}}"# .data(using: .utf8)!

        try await subscribe(expecting: testJSON)
        await waitForExpectations(timeout: 0.05)
        setupExpectations()

        receivedCompletionSuccess.isInverted = false
        receivedCompletionFailure.isInverted = true
        receivedStateValueConnecting.isInverted = false
        receivedStateValueConnected.isInverted = false
        receivedStateValueDisconnected.isInverted = false

        receivedDataValueSuccess.isInverted = false
        receivedDataValueSuccess.expectedFulfillmentCount = 2
        receivedDataValueError.isInverted = true

        subscriptionEventHandler(.connection(.connecting), subscriptionItem)
        subscriptionEventHandler(.connection(.connected), subscriptionItem)
        subscriptionEventHandler(.data(testData), subscriptionItem)
        subscriptionEventHandler(.data(testData), subscriptionItem)
        subscriptionEventHandler(.connection(.disconnected), subscriptionItem)

        await waitForExpectations(timeout: 0.05)
    }

    func testMixedSuccessAndErrorValues() async throws {
        let successfulTestData = #"{"data": {"foo": true}}"# .data(using: .utf8)!
        let invalidTestData = #"{"data": {"foo": true}, "errors": []}"# .data(using: .utf8)!

        try await subscribe()
        await waitForExpectations(timeout: 0.05)
        setupExpectations()

        receivedCompletionSuccess.isInverted = false
        receivedCompletionFailure.isInverted = true
        receivedStateValueConnecting.isInverted = false
        receivedStateValueConnected.isInverted = false
        receivedStateValueDisconnected.isInverted = false

        receivedDataValueSuccess.isInverted = false
        receivedDataValueSuccess.expectedFulfillmentCount = 2
        receivedDataValueError.isInverted = false

        subscriptionEventHandler(.connection(.connecting), subscriptionItem)
        subscriptionEventHandler(.connection(.connected), subscriptionItem)
        subscriptionEventHandler(.data(successfulTestData), subscriptionItem)
        subscriptionEventHandler(.data(invalidTestData), subscriptionItem)
        subscriptionEventHandler(.data(successfulTestData), subscriptionItem)
        subscriptionEventHandler(.connection(.disconnected), subscriptionItem)

        await waitForExpectations(timeout: 0.05)
    }

    // MARK: - Utilities

    /// Sets up test with a mock subscription connection handler that populates
    /// self.subscriptionItem and self.subscriptionEventHandler, then fulfills
    /// self.onSubscribeInvoked
    func setUpMocksAndSubscriptionItems() throws {
        let onSubscribe: MockSubscriptionConnection.OnSubscribe = {
            requestString, variables, eventHandler in
            let item = SubscriptionItem(
                requestString: requestString,
                variables: variables,
                eventHandler: eventHandler
            )

            self.subscriptionItem = item
            self.subscriptionEventHandler = eventHandler
            Task { await self.onSubscribeInvoked.fulfill() }
            return item
        }

        let onGetOrCreateConnection: MockSubscriptionConnectionFactory.OnGetOrCreateConnection = { _, _, _, _  in
            MockSubscriptionConnection(onSubscribe: onSubscribe, onUnsubscribe: { _ in })
        }

        try setUpPluginForSubscriptionResponse(onGetOrCreateConnection: onGetOrCreateConnection)
    }

    /// Calls `Amplify.API.subscribe` with a request made from a generic document, and returns
    /// the operation created from that subscription. If `expectedValue` is not nil, also asserts
    /// that the received value is equal to the expected value
    func subscribe(
        expecting expectedValue: JSONValue? = nil
    ) async throws {
        let testDocument = "subscribe { subscribeTodos { id name description }}"

        let request = GraphQLRequest(
            document: testDocument,
            variables: nil,
            responseType: JSONValue.self
        )
        let subscription = apiPlugin.subscribe(request: request)
        Task {
            do {
                for try await subscriptionEvent in subscription {
                    switch subscriptionEvent {
                    case .connection(let connectionState):
                        switch connectionState {
                        case .connecting:
                            await self.receivedStateValueConnecting.fulfill()
                        case .connected:
                            await self.receivedStateValueConnected.fulfill()
                        case .disconnected:
                            await self.receivedStateValueDisconnected.fulfill()
                        }
                    case .data(let result):
                        switch result {
                        case .success(let actualValue):
                            if let expectedValue = expectedValue {
                                XCTAssertEqual(actualValue, expectedValue)
                            }
                            await self.receivedDataValueSuccess.fulfill()
                        case .failure:
                            await self.receivedDataValueError.fulfill()
                        }
                    }
                }
                
                await self.receivedCompletionSuccess.fulfill()
            } catch {
                await self.receivedCompletionFailure.fulfill()
            }
        }
    }
}
