//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
@preconcurrency import Combine
import XCTest
@_spi(WebSocket) import AWSPluginsCore
@testable import AWSAPIPlugin

/// Regression tests for https://github.com/aws-amplify/amplify-swift/issues/4220.
///
/// After iOS suspends the app process, the kernel defuncts TCP flows bound to
/// the WebSocket connection. When the app returns to foreground and attempts to
/// resubscribe, `WebSocketClient.write()` throws NSPOSIXErrorDomain Code=53
/// ("Software caused connection abort"). The library must detect this write
/// failure and trigger a full reconnection cycle so subscriptions can recover.
class AppSyncRealTimeClientWriteFailureTests: XCTestCase {

    /// Verifies that when a WebSocket write fails with a connection error,
    /// AppSyncRealTimeClient propagates the error to the subscription stream
    /// so the subscription does not remain stuck in "subscribing" state.
    ///
    /// - Given:
    ///    - An AppSyncRealTimeClient in connected state with MockWebSocketClient.
    /// - When:
    ///    - A subscription `start` request is sent, but the write fails
    ///      (simulating a dead socket after process suspension).
    /// - Then:
    ///    - The subscription receives an error event (not stuck in subscribing).
    ///    - The sendRequest call propagates the failure through the subject.
    func testSubscribe_whenWriteFailsWithConnectionAbort_shouldPropagateError() async throws {
        var cancellables = Set<AnyCancellable>()
        let mockWebSocketClient = MockWriteFailingWebSocketClient()
        let mockAppSyncRequestInterceptor = MockAppSyncRequestInterceptor()
        let appSyncClient = AppSyncRealTimeClient(
            endpoint: URL(string: "https://example.com")!,
            requestInterceptor: mockAppSyncRequestInterceptor,
            webSocketClient: mockWebSocketClient
        )

        // Simulate connected state
        await mockWebSocketClient.setStateToConnected()
        Task {
            try await Task.sleep(nanoseconds: 50_000_000)
            await mockWebSocketClient.subject.send(.connected)
            try await Task.sleep(nanoseconds: 50_000_000)
            await mockWebSocketClient.subject.send(.string("""
                {"type": "connection_ack", "payload": { "connectionTimeoutMs": 300000 }}
            """))
        }
        try await appSyncClient.connect()

        // Now make writes fail (simulating dead socket)
        await mockWebSocketClient.setShouldFailWrites(true)

        let id = UUID().uuidString
        let errorReceived = expectation(description: "Subscription should receive error from write failure")
        errorReceived.assertForOverFulfill = false

        let subscription = try await appSyncClient.subscribe(id: id, query: "subscription { onTest { id } }")
            .sink { event in
                if case .error = event {
                    errorReceived.fulfill()
                }
            }
        cancellables.insert(subscription)

        await fulfillment(of: [errorReceived], timeout: 8)
        withExtendedLifetime(cancellables) { }
    }

