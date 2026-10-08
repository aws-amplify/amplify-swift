//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@preconcurrency import Combine
import XCTest
@testable @_spi(WebSocket) import AWSPluginsCore

// Waits cover real local-socket connect/disconnect/auto-retry round-trips (incl. retry backoff),
// which can exceed a few seconds under CI load — hence a generous shared budget.
private let timeout: TimeInterval = 10

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class WebSocketClientTests: XCTestCase, @unchecked Sendable {
    var localWebSocketServer: LocalWebSocketServer?

    override func setUp() async throws {
        localWebSocketServer = LocalWebSocketServer()
    }

    override func tearDown() async throws {
        localWebSocketServer?.stop()
    }

    func testConnect_withHttpScheme_didConnectedWithWs() async throws {
        guard let endpoint = try localWebSocketServer?.start() else {
            XCTFail("Local WebSocket server failed to start")
            return
        }
        let webSocketClient = WebSocketClient(url: endpoint)
        await verifyConnected(webSocketClient)
    }

    func testDisconnect_didDisconnectFromRemote() async throws {
        var cancellables = Set<AnyCancellable>()
        guard let endpoint = try localWebSocketServer?.start() else {
            XCTFail("Local WebSocket server failed to start")
            return
        }

        let disconnectedExpectation = expectation(description: "WebSocket did disconnect")

        let webSocketClient = WebSocketClient(url: endpoint)
        await verifyConnected(webSocketClient)

        webSocketClient.publisher
            .sink { event in
                switch event {
                case let .disconnected(closeCode, reason):
                    XCTAssertNil(reason)
                    XCTAssertEqual(closeCode, .goingAway)
                    disconnectedExpectation.fulfill()
                default:
                    XCTFail("No other type of event should be received")
                }
            }
            .store(in: &cancellables)
        await webSocketClient.disconnect()
        await fulfillment(of: [disconnectedExpectation], timeout: timeout)
    }

    func testWriteAndRead_withWebSocketClient_didBehavesCorrectly() async throws {
        var cancellables = Set<AnyCancellable>()
        guard let endpoint = try localWebSocketServer?.start() else {
            XCTFail("Local WebSocket server failed to start")
            return
        }

        let messageReceivedExpectation = expectation(description: "WebSocket could read/write text message")
        let dataReceivedExpectation = expectation(description: "WebSocket could read/wirte binary message")
        let sampleMessage = UUID().uuidString
        let sampleDataMessage = UUID().uuidString

        let webSocketClient = WebSocketClient(url: endpoint)
        await verifyConnected(webSocketClient)
        webSocketClient.publisher.sink { event in
            switch event {
            case .string(let message) where message == sampleMessage:
                messageReceivedExpectation.fulfill()
            case .data(let data):
                XCTAssertEqual(sampleDataMessage.hexaData, data)
                dataReceivedExpectation.fulfill()
            default:
                XCTFail("No other type of event should be received")
            }
        }.store(in: &cancellables)

        try await webSocketClient.write(message: sampleMessage)
        try await webSocketClient.write(message: sampleDataMessage.hexaData)
        await fulfillment(of: [
            messageReceivedExpectation,
            dataReceivedExpectation
        ], timeout: timeout, enforceOrder: true)
    }

    func testWebSocketClient_whenNetworkStateChagnes_disconnectOrReconnect() async throws {
        var cancellables = Set<AnyCancellable>()
        guard let endpoint = try localWebSocketServer?.start() else {
            XCTFail("Local WebSocket server failed to start")
            return
        }

        let mockNetworkMonitor = MockNetworkMonitor()
        let webSocketClient = WebSocketClient(url: endpoint, networkMonitor: mockNetworkMonitor)
        await verifyConnected(webSocketClient, autoConnectOnNetworkStatusChange: true)

        let disconnectExpectation = expectation(description: "Network drop should trigger disconnect")
        webSocketClient.publisher.sink { event in
            switch event {
            case let .disconnected(closeCode, reason):
                XCTAssertEqual(closeCode, .invalid)
                XCTAssertNil(reason)
                disconnectExpectation.fulfill()
            case let .error(error):
                XCTAssertEqual(error as? WebSocketClient.Error, WebSocketClient.Error.connectionCancelled)
            default:
                XCTFail("No other type of event should be received")
            }
        }
        .store(in: &cancellables)
        // set network offline
        await mockNetworkMonitor.updateState(.offline)
        await fulfillment(of: [disconnectExpectation], timeout: timeout)
        cancellables = Set()

        try await Task.sleep(seconds: 0.1)
        let reconnectExpectation = expectation(description: "Network back online trigger reconnect")
        webSocketClient.publisher.sink { event in
            switch event {
            case .connected:
                reconnectExpectation.fulfill()
            default:
                XCTFail("No other type of event should be received")
            }
        }
        .store(in: &cancellables)
        // set network online again
        await mockNetworkMonitor.updateState(.online)
        await fulfillment(of: [reconnectExpectation], timeout: timeout)
    }

    func testAutoRetry_whenReceiveTransientFailureFromServer() async throws {
        var cancellables = Set<AnyCancellable>()
        guard let endpoint = try localWebSocketServer?.start() else {
            XCTFail("Local WebSocket server failed to start")
            return
        }

        let webSocketClient = WebSocketClient(url: endpoint)
        await verifyConnected(webSocketClient, autoRetryOnConnectionFailure: true)

        let disconnectExpectation = expectation(description: "Tresient Server Error should trigger retry")
        let reconnectedExpectation = expectation(description: "Connected should be re-triggered")

        webSocketClient.publisher.sink { event in
            switch event {
            case let .disconnected(closeCode, reason):
                XCTAssertEqual(closeCode, .internalServerError)
                XCTAssert(reason == nil || reason!.isEmpty)
                disconnectExpectation.fulfill()
            case .connected:
                reconnectedExpectation.fulfill()
            case .error, .data:
                // A transient server failure can surface a `.error`/`.data` event around the
                // disconnect; ignore only those. The ordered disconnect->reconnect gates the test.
                break
            default:
                XCTFail("No other type of event should be received")
            }
        }
        .store(in: &cancellables)
        localWebSocketServer?.sendTransientFailureToConnections()
        await fulfillment(of: [disconnectExpectation, reconnectedExpectation], timeout: timeout, enforceOrder: true)
    }

    /// Verifies that repeated probe failures recycle the socket and it reconnects.
    ///
    /// - Given: A probe that fails twice and then succeeds, with auto-retry enabled
    /// - When: The liveness monitor runs
    /// - Then: The socket closes with `.abnormalClosure` and then reconnects, in that order
    func testLivenessPing_recyclesConnection_whenServerDoesNotRespondToPing() async throws {
        var cancellables = Set<AnyCancellable>()
        guard let endpoint = try localWebSocketServer?.start() else {
            XCTFail("Local WebSocket server failed to start")
            return
        }

        // Synthetic probe: fails the first two checks, then succeeds. The local server stays up;
        // no real pong is suppressed.
        actor DeadThenAlive {
            private var calls = 0
            func probe() -> Bool {
                calls += 1
                return calls > 2
            }
        }
        let probe = DeadThenAlive()

        let webSocketClient = WebSocketClient(
            url: endpoint,
            pingInterval: 0.3,
            pingTimeout: 0.3,
            isConnectionAlive: { _, _ in await probe.probe() }
        )
        await verifyConnected(webSocketClient, autoRetryOnConnectionFailure: true)

        let disconnected = expectation(description: "Dead ping disconnects the socket")
        let reconnected = expectation(description: "Client reconnects after recycling")
        webSocketClient.publisher.sink { event in
            switch event {
            case let .disconnected(closeCode, _) where closeCode == .abnormalClosure:
                disconnected.fulfill()
            case .connected:
                reconnected.fulfill()
            default:
                break
            }
        }
        .store(in: &cancellables)

        await fulfillment(of: [disconnected, reconnected], timeout: timeout, enforceOrder: true)
    }

    /// Verifies that a single failed probe does not recycle the connection (anti-flap guard).
    ///
    /// - Given: A probe that fails once and then succeeds
    /// - When: Several liveness cycles run
    /// - Then: The original connection remains active
    func testLivenessPing_doesNotRecycle_onSingleMiss() async throws {
        guard let endpoint = try localWebSocketServer?.start() else {
            XCTFail("Local WebSocket server failed to start")
            return
        }

        // Synthetic probe: fails once, then succeeds.
        actor MissOnce {
            private var calls = 0
            func probe() -> Bool {
                calls += 1
                return calls > 1
            }
        }
        let missOnce = MissOnce()

        let webSocketClient = WebSocketClient(
            url: endpoint,
            pingInterval: 0.3,
            pingTimeout: 0.3,
            isConnectionAlive: { _, _ in await missOnce.probe() }
        )
        await verifyConnected(webSocketClient)

        // Allow several ping cycles to run (one miss, then healthy).
        try await Task.sleep(seconds: 1.5)
        let stillConnected = await webSocketClient.isConnected
        XCTAssertTrue(stillConnected, "A single missed ping must not recycle a healthy connection")
        await webSocketClient.disconnect()
    }

    /// Verifies that a close callback from a superseded socket is ignored.
    ///
    /// - Given: A connected client whose current socket differs from a stale socket task
    /// - When: The close delegate fires for the stale socket
    /// - Then: No `.disconnected` is published, so the active connection's subscriptions survive
    func testLivenessPing_ignoresCloseFromSupersededSocket() async throws {
        var cancellables = Set<AnyCancellable>()
        guard let endpoint = try localWebSocketServer?.start() else {
            XCTFail("Local WebSocket server failed to start")
            return
        }

        let webSocketClient = WebSocketClient(url: endpoint)
        await verifyConnected(webSocketClient)

        // A task that was never the client's current connection stands in for a superseded socket.
        let supersededTask = URLSession(configuration: .default)
            .webSocketTask(with: URL(string: "ws://localhost")!)

        let noDisconnect = expectation(description: "Superseded close must not publish .disconnected")
        noDisconnect.isInverted = true
        webSocketClient.publisher.sink { event in
            if case .disconnected = event {
                noDisconnect.fulfill()
            }
        }
        .store(in: &cancellables)

        webSocketClient.urlSession(
            URLSession(configuration: .default),
            webSocketTask: supersededTask,
            didCloseWith: .abnormalClosure,
            reason: nil
        )

        await fulfillment(of: [noDisconnect], timeout: 1.0)
        let stillConnected = await webSocketClient.isConnected
        XCTAssertTrue(stillConnected, "A superseded socket close must not disconnect the active connection")
        await webSocketClient.disconnect()
    }

    private func verifyConnected(
        _ webSocketClient: WebSocketClient,
        autoConnectOnNetworkStatusChange: Bool = false,
        autoRetryOnConnectionFailure: Bool = false
    ) async {
        var cancellables = Set<AnyCancellable>()
        let connectedExpectation = expectation(description: "WebSocket did connect")
        webSocketClient.publisher.sink { event in
            switch event {
            case .connected:
                connectedExpectation.fulfill()
            default:
                XCTFail("No other type of event should be received")
            }
        }.store(in: &cancellables)

        await webSocketClient.connect(
            autoConnectOnNetworkStatusChange: autoConnectOnNetworkStatusChange,
            autoRetryOnConnectionFailure: autoRetryOnConnectionFailure
        )
        await fulfillment(of: [connectedExpectation], timeout: timeout)
    }

}


// `@unchecked Sendable`: the protocol it conforms to now requires `Sendable`. Test double driven
// by a single test at a time.
private final class MockNetworkMonitor: WebSocketNetworkMonitorProtocol, @unchecked Sendable {
    typealias State = AmplifyNetworkMonitor.State
    let subject = PassthroughSubject<State, Never>()
    var publisher: AnyPublisher<(State, State), Never> {
        subject.scan((State.online, State.online)) { partial, newValue in
            (partial.1, newValue)
        }.eraseToAnyPublisher()
    }

    func updateState(_ nextState: AmplifyNetworkMonitor.State) async {
        subject.send(nextState)
    }


}

private extension String {
    var hexaData: Data {
        .init(hexa)
    }

    private var hexa: UnfoldSequence<UInt8, Index> {
        sequence(state: startIndex) { startIndex in
            // bail if we've reached the end of the string
            guard startIndex < self.endIndex else { return nil }

            // get the next two characters
            let endIndex = self.index(startIndex, offsetBy: 2, limitedBy: self.endIndex) ?? self.endIndex
            defer { startIndex = endIndex }

            // convert the characters to a UInt8
            return UInt8(self[startIndex ..< endIndex], radix: 16)
        }
    }
}
