//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@preconcurrency import Combine
import XCTest
@testable @_spi(WebSocket) import AWSPluginsCore

/// Regression tests for https://github.com/aws-amplify/amplify-swift/issues/4220.
///
/// These tests verify that `WebSocketClient` correctly handles connection
/// failures that occur when iOS suspends the app process and the kernel
/// defuncts TCP flows. The key failure mode is:
///
/// 1. App goes to background → iOS defuncts TCP socket
/// 2. App returns to foreground → WebSocket appears connected but is dead
/// 3. Write attempts fail with ECONNABORTED (Code 53)
/// 4. Client must detect this and trigger reconnection
///
/// The tests also cover the scenario where the server forcibly closes the
/// connection (simulating the socket being torn down), and verify that the
/// client properly emits disconnect events and reconnects.
class WebSocketClientConnectionAbortTests: XCTestCase {
    var localWebSocketServer: LocalWebSocketServer?

    override func setUp() async throws {
        localWebSocketServer = LocalWebSocketServer()
    }

    override func tearDown() async throws {
        localWebSocketServer?.stop()
    }

    /// Verifies that when the server forcibly closes the WebSocket connection
    /// (simulating a socket defunct after process suspension), the client
    /// emits a `.disconnected` event and reconnects when auto-retry is enabled.
    ///
    /// This simulates the scenario from GH-4220 where the TCP connection is
    /// torn down by the OS during background, and the client needs to detect
    /// and recover from it.
    ///
    /// - Given:
    ///    - A WebSocketClient connected to a local server with
    ///      autoRetryOnConnectionFailure enabled.
    /// - When:
    ///    - The server forcibly closes the connection with an error code
    ///      (simulating OS-level socket defunct).
    /// - Then:
    ///    - The client emits a `.disconnected` event.
    ///    - The client automatically reconnects (`.connected` event).
    func testWebSocketClient_whenServerForciblyCloses_shouldDisconnectAndReconnect() async throws {
        var cancellables = Set<AnyCancellable>()
        guard let endpoint = try localWebSocketServer?.start() else {
            XCTFail("Local WebSocket server failed to start")
            return
        }

        let webSocketClient = WebSocketClient(url: endpoint)
        await verifyConnected(webSocketClient, autoRetryOnConnectionFailure: true)

        let disconnectExpectation = expectation(description: "Client should detect disconnect")
        let reconnectExpectation = expectation(description: "Client should reconnect after server close")

        await webSocketClient.publisher.sink { event in
            switch event {
            case .disconnected:
                disconnectExpectation.fulfill()
            case .connected:
                reconnectExpectation.fulfill()
            default:
                break
            }
        }
        .store(in: &cancellables)

        // Simulate server forcibly closing the connection (like OS defunct)
        localWebSocketServer?.sendTransientFailureToConnections()

        await fulfillment(
            of: [disconnectExpectation, reconnectExpectation],
            timeout: 10,
            enforceOrder: true
        )
    }

    /// Verifies that when the network goes offline and back online (simulating
    /// the app returning from background where the socket was defuncted), the
    /// WebSocket client properly tears down the stale connection and creates
    /// a new one.
    ///
    /// This is the core recovery path for GH-4220: after process suspension
    /// defuncts the TCP flow, the network monitor detects the path change and
    /// the client must recycle the connection.
    ///
    /// - Given:
    ///    - A WebSocketClient connected via MockNetworkMonitor with
    ///      autoConnectOnNetworkStatusChange enabled.
    /// - When:
    ///    - Network goes offline (simulating socket defunct detection).
    ///    - Network comes back online (simulating foreground return).
    /// - Then:
    ///    - Client emits `.disconnected` when going offline.
    ///    - Client emits `.connected` when coming back online.
    func testWebSocketClient_whenNetworkDropsAndRecovers_shouldReconnect() async throws {
        var cancellables = Set<AnyCancellable>()
        guard let endpoint = try localWebSocketServer?.start() else {
            XCTFail("Local WebSocket server failed to start")
            return
        }

        let mockNetworkMonitor = MockNetworkMonitor()
        let webSocketClient = WebSocketClient(url: endpoint, networkMonitor: mockNetworkMonitor)
        await verifyConnected(webSocketClient, autoConnectOnNetworkStatusChange: true)

        let disconnectExpectation = expectation(description: "Network drop triggers disconnect")
        let reconnectExpectation = expectation(description: "Network recovery triggers reconnect")

        await webSocketClient.publisher.sink { event in
            switch event {
            case .disconnected:
                disconnectExpectation.fulfill()
            case .connected:
                reconnectExpectation.fulfill()
            default:
                break
            }
        }
        .store(in: &cancellables)

        // Simulate network going offline (as happens when iOS defuncts sockets)
        await mockNetworkMonitor.updateState(.offline)
        await fulfillment(of: [disconnectExpectation], timeout: 5)

        // Simulate network coming back online (app returns to foreground)
        await mockNetworkMonitor.updateState(.online)
        await fulfillment(of: [reconnectExpectation], timeout: 5)
    }