    /// Verifies that when a connected AppSyncRealTimeClient receives a
    /// `.disconnected` event (as would happen when the WebSocket detects a
    /// dead connection), it transitions to `.connectionDropped` state and
    /// triggers reconnection when the WebSocket comes back online.
    ///
    /// - Given:
    ///    - An AppSyncRealTimeClient in connected state with an active subscription.
    /// - When:
    ///    - The WebSocket emits a `.disconnected` event (simulating socket death
    ///      detection after process suspension).
    ///    - Followed by a `.connected` event (simulating successful reconnection).
    /// - Then:
    ///    - The client sends `connection_init` again (reconnection).
    ///    - After receiving `connection_ack`, it resumes existing subscriptions
    ///      by sending a new `start` request.
    func testConnectionDrop_withActiveSubscription_shouldReconnectAndResubscribe() async throws {
        var cancellables = Set<AnyCancellable>()
        let mockWebSocketClient = MockWebSocketClient()
        let mockAppSyncRequestInterceptor = MockAppSyncRequestInterceptor()
        let appSyncClient = AppSyncRealTimeClient(
            endpoint: URL(string: "https://example.com")!,
            requestInterceptor: mockAppSyncRequestInterceptor,
            webSocketClient: mockWebSocketClient
        )

        let id = UUID().uuidString

        let initialSubscribed = expectation(description: "Initial subscription established")
        let resubscribedAfterDrop = expectation(description: "Subscription re-established after connection drop")
        resubscribedAfterDrop.assertForOverFulfill = false

        let subscribedCount = AtomicCounter()

        await mockWebSocketClient.setStateToConnected()

        // Wire up the mock to respond to protocol messages
        await mockWebSocketClient.actionSubject
            .sink { action in
                switch action {
                case .connect:
                    Task {
                        await mockWebSocketClient.subject.send(.connected)
                    }
                case .write(let message):
                    guard let response = try? JSONDecoder().decode(
                        JSONValue.self,
                        from: message.data(using: .utf8)!
                    ) else { return }

                    switch response.type?.stringValue {
                    case "connection_init":
                        Task {
                            try await Task.sleep(nanoseconds: 50_000_000)
                            await mockWebSocketClient.subject.send(.string("""
                                {"type": "connection_ack", "payload": { "connectionTimeoutMs": 300000 }}
                            """))
                        }
                    case "start":
                        Task {
                            try await Task.sleep(nanoseconds: 50_000_000)
                            await mockWebSocketClient.subject.send(.string("""
                                {"type": "start_ack", "id": "\(id)"}
                            """))
                        }
                    default:
                        break
                    }
                default:
                    break
                }
            }
            .store(in: &cancellables)

        // Subscribe and wait for initial subscription
        let subscription = try await appSyncClient.subscribe(id: id, query: "subscription { onTest { id } }")
            .sink { event in
                if case .subscribed = event {
                    let count = subscribedCount.increment()
                    if count == 1 {
                        initialSubscribed.fulfill()
                    } else {
                        resubscribedAfterDrop.fulfill()
                    }
                }
            }
        cancellables.insert(subscription)

        await fulfillment(of: [initialSubscribed], timeout: 5)

        // Simulate connection drop (as happens when iOS defuncts the socket)
        await mockWebSocketClient.subject.send(.disconnected(.invalid, nil))

        // Simulate WebSocket reconnecting (auto-retry brings it back)
        try await Task.sleep(nanoseconds: 100_000_000)
        await mockWebSocketClient.subject.send(.connected)

        await fulfillment(of: [resubscribedAfterDrop], timeout: 10)
        withExtendedLifetime(cancellables) { }
    }

