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

// Regression tests for the AppSync real-time connection/cost spike: a
// session-expiry connection_error was swallowed, so connectionInit timed out and
// connect() retried, opening a new connection on every retry.
// https://github.com/aws-amplify/amplify-swift/issues/4007
class AppSyncRealTimeClientReconnectTests: XCTestCase {

    private func makeClient(
        _ webSocketClient: MockWebSocketClient
    ) -> AppSyncRealTimeClient {
        AppSyncRealTimeClient(
            endpoint: URL(string: "https://example.com")!,
            requestInterceptor: MockAppSyncRequestInterceptor(),
            webSocketClient: webSocketClient
        )
    }

    private var unauthorizedConnectionError: AppSyncRealTimeResponse {
        .init(
            id: nil,
            payload: .object([
                "errors": .array([
                    .object([
                        "errorType": "UnauthorizedException",
                        "message": "Unauthorized"
                    ])
                ])
            ]),
            type: .connectionError
        )
    }

    // A connection_error received while waiting for connection_ack must fail the
    // connectionInit request with the decoded error. Before the fix it was
    // unhandled, so the request hung until it timed out.
    func testConnectionInit_withUnauthorizedConnectionError_failsWithUnauthorized() async {
        let webSocketClient = MockWebSocketClient()
        let client = makeClient(webSocketClient)

        // Respond only once connectionInit has been written, so the request's
        // listener is guaranteed to be subscribed first (avoids a timing race).
        var cancellables = Set<AnyCancellable>()
        await webSocketClient.actionSubject
            .sink { action in
                guard case .write(let message) = action,
                      message.contains("connection_init") else { return }
                client.subject.send(.success(self.unauthorizedConnectionError))
            }
            .store(in: &cancellables)

        let failed = expectation(description: "connectionInit fails with unauthorized")
        Task {
            do {
                try await client.sendRequest(.connectionInit, timeout: 2)
                XCTFail("connectionInit should have failed")
            } catch {
                XCTAssertEqual(error as? AppSyncRealTimeRequest.Error, .unauthorized)
                failed.fulfill()
            }
        }
        await fulfillment(of: [failed], timeout: 3)
    }

    // A non-recoverable auth error must stop connect() immediately instead of
    // retrying, otherwise every retry opens another connection to AppSync.
    func testConnect_withUnauthorizedError_throwsWithoutRetrying() async {
        let webSocketClient = MockWebSocketClient()
        let client = makeClient(webSocketClient)

        let lock = NSLock()
        var connectionInitCount = 0
        var cancellables = Set<AnyCancellable>()
        await webSocketClient.actionSubject
            .sink { action in
                guard case .write(let message) = action,
                      message.contains("connection_init") else { return }
                lock.lock()
                connectionInitCount += 1
                lock.unlock()
                client.subject.send(.success(self.unauthorizedConnectionError))
            }
            .store(in: &cancellables)

        let failed = expectation(description: "connect fails with unauthorized")
        Task {
            do {
                try await client.connect()
                XCTFail("connect should have failed")
            } catch {
                XCTAssertEqual(error as? AppSyncRealTimeRequest.Error, .unauthorized)
                failed.fulfill()
            }
        }
        await fulfillment(of: [failed], timeout: 3)

        lock.lock()
        let count = connectionInitCount
        lock.unlock()
        XCTAssertEqual(count, 1, "connect() must not retry a non-recoverable auth error")
    }

