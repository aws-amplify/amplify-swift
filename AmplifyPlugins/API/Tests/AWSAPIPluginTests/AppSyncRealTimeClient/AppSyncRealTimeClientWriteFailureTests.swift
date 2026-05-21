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
/// ("Software caused connection abort"). The library must propagate this error
/// to subscribers so they don't remain stuck in "subscribing" state.
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
        let ids = (0 ..< subscriptionCount).map { _ in UUID().uuidString }

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