    /// Verifies that multiple concurrent subscriptions all recover after a
    /// connection drop. This reproduces the GH-4220 scenario where 6 workers
    /// all get stuck in "connecting" because the reconnection/resubscription
    /// path doesn't handle multiple subscriptions correctly.
    ///
    /// - Given:
    ///    - An AppSyncRealTimeClient with 6 active subscriptions.
    /// - When:
    ///    - The WebSocket emits `.disconnected` (connection drop).
    ///    - Followed by `.connected` (reconnection).
    ///    - Server responds with `connection_ack` and `start_ack` for each.
    /// - Then:
    ///    - All 6 subscriptions receive a second `.subscribed` event.
    func testMultipleSubscriptions_afterConnectionDrop_shouldAllResubscribe() async throws {
        var cancellables = Set<AnyCancellable>()
        let mockWebSocketClient = MockWebSocketClient()
        let mockAppSyncRequestInterceptor = MockAppSyncRequestInterceptor()
        let appSyncClient = AppSyncRealTimeClient(
            endpoint: URL(string: "https://example.com")!,
            requestInterceptor: mockAppSyncRequestInterceptor,
            webSocketClient: mockWebSocketClient
        )

        let subscriptionCount = 6
        let ids = (0..<subscriptionCount).map { _ in UUID().uuidString }

        let allInitiallySubscribed = expectation(description: "All subscriptions initially established")
        allInitiallySubscribed.expectedFulfillmentCount = subscriptionCount

        let allResubscribed = expectation(description: "All subscriptions re-established after drop")
        allResubscribed.expectedFulfillmentCount = subscriptionCount

        // Track per-subscription subscribed counts
        let subscribedCounts = (0..<subscriptionCount).map { _ in AtomicCounter() }

        await mockWebSocketClient.setStateToConnected()

        // Wire up mock to respond to protocol messages
        await mockWebSocketClient.actionSubject
            .sink { action in
                switch action {
                case .connect:
                    Task {
                        await mockWebSocketClient.subject.send(.connected)
                    }
                case .write(let message):
                    guard let response = try? JSONDecoder().decode(
                        JSONValue.self,
                        from: message.data(using: .utf8)!
                    ) else { return }

                    switch response.type?.stringValue {
                    case "connection_init":
                        Task {
                            try await Task.sleep(nanoseconds: 30_000_000)
                            await mockWebSocketClient.subject.send(.string("""
                                {"type": "connection_ack", "payload": { "connectionTimeoutMs": 300000 }}
                            """))
                        }
                    case "start":
                        let startId = response.id?.stringValue ?? ""
                        Task {
                            try await Task.sleep(nanoseconds: 30_000_000)
                            await mockWebSocketClient.subject.send(.string("""
                                {"type": "start_ack", "id": "\(startId)"}
                            """))
                        }
                    default:
                        break
                    }
                default:
                    break
                }
            }
            .store(in: &cancellables)

        // Create all subscriptions
        for (index, id) in ids.enumerated() {
            let subscription = try await appSyncClient.subscribe(
                id: id,
                query: "subscription { onTest { id } }"
            ).sink { event in
                if case .subscribed = event {
                    let count = subscribedCounts[index].increment()
                    if count == 1 {
                        allInitiallySubscribed.fulfill()
                    } else if count == 2 {
                        allResubscribed.fulfill()
                    }
                }
            }
            cancellables.insert(subscription)
        }

        await fulfillment(of: [allInitiallySubscribed], timeout: 10)

        // Simulate connection drop
        await mockWebSocketClient.subject.send(.disconnected(.invalid, nil))

        // Simulate reconnection
        try await Task.sleep(nanoseconds: 100_000_000)
        await mockWebSocketClient.subject.send(.connected)

        await fulfillment(of: [allResubscribed], timeout: 15)
        withExtendedLifetime(cancellables) { }
    }

