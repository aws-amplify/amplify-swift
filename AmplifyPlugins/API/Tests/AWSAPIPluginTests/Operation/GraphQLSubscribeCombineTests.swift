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
@_implementationOnly import AmplifyAsyncTesting
import AppSyncRealTimeClient

class GraphQLSubscribeCombineTests: OperationTestBase {

    var sink: AnyCancellable?
    
    // Setup expectations
    var onSubscribeInvoked: AsyncExpectation!
    var receivedCompletionSuccess: AsyncExpectation!
    var receivedCompletionFailure: AsyncExpectation!
    
    // Subscription state expectations
    var receivedStateValueConnecting: AsyncExpectation!
    var receivedStateValueConnected: AsyncExpectation!
    var receivedStateValueDisconnected: AsyncExpectation!

    // Subscription item expectations
    var receivedDataValueSuccess: AsyncExpectation!
    var receivedDataValueError: AsyncExpectation!

    // Handles to the subscription item and event handler used to make mock calls into the
    // subscription system
    var subscriptionItem: SubscriptionItem!
    var subscriptionEventHandler: SubscriptionEventHandler!

    var connectionStateSink: AnyCancellable?
    var subscriptionDataSink: AnyCancellable?

    override func setUp() async throws {
        try await super.setUp()

        onSubscribeInvoked = asyncExpectation(description: "onSubscribeInvoked")

        receivedCompletionSuccess = asyncExpectation(description: "receivedStateCompletionSuccess")
        receivedCompletionFailure = asyncExpectation(description: "receivedStateCompletionFailure")
        receivedStateValueConnecting = asyncExpectation(description: "receivedStateValueConnecting")
        receivedStateValueConnected = asyncExpectation(description: "receivedStateValueConnected")
        receivedStateValueDisconnected = asyncExpectation(description: "receivedStateValueDisconnected")

        receivedDataValueSuccess = asyncExpectation(description: "receivedDataValueSuccess")
        receivedDataValueError = asyncExpectation(description: "receivedDataValueError")

        try setUpMocksAndSubscriptionItems()
    }

    func waitForSubscriptionExpectations() async {
        await waitForExpectations([receivedCompletionSuccess,
                                   receivedCompletionFailure,
                                   receivedStateValueConnecting,
                                   receivedStateValueConnected,
                                   receivedStateValueDisconnected,
                                   receivedDataValueSuccess,
                                   receivedDataValueError], timeout: 0.05)
    }
    
    func testHappyPath() async throws {
        await receivedCompletionSuccess.setShouldTrigger(true)
        await receivedCompletionFailure.setShouldTrigger(false)
        await receivedStateValueConnecting.setShouldTrigger(true)
        await receivedStateValueConnected.setShouldTrigger(true)
        await receivedStateValueDisconnected.setShouldTrigger(true)

        await receivedDataValueSuccess.setShouldTrigger(true)
        await receivedDataValueError.setShouldTrigger(false)

        let testJSON: JSONValue = ["foo": true]
        let testData = #"{"data": {"foo": true}}"# .data(using: .utf8)!

        try await subscribe(expecting: testJSON)
        await waitForExpectations([onSubscribeInvoked], timeout: 0.05)

        subscriptionEventHandler(.connection(.connecting), subscriptionItem)
        subscriptionEventHandler(.connection(.connected), subscriptionItem)
        subscriptionEventHandler(.data(testData), subscriptionItem)
        subscriptionEventHandler(.connection(.disconnected), subscriptionItem)

        await waitForSubscriptionExpectations()
    }

    func testConnectionWithNoData() async throws {
        await receivedCompletionSuccess.setShouldTrigger(true)
        await receivedCompletionFailure.setShouldTrigger(false)
        await receivedStateValueConnecting.setShouldTrigger(true)
        await receivedStateValueConnected.setShouldTrigger(true)
        await receivedStateValueDisconnected.setShouldTrigger(true)

        await receivedDataValueSuccess.setShouldTrigger(false)
        await receivedDataValueError.setShouldTrigger(false)

        try await subscribe()
        await waitForExpectations([onSubscribeInvoked], timeout: 0.05)

        subscriptionEventHandler(.connection(.connecting), subscriptionItem)
        subscriptionEventHandler(.connection(.connected), subscriptionItem)
        subscriptionEventHandler(.connection(.disconnected), subscriptionItem)

        await waitForSubscriptionExpectations()
    }

    func testConnectionError() async throws {
        await receivedCompletionSuccess.setShouldTrigger(false)
        await receivedCompletionFailure.setShouldTrigger(true)
        await receivedStateValueConnecting.setShouldTrigger(true)
        await receivedStateValueConnected.setShouldTrigger(false)
        await receivedStateValueDisconnected.setShouldTrigger(false)

        await receivedDataValueSuccess.setShouldTrigger(false)
        await receivedDataValueError.setShouldTrigger(false)

        try await subscribe()
        await waitForExpectations([onSubscribeInvoked], timeout: 0.05)

        subscriptionEventHandler(.connection(.connecting), subscriptionItem)
        subscriptionEventHandler(.failed("Error"), subscriptionItem)

        await waitForSubscriptionExpectations()
    }

