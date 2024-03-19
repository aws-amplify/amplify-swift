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

    var connectionStateSink: AnyCancellable?
    var subscriptionDataSink: AnyCancellable?
    var expectedCompletionFailureError: APIError?
    var mockAppSyncRealTimeClient: MockAppSyncRealTimeClient?

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

    override func tearDown() async throws {
        connectionStateSink?.cancel()
        subscriptionDataSink?.cancel()

        onSubscribeInvoked = nil
        receivedCompletionFailure = nil
        receivedCompletionSuccess = nil
        receivedStateValueConnected = nil
        receivedStateValueConnecting = nil
        receivedStateValueDisconnected = nil

        receivedDataValueError = nil
        receivedDataValueSuccess = nil
        mockAppSyncRealTimeClient = nil
        try await super.tearDown()
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
        let testData: JSONValue = [
            "data": [
                "foo": true
            ]
        ]

        try await subscribe(expecting: testJSON)
        await fulfillment(of: [onSubscribeInvoked], timeout: 0.05)

        try await MockAppSyncRealTimeClient.waitForSubscirbing()
        try await MockAppSyncRealTimeClient.waitForSubscirbed()
        mockAppSyncRealTimeClient?.triggerEvent(.data(testData))
        mockAppSyncRealTimeClient?.triggerEvent(.unsubscribed)

        await waitForSubscriptionExpectations()
    }

    func testConnectionWithNoData() async throws {
        receivedCompletionFailure.isInverted = true
        receivedDataValueSuccess.isInverted = true
        receivedDataValueError.isInverted = true

        try await subscribe()
        await fulfillment(of: [onSubscribeInvoked], timeout: 0.05)
        try await MockAppSyncRealTimeClient.waitForSubscirbing()
        try await MockAppSyncRealTimeClient.waitForSubscirbed()
        mockAppSyncRealTimeClient?.triggerEvent(.unsubscribed)

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

        try await MockAppSyncRealTimeClient.waitForSubscirbing()
        mockAppSyncRealTimeClient?.triggerEvent(.error([AppSyncRealTimeRequest.Error.limitExceeded]))
        expectedCompletionFailureError = APIError.operationError("", "", AppSyncRealTimeRequest.Error.limitExceeded)
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

        let unauthorizedError = GraphQLError(message: "", extensions: ["errorType": "Unauthorized"])
        try await MockAppSyncRealTimeClient.waitForSubscirbing()
        mockAppSyncRealTimeClient?.triggerEvent(.error([unauthorizedError]))
        expectedCompletionFailureError = APIError.operationError(
            "Subscription item event failed with error: Unauthorized",
            "",
            GraphQLResponseError<JSONValue>.error([unauthorizedError])
        )
        await waitForSubscriptionExpectations()
    }
    
    func testConnectionErrorWithAppSyncConnectionError() async throws {
        receivedCompletionSuccess.isInverted = true
        receivedStateValueConnected.isInverted = true
        receivedStateValueDisconnected.isInverted = true
        receivedDataValueSuccess.isInverted = true
        receivedDataValueError.isInverted = true

        try await subscribe()
        await fulfillment(of: [onSubscribeInvoked], timeout: 0.05)

        try await MockAppSyncRealTimeClient.waitForSubscirbing()
        mockAppSyncRealTimeClient?.triggerEvent(.error([URLError(URLError.Code(rawValue: 400))]))
        expectedCompletionFailureError = APIError.operationError("", "", URLError(URLError.Code(rawValue: 400)))
        await waitForSubscriptionExpectations()
    }

    func testDecodingError() async throws {
        let testData: JSONValue = [
            "data": [ "foo": true ],
            "errors": []
        ]
        receivedCompletionFailure.isInverted = true
        receivedDataValueSuccess.isInverted = true

        try await subscribe()
        await fulfillment(of: [onSubscribeInvoked], timeout: 0.05)
        try await MockAppSyncRealTimeClient.waitForSubscirbing()
        try await MockAppSyncRealTimeClient.waitForSubscirbed()
        mockAppSyncRealTimeClient?.triggerEvent(.data(testData))
        mockAppSyncRealTimeClient?.triggerEvent(.unsubscribed)

        await waitForSubscriptionExpectations()
    }

    func testMultipleSuccessValues() async throws {
        let testJSON: JSONValue = ["foo": true]
        let testData: JSONValue = [
            "data": [ "foo": true ]
        ]

        receivedCompletionFailure.isInverted = true
        receivedDataValueError.isInverted = true
        receivedDataValueSuccess.expectedFulfillmentCount = 2

        try await subscribe(expecting: testJSON)
        await fulfillment(of: [onSubscribeInvoked], timeout: 0.05)

        try await MockAppSyncRealTimeClient.waitForSubscirbing()
        try await MockAppSyncRealTimeClient.waitForSubscirbed()
        mockAppSyncRealTimeClient?.triggerEvent(.data(testData))
        mockAppSyncRealTimeClient?.triggerEvent(.data(testData))
        mockAppSyncRealTimeClient?.triggerEvent(.unsubscribed)

        await waitForSubscriptionExpectations()
    }

    func testMixedSuccessAndErrorValues() async throws {
        let successfulTestData: JSONValue = [
            "data": [ "foo": true ]
        ]
        let invalidTestData: JSONValue = [
            "data": [ "foo": true ],
            "errors": []
        ]

        receivedCompletionFailure.isInverted = true
        receivedDataValueSuccess.expectedFulfillmentCount = 2

        try await subscribe()
        await fulfillment(of: [onSubscribeInvoked], timeout: 0.05)

        try await MockAppSyncRealTimeClient.waitForSubscirbing()
        try await MockAppSyncRealTimeClient.waitForSubscirbed()
        mockAppSyncRealTimeClient?.triggerEvent(.data(successfulTestData))
        mockAppSyncRealTimeClient?.triggerEvent(.data(invalidTestData))
        mockAppSyncRealTimeClient?.triggerEvent(.data(successfulTestData))
        mockAppSyncRealTimeClient?.triggerEvent(.unsubscribed)

        await waitForSubscriptionExpectations()
    }

    // MARK: - Utilities

    /// Sets up test with a mock subscription connection handler that populates
    /// self.subscriptionItem and self.subscriptionEventHandler, then fulfills
    /// self.onSubscribeInvoked
    func setUpMocksAndSubscriptionItems() throws {
        defer { self.onSubscribeInvoked.fulfill() }
        let mockAppSyncRealTimeClient = MockAppSyncRealTimeClient()
        self.mockAppSyncRealTimeClient = mockAppSyncRealTimeClient
        try setUpPluginForSubscriptionResponse { _, _, _, _, _ in
            mockAppSyncRealTimeClient
        }
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
            switch (lhs, rhs) {
            case let (lhs, rhs) as (URLError, URLError):
                return lhs == rhs
            case let (lhs, rhs) as (GraphQLResponseError<JSONValue>, GraphQLResponseError<JSONValue>):
                return lhs.errorDescription == rhs.errorDescription
            case let (lhs, rhs) as (AppSyncRealTimeRequest.Error, AppSyncRealTimeRequest.Error):
                return lhs == rhs
            case (.none, .none): return true
            default: return false
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
