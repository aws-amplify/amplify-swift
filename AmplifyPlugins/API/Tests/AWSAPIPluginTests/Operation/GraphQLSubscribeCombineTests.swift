////
//// Copyright Amazon.com Inc. or its affiliates.
//// All Rights Reserved.
////
//// SPDX-License-Identifier: Apache-2.0
////
//
//import Combine
//import XCTest
//
//import Amplify
//@testable import AmplifyTestCommon
//@testable import AWSAPIPlugin
//@_implementationOnly import AmplifyAsyncTesting
//
//class GraphQLSubscribeCombineTests: OperationTestBase {
//
//    var sink: AnyCancellable?
//    
//    // Setup expectations
//    var onSubscribeInvoked: XCTestExpectation!
//    var receivedCompletionSuccess: XCTestExpectation!
//    var receivedCompletionFailure: XCTestExpectation!
//
//    // Subscription state expectations
//    var receivedStateValueConnecting: XCTestExpectation!
//    var receivedStateValueConnected: XCTestExpectation!
//    var receivedStateValueDisconnected: XCTestExpectation!
//
//    // Subscription item expectations
//    var receivedDataValueSuccess: XCTestExpectation!
//    var receivedDataValueError: XCTestExpectation!
//
//    var connectionStateSink: AnyCancellable?
//    var subscriptionDataSink: AnyCancellable?
//
//    override func setUp() async throws {
//        try await super.setUp()
//
//        onSubscribeInvoked = expectation(description: "onSubscribeInvoked")
//
//        receivedCompletionSuccess = expectation(description: "receivedStateCompletionSuccess")
//        receivedCompletionFailure = expectation(description: "receivedStateCompletionFailure")
//        receivedStateValueConnecting = expectation(description: "receivedStateValueConnecting")
//        receivedStateValueConnected = expectation(description: "receivedStateValueConnected")
//        receivedStateValueDisconnected = expectation(description: "receivedStateValueDisconnected")
//
//        receivedDataValueSuccess = expectation(description: "receivedDataValueSuccess")
//        receivedDataValueError = expectation(description: "receivedDataValueError")
//
//        try setUpMocksAndSubscriptionItems()
//    }
//
//    func waitForSubscriptionExpectations() async {
//        await fulfillment(of: [receivedCompletionSuccess,
//                                   receivedCompletionFailure,
//                                   receivedStateValueConnecting,
//                                   receivedStateValueConnected,
//                                   receivedStateValueDisconnected,
//                                   receivedDataValueSuccess,
//                                   receivedDataValueError], timeout: 0.05)
//    }
//    
//    func testHappyPath() async throws {
//        receivedCompletionFailure.isInverted = true
//        receivedDataValueError.isInverted = true
//
//        let testJSON: JSONValue = ["foo": true]
//        let testData = Data(#"{"data": {"foo": true}}"#.utf8)
//
//        try await subscribe(expecting: testJSON)
//        await fulfillment(of: [onSubscribeInvoked], timeout: 0.05)
//
////        subscriptionEventHandler(.connection(.connecting), subscriptionItem)
////        subscriptionEventHandler(.connection(.connected), subscriptionItem)
////        subscriptionEventHandler(.data(testData), subscriptionItem)
////        subscriptionEventHandler(.connection(.disconnected), subscriptionItem)
////
////        await waitForSubscriptionExpectations()
//    }
//
////    func testConnectionWithNoData() async throws {
////        receivedCompletionFailure.isInverted = true
////        receivedDataValueSuccess.isInverted = true
////        receivedDataValueError.isInverted = true
////
////        try await subscribe()
////        await fulfillment(of: [onSubscribeInvoked], timeout: 0.05)
////
////        subscriptionEventHandler(.connection(.connecting), subscriptionItem)
////        subscriptionEventHandler(.connection(.connected), subscriptionItem)
////        subscriptionEventHandler(.connection(.disconnected), subscriptionItem)
////
////        await waitForSubscriptionExpectations()
////    }
////
////    func testConnectionError() async throws {
////        receivedCompletionSuccess.isInverted = true
////        receivedStateValueConnected.isInverted = true
////        receivedStateValueDisconnected.isInverted = true
////        receivedDataValueSuccess.isInverted = true
////        receivedDataValueError.isInverted = true
////
////        try await subscribe()
////        await fulfillment(of: [onSubscribeInvoked], timeout: 0.05)
////
////        subscriptionEventHandler(.connection(.connecting), subscriptionItem)
////        subscriptionEventHandler(.failed("Error"), subscriptionItem)
////
////        await waitForSubscriptionExpectations()
////    }
////
////    func testDecodingError() async throws {
////        let testData = Data(#"{"data": {"foo": true}, "errors": []}"#.utf8)
////        receivedCompletionFailure.isInverted = true
////        receivedDataValueSuccess.isInverted = true
////
////        try await subscribe()
////        await fulfillment(of: [onSubscribeInvoked], timeout: 0.05)
////
////        subscriptionEventHandler(.connection(.connecting), subscriptionItem)
////        subscriptionEventHandler(.connection(.connected), subscriptionItem)
////        subscriptionEventHandler(.data(testData), subscriptionItem)
////        subscriptionEventHandler(.connection(.disconnected), subscriptionItem)
////
////        await waitForSubscriptionExpectations()
////    }
////
////    func testMultipleSuccessValues() async throws {
////        let testJSON: JSONValue = ["foo": true]
////        let testData = Data(#"{"data": {"foo": true}}"#.utf8)
////        receivedCompletionFailure.isInverted = true
////        receivedDataValueError.isInverted = true
////        receivedDataValueSuccess.expectedFulfillmentCount = 2
////
////        try await subscribe(expecting: testJSON)
////        await fulfillment(of: [onSubscribeInvoked], timeout: 0.05)
////
////        subscriptionEventHandler(.connection(.connecting), subscriptionItem)
////        subscriptionEventHandler(.connection(.connected), subscriptionItem)
////        subscriptionEventHandler(.data(testData), subscriptionItem)
////        subscriptionEventHandler(.data(testData), subscriptionItem)
////        subscriptionEventHandler(.connection(.disconnected), subscriptionItem)
////
////        await waitForSubscriptionExpectations()
////    }
////
////    func testMixedSuccessAndErrorValues() async throws {
////        let successfulTestData = Data(#"{"data": {"foo": true}}"#.utf8)
////        let invalidTestData = Data(#"{"data": {"foo": true}, "errors": []}"#.utf8)
////        receivedCompletionFailure.isInverted = true
////        receivedDataValueSuccess.expectedFulfillmentCount = 2
////
////        try await subscribe()
////        await fulfillment(of: [onSubscribeInvoked], timeout: 0.05)
////
////        subscriptionEventHandler(.connection(.connecting), subscriptionItem)
////        subscriptionEventHandler(.connection(.connected), subscriptionItem)
////        subscriptionEventHandler(.data(successfulTestData), subscriptionItem)
////        subscriptionEventHandler(.data(invalidTestData), subscriptionItem)
////        subscriptionEventHandler(.data(successfulTestData), subscriptionItem)
////        subscriptionEventHandler(.connection(.disconnected), subscriptionItem)
////
////        await waitForSubscriptionExpectations()
////    }
////
//    // MARK: - Utilities
//
//    /// Sets up test with a mock subscription connection handler that populates
//    /// self.subscriptionItem and self.subscriptionEventHandler, then fulfills
//    /// self.onSubscribeInvoked
//    func setUpMocksAndSubscriptionItems() throws {
//        let onSubscribe: MockSubscriptionConnection.OnSubscribe = {
//            requestString, variables, eventHandler in
//            let item = SubscriptionItem(
//                requestString: requestString,
//                variables: variables,
//                eventHandler: eventHandler
//            )
//
//            self.subscriptionItem = item
//            self.subscriptionEventHandler = eventHandler
//            self.onSubscribeInvoked.fulfill()
//            return item
//        }
//
//        let onGetOrCreateConnection: MockSubscriptionConnectionFactory.OnGetOrCreateConnection = { _, _, _, _, _  in
//            MockSubscriptionConnection(onSubscribe: onSubscribe, onUnsubscribe: { _ in })
//        }
//
//        try setUpPluginForSubscriptionResponse(onGetOrCreateConnection: onGetOrCreateConnection)
//    }
//
//    /// Calls `Amplify.API.subscribe` with a request made from a generic document, and returns
//    /// the operation created from that subscription. If `expectedValue` is not nil, also asserts
//    /// that the received value is equal to the expected value
//    func subscribe(
//        expecting expectedValue: JSONValue? = nil
//    ) async throws {
//        let testDocument = "subscribe { subscribeTodos { id name description }}"
//
//        let request = GraphQLRequest(
//            document: testDocument,
//            variables: nil,
//            responseType: JSONValue.self
//        )
//        let subscription = apiPlugin.subscribe(request: request)
//        sink = Amplify.Publisher.create(subscription).sink { completion in
//            switch completion {
//            case .failure:
//                self.receivedCompletionFailure.fulfill()
//            case .finished:
//                self.receivedCompletionSuccess.fulfill()
//            }
//        } receiveValue: { subscriptionEvent in
//            switch subscriptionEvent {
//            case .connection(let connectionState):
//                switch connectionState {
//                case .connecting:
//                    self.receivedStateValueConnecting.fulfill()
//                case .connected:
//                    self.receivedStateValueConnected.fulfill()
//                case .disconnected:
//                    self.receivedStateValueDisconnected.fulfill()
//                }
//            case .data(let result):
//                switch result {
//                case .success(let actualValue):
//                    if let expectedValue = expectedValue {
//                        XCTAssertEqual(actualValue, expectedValue)
//                    }
//                    self.receivedDataValueSuccess.fulfill()
//                case .failure:
//                    self.receivedDataValueError.fulfill()
//                }
//            }
//        }
//    }
//
//}
