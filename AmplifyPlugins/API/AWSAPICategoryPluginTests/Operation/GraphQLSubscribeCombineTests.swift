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
@testable import AWSAPICategoryPlugin

import AppSyncRealTimeClient

@available(iOS 13.0, *)
class GraphQLSubscribeCombineTests: OperationTestBase {

    // Setup expectations
    var onSubscribeInvoked: XCTestExpectation!

    // Subscription state expectations
    var receivedStateCompletionSuccess: XCTestExpectation!
    var receivedStateCompletionFailure: XCTestExpectation!
    var receivedStateValueConnecting: XCTestExpectation!
    var receivedStateValueConnected: XCTestExpectation!
    var receivedStateValueDisconnected: XCTestExpectation!

    // Subscription item expectations
    var receivedDataCompletionSuccess: XCTestExpectation!
    var receivedDataCompletionFailure: XCTestExpectation!
    var receivedDataValueSuccess: XCTestExpectation!
    var receivedDataValueError: XCTestExpectation!

    // Handles to the subscription item and event handler used to make mock calls into the
    // subscription system
    var subscriptionItem: SubscriptionItem!
    var subscriptionEventHandler: SubscriptionEventHandler!

    var connectionStateSink: AnyCancellable?
    var subscriptionDataSink: AnyCancellable?

    override func setUpWithError() throws {
        try super.setUpWithError()

        onSubscribeInvoked = expectation(description: "onSubscribeInvoked")

        receivedStateCompletionSuccess = expectation(description: "receivedStateCompletionSuccess")
        receivedStateCompletionFailure = expectation(description: "receivedStateCompletionFailure")
        receivedStateValueConnecting = expectation(description: "receivedStateValueConnecting")
        receivedStateValueConnected = expectation(description: "receivedStateValueConnected")
        receivedStateValueDisconnected = expectation(description: "receivedStateValueDisconnected")

        receivedDataCompletionSuccess = expectation(description: "receivedDataCompletionSuccess")
        receivedDataCompletionFailure = expectation(description: "receivedDataCompletionFailure")
        receivedDataValueSuccess = expectation(description: "receivedDataValueSuccess")
        receivedDataValueError = expectation(description: "receivedDataValueError")

        try setUpMocksAndSubscriptionItems()
    }

    func testHappyPath() throws {
        receivedStateCompletionSuccess.shouldTrigger = true
        receivedStateCompletionFailure.shouldTrigger = false
        receivedStateValueConnecting.shouldTrigger = true
        receivedStateValueConnected.shouldTrigger = true
        receivedStateValueDisconnected.shouldTrigger = true

        receivedDataCompletionSuccess.shouldTrigger = true
        receivedDataCompletionFailure.shouldTrigger = false
        receivedDataValueSuccess.shouldTrigger = true
        receivedDataValueError.shouldTrigger = false

        let testJSON: JSONValue = ["foo": true]
        let testData = #"{"data": {"foo": true}}"# .data(using: .utf8)!

        subscribe(expecting: testJSON)
        wait(for: [onSubscribeInvoked], timeout: 0.05)

        subscriptionEventHandler(.connection(.connecting), subscriptionItem)
        subscriptionEventHandler(.connection(.connected), subscriptionItem)
        subscriptionEventHandler(.data(testData), subscriptionItem)
        subscriptionEventHandler(.connection(.disconnected), subscriptionItem)

        waitForExpectations(timeout: 0.05)
    }

    func testConnectionWithNoData() throws {
        receivedStateCompletionSuccess.shouldTrigger = true
        receivedStateCompletionFailure.shouldTrigger = false
        receivedStateValueConnecting.shouldTrigger = true
        receivedStateValueConnected.shouldTrigger = true
        receivedStateValueDisconnected.shouldTrigger = true

        receivedDataCompletionSuccess.shouldTrigger = true
        receivedDataCompletionFailure.shouldTrigger = false
        receivedDataValueSuccess.shouldTrigger = false
        receivedDataValueError.shouldTrigger = false

        subscribe()
        wait(for: [onSubscribeInvoked], timeout: 0.05)

        subscriptionEventHandler(.connection(.connecting), subscriptionItem)
        subscriptionEventHandler(.connection(.connected), subscriptionItem)
        subscriptionEventHandler(.connection(.disconnected), subscriptionItem)

        waitForExpectations(timeout: 0.05)
    }

    func testConnectionError() throws {
        receivedStateCompletionSuccess.shouldTrigger = false
        receivedStateCompletionFailure.shouldTrigger = true
        receivedStateValueConnecting.shouldTrigger = true
        receivedStateValueConnected.shouldTrigger = false
        receivedStateValueDisconnected.shouldTrigger = false

        receivedDataCompletionSuccess.shouldTrigger = false
        receivedDataCompletionFailure.shouldTrigger = true
        receivedDataValueSuccess.shouldTrigger = false
        receivedDataValueError.shouldTrigger = false

        subscribe()
        wait(for: [onSubscribeInvoked], timeout: 0.05)

        subscriptionEventHandler(.connection(.connecting), subscriptionItem)
        subscriptionEventHandler(.failed("Error"), subscriptionItem)

        waitForExpectations(timeout: 0.05)
    }