    /// Verifies that rapidly stopping and restarting subscriptions (as happens
    /// during iOS foreground recovery) does not leave subscriptions orphaned.
    /// This reproduces the race condition from GH-4220 where unsubscribe is
    /// called on a subscription still in "subscribing" state.
    ///
    /// - Given:
    ///    - An AppSyncRealTimeClient in connected state.
    /// - When:
    ///    - A subscription is created and immediately unsubscribed before
    ///      the `start_ack` arrives.
    ///    - A new subscription with the same query is then created.
    /// - Then:
    ///    - The second subscription successfully reaches "subscribed" state.
    ///    - No subscription is left orphaned.
    func testRapidUnsubscribeResubscribe_shouldNotOrphanSubscription() async throws {
        var cancellables = Set<AnyCancellable>()
        let mockWebSocketClient = MockWebSocketClient()
        let mockAppSyncRequestInterceptor = MockAppSyncRequestInterceptor()
        let appSyncClient = AppSyncRealTimeClient(
            endpoint: URL(string: "https://example.com")!,
            requestInterceptor: mockAppSyncRequestInterceptor,
            webSocketClient: mockWebSocketClient
        )

        await mockWebSocketClient.setStateToConnected()

        // Wire up mock — delay start_ack to simulate network latency
        await mockWebSocketClient.actionSubject
            .sink { action in
                switch action {
                case .connect:
                    Task {
                        await mockWebSocketClient.subject.send(.connected)
                    }
                case .write(let message):
                    guard let response = try? JSONDecoder().decode(
                        JSONValue.self,
                        from: message.data(using: .utf8)!
                    ) else { return }

                    switch response.type?.stringValue {
                    case "connection_init":
                        Task {
                            try await Task.sleep(nanoseconds: 30_000_000)
                            await mockWebSocketClient.subject.send(.string("""
                                {"type": "connection_ack", "payload": { "connectionTimeoutMs": 300000 }}
                            """))
                        }
                    case "start":
                        let startId = response.id?.stringValue ?? ""
                        // Delayed start_ack — simulates network round-trip
                        Task {
                            try await Task.sleep(nanoseconds: 200_000_000)
                            await mockWebSocketClient.subject.send(.string("""
                                {"type": "start_ack", "id": "\(startId)"}
                            """))
                        }
                    case "stop":
                        let stopId = response.id?.stringValue ?? ""
                        Task {
                            try await Task.sleep(nanoseconds: 30_000_000)
                            await mockWebSocketClient.subject.send(.string("""
                                {"type": "complete", "id": "\(stopId)"}
                            """))
                        }
                    default:
                        break
                    }
                default:
                    break
                }
            }
            .store(in: &cancellables)

        // Connect first
        Task {
            try await Task.sleep(nanoseconds: 50_000_000)
            await mockWebSocketClient.subject.send(.connected)
            try await Task.sleep(nanoseconds: 50_000_000)
            await mockWebSocketClient.subject.send(.string("""
                {"type": "connection_ack", "payload": { "connectionTimeoutMs": 300000 }}
            """))
        }
        try await appSyncClient.connect()

        // Create first subscription and immediately unsubscribe (before start_ack)
        let firstId = UUID().uuidString
        let firstSubscription = try await appSyncClient.subscribe(
            id: firstId,
            query: "subscription { onTest { id } }"
        ).sink { _ in }
        cancellables.insert(firstSubscription)

        // Unsubscribe quickly — before start_ack arrives
        try await Task.sleep(nanoseconds: 50_000_000)
        try await appSyncClient.unsubscribe(id: firstId)

        // Create second subscription — this should succeed
        let secondId = UUID().uuidString
        let secondSubscribed = expectation(description: "Second subscription should reach subscribed state")
        secondSubscribed.assertForOverFulfill = false

        let secondSubscription = try await appSyncClient.subscribe(
            id: secondId,
            query: "subscription { onTest { id } }"
        ).sink { event in
            if case .subscribed = event {
                secondSubscribed.fulfill()
            }
        }
        cancellables.insert(secondSubscription)

        await fulfillment(of: [secondSubscribed], timeout: 5)
        withExtendedLifetime(cancellables) { }
    }