    // The continuous connection spam comes from the socket auto-retrying into the
    // same auth failure. On a non-recoverable error the client must disconnect the
    // socket to turn that auto-retry off.
    func testConnect_withUnauthorizedError_stopsSocketAutoRetry() async {
        let webSocketClient = MockWebSocketClient()
        let client = makeClient(webSocketClient)

        let disconnected = expectation(description: "socket disconnected to stop auto-retry")
        disconnected.assertForOverFulfill = false
        var cancellables = Set<AnyCancellable>()
        await webSocketClient.actionSubject
            .sink { action in
                switch action {
                case .write(let message) where message.contains("connection_init"):
                    client.subject.send(.success(self.unauthorizedConnectionError))
                case .disconnect:
                    disconnected.fulfill()
                default:
                    break
                }
            }
            .store(in: &cancellables)

        let failed = expectation(description: "connect fails with unauthorized")
        Task {
            do {
                try await client.connect()
                XCTFail("connect should have failed")
            } catch {
                XCTAssertEqual(error as? AppSyncRealTimeRequest.Error, .unauthorized)
                failed.fulfill()
            }
        }
        await fulfillment(of: [failed, disconnected], timeout: 3)
    }

    // Guards the give-up predicate: only auth/limit errors are non-recoverable.
    // Recoverable errors (timeout, network, cancellation) must NOT trigger the
    // give-up, otherwise normal reconnection would be broken.
    func testIsNonRecoverable_classification() {
        XCTAssertTrue(AppSyncRealTimeClient.isNonRecoverable(AppSyncRealTimeRequest.Error.unauthorized))
        XCTAssertTrue(AppSyncRealTimeClient.isNonRecoverable(AppSyncRealTimeRequest.Error.maxSubscriptionsReached))
        XCTAssertTrue(AppSyncRealTimeClient.isNonRecoverable(AppSyncRealTimeRequest.Error.limitExceeded))
        XCTAssertFalse(AppSyncRealTimeClient.isNonRecoverable(AppSyncRealTimeRequest.Error.timeout))
        XCTAssertFalse(AppSyncRealTimeClient.isNonRecoverable(
            AppSyncRealTimeRequest.Error.unknown(payload: nil)
        ))
        XCTAssertFalse(AppSyncRealTimeClient.isNonRecoverable(CancellationError()))
        XCTAssertFalse(AppSyncRealTimeClient.isNonRecoverable(URLError(.notConnectedToInternet)))
    }

    // Guards the connect() retry predicate: cancellation and non-recoverable
    // errors are not retried; everything else (e.g. timeout) is.
    func testShouldRetryConnection_classification() {
        XCTAssertFalse(AppSyncRealTimeClient.shouldRetryConnection(CancellationError()))
        XCTAssertFalse(AppSyncRealTimeClient.shouldRetryConnection(AppSyncRealTimeRequest.Error.unauthorized))
        XCTAssertTrue(AppSyncRealTimeClient.shouldRetryConnection(AppSyncRealTimeRequest.Error.timeout))
        XCTAssertTrue(AppSyncRealTimeClient.shouldRetryConnection(URLError(.networkConnectionLost)))
    }

    // A subscription that fails with a non-recoverable error must not be
    // resubscribed on the next reconnect (resumeExistingSubscriptions), otherwise
    // it re-sends `start` on every reconnect — the SubscribeClientError spike.
    func testSubscription_afterNonRecoverableError_isNotResubscribed() async {
        let webSocketClient = MockWebSocketClient()
        let client = makeClient(webSocketClient)
        let subscription = AppSyncRealTimeSubscription(
            id: "sub-4007",
            query: "subscription { onEvent { id } }",
            appSyncRealTimeClient: client
        )

        let lock = NSLock()
        var startCount = 0
        var cancellables = Set<AnyCancellable>()
        await webSocketClient.actionSubject
            .sink { action in
                guard case .write(let message) = action,
                      message.contains("sub-4007") else { return }
                lock.lock()
                startCount += 1
                lock.unlock()
                client.subject.send(.success(.init(
                    id: "sub-4007",
                    payload: .object([
                        "errors": .array([
                            .object([
                                "errorType": "UnauthorizedException",
                                "message": "Unauthorized"
                            ])
                        ])
                    ]),
                    type: .error
                )))
            }
            .store(in: &cancellables)

        // First subscribe fails with a non-recoverable auth error -> terminated.
        do {
            try await subscription.subscribe()
            XCTFail("subscribe should have failed")
        } catch {
            XCTAssertEqual(error as? AppSyncRealTimeRequest.Error, .unauthorized)
        }

        // Simulate resume-on-reconnect: it must NOT send another start.
        try? await subscription.subscribe()

        lock.lock()
        let count = startCount
        lock.unlock()
        XCTAssertEqual(count, 1, "a non-recoverable subscription failure must not be resubscribed")
    }