    /// Regression test for https://github.com/aws-amplify/amplify-swift/issues/4220.
    /// Verifies that an (.online, .online) path change during initial connection
    /// does NOT recycle the connection. On iOS 26, NWPathMonitor fires path
    /// updates aggressively during the WebSocket TCP/TLS handshake. Without
    /// the fix, this triggers the PR #3976 recycle logic which kills the
    /// in-progress handshake, creating an infinite recycle loop.
    ///
    /// - Given:
    ///    - A WebSocketClient connecting via MockNetworkMonitor with
    ///      autoConnectOnNetworkStatusChange enabled.
    ///    - The scan is seeded at (.online, .online) so one .online emission
    ///      produces the (.online, .online) tuple.
    /// - When:
    ///    - .online is emitted immediately after connect() is called, before
    ///      the WebSocket handshake completes.
    /// - Then:
    ///    - The client does NOT emit a `.disconnected` event (no recycle).
    ///    - The client successfully connects (`.connected` event).
    func testWebSocketClient_whenOnlineOnlineFiresDuringInitialConnect_shouldNotRecycle() async throws {
        var cancellables = Set<AnyCancellable>()
        guard let endpoint = try localWebSocketServer?.start() else {
            XCTFail("Local WebSocket server failed to start")
            return
        }

        let mockNetworkMonitor = MockNetworkMonitor()
        let webSocketClient = WebSocketClient(url: endpoint, networkMonitor: mockNetworkMonitor)

        let connectedExpectation = expectation(description: "WebSocket should connect successfully")
        let noDisconnect = expectation(description: "Should NOT receive disconnect during initial connect")
        noDisconnect.isInverted = true

        await webSocketClient.publisher.sink { event in
            switch event {
            case .connected:
                connectedExpectation.fulfill()
            case .disconnected:
                noDisconnect.fulfill()
            default:
                break
            }
        }.store(in: &cancellables)

        // Start connecting — autoConnect is now true
        await webSocketClient.connect(
            autoConnectOnNetworkStatusChange: true,
            autoRetryOnConnectionFailure: false
        )

        // Fire (.online, .online) immediately — before handshake completes.
        // Without the fix, this triggers recycle and kills the connection.
        await mockNetworkMonitor.updateState(.online)

        await fulfillment(of: [connectedExpectation], timeout: 5)
        // Verify no disconnect happened (inverted expectation waits 2s)
        await fulfillment(of: [noDisconnect], timeout: 2)
    }

    /// Regression test for https://github.com/aws-amplify/amplify-swift/issues/4220.
    /// Verifies that an (.online, .offline) transition during initial connection
    /// does NOT tear down the in-progress handshake. On iOS 26, NWPathMonitor
    /// can briefly report unsatisfied during a path transition even though the
    /// network is actually available.
    ///
    /// - Given:
    ///    - A WebSocketClient connecting via MockNetworkMonitor with
    ///      autoConnectOnNetworkStatusChange enabled.
    /// - When:
    ///    - .offline is emitted immediately after connect(), before the
    ///      WebSocket handshake completes.
    /// - Then:
    ///    - The client does NOT emit a `.disconnected` event.
    ///    - The client successfully connects.
    func testWebSocketClient_whenOfflineFiresDuringInitialConnect_shouldNotTearDown() async throws {
        var cancellables = Set<AnyCancellable>()
        guard let endpoint = try localWebSocketServer?.start() else {
            XCTFail("Local WebSocket server failed to start")
            return
        }

        let mockNetworkMonitor = MockNetworkMonitor()
        let webSocketClient = WebSocketClient(url: endpoint, networkMonitor: mockNetworkMonitor)

        let connectedExpectation = expectation(description: "WebSocket should connect successfully")
        let noDisconnect = expectation(description: "Should NOT receive disconnect during initial connect")
        noDisconnect.isInverted = true

        await webSocketClient.publisher.sink { event in
            switch event {
            case .connected:
                connectedExpectation.fulfill()
            case .disconnected:
                noDisconnect.fulfill()
            default:
                break
            }
        }.store(in: &cancellables)

        await webSocketClient.connect(
            autoConnectOnNetworkStatusChange: true,
            autoRetryOnConnectionFailure: false
        )

        // Fire (.online, .offline) immediately — before handshake completes.
        // Without the fix, this cancels the in-progress connection.
        await mockNetworkMonitor.updateState(.offline)

        await fulfillment(of: [connectedExpectation], timeout: 5)
        await fulfillment(of: [noDisconnect], timeout: 2)
    }

