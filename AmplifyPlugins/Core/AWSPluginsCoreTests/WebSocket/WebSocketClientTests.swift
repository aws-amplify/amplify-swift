//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@preconcurrency import Combine
import XCTest
@testable @_spi(WebSocket) import AWSPluginsCore

private let timeout: TimeInterval = 5

class WebSocketClientTests: XCTestCase {
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

        await webSocketClient.publisher
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
        await webSocketClient.publisher.sink { event in
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
        await webSocketClient.publisher.sink { event in
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
        await webSocketClient.publisher.sink { event in
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

    // Regression test for https://github.com/aws-amplify/amplify-swift/issues/3976
    //
    // When iOS recycles the underlying TCP route during a scenePhase transition,
    // NWPathMonitor reports path.status == .satisfied both before and after the
    // recycle. AmplifyNetworkMonitor maps .satisfied to .online, so the publisher
    // emits (.online, .online). The existing URLSessionWebSocketTask is now dead
    // on the stale route, but WebSocketClient.onNetworkStateChange hits
    // `default: break` and never cancels/recreates the connection. Every cached
    // subscriber then reuses the zombie client.
    //
    // This test drives the mock through an (.online, .online) transition while
    // the client is connected with autoConnectOnNetworkStatusChange = true, and
    // expects the client to tear down and re-establish the connection.
    // It should FAIL against the current implementation.
    func testWebSocketClient_whenNetworkPathChangesWhileOnline_shouldRecycleConnection() async throws {
        var cancellables = Set<AnyCancellable>()
        guard let endpoint = try localWebSocketServer?.start() else {
            XCTFail("Local WebSocket server failed to start")
            return
        }

        let mockNetworkMonitor = MockNetworkMonitor()
        let webSocketClient = WebSocketClient(url: endpoint, networkMonitor: mockNetworkMonitor)
        await verifyConnected(webSocketClient, autoConnectOnNetworkStatusChange: true)

        let disconnectExpectation = expectation(description: "Path change should force a disconnect")
        let reconnectExpectation = expectation(description: "Path change should trigger a reconnect")

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

        // Simulate NWPathMonitor firing .satisfied again after a path recycle.
        // The scan seed in MockNetworkMonitor is (.online, .online), so sending
        // .online produces exactly the (.online, .online) tuple from issue #3976.
        await mockNetworkMonitor.updateState(.online)

        await fulfillment(
            of: [disconnectExpectation, reconnectExpectation],
            timeout: timeout,
            enforceOrder: true
        )
    }

    // Integration-level companion to the unit test above. Uses a real
    // AmplifyNetworkMonitor (backed by NWPathMonitor) instead of a mock, so
    // the scan seed matches production exactly: (.none, .none) → (.none, .online)
    // → (.online, .online). Drives state through the class's public
    // `updateState` seam — the same seam WebSocketClient itself uses at
    // WebSocketClient.swift when it reports connectionLost.
    //
    // This proves the bug is not an artifact of MockNetworkMonitor's scan seed:
    // even with the real AmplifyNetworkMonitor, a second .online emission
    // produces (.online, .online) and the client fails to recycle.
    func testWebSocketClient_withRealNetworkMonitor_whenPathChangesWhileOnline_shouldRecycle() async throws {
        var cancellables = Set<AnyCancellable>()
        guard let endpoint = try localWebSocketServer?.start() else {
            XCTFail("Local WebSocket server failed to start")
            return
        }

        let realNetworkMonitor = AmplifyNetworkMonitor()
        let webSocketClient = WebSocketClient(url: endpoint, networkMonitor: realNetworkMonitor)

        // Prime the scan so (previous, next) reaches (.online, .online) on the
        // second emission. This mirrors production: first NWPathMonitor fire
        // yields (.none, .online), second yields (.online, .online).
        await realNetworkMonitor.updateState(.online)

        await verifyConnected(webSocketClient, autoConnectOnNetworkStatusChange: true)

        let disconnectExpectation = expectation(description: "Path change should force a disconnect")
        let reconnectExpectation = expectation(description: "Path change should trigger a reconnect")

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

        // Second .online emission → scan produces (.online, .online) —
        // the exact tuple from issue #3976.
        await realNetworkMonitor.updateState(.online)

        await fulfillment(
            of: [disconnectExpectation, reconnectExpectation],
            timeout: timeout,
            enforceOrder: true
        )
    }

    // Monitor-level test: proves that the real AmplifyNetworkMonitor.publisher
    // emits (.online, .online) on two consecutive .online updateState() calls.
    // This is the signal boundary feeding WebSocketClient.onNetworkStateChange.
    //
    // This test documents the shape of the bug input: the monitor faithfully
    // reports "still online" twice in a row. It's WebSocketClient's switch
    // statement that drops it, but we need to know the monitor will actually
    // emit this tuple when NWPathMonitor fires .satisfied again during a path
    // recycle (which is how production AmplifyNetworkMonitor behaves — see
    // AmplifyNetworkMonitor.swift:32-34, where any .satisfied path → .online).
    //
    // This should PASS today regardless of the WebSocketClient fix —
    // it's characterizing the input signal.
    func testAmplifyNetworkMonitor_whenOnlineEmittedTwice_publishesOnlineOnlineTuple() async throws {
        var cancellables = Set<AnyCancellable>()
        let monitor = AmplifyNetworkMonitor()

        let expectOnlineOnline = expectation(description: "publisher emits (.online, .online)")
        expectOnlineOnline.assertForOverFulfill = false

        monitor.publisher.sink { tuple in
            if tuple.0 == .online && tuple.1 == .online {
                expectOnlineOnline.fulfill()
            }
        }
        .store(in: &cancellables)

        // Two consecutive .online emissions must produce an (.online, .online)
        // tuple through the scan — the exact input that triggers issue #3976
        // in WebSocketClient.onNetworkStateChange.
        await monitor.updateState(.online)
        await monitor.updateState(.online)

        await fulfillment(of: [expectOnlineOnline], timeout: timeout)
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

        await webSocketClient.publisher.sink { event in
            switch event {
            case let .disconnected(closeCode, reason):
                XCTAssertEqual(closeCode, .internalServerError)
                XCTAssert(reason == nil || reason!.isEmpty)
                disconnectExpectation.fulfill()
            case .connected:
                reconnectedExpectation.fulfill()
            default:
                XCTFail("No other type of event should be received")
            }
        }
        .store(in: &cancellables)
        localWebSocketServer?.sendTransientFailureToConnections()
        await fulfillment(of: [disconnectExpectation, reconnectedExpectation], timeout: timeout, enforceOrder: true)
    }

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
