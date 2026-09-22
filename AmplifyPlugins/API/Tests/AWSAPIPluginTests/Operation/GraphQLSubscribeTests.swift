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

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class GraphQLSubscribeTests: OperationTestBase, @unchecked Sendable {

    var mockAppSyncRealTimeClient: MockAppSyncRealTimeClient!

    /// Thread-safe collector for the subscribe callbacks. `waitUntilComplete()` resumes when the
    /// completion listener fires, so tests await the terminal event deterministically (no timeout).
    private final class EventCollector: @unchecked Sendable {
        private let lock = NSLock()
        private var connected = false
        private var disconnected = false
        private var successes: [JSONValue] = []
        private var errorCount = 0
        private var finished = false
        private var failed = false
        private var continuation: CheckedContinuation<Void, Never>?

        func recordConnected() { lock.withLock { connected = true } }
        func recordDisconnected() { lock.withLock { disconnected = true } }
        func recordSuccess(_ value: JSONValue) { lock.withLock { successes.append(value) } }
        func recordError() { lock.withLock { errorCount += 1 } }

        func complete(failed: Bool) {
            let resume: CheckedContinuation<Void, Never>?
            lock.lock()
            if failed { self.failed = true } else { finished = true }
            resume = continuation
            continuation = nil
            lock.unlock()
            resume?.resume()
        }

        func waitUntilComplete() async {
            await withCheckedContinuation { cont in
                lock.lock()
                if finished || failed {
                    lock.unlock()
                    cont.resume()
                } else {
                    continuation = cont
                    lock.unlock()
                }
            }
        }

        var result: (connected: Bool, disconnected: Bool, successes: [JSONValue], errorCount: Int, finished: Bool, failed: Bool) {
            lock.withLock { (connected, disconnected, successes, errorCount, finished, failed) }
        }
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
        let collector = EventCollector()
        subscribe(expecting: testJSON, collector: collector)

        try await mockAppSyncRealTimeClient?.waitForSubscirbing()
        try await mockAppSyncRealTimeClient?.waitForSubscirbed()
        mockAppSyncRealTimeClient.triggerEvent(.data(testData))
        mockAppSyncRealTimeClient.triggerEvent(.unsubscribed)

        await collector.waitUntilComplete()
        let result = collector.result
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
        mockAppSyncRealTimeClient.triggerEvent(.unsubscribed)

        await collector.waitUntilComplete()
        let result = collector.result
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
        mockAppSyncRealTimeClient.triggerEvent(.error(["Error"]))

        await collector.waitUntilComplete()
        let result = collector.result
        XCTAssertFalse(result.connected)
        XCTAssertFalse(result.disconnected)
        XCTAssertTrue(result.successes.isEmpty)
        XCTAssertEqual(result.errorCount, 0)
        XCTAssertFalse(result.finished)
        XCTAssertTrue(result.failed)
    }

    func testDecodingError() async throws {
        let testData: JSONValue = [
            "data": ["foo": true],
            "errors": []
        ]
        let collector = EventCollector()
        subscribe(collector: collector)

        try await mockAppSyncRealTimeClient?.waitForSubscirbing()
        try await mockAppSyncRealTimeClient?.waitForSubscirbed()
        mockAppSyncRealTimeClient.triggerEvent(.data(testData))
        mockAppSyncRealTimeClient.triggerEvent(.unsubscribed)

        await collector.waitUntilComplete()
        let result = collector.result
        XCTAssertTrue(result.connected)
        XCTAssertTrue(result.disconnected)
        XCTAssertTrue(result.successes.isEmpty)
        XCTAssertEqual(result.errorCount, 1)
        XCTAssertTrue(result.finished)
        XCTAssertFalse(result.failed)
    }

    func testMultipleSuccessValues() async throws {
        let testJSON: JSONValue = ["foo": true]
        let testData: JSONValue = ["data": ["foo": true]]
        let collector = EventCollector()
        subscribe(expecting: testJSON, collector: collector)

        try await mockAppSyncRealTimeClient?.waitForSubscirbing()
        try await mockAppSyncRealTimeClient?.waitForSubscirbed()
        mockAppSyncRealTimeClient.triggerEvent(.data(testData))
        mockAppSyncRealTimeClient.triggerEvent(.data(testData))
        mockAppSyncRealTimeClient.triggerEvent(.unsubscribed)

        await collector.waitUntilComplete()
        let result = collector.result
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
        mockAppSyncRealTimeClient.triggerEvent(.data(successfulTestData))
        mockAppSyncRealTimeClient.triggerEvent(.data(invalidTestData))
        mockAppSyncRealTimeClient.triggerEvent(.data(successfulTestData))
        mockAppSyncRealTimeClient.triggerEvent(.unsubscribed)

        await collector.waitUntilComplete()
        let result = collector.result
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

    /// Starts a subscription, routing its callbacks into `collector`.
    @discardableResult
    private func subscribe(
        expecting expectedValue: JSONValue? = nil,
        collector: EventCollector
    ) -> GraphQLSubscriptionOperation<JSONValue> {
        let request = GraphQLRequest(
            document: "subscribe { subscribeTodos { id name description }}",
            variables: nil,
            responseType: JSONValue.self
        )

        return apiPlugin.subscribe(
            request: request,
            valueListener: { value in
                switch value {
                case .connection(let connectionState):
                    switch connectionState {
                    case .connecting:
                        break
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
            },
            completionListener: { result in
                switch result {
                case .failure:
                    collector.complete(failed: true)
                case .success:
                    collector.complete(failed: false)
                }
            }
        )
    }
}
