//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSAPICategoryPlugin
import AppSyncRealTimeClient

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

    // Handles to the subscription item and event handler used to make mock calls into the
    // subscription system
    var subscriptionItem: SubscriptionItem!
    var subscriptionEventHandler: SubscriptionEventHandler!

    var expectedCompletionFailureError: APIError?

    override func setUpWithError() throws {
        try super.setUpWithError()

        onSubscribeInvoked = expectation(description: "onSubscribeInvoked")

        receivedCompletionFinish = expectation(description: "receivedCompletionFinish")
        receivedCompletionFailure = expectation(description: "receivedCompletionFailure")

        receivedConnected = expectation(description: "receivedConnected")
        receivedDisconnected = expectation(description: "receivedDisconnected")

        receivedSubscriptionEventData = expectation(description: "receivedSubscriptionEventData")
        receivedSubscriptionEventError = expectation(description: "receivedSubscriptionEventError")

        try setUpMocksAndSubscriptionItems()
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
    func testHappyPath() throws {
        let testJSON: JSONValue = ["foo": true]
        let testData = #"{"data": {"foo": true}}"# .data(using: .utf8)!
        receivedCompletionFinish.shouldTrigger = true
        receivedCompletionFailure.shouldTrigger = false
        receivedConnected.shouldTrigger = true
        receivedDisconnected.shouldTrigger = true
        receivedSubscriptionEventData.shouldTrigger = true
        receivedSubscriptionEventError.shouldTrigger = false

        subscribe(expecting: testJSON)
        wait(for: [onSubscribeInvoked], timeout: 0.05)

        subscriptionEventHandler(.connection(.connecting), subscriptionItem)
        subscriptionEventHandler(.connection(.connected), subscriptionItem)
        subscriptionEventHandler(.data(testData), subscriptionItem)
        subscriptionEventHandler(.connection(.disconnected), subscriptionItem)

        waitForExpectations(timeout: 0.05)
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
    func testConnectionWithNoData() throws {
        receivedCompletionFinish.shouldTrigger = true
        receivedCompletionFailure.shouldTrigger = false
        receivedConnected.shouldTrigger = true
        receivedDisconnected.shouldTrigger = true
        receivedSubscriptionEventData.shouldTrigger = false
        receivedSubscriptionEventError.shouldTrigger = false

        subscribe()
        wait(for: [onSubscribeInvoked], timeout: 0.05)

        subscriptionEventHandler(.connection(.connecting), subscriptionItem)
        subscriptionEventHandler(.connection(.connected), subscriptionItem)
        subscriptionEventHandler(.connection(.disconnected), subscriptionItem)

        waitForExpectations(timeout: 0.05)
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
    func testConnectionErrorWithLimitExceeded() throws {
        receivedCompletionFinish.shouldTrigger = false
        receivedCompletionFailure.shouldTrigger = true
        receivedConnected.shouldTrigger = false
        receivedDisconnected.shouldTrigger = false
        receivedSubscriptionEventData.shouldTrigger = false
        receivedSubscriptionEventError.shouldTrigger = false

        subscribe()
        wait(for: [onSubscribeInvoked], timeout: 0.05)

        subscriptionEventHandler(.failed(ConnectionProviderError.limitExceeded(nil)), subscriptionItem)
        expectedCompletionFailureError = APIError.operationError("", "", ConnectionProviderError.limitExceeded(nil))
        waitForExpectations(timeout: 0.05)
    }

    func testConnectionErrorWithSubscriptionError() throws {
        receivedCompletionFinish.shouldTrigger = false
        receivedCompletionFailure.shouldTrigger = true
        receivedConnected.shouldTrigger = false
        receivedDisconnected.shouldTrigger = false
        receivedSubscriptionEventData.shouldTrigger = false
        receivedSubscriptionEventError.shouldTrigger = false

        subscribe()
        wait(for: [onSubscribeInvoked], timeout: 0.05)

        subscriptionEventHandler(.connection(.connecting), subscriptionItem)
        subscriptionEventHandler(.failed(ConnectionProviderError.subscription("", nil)), subscriptionItem)
        expectedCompletionFailureError = APIError.operationError("", "", ConnectionProviderError.subscription("", nil))
        waitForExpectations(timeout: 0.05)
    }

    func testConnectionErrorWithConnectionUnauthorizedError() throws {
        receivedCompletionFinish.shouldTrigger = false
        receivedCompletionFailure.shouldTrigger = true
        receivedConnected.shouldTrigger = false
        receivedDisconnected.shouldTrigger = false
        receivedSubscriptionEventData.shouldTrigger = false
        receivedSubscriptionEventError.shouldTrigger = false

        subscribe()
        wait(for: [onSubscribeInvoked], timeout: 0.05)

        subscriptionEventHandler(.connection(.connecting), subscriptionItem)
        subscriptionEventHandler(.failed(ConnectionProviderError.unauthorized), subscriptionItem)
        expectedCompletionFailureError = APIError.operationError("", "", ConnectionProviderError.unauthorized)
        waitForExpectations(timeout: 0.05)
    }

    func testConnectionErrorWithConnectionProviderConnectionError() throws {
        receivedCompletionFinish.shouldTrigger = false
        receivedCompletionFailure.shouldTrigger = true
        receivedConnected.shouldTrigger = false
        receivedDisconnected.shouldTrigger = false
        receivedSubscriptionEventData.shouldTrigger = false
        receivedSubscriptionEventError.shouldTrigger = false

        subscribe()
        wait(for: [onSubscribeInvoked], timeout: 0.05)

        subscriptionEventHandler(.connection(.connecting), subscriptionItem)
        subscriptionEventHandler(.failed(ConnectionProviderError.connection), subscriptionItem)
        expectedCompletionFailureError = APIError.networkError("", nil, URLError(.networkConnectionLost))
        waitForExpectations(timeout: 0.05)
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
    func testDecodingError() throws {
        let testData = #"{"data": {"foo": true}, "errors": []}"# .data(using: .utf8)!
        receivedCompletionFinish.shouldTrigger = true
        receivedCompletionFailure.shouldTrigger = false
        receivedConnected.shouldTrigger = true
        receivedDisconnected.shouldTrigger = true
        receivedSubscriptionEventData.shouldTrigger = false
        receivedSubscriptionEventError.shouldTrigger = true

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
        receivedCompletionFinish.shouldTrigger = true
        receivedCompletionFailure.shouldTrigger = false
        receivedConnected.shouldTrigger = true
        receivedDisconnected.shouldTrigger = true
        receivedSubscriptionEventData.shouldTrigger = true
        receivedSubscriptionEventData.expectedFulfillmentCount = 2
        receivedSubscriptionEventError.shouldTrigger = false

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
        receivedCompletionFinish.shouldTrigger = true
        receivedCompletionFailure.shouldTrigger = false
        receivedConnected.shouldTrigger = true
        receivedDisconnected.shouldTrigger = true
        receivedSubscriptionEventData.shouldTrigger = true
        receivedSubscriptionEventData.expectedFulfillmentCount = 2
        receivedSubscriptionEventError.shouldTrigger = true

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

        let onGetOrCreateConnection: MockSubscriptionConnectionFactory.OnGetOrCreateConnection = { _, _, _, _  in
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
            case .failure(let error):
                if let apiError = error as? APIError,
                   let expectedError = self.expectedCompletionFailureError {
                    XCTAssertEqual(apiError, expectedError)
                }
                self.receivedCompletionFailure.fulfill()
            case .success:
                self.receivedCompletionFinish.fulfill()
            }
        })

        return operation
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