    // The heartbeat-timeout and connection-drop paths can both fire a reconnect.
    // While one reconnect is in flight (connect() blocked awaiting connection_ack)
    // the other must be skipped, so only a single connection is opened.
    func testConcurrentReconnects_areSingleFlight() async throws {
        let webSocketClient = MockWebSocketClient()
        let client = makeClient(webSocketClient)

        let lock = NSLock()
        var connectCount = 0
        var cancellables = Set<AnyCancellable>()
        await webSocketClient.actionSubject
            .sink { action in
                guard case .connect = action else { return }
                lock.lock()
                connectCount += 1
                lock.unlock()
            }
            .store(in: &cancellables)

        // Let the client subscribe to the WebSocket event publisher (init Task).
        try await Task.sleep(nanoseconds: 200 * 1_000_000)

        // First reconnect: connect() blocks (no connection_ack ever sent), so the
        // reconnect stays in flight for the whole window.
        await webSocketClient.subject.send(.disconnected(.normalClosure, nil))
        try await Task.sleep(nanoseconds: 150 * 1_000_000)
        await webSocketClient.subject.send(.connected)
        try await Task.sleep(nanoseconds: 300 * 1_000_000)

        // Second trigger while the first reconnect is still in flight.
        await webSocketClient.subject.send(.disconnected(.normalClosure, nil))
        try await Task.sleep(nanoseconds: 150 * 1_000_000)
        await webSocketClient.subject.send(.connected)
        try await Task.sleep(nanoseconds: 300 * 1_000_000)

        lock.lock()
        let count = connectCount
        lock.unlock()
        XCTAssertEqual(count, 1, "overlapping reconnects must collapse to a single connect()")
    }

    // A transient error (e.g. LimitExceededError throttling) must NOT permanently
    // terminate the subscription; it stays resumable on the next reconnect.
    func testSubscription_afterLimitExceeded_isResubscribed() async {
        let webSocketClient = MockWebSocketClient()
        let client = makeClient(webSocketClient)
        let subscription = AppSyncRealTimeSubscription(
            id: "sub-limit",
            query: "subscription { onEvent { id } }",
            appSyncRealTimeClient: client
        )

        let lock = NSLock()
        var startCount = 0
        var cancellables = Set<AnyCancellable>()
        await webSocketClient.actionSubject
            .sink { action in
                guard case .write(let message) = action,
                      message.contains("sub-limit") else { return }
                lock.lock()
                startCount += 1
                lock.unlock()
                client.subject.send(.success(.init(
                    id: "sub-limit",
                    payload: .object([
                        "errors": .array([
                            .object([
                                "errorType": "LimitExceededError",
                                "message": "Rate exceeded"
                            ])
                        ])
                    ]),
                    type: .error
                )))
            }
            .store(in: &cancellables)

        // First subscribe fails with a transient limit error.
        do {
            try await subscription.subscribe()
            XCTFail("subscribe should have failed")
        } catch {
            XCTAssertEqual(error as? AppSyncRealTimeRequest.Error, .limitExceeded)
        }

        // Resume-on-reconnect must send another start (not permanently terminated).
        try? await subscription.subscribe()

        lock.lock()
        let count = startCount
        lock.unlock()
        XCTAssertEqual(count, 2, "a transient limitExceeded must be retried on resubscribe, not terminated")
    }
}
