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

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class GraphQLSubscribeCombineTests: OperationTestBase, @unchecked Sendable {

    var sink: AnyCancellable?
    var mockAppSyncRealTimeClient: MockAppSyncRealTimeClient?

    /// Thread-safely collects sink events until completion or the wait timeout.
    private final class EventCollector: @unchecked Sendable {
        private let lock = NSLock()
        private var connecting = false
        private var connected = false
        private var disconnected = false
        private var successes: [JSONValue] = []
        private var errorCount = 0
        private var finished = false
        private var failed = false

        func recordConnecting() { lock.withLock { connecting = true } }
        func recordConnected() { lock.withLock { connected = true } }
        func recordDisconnected() { lock.withLock { disconnected = true } }
        func recordSuccess(_ value: JSONValue) { lock.withLock { successes.append(value) } }
        func recordError() { lock.withLock { errorCount += 1 } }

        func complete(failed: Bool) {
            lock.withLock { if failed { self.failed = true } else { finished = true } }
        }

        /// Bounded so a missing terminal event fails the test instead of hanging the shard.
        func waitUntilComplete(
            timeout: TimeInterval = 10,
            file: StaticString = #filePath,
            line: UInt = #line
        ) async {
            let deadline = Date().addingTimeInterval(timeout)
            while !lock.withLock({ finished || failed }) {
                if Date() >= deadline {
                    XCTFail("Timed out waiting for subscription completion", file: file, line: line)
                    return
                }
                try? await Task.sleep(nanoseconds: 5_000_000)
            }
        }

        var result: (connecting: Bool, connected: Bool, disconnected: Bool, successes: [JSONValue], errorCount: Int, finished: Bool, failed: Bool) {
            lock.withLock { (connecting, connected, disconnected, successes, errorCount, finished, failed) }
        }
    }

    override func setUp() async throws {
        try await super.setUp()
        try setUpMocksAndSubscriptionItems()
    }

    override func tearDown() async throws {
        sink?.cancel()
        sink = nil
        mockAppSyncRealTimeClient = nil
        try await super.tearDown()
    }

    func testHappyPath() async throws {
        let testJSON: JSONValue = ["foo": true]
        let testData: JSONValue = ["data": ["foo": true]]
        let collector = EventCollector()
        subscribe(expecting: testJSON, collector: collector)

        try await mockAppSyncRealTimeClient?.waitForSubscirbing()
        try await mockAppSyncRealTimeClient?.waitForSubscirbed()
        mockAppSyncRealTimeClient?.triggerEvent(.data(testData))
        mockAppSyncRealTimeClient?.triggerEvent(.unsubscribed)

        await collector.waitUntilComplete()
        let result = collector.result
        XCTAssertTrue(result.connecting)
        XCTAssertTrue(result.connected)
        XCTAssertTrue(result.disconnected)
        XCTAssertEqual(result.successes, [testJSON])
        XCTAssertEqual(result.errorCount, 0)
        XCTAssertTrue(result.finished)
        XCTAssertFalse(result.failed)
    }

    func testConnectionWithNoData() async throws {
        let collector = EventCollector()
        subscribe(collector: collector)

        try await mockAppSyncRealTimeClient?.waitForSubscirbing()
        try await mockAppSyncRealTimeClient?.waitForSubscirbed()
        mockAppSyncRealTimeClient?.triggerEvent(.unsubscribed)

        await collector.waitUntilComplete()
        let result = collector.result
        XCTAssertTrue(result.connecting)
        XCTAssertTrue(result.connected)
        XCTAssertTrue(result.disconnected)
        XCTAssertTrue(result.successes.isEmpty)
        XCTAssertEqual(result.errorCount, 0)
        XCTAssertTrue(result.finished)
        XCTAssertFalse(result.failed)
    }

    func testConnectionError() async throws {
        let collector = EventCollector()
        subscribe(collector: collector)

        try await mockAppSyncRealTimeClient?.waitForSubscirbing()
        mockAppSyncRealTimeClient?.triggerEvent(.error(["Error"]))

        await collector.waitUntilComplete()
        let result = collector.result
        XCTAssertTrue(result.connecting)
        XCTAssertFalse(result.connected)
        XCTAssertFalse(result.disconnected)
        XCTAssertTrue(result.successes.isEmpty)
        XCTAssertEqual(result.errorCount, 0)
        XCTAssertFalse(result.finished)
        XCTAssertTrue(result.failed)
    }

    func testMultipleSuccessValues() async throws {
        let testJSON: JSONValue = ["foo": true]
        let testData: JSONValue = ["data": ["foo": true]]
        let collector = EventCollector()
        subscribe(expecting: testJSON, collector: collector)

        try await mockAppSyncRealTimeClient?.waitForSubscirbing()
        try await mockAppSyncRealTimeClient?.waitForSubscirbed()
        mockAppSyncRealTimeClient?.triggerEvent(.data(testData))
        mockAppSyncRealTimeClient?.triggerEvent(.data(testData))
        mockAppSyncRealTimeClient?.triggerEvent(.unsubscribed)

        await collector.waitUntilComplete()
        let result = collector.result
        XCTAssertTrue(result.connecting)
        XCTAssertTrue(result.connected)
        XCTAssertTrue(result.disconnected)
        XCTAssertEqual(result.successes, [testJSON, testJSON])
        XCTAssertEqual(result.errorCount, 0)
        XCTAssertTrue(result.finished)
        XCTAssertFalse(result.failed)
    }

    func testMixedSuccessAndErrorValues() async throws {
        let successfulTestData: JSONValue = ["data": ["foo": true]]
        let invalidTestData: JSONValue = [
            "data": ["foo": true],
            "errors": []
        ]
        let collector = EventCollector()
        subscribe(collector: collector)

        try await mockAppSyncRealTimeClient?.waitForSubscirbing()
        try await mockAppSyncRealTimeClient?.waitForSubscirbed()
        mockAppSyncRealTimeClient?.triggerEvent(.data(successfulTestData))
        mockAppSyncRealTimeClient?.triggerEvent(.data(invalidTestData))
        mockAppSyncRealTimeClient?.triggerEvent(.data(successfulTestData))
        mockAppSyncRealTimeClient?.triggerEvent(.unsubscribed)

        await collector.waitUntilComplete()
        let result = collector.result
        XCTAssertTrue(result.connecting)
        XCTAssertTrue(result.connected)
        XCTAssertTrue(result.disconnected)
        XCTAssertEqual(result.successes.count, 2)
        XCTAssertEqual(result.errorCount, 1)
        XCTAssertTrue(result.finished)
        XCTAssertFalse(result.failed)
    }

    // MARK: - Utilities

    func setUpMocksAndSubscriptionItems() throws {
        let mockAppSyncRealTimeClient = MockAppSyncRealTimeClient()
        self.mockAppSyncRealTimeClient = mockAppSyncRealTimeClient
        try setUpPluginForSubscriptionResponse { _, _, _, _, _ in
            mockAppSyncRealTimeClient
        }
    }

    /// Starts a subscription, routing its Combine events into `collector`.
    private func subscribe(
        expecting expectedValue: JSONValue? = nil,
        collector: EventCollector
    ) {
        let request = GraphQLRequest(
            document: "subscribe { subscribeTodos { id name description }}",
            variables: nil,
            responseType: JSONValue.self
        )
        let subscription = apiPlugin.subscribe(request: request)
        sink = Amplify.Publisher.create(subscription).sink { completion in
            switch completion {
            case .failure:
                collector.complete(failed: true)
            case .finished:
                collector.complete(failed: false)
            }
        } receiveValue: { subscriptionEvent in
            switch subscriptionEvent {
            case .connection(let connectionState):
                switch connectionState {
                case .connecting:
                    collector.recordConnecting()
                case .connected:
                    collector.recordConnected()
                case .disconnected:
                    collector.recordDisconnected()
                }
            case .data(let result):
                switch result {
                case .success(let actualValue):
                    if let expectedValue {
                        XCTAssertEqual(actualValue, expectedValue)
                    }
                    collector.recordSuccess(actualValue)
                case .failure:
                    collector.recordError()
                }
            }
        }
    }
}