    /// Regression test for https://github.com/aws-amplify/amplify-swift/issues/4220.
    /// Verifies that multiple rapid (.online, .online) emissions during initial
    /// connection do not prevent the client from ever connecting. This is the
    /// exact scenario from the customer's logs where NWPathMonitor fires
    /// repeatedly during the handshake window.
    ///
    /// - Given:
    ///    - A WebSocketClient connecting via MockNetworkMonitor.
    /// - When:
    ///    - Multiple .online emissions fire in rapid succession during the
    ///      initial connection handshake.
    /// - Then:
    ///    - The client eventually connects successfully.
    func testWebSocketClient_whenMultipleOnlineOnlineDuringInitialConnect_shouldStillConnect() async throws {
        var cancellables = Set<AnyCancellable>()
        guard let endpoint = try localWebSocketServer?.start() else {
            XCTFail("Local WebSocket server failed to start")
            return
        }

        let mockNetworkMonitor = MockNetworkMonitor()
        let webSocketClient = WebSocketClient(url: endpoint, networkMonitor: mockNetworkMonitor)

        let connectedExpectation = expectation(description: "WebSocket should eventually connect")

        await webSocketClient.publisher.sink { event in
            if case .connected = event {
                connectedExpectation.fulfill()
            }
        }.store(in: &cancellables)

        await webSocketClient.connect(
            autoConnectOnNetworkStatusChange: true,
            autoRetryOnConnectionFailure: true
        )

        // Rapid-fire .online emissions — each produces (.online, .online).
        // Without the fix, each one recycles the connection, preventing
        // the handshake from ever completing.
        await mockNetworkMonitor.updateState(.online)
        await mockNetworkMonitor.updateState(.online)
        await mockNetworkMonitor.updateState(.online)
        await mockNetworkMonitor.updateState(.online)
        await mockNetworkMonitor.updateState(.online)

        await fulfillment(of: [connectedExpectation], timeout: 5)
    }

    /// Verifies that after a successful connection, (.online, .online) still
    /// triggers the recycle (preserving the PR #3976 fix). The
    /// hasSuccessfullyConnected guard must only suppress recycling during
    /// initial handshake, not after the connection is established.
    ///
    /// - Given:
    ///    - A WebSocketClient that has successfully connected.
    /// - When:
    ///    - .online is emitted (producing (.online, .online) through the scan).
    /// - Then:
    ///    - The client recycles: emits `.disconnected` then `.connected`.
    func testWebSocketClient_afterSuccessfulConnect_onlineOnlineShouldStillRecycle() async throws {
        var cancellables = Set<AnyCancellable>()
        guard let endpoint = try localWebSocketServer?.start() else {
            XCTFail("Local WebSocket server failed to start")
            return
        }

        let mockNetworkMonitor = MockNetworkMonitor()
        let webSocketClient = WebSocketClient(url: endpoint, networkMonitor: mockNetworkMonitor)
        await verifyConnected(webSocketClient, autoConnectOnNetworkStatusChange: true)

        let disconnectExpectation = expectation(description: "Should disconnect on path recycle")
        let reconnectExpectation = expectation(description: "Should reconnect after path recycle")

        await webSocketClient.publisher.sink { event in
            switch event {
            case .disconnected:
                disconnectExpectation.fulfill()
            case .connected:
                reconnectExpectation.fulfill()
            default:
                break
            }
        }.store(in: &cancellables)

        // After successful connection, (.online, .online) should still recycle
        await mockNetworkMonitor.updateState(.online)

        await fulfillment(
            of: [disconnectExpectation, reconnectExpectation],
            timeout: 5,
            enforceOrder: true
        )
    }

    // MARK: - Helpers

    private func verifyConnected(
        _ webSocketClient: WebSocketClient,
        autoConnectOnNetworkStatusChange: Bool = false,
        autoRetryOnConnectionFailure: Bool = false
    ) async {
        var cancellables = Set<AnyCancellable>()
        let connectedExpectation = expectation(description: "WebSocket did connect")
        await webSocketClient.publisher.sink { event in
            switch event {
            case .connected:
                connectedExpectation.fulfill()
            default:
                XCTFail("No other type of event should be received during initial connect")
            }
        }.store(in: &cancellables)

        await webSocketClient.connect(
            autoConnectOnNetworkStatusChange: autoConnectOnNetworkStatusChange,
            autoRetryOnConnectionFailure: autoRetryOnConnectionFailure
        )
        await fulfillment(of: [connectedExpectation], timeout: 5)
    }
}

// MARK: - Mock Network Monitor

private class MockNetworkMonitor: WebSocketNetworkMonitorProtocol {
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
