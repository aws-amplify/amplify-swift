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

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class AppSyncRealTimeClientFailureTests: XCTestCase, @unchecked Sendable {

    private static let connectionAck = """
        {"type": "connection_ack", "payload": { "connectionTimeoutMs": 300000 }}
    """

    /// An error AppSync can return for `connection_init` that the client retries
    private static let recoverableConnectionError = """
        {"type": "connection_error", "payload": { "errors": [{ "errorType": "InternalFailure", "message": "retry" }] }}
    """

    private func makeClient(_ webSocketClient: MockWebSocketClient) -> AppSyncRealTimeClient {
        AppSyncRealTimeClient(
            endpoint: URL(string: "https://example.com")!,
            requestInterceptor: MockAppSyncRequestInterceptor(),
            webSocketClient: webSocketClient
        )
    }

    /// Answers every `connection_init` the client writes, with `ack` or with a recoverable error
    private func answerConnectionInit(
        on webSocketClient: MockWebSocketClient,
        connectionInits: AtomicValue<Int>,
        acknowledge: AtomicValue<Bool>
    ) async -> AnyCancellable {
        await webSocketClient.actionSubject.sink { action in
            guard case .write(let message) = action, message.contains("connection_init") else {
                return
            }
            _ = connectionInits.increment()
            let response = acknowledge.get() ? Self.connectionAck : Self.recoverableConnectionError
            Task { await webSocketClient.subject.send(.string(response)) }
        }
    }

    /// Answers every `start` the client writes with `response(id)`, after `delay`
    private func answerStart(
        on webSocketClient: MockWebSocketClient,
        after delay: TimeInterval = 0,
        with response: @escaping @Sendable (String) -> String
    ) async -> AnyCancellable {
        await webSocketClient.actionSubject.sink { action in
            guard case .write(let message) = action,
                  let request = try? JSONDecoder().decode(JSONValue.self, from: Data(message.utf8)),
                  request.type?.stringValue == "start",
                  let id = request.id?.stringValue else {
                return
            }
            Task {
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                await webSocketClient.subject.send(.string(response(id)))
            }
        }
    }

    private func waitUntil(timeout: TimeInterval = 2, _ condition: () -> Bool) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition(), Date() < deadline {
            try await Task.sleep(nanoseconds: 10 * 1_000_000)
        }
    }

    private func connectedClient(_ webSocketClient: MockWebSocketClient) async throws -> (AppSyncRealTimeClient, AnyCancellable) {
        let client = makeClient(webSocketClient)
        await webSocketClient.setStateToConnected()
        let answers = await answerConnectionInit(
            on: webSocketClient,
            connectionInits: AtomicValue(initialValue: 0),
            acknowledge: AtomicValue(initialValue: true)
        )
        try await client.connect()
        return (client, answers)
    }

    /// `connect()` in a cancelled task leaves the client able to connect.
    ///
    /// - Given: A client that has never connected
    /// - When:
    ///    - `connect()` runs in a task that is already cancelled
    ///    - Then `connect()` runs in a live task
    /// - Then:
    ///    - The first call throws `CancellationError` without claiming `.connecting` or opening the socket
    ///    - The second call opens the socket
    ///
    func testConnect_inCancelledTask_doesNotBlockALaterConnect() async throws {
        let webSocketClient = MockWebSocketClient()
        let client = makeClient(webSocketClient)
        let socketConnects = AtomicValue(initialValue: 0)
        let sink = await webSocketClient.actionSubject.sink { action in
            if case .connect = action {
                _ = socketConnects.increment()
            }
        }
        let connectingStates = AtomicValue(initialValue: 0)
        let states = await client.statePublisher.sink { state in
            if state == .connecting {
                _ = connectingStates.increment()
            }
        }

        let cancelled = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            try await client.connect()
        }
        let cancelledResult = await cancelled.result
        guard case .failure(let error) = cancelledResult else {
            XCTFail("Expected the cancelled connect to throw")
            return
        }
        XCTAssertTrue(error is CancellationError, "Got \(error)")
        XCTAssertEqual(socketConnects.get(), 0)
        XCTAssertEqual(connectingStates.get(), 0, "A cancelled task claimed .connecting")

        let live = Task { try await client.connect() }
        try await waitUntil { socketConnects.get() > 0 }
        XCTAssertEqual(socketConnects.get(), 1)
        live.cancel()
        sink.cancel()
        states.cancel()
    }

    /// An idle disconnect that cancels a pending subscription start leaves the client able to connect.
    ///
    /// - Given: A client whose only subscription is removed before its deferred start runs
    /// - When:
    ///    - The client disconnects because it is idle, cancelling that start
    ///    - Then `connect()` runs in a live task
    /// - Then:
    ///    - The live connect opens the socket every time
    ///
    func testIdleDisconnectCancellingAPendingStart_doesNotBlockLaterConnects() async throws {
        var blocked = 0
        for index in 0 ..< 50 {
            let webSocketClient = MockWebSocketClient()
            let client = makeClient(webSocketClient)
            _ = try await client.subscribe(id: "subscription-\(index)", query: "query")
            try await client.unsubscribe(id: "subscription-\(index)")
            await client.disconnectWhenIdel()
            try await Task.sleep(nanoseconds: 20 * 1_000_000)

            let socketConnects = AtomicValue(initialValue: 0)
            let sink = await webSocketClient.actionSubject.sink { action in
                if case .connect = action {
                    _ = socketConnects.increment()
                }
            }
            let live = Task { try? await client.connect() }
            try await waitUntil { socketConnects.get() > 0 }
            if socketConnects.get() == 0 {
                blocked += 1
            }
            live.cancel()
            sink.cancel()
        }
        XCTAssertEqual(blocked, 0, "\(blocked) of 50 clients could no longer connect")
    }

    /// A connection attempt that runs out of retries closes its socket, tells subscribers, and allows a new attempt.
    ///
    /// - Given: A client whose every `connection_init` is answered with a recoverable error
    /// - When:
    ///    - `connect()` retries until it gives up
    ///    - Then AppSync starts acknowledging, and `connect()` runs again
    /// - Then:
    ///    - The first call throws, closes the socket, and sends `connectionLost` to subscribers
    ///    - The second call sends a new `connection_init` and connects
    ///
    func testConnect_whenRetriesRunOut_reportsConnectionLostAndAllowsANewAttempt() async throws {
        let webSocketClient = MockWebSocketClient()
        let client = makeClient(webSocketClient)
        let connectionInits = AtomicValue(initialValue: 0)
        let acknowledge = AtomicValue(initialValue: false)
        let answers = await answerConnectionInit(
            on: webSocketClient,
            connectionInits: connectionInits,
            acknowledge: acknowledge
        )
        let socketDisconnects = AtomicValue(initialValue: 0)
        let disconnects = await webSocketClient.actionSubject.sink { action in
            if case .disconnect = action {
                _ = socketDisconnects.increment()
            }
        }
        let connectionLost = expectation(description: "Subscribers are told the connection was lost")
        let failures = client.subject.sink { result in
            if case .failure(let error) = result, (error as? WebSocketClient.Error) == .connectionLost {
                connectionLost.fulfill()
            }
        }

        do {
            try await client.connect()
            XCTFail("Expected connect() to give up")
        } catch {
            XCTAssertTrue(error is RetryWithJitter.Error, "Got \(error)")
        }
        await fulfillment(of: [connectionLost], timeout: 1)
        XCTAssertEqual(socketDisconnects.get(), 1)
        let initsBeforeRetry = connectionInits.get()

        acknowledge.set(true)
        try await client.connect()
        let isConnected = await client.isConnected
        XCTAssertTrue(isConnected)
        XCTAssertEqual(connectionInits.get(), initsBeforeRetry + 1)
        answers.cancel()
        disconnects.cancel()
        failures.cancel()
    }

    /// An attempt that ends after a newer one took over leaves `.connecting` to the newer attempt.
    ///
    /// - Given: A connect attempt waiting for its `connection_ack`
    /// - When:
    ///    - The client disconnects, and a second attempt starts and waits for its own ack
    ///    - Then the first attempt ends
    /// - Then:
    ///    - The second attempt still owns `.connecting`, so another `connect()` doesn't start a third
    ///
    func testEndedAttempt_doesNotReleaseANewerAttemptsConnecting() async throws {
        let webSocketClient = MockWebSocketClient()
        let client = makeClient(webSocketClient)
        let connectionInits = AtomicValue(initialValue: 0)
        let sink = await webSocketClient.actionSubject.sink { action in
            if case .write(let message) = action, message.contains("connection_init") {
                _ = connectionInits.increment()
            }
        }

        let first = Task { try await client.connect() }
        try await waitUntil { connectionInits.get() == 1 }
        await client.disconnect()
        first.cancel()
        // Well before the second attempt's own 5 s wait ends, so its retry can't be mistaken for a third attempt
        try await Task.sleep(nanoseconds: 1_000_000_000)
        let second = Task { try await client.connect() }
        try await waitUntil { connectionInits.get() == 2 }

        // The first attempt's connection_init times out, then its cancelled retry ends it
        _ = await first.result
        let third = Task { try await client.connect() }
        try await Task.sleep(nanoseconds: 200 * 1_000_000)

        XCTAssertEqual(connectionInits.get(), 2, "The first attempt released the second attempt's .connecting")
        third.cancel()
        second.cancel()
        sink.cancel()
    }

    /// A start that AppSync never acknowledges on a live connection fails the subscription.
    ///
    /// - Given: A connected client
    /// - When:
    ///    - A subscription's `start` gets no response
    /// - Then:
    ///    - The subscription receives a `connectionLost` error once the start times out
    ///
    func testSubscribe_whenStartIsNeverAcknowledged_reportsConnectionLost() async throws {
        let webSocketClient = MockWebSocketClient()
        let (client, answers) = try await connectedClient(webSocketClient)

        let connectionLost = expectation(description: "The subscription is told its start failed")
        let events = try await client.subscribe(id: UUID().uuidString, query: "query").sink { event in
            if case .error(let errors) = event,
               errors.contains(where: { ($0 as? WebSocketClient.Error) == .connectionLost }) {
                connectionLost.fulfill()
            }
        }

        await fulfillment(of: [connectionLost], timeout: AppSyncRealTimeSubscription.startTimeout + 3)
        answers.cancel()
        events.cancel()
    }

    /// A start acknowledged after 6 s, as a cold Lambda authorizer can make it, still subscribes.
    ///
    /// - Given: A connected client
    /// - When:
    ///    - AppSync acknowledges a subscription's `start` after 6 s
    /// - Then:
    ///    - The subscription is subscribed and receives no error
    ///
    func testSubscribe_whenStartIsAcknowledgedSlowly_subscribesWithoutAnError() async throws {
        let webSocketClient = MockWebSocketClient()
        let (client, answers) = try await connectedClient(webSocketClient)
        let startAnswers = await answerStart(on: webSocketClient, after: 6) { id in
            #"{"type": "start_ack", "id": "\#(id)"}"#
        }

        let subscribed = expectation(description: "The subscription is subscribed")
        let failed = expectation(description: "The subscription receives an error")
        failed.isInverted = true
        let events = try await client.subscribe(id: UUID().uuidString, query: "query").sink { event in
            switch event {
            case .subscribed:
                subscribed.fulfill()
            case .error:
                failed.fulfill()
            default:
                break
            }
        }

        await fulfillment(of: [subscribed], timeout: 9)
        await fulfillment(of: [failed], timeout: 0.5)
        answers.cancel()
        startAnswers.cancel()
        events.cancel()
    }

    /// A request rejected by an error frame it can't parse fails at once.
    ///
    /// - Given: A connected client, so it is already reading the socket
    /// - When:
    ///    - A `start` gets an `error` response whose errors have no `errorType`
    /// - Then:
    ///    - The request fails at once instead of waiting for its timeout, which would report the rejection again
    ///
    func testSendRequest_whenRejectedByAnUnparseableError_failsAtOnce() async throws {
        let webSocketClient = MockWebSocketClient()
        let (client, answers) = try await connectedClient(webSocketClient)
        let startAnswers = await answerStart(on: webSocketClient) { id in
            #"{"type": "error", "id": "\#(id)", "payload": { "errors": [{ "message": "rejected" }] }}"#
        }

        let started = Date()
        do {
            try await client.sendRequest(.start(.init(id: "subscription", data: "query", auth: nil)), timeout: 5)
            XCTFail("Expected the start to fail")
        } catch {
            XCTAssertNotEqual(error as? AppSyncRealTimeRequest.Error, .timeout)
        }
        XCTAssertLessThan(Date().timeIntervalSince(started), 2)
        answers.cancel()
        startAnswers.cancel()
    }
}
