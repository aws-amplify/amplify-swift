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
    var expectedCompletionFailureError: APIError?

    override func setUp() async throws {
        try await super.setUp()

        onSubscribeInvoked = expectation(description: "onSubscribeInvoked")

        receivedCompletionSuccess = expectation(description: "receivedStateCompletionSuccess")
        receivedCompletionFailure = expectation(description: "receivedStateCompletionFailure")
        receivedStateValueConnecting = expectation(description: "receivedStateValueConnecting")
        receivedStateValueConnected = expectation(description: "receivedStateValueConnected")
        receivedStateValueDisconnected = expectation(description: "receivedStateValueDisconnected")

        receivedDataValueSuccess = expectation(description: "receivedDataValueSuccess")
        receivedDataValueError = expectation(description: "receivedDataValueError")

        try setUpMocksAndSubscriptionItems()
    }

    func waitForSubscriptionExpectations() async {
        await fulfillment(
            of: [
                receivedCompletionSuccess,
                receivedCompletionFailure,
                receivedStateValueConnecting,
                receivedStateValueConnected,
                receivedStateValueDisconnected,
                receivedDataValueSuccess,
                receivedDataValueError
            ],
            timeout: 0.05
        )
    }
    
    func testHappyPath() async throws {
        receivedCompletionFailure.isInverted = true
        receivedDataValueError.isInverted = true

        let testJSON: JSONValue = ["foo": true]
        let testData = #"{"data": {"foo": true}}"# .data(using: .utf8)!

        try await subscribe(expecting: testJSON)
        await fulfillment(of: [onSubscribeInvoked], timeout: 0.05)

        subscriptionEventHandler(.connection(.connecting), subscriptionItem)
        subscriptionEventHandler(.connection(.connected), subscriptionItem)
        subscriptionEventHandler(.data(testData), subscriptionItem)
        subscriptionEventHandler(.connection(.disconnected), subscriptionItem)

        await waitForSubscriptionExpectations()
    }

    func testConnectionWithNoData() async throws {
        receivedCompletionFailure.isInverted = true
        receivedDataValueSuccess.isInverted = true
        receivedDataValueError.isInverted = true

        try await subscribe()
        await fulfillment(of: [onSubscribeInvoked], timeout: 0.05)

        subscriptionEventHandler(.connection(.connecting), subscriptionItem)
        subscriptionEventHandler(.connection(.connected), subscriptionItem)
        subscriptionEventHandler(.connection(.disconnected), subscriptionItem)

        await waitForSubscriptionExpectations()
    }

    func testConnectionErrorWithLimitExceeded() async throws {
        receivedCompletionSuccess.isInverted = true
        receivedStateValueConnected.isInverted = true
        receivedStateValueDisconnected.isInverted = true
        receivedDataValueSuccess.isInverted = true
        receivedDataValueError.isInverted = true

        try await subscribe()
        await fulfillment(of: [onSubscribeInvoked], timeout: 0.05)

        subscriptionEventHandler(.connection(.connecting), subscriptionItem)
        subscriptionEventHandler(.failed(ConnectionProviderError.limitExceeded(nil)), subscriptionItem)
        expectedCompletionFailureError = APIError.operationError("", "", ConnectionProviderError.limitExceeded(nil))
        await waitForSubscriptionExpectations()
    }
    
    func testConnectionErrorWithSubscriptionError() async throws {
        receivedCompletionSuccess.isInverted = true
        receivedStateValueConnected.isInverted = true
        receivedStateValueDisconnected.isInverted = true
        receivedDataValueSuccess.isInverted = true
        receivedDataValueError.isInverted = true

        try await subscribe()
        await fulfillment(of: [onSubscribeInvoked], timeout: 0.05)

        subscriptionEventHandler(.connection(.connecting), subscriptionItem)
        subscriptionEventHandler(.failed(ConnectionProviderError.subscription("", nil)), subscriptionItem)
        expectedCompletionFailureError = APIError.operationError("", "", ConnectionProviderError.subscription("", nil))
        await waitForSubscriptionExpectations()
    }
    
    func testConnectionErrorWithConnectionUnauthorizedError() async throws {
        receivedCompletionSuccess.isInverted = true
        receivedStateValueConnected.isInverted = true
        receivedStateValueDisconnected.isInverted = true
        receivedDataValueSuccess.isInverted = true
        receivedDataValueError.isInverted = true

        try await subscribe()
        await fulfillment(of: [onSubscribeInvoked], timeout: 0.05)

        subscriptionEventHandler(.connection(.connecting), subscriptionItem)
        subscriptionEventHandler(.failed(ConnectionProviderError.unauthorized), subscriptionItem)
        expectedCompletionFailureError = APIError.operationError("", "", ConnectionProviderError.unauthorized)
        await waitForSubscriptionExpectations()
    }
    
    func testConnectionErrorWithConnectionProviderConnectionError() async throws {
        receivedCompletionSuccess.isInverted = true
        receivedStateValueConnected.isInverted = true
        receivedStateValueDisconnected.isInverted = true
        receivedDataValueSuccess.isInverted = true
        receivedDataValueError.isInverted = true

        try await subscribe()
        await fulfillment(of: [onSubscribeInvoked], timeout: 0.05)

        subscriptionEventHandler(.connection(.connecting), subscriptionItem)
        subscriptionEventHandler(.failed(ConnectionProviderError.connection), subscriptionItem)
        expectedCompletionFailureError = APIError.networkError("", nil, URLError(.networkConnectionLost))
        await waitForSubscriptionExpectations()
    }

    func testDecodingError() async throws {
        let testData = #"{"data": {"foo": true}, "errors": []}"# .data(using: .utf8)!
        receivedCompletionFailure.isInverted = true
        receivedDataValueSuccess.isInverted = true

        try await subscribe()
        await fulfillment(of: [onSubscribeInvoked], timeout: 0.05)

        subscriptionEventHandler(.connection(.connecting), subscriptionItem)
        subscriptionEventHandler(.connection(.connected), subscriptionItem)
        subscriptionEventHandler(.data(testData), subscriptionItem)
        subscriptionEventHandler(.connection(.disconnected), subscriptionItem)

        await waitForSubscriptionExpectations()
    }

    func testMultipleSuccessValues() async throws {
        let testJSON: JSONValue = ["foo": true]
        let testData = #"{"data": {"foo": true}}"# .data(using: .utf8)!

        receivedCompletionFailure.isInverted = true
        receivedDataValueError.isInverted = true
        receivedDataValueSuccess.expectedFulfillmentCount = 2

        try await subscribe(expecting: testJSON)
        await fulfillment(of: [onSubscribeInvoked], timeout: 0.05)

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

        receivedCompletionFailure.isInverted = true
        receivedDataValueSuccess.expectedFulfillmentCount = 2

        try await subscribe()
        await fulfillment(of: [onSubscribeInvoked], timeout: 0.05)

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
                            self.receivedStateValueConnecting.fulfill()
                        case .connected:
                            self.receivedStateValueConnected.fulfill()
                        case .disconnected:
                            self.receivedStateValueDisconnected.fulfill()
                        }
                    case .data(let result):
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
                }
                
                self.receivedCompletionSuccess.fulfill()
            } catch {
                if let apiError = error as? APIError,
                   let expectedError = expectedCompletionFailureError {
                    XCTAssertEqual(apiError, expectedError)
                }
                
                self.receivedCompletionFailure.fulfill()
            }
        }
    }
}
 
extension APIError: Equatable {
    public static func == (lhs: APIError, rhs: APIError) -> Bool {
        switch (lhs, rhs) {
        case (.unknown, .unknown),
            (.invalidConfiguration, .invalidConfiguration),
            (.httpStatusError, .httpStatusError),
            (.pluginError, .pluginError):
            return true
        case (.operationError(_, _, let lhs), .operationError(_, _, let rhs)):
            if let lhs = lhs as? ConnectionProviderError, let rhs = rhs as? ConnectionProviderError {
                switch (lhs, rhs) {
                case (.connection, .connection),
                    (.jsonParse, .jsonParse),
                    (.limitExceeded, .limitExceeded),
                    (.subscription, .subscription),
                    (.unauthorized, .unauthorized),
                    (.unknown, .unknown):
                    return true
                default:
                    return false
                }
            } else if lhs == nil && rhs == nil {
                return true
            } else {
                return false
            }
        case (.networkError(_, _, let lhs), .networkError(_, _, let rhs)):
            if let lhs = lhs as? URLError, let rhs = rhs as? URLError {
                return lhs.code == rhs.code
            } else if lhs == nil && rhs == nil {
                return true
            } else {
                return false
            }
        default:
            return false
        }
    }
}