    func testDecodingError() async throws {
        let testData = #"{"data": {"foo": true}, "errors": []}"# .data(using: .utf8)!
        await receivedCompletionSuccess.setShouldTrigger(true)
        await receivedCompletionFailure.setShouldTrigger(false)
        await receivedStateValueConnecting.setShouldTrigger(true)
        await receivedStateValueConnected.setShouldTrigger(true)
        await receivedStateValueDisconnected.setShouldTrigger(true)

        await receivedDataValueSuccess.setShouldTrigger(false)
        await receivedDataValueError.setShouldTrigger(true)

        try await subscribe()
        await waitForExpectations([onSubscribeInvoked], timeout: 0.05)

        subscriptionEventHandler(.connection(.connecting), subscriptionItem)
        subscriptionEventHandler(.connection(.connected), subscriptionItem)
        subscriptionEventHandler(.data(testData), subscriptionItem)
        subscriptionEventHandler(.connection(.disconnected), subscriptionItem)

        await waitForSubscriptionExpectations()
    }

    func testMultipleSuccessValues() async throws {
        let testJSON: JSONValue = ["foo": true]
        let testData = #"{"data": {"foo": true}}"# .data(using: .utf8)!
        await receivedCompletionSuccess.setShouldTrigger(true)
        await receivedCompletionFailure.setShouldTrigger(false)
        await receivedStateValueConnecting.setShouldTrigger(true)
        await receivedStateValueConnected.setShouldTrigger(true)
        await receivedStateValueDisconnected.setShouldTrigger(true)

        await receivedDataValueSuccess.setShouldTrigger(true)
        await receivedDataValueSuccess.setExpectedFulfillmentCount(2)
        await receivedDataValueError.setShouldTrigger(false)

        try await subscribe(expecting: testJSON)
        await waitForExpectations([onSubscribeInvoked], timeout: 0.05)

        subscriptionEventHandler(.connection(.connecting), subscriptionItem)
        subscriptionEventHandler(.connection(.connected), subscriptionItem)
        subscriptionEventHandler(.data(testData), subscriptionItem)
        subscriptionEventHandler(.data(testData), subscriptionItem)
        subscriptionEventHandler(.connection(.disconnected), subscriptionItem)

        await waitForSubscriptionExpectations()
    }

    func testMixedSuccessAndErrorValues() async throws {
        let successfulTestData = #"{"data": {"foo": true}}"# .data(using: .utf8)!
        let invalidTestData = #"{"data": {"foo": true}, "errors": []}"# .data(using: .utf8)!
        await receivedCompletionSuccess.setShouldTrigger(true)
        await receivedCompletionFailure.setShouldTrigger(false)
        await receivedStateValueConnecting.setShouldTrigger(true)
        await receivedStateValueConnected.setShouldTrigger(true)
        await receivedStateValueDisconnected.setShouldTrigger(true)

        await receivedDataValueSuccess.setShouldTrigger(true)
        await receivedDataValueSuccess.setExpectedFulfillmentCount(2)
        await receivedDataValueError.setShouldTrigger(true)

        try await subscribe()
        await waitForExpectations([onSubscribeInvoked], timeout: 0.05)

        subscriptionEventHandler(.connection(.connecting), subscriptionItem)
        subscriptionEventHandler(.connection(.connected), subscriptionItem)
        subscriptionEventHandler(.data(successfulTestData), subscriptionItem)
        subscriptionEventHandler(.data(invalidTestData), subscriptionItem)
        subscriptionEventHandler(.data(successfulTestData), subscriptionItem)
        subscriptionEventHandler(.connection(.disconnected), subscriptionItem)

        await waitForSubscriptionExpectations()
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

        let onGetOrCreateConnection: MockSubscriptionConnectionFactory.OnGetOrCreateConnection = { _, _, _, _, _  in
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
        sink = Amplify.Publisher.create(subscription).sink { completion in
            switch completion {
            case .failure:
                Task { await self.receivedCompletionFailure.fulfill() }
            case .finished:
                Task { await self.receivedCompletionSuccess.fulfill() }
            }
        } receiveValue: { subscriptionEvent in
            switch subscriptionEvent {
            case .connection(let connectionState):
                switch connectionState {
                case .connecting:
                    Task { await self.receivedStateValueConnecting.fulfill() }
                case .connected:
                    Task { await self.receivedStateValueConnected.fulfill() }
                case .disconnected:
                    Task { await self.receivedStateValueDisconnected.fulfill() }
                }
            case .data(let result):
                switch result {
                case .success(let actualValue):
                    if let expectedValue = expectedValue {
                        XCTAssertEqual(actualValue, expectedValue)
                    }
                    Task { await self.receivedDataValueSuccess.fulfill() }
                case .failure:
                    Task { await self.receivedDataValueError.fulfill() }
                }
            }
        }
    }

}