    func testDecodingError() throws {
        let testData = #"{"data": {"foo": true}, "errors": []}"# .data(using: .utf8)!
        receivedStateCompletionSuccess.shouldTrigger = true
        receivedStateCompletionFailure.shouldTrigger = false
        receivedStateValueConnecting.shouldTrigger = true
        receivedStateValueConnected.shouldTrigger = true
        receivedStateValueDisconnected.shouldTrigger = true

        receivedDataCompletionSuccess.shouldTrigger = true
        receivedDataCompletionFailure.shouldTrigger = false
        receivedDataValueSuccess.shouldTrigger = false
        receivedDataValueError.shouldTrigger = true

        subscribe()
        wait(for: [onSubscribeInvoked], timeout: 0.05)

        subscriptionEventHandler(.connection(.connecting), subscriptionItem)
        subscriptionEventHandler(.connection(.connected), subscriptionItem)
        subscriptionEventHandler(.data(testData), subscriptionItem)
        subscriptionEventHandler(.connection(.disconnected), subscriptionItem)

        waitForExpectations(timeout: 0.05)
    }

    func testMultipleSuccessValues() throws {
        let testJSON: JSONValue = ["foo": true]
        let testData = #"{"data": {"foo": true}}"# .data(using: .utf8)!
        receivedStateCompletionSuccess.shouldTrigger = true
        receivedStateCompletionFailure.shouldTrigger = false
        receivedStateValueConnecting.shouldTrigger = true
        receivedStateValueConnected.shouldTrigger = true
        receivedStateValueDisconnected.shouldTrigger = true

        receivedDataCompletionSuccess.shouldTrigger = true
        receivedDataCompletionFailure.shouldTrigger = false
        receivedDataValueSuccess.shouldTrigger = true
        receivedDataValueSuccess.expectedFulfillmentCount = 2
        receivedDataValueError.shouldTrigger = false

        subscribe(expecting: testJSON)
        wait(for: [onSubscribeInvoked], timeout: 0.05)

        subscriptionEventHandler(.connection(.connecting), subscriptionItem)
        subscriptionEventHandler(.connection(.connected), subscriptionItem)
        subscriptionEventHandler(.data(testData), subscriptionItem)
        subscriptionEventHandler(.data(testData), subscriptionItem)
        subscriptionEventHandler(.connection(.disconnected), subscriptionItem)

        waitForExpectations(timeout: 0.05)
    }

    func testMixedSuccessAndErrorValues() throws {
        let successfulTestData = #"{"data": {"foo": true}}"# .data(using: .utf8)!
        let invalidTestData = #"{"data": {"foo": true}, "errors": []}"# .data(using: .utf8)!
        receivedStateCompletionSuccess.shouldTrigger = true
        receivedStateCompletionFailure.shouldTrigger = false
        receivedStateValueConnecting.shouldTrigger = true
        receivedStateValueConnected.shouldTrigger = true
        receivedStateValueDisconnected.shouldTrigger = true

        receivedDataCompletionSuccess.shouldTrigger = true
        receivedDataCompletionFailure.shouldTrigger = false
        receivedDataValueSuccess.shouldTrigger = true
        receivedDataValueSuccess.expectedFulfillmentCount = 2
        receivedDataValueError.shouldTrigger = true

        subscribe()
        wait(for: [onSubscribeInvoked], timeout: 0.05)

        subscriptionEventHandler(.connection(.connecting), subscriptionItem)
        subscriptionEventHandler(.connection(.connected), subscriptionItem)
        subscriptionEventHandler(.data(successfulTestData), subscriptionItem)
        subscriptionEventHandler(.data(invalidTestData), subscriptionItem)
        subscriptionEventHandler(.data(successfulTestData), subscriptionItem)
        subscriptionEventHandler(.connection(.disconnected), subscriptionItem)

        waitForExpectations(timeout: 0.05)
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
            self.onSubscribeInvoked.fulfill()
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

        let operation = apiPlugin.subscribe(request: request)
        connectionStateSink = operation
            .connectionStatePublisher
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .failure:
                        self.receivedStateCompletionFailure.fulfill()
                    case .finished:
                        self.receivedStateCompletionSuccess.fulfill()
                    }
            }, receiveValue: { connectionState in
                switch connectionState {
                case .connecting:
                    self.receivedStateValueConnecting.fulfill()
                case .connected:
                    self.receivedStateValueConnected.fulfill()
                case .disconnected:
                    self.receivedStateValueDisconnected.fulfill()
                }
            }
        )

        subscriptionDataSink = operation
            .subscriptionDataPublisher
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure:
                    self.receivedDataCompletionFailure.fulfill()
                case .finished:
                    self.receivedDataCompletionSuccess.fulfill()
                }
            }, receiveValue: { result in
                switch result {
                case .success(let actualValue):
                    if let expectedValue = expectedValue {
                        XCTAssertEqual(actualValue, expectedValue)
                    }
                    self.receivedDataValueSuccess.fulfill()
                case .failure:
                    self.receivedDataValueError.fulfill()
                }
            }
        )

        return operation
    }

}