    /// Verifies that when a WebSocket emits a `.error(.connectionLost)` event
    /// (as happens when `didCompleteWithError` fires with ECONNABORTED),
    /// all active subscriptions receive the error and the client transitions
    /// to a state that allows reconnection.
    ///
    /// - Given:
    ///    - An AppSyncRealTimeClient with 3 active subscriptions.
    /// - When:
    ///    - The WebSocket emits `.error(.connectionLost)`.
    /// - Then:
    ///    - All 3 subscriptions receive an error event containing
    ///      `WebSocketClient.Error.connectionLost`.
    func testConnectionLostError_withMultipleSubscriptions_shouldPropagateToAll() async throws {
        var cancellables = Set<AnyCancellable>()
        let mockWebSocketClient = MockWebSocketClient()
        let mockAppSyncRequestInterceptor = MockAppSyncRequestInterceptor()
        let appSyncClient = AppSyncRealTimeClient(
            endpoint: URL(string: "https://example.com")!,
            requestInterceptor: mockAppSyncRequestInterceptor,
            webSocketClient: mockWebSocketClient
        )

        let subscriptionCount = 3
        let ids = (0..<subscriptionCount).map { _ in UUID().uuidString }

        let allSubscribed = expectation(description: "All subscriptions established")
        allSubscribed.expectedFulfillmentCount = subscriptionCount

        let allReceivedError = expectation(description: "All subscriptions received connection lost error")
        allReceivedError.expectedFulfillmentCount = subscriptionCount

        await mockWebSocketClient.setStateToConnected()

        // Wire up mock
        await mockWebSocketClient.actionSubject
            .sink { action in
                if case .write(let message) = action {
                    guard let response = try? JSONDecoder().decode(
                        JSONValue.self,
                        from: message.data(using: .utf8)!
                    ) else { return }

                    switch response.type?.stringValue {
                    case "connection_init":
                        Task {
                            try await Task.sleep(nanoseconds: 30_000_000)
                            await mockWebSocketClient.subject.send(.string("""
                                {"type": "connection_ack", "payload": { "connectionTimeoutMs": 300000 }}
                            """))
                        }
                    case "start":
                        let startId = response.id?.stringValue ?? ""
                        Task {
                            try await Task.sleep(nanoseconds: 30_000_000)
                            await mockWebSocketClient.subject.send(.string("""
                                {"type": "start_ack", "id": "\(startId)"}
                            """))
                        }
                    default:
                        break
                    }
                }
            }
            .store(in: &cancellables)

        // Establish initial connection
        Task {
            try await Task.sleep(nanoseconds: 50_000_000)
            await mockWebSocketClient.subject.send(.connected)
            try await Task.sleep(nanoseconds: 50_000_000)
            await mockWebSocketClient.subject.send(.string("""
                {"type": "connection_ack", "payload": { "connectionTimeoutMs": 300000 }}
            """))
        }
        try await appSyncClient.connect()

        // Create subscriptions
        for id in ids {
            let subscription = try await appSyncClient.subscribe(
                id: id,
                query: "subscription { onTest { id } }"
            ).sink { event in
                if case .subscribed = event {
                    allSubscribed.fulfill()
                } else if case .error(let errors) = event {
                    if errors.contains(where: {
                        ($0 as? WebSocketClient.Error) == .connectionLost
                    }) {
                        allReceivedError.fulfill()
                    }
                }
            }
            cancellables.insert(subscription)
        }

        await fulfillment(of: [allSubscribed], timeout: 10)

        // Simulate connection lost (as happens when iOS defuncts the socket
        // and didCompleteWithError fires with ECONNABORTED)
        await mockWebSocketClient.subject.send(.error(WebSocketClient.Error.connectionLost))

        await fulfillment(of: [allReceivedError], timeout: 5)
        withExtendedLifetime(cancellables) { }
    }
}

// MARK: - Test Helpers

/// A mock WebSocket client that can be configured to fail on write operations,
/// simulating a dead socket after iOS process suspension.
private actor MockWriteFailingWebSocketClient: AppSyncWebSocketClientProtocol {
    var subject = PassthroughSubject<WebSocketEvent, Never>()
    private var state: MockWebSocketClient.State = .none
    private var shouldFailWrites = false

    var isConnected: Bool {
        state == .connected
    }

    var publisher: AnyPublisher<WebSocketEvent, Never> {
        subject.eraseToAnyPublisher()
    }

    func connect(autoConnectOnNetworkStatusChange: Bool, autoRetryOnConnectionFailure: Bool) {
        // no-op for this mock
    }

    func disconnect() {
        // no-op for this mock
    }

    func write(message: String) throws {
        if shouldFailWrites {
            // Simulate NSPOSIXErrorDomain Code=53 "Software caused connection abort"
            let error = NSError(
                domain: NSPOSIXErrorDomain,
                code: Int(ECONNABORTED),
                userInfo: [NSLocalizedDescriptionKey: "Software caused connection abort"]
            )
            throw error
        }
    }

    func setStateToConnected() {
        state = .connected
    }

    func setShouldFailWrites(_ shouldFail: Bool) {
        shouldFailWrites = shouldFail
    }
}

/// Thread-safe counter for tracking subscription events across concurrent tasks.
private final class AtomicCounter: @unchecked Sendable {
    private var value: Int = 0
    private let lock = NSLock()

    @discardableResult
    func increment() -> Int {
        lock.lock()
        defer { lock.unlock() }
        value += 1
        return value
    }

    var current: Int {
        lock.lock()
        defer { lock.unlock() }
        return value
    }
}
