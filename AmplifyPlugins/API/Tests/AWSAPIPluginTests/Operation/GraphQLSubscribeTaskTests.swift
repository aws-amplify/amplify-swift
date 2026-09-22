//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

import Amplify
@testable import AmplifyTestCommon
@testable import AWSAPIPlugin

class GraphQLSubscribeTasksTests: OperationTestBase {

    var mockAppSyncRealTimeClient: MockAppSyncRealTimeClient?

    /// Events collected by draining a subscription to completion.
    private struct DrainedEvents {
        var connecting = false
        var connected = false
        var disconnected = false
        var successes: [JSONValue] = []
        var errorCount = 0
        var finished = false
        var failure: APIError?
    }

    override func setUp() async throws {
        try await super.setUp()
        try setUpMocksAndSubscriptionItems()
    }

    override func tearDown() async throws {
        mockAppSyncRealTimeClient = nil
        try await super.tearDown()
    }

    func testHappyPath() async throws {
        let testJSON: JSONValue = ["foo": true]
        let testData: JSONValue = ["data": ["foo": true]]
        let subscription = subscribe()
        async let drained = drain(subscription)

        try await MockAppSyncRealTimeClient.waitForSubscirbing()
        try await MockAppSyncRealTimeClient.waitForSubscirbed()
        mockAppSyncRealTimeClient?.triggerEvent(.data(testData))
        mockAppSyncRealTimeClient?.triggerEvent(.unsubscribed)

        let events = await drained
        XCTAssertTrue(events.connecting)
        XCTAssertTrue(events.connected)
        XCTAssertTrue(events.disconnected)
        XCTAssertEqual(events.successes, [testJSON])
        XCTAssertEqual(events.errorCount, 0)
        XCTAssertTrue(events.finished)
        XCTAssertNil(events.failure)
    }

    func testConnectionWithNoData() async throws {
        let subscription = subscribe()
        async let drained = drain(subscription)

        try await MockAppSyncRealTimeClient.waitForSubscirbing()
        try await MockAppSyncRealTimeClient.waitForSubscirbed()
        mockAppSyncRealTimeClient?.triggerEvent(.unsubscribed)

        let events = await drained
        XCTAssertTrue(events.connecting)
        XCTAssertTrue(events.connected)
        XCTAssertTrue(events.disconnected)
        XCTAssertTrue(events.successes.isEmpty)
        XCTAssertEqual(events.errorCount, 0)
        XCTAssertTrue(events.finished)
        XCTAssertNil(events.failure)
    }

    func testConnectionErrorWithLimitExceeded() async throws {
        let subscription = subscribe()
        async let drained = drain(subscription)

        try await MockAppSyncRealTimeClient.waitForSubscirbing()
        mockAppSyncRealTimeClient?.triggerEvent(.error([AppSyncRealTimeRequest.Error.limitExceeded]))

        let events = await drained
        XCTAssertTrue(events.connecting)
        XCTAssertFalse(events.connected)
        XCTAssertFalse(events.disconnected)
        XCTAssertTrue(events.successes.isEmpty)
        XCTAssertEqual(events.errorCount, 0)
        XCTAssertFalse(events.finished)
        XCTAssertEqual(events.failure, APIError.operationError("", "", AppSyncRealTimeRequest.Error.limitExceeded))
    }

    func testConnectionErrorWithConnectionUnauthorizedError() async throws {
        let subscription = subscribe()
        async let drained = drain(subscription)

        let unauthorizedError = GraphQLError(message: "", extensions: ["errorType": "Unauthorized"])
        try await MockAppSyncRealTimeClient.waitForSubscirbing()
        mockAppSyncRealTimeClient?.triggerEvent(.error([unauthorizedError]))

        let events = await drained
        XCTAssertTrue(events.connecting)
        XCTAssertFalse(events.connected)
        XCTAssertFalse(events.disconnected)
        XCTAssertTrue(events.successes.isEmpty)
        XCTAssertEqual(events.errorCount, 0)
        XCTAssertFalse(events.finished)
        XCTAssertEqual(
            events.failure,
            APIError.operationError(
                "Subscription item event failed with error: Unauthorized",
                "",
                GraphQLResponseError<JSONValue>.error([unauthorizedError])
            )
        )
    }

    func testConnectionErrorWithAppSyncConnectionError() async throws {
        let subscription = subscribe()
        async let drained = drain(subscription)

        try await MockAppSyncRealTimeClient.waitForSubscirbing()
        mockAppSyncRealTimeClient?.triggerEvent(.error([URLError(URLError.Code(rawValue: 400))]))

        let events = await drained
        XCTAssertTrue(events.connecting)
        XCTAssertFalse(events.connected)
        XCTAssertFalse(events.disconnected)
        XCTAssertTrue(events.successes.isEmpty)
        XCTAssertEqual(events.errorCount, 0)
        XCTAssertFalse(events.finished)
        XCTAssertEqual(events.failure, APIError.operationError("", "", URLError(URLError.Code(rawValue: 400))))
    }

    func testDecodingError() async throws {
        let testData: JSONValue = [
            "data": ["foo": true],
            "errors": []
        ]
        let subscription = subscribe()
        async let drained = drain(subscription)

        try await MockAppSyncRealTimeClient.waitForSubscirbing()
        try await MockAppSyncRealTimeClient.waitForSubscirbed()
        mockAppSyncRealTimeClient?.triggerEvent(.data(testData))
        mockAppSyncRealTimeClient?.triggerEvent(.unsubscribed)

        let events = await drained
        XCTAssertTrue(events.connecting)
        XCTAssertTrue(events.connected)
        XCTAssertTrue(events.disconnected)
        XCTAssertTrue(events.successes.isEmpty)
        XCTAssertEqual(events.errorCount, 1)
        XCTAssertTrue(events.finished)
        XCTAssertNil(events.failure)
    }

    func testMultipleSuccessValues() async throws {
        let testJSON: JSONValue = ["foo": true]
        let testData: JSONValue = ["data": ["foo": true]]
        let subscription = subscribe()
        async let drained = drain(subscription)

        try await MockAppSyncRealTimeClient.waitForSubscirbing()
        try await MockAppSyncRealTimeClient.waitForSubscirbed()
        mockAppSyncRealTimeClient?.triggerEvent(.data(testData))
        mockAppSyncRealTimeClient?.triggerEvent(.data(testData))
        mockAppSyncRealTimeClient?.triggerEvent(.unsubscribed)

        let events = await drained
        XCTAssertTrue(events.connecting)
        XCTAssertTrue(events.connected)
        XCTAssertTrue(events.disconnected)
        XCTAssertEqual(events.successes, [testJSON, testJSON])
        XCTAssertEqual(events.errorCount, 0)
        XCTAssertTrue(events.finished)
        XCTAssertNil(events.failure)
    }

    func testMixedSuccessAndErrorValues() async throws {
        let successfulTestData: JSONValue = ["data": ["foo": true]]
        let invalidTestData: JSONValue = [
            "data": ["foo": true],
            "errors": []
        ]
        let subscription = subscribe()
        async let drained = drain(subscription)

        try await MockAppSyncRealTimeClient.waitForSubscirbing()
        try await MockAppSyncRealTimeClient.waitForSubscirbed()
        mockAppSyncRealTimeClient?.triggerEvent(.data(successfulTestData))
        mockAppSyncRealTimeClient?.triggerEvent(.data(invalidTestData))
        mockAppSyncRealTimeClient?.triggerEvent(.data(successfulTestData))
        mockAppSyncRealTimeClient?.triggerEvent(.unsubscribed)

        let events = await drained
        XCTAssertTrue(events.connecting)
        XCTAssertTrue(events.connected)
        XCTAssertTrue(events.disconnected)
        XCTAssertEqual(events.successes.count, 2)
        XCTAssertEqual(events.errorCount, 1)
        XCTAssertTrue(events.finished)
        XCTAssertNil(events.failure)
    }

    // MARK: - Utilities

    func setUpMocksAndSubscriptionItems() throws {
        let mockAppSyncRealTimeClient = MockAppSyncRealTimeClient()
        self.mockAppSyncRealTimeClient = mockAppSyncRealTimeClient
        try setUpPluginForSubscriptionResponse { _, _, _, _, _ in
            mockAppSyncRealTimeClient
        }
    }

    /// Starts a subscription and returns its event sequence.
    func subscribe() -> AmplifyAsyncThrowingSequence<GraphQLSubscriptionEvent<JSONValue>> {
        let request = GraphQLRequest(
            document: "subscribe { subscribeTodos { id name description }}",
            variables: nil,
            responseType: JSONValue.self
        )
        return apiPlugin.subscribe(request: request)
    }

    /// Consumes the subscription inline (no detached task/timeout) until it finishes or fails,
    /// collecting the events so the caller can assert on them deterministically.
    private func drain(
        _ subscription: AmplifyAsyncThrowingSequence<GraphQLSubscriptionEvent<JSONValue>>
    ) async -> DrainedEvents {
        var events = DrainedEvents()
        do {
            for try await event in subscription {
                switch event {
                case .connection(let connectionState):
                    switch connectionState {
                    case .connecting: events.connecting = true
                    case .connected: events.connected = true
                    case .disconnected: events.disconnected = true
                    }
                case .data(let result):
                    switch result {
                    case .success(let value): events.successes.append(value)
                    case .failure: events.errorCount += 1
                    }
                }
            }
            events.finished = true
        } catch {
            events.failure = error as? APIError
        }
        return events
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
