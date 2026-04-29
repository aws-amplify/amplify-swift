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

    /// Regression test for https://github.com/aws-amplify/amplify-swift/issues/3976.
    /// When iOS recycles the TCP route during a scenePhase transition,
    /// NWPathMonitor reports .satisfied both before and after, producing
    /// (.online, .online) through AmplifyNetworkMonitor's scan. Before the
    /// fix, WebSocketClient.onNetworkStateChange hit `default: break` and
    /// left the stale URLSessionWebSocketTask in place — a zombie.
    ///
    /// - Given:
    ///    - A WebSocketClient connected via a MockNetworkMonitor whose scan
    ///      seed is (.online, .online), so one updateState(.online) produces
    ///      the bug tuple deterministically.
    ///    - autoConnectOnNetworkStatusChange is true.
    /// - When:
    ///    - The mock emits .online, producing an (.online, .online) tuple.
    /// - Then:
    ///    - WebSocketClient sends a `.disconnected` event (stale task torn down).
    ///    - WebSocketClient emits a fresh `.connected` event (new connection).
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

    /// Integration-level companion to the mock-based test above. Proves the
    /// fix works with the real AmplifyNetworkMonitor's scan seed (.none, .none)
    /// — i.e., the bug is not an artifact of MockNetworkMonitor's seeding.
    /// Drives state through `updateState`, the same seam WebSocketClient
    /// itself uses when reporting connectionLost. Tolerates spontaneous
    /// NWPathMonitor firings on watchOS by counting `.connected` events
    /// instead of using the strict verifyConnected helper.
    ///
    /// - Given:
    ///    - A WebSocketClient wired to a real AmplifyNetworkMonitor with its
    ///      natural scan seed (.none, .none).
    ///    - A publisher sink attached before connect() so no events are lost
    ///      while the client's internal sink is still attaching.
    ///    - autoConnectOnNetworkStatusChange is true.
    /// - When:
    ///    - The monitor's updateState(.online) is called twice, producing
    ///      (.none, .online) then (.online, .online) through the scan.
    /// - Then:
    ///    - A second `.connected` event is observed (initial connect + recycle
    ///      reconnect), confirming the WebSocket was torn down and rebuilt.
    func testWebSocketClient_withRealNetworkMonitor_whenPathChangesWhileOnline_shouldRecycle() async throws {
        var cancellables = Set<AnyCancellable>()
        guard let endpoint = try localWebSocketServer?.start() else {
            XCTFail("Local WebSocket server failed to start")
            return
        }

        let realNetworkMonitor = AmplifyNetworkMonitor()
        let webSocketClient = WebSocketClient(url: endpoint, networkMonitor: realNetworkMonitor)

        let initialConnect = expectation(description: "Initial WebSocket connect")
        let reconnectAfterPathChange = expectation(description: "Reconnect after (.online, .online)")
        let connectedCounter = AtomicInt()

        await webSocketClient.publisher.sink { event in
            if case .connected = event {
                let count = connectedCounter.increment()
                if count == 1 {
                    initialConnect.fulfill()
                } else if count == 2 {
                    reconnectAfterPathChange.fulfill()
                }
            }
            // Tolerate .disconnected / .error / .string / .data events,
            // which can arrive from NWPathMonitor-driven recycling or from
            // LocalWebSocketServer teardown.
        }
        .store(in: &cancellables)

        await webSocketClient.connect(
            autoConnectOnNetworkStatusChange: true,
            autoRetryOnConnectionFailure: false
        )
        await fulfillment(of: [initialConnect], timeout: timeout)

        // WebSocketClient.init spawns its sink via Task { startNetworkMonitor() };
        // by the time initialConnect fulfils, the sink is attached.
        // Prime the scan so (previous, next) reaches (.online, .online) on
        // the second updateState — first reaches (.none, .online).
        await realNetworkMonitor.updateState(.online)

        // Second .online emission → scan produces (.online, .online) —
        // the exact tuple from issue #3976. With the fix, this triggers a
        // recycle that yields a second `.connected`.
        await realNetworkMonitor.updateState(.online)

        await fulfillment(of: [reconnectAfterPathChange], timeout: timeout)
    }

    /// Characterizes the input signal that drives issue #3976. Proves that
    /// the real AmplifyNetworkMonitor.publisher emits the (.online, .online)
    /// tuple when two .online states are sent consecutively — which is what
    /// WebSocketClient.onNetworkStateChange receives during a scenePhase-
    /// triggered NWPath recycle. Does not exercise the fix; passes both
    /// before and after.
    ///
    /// - Given:
    ///    - A fresh AmplifyNetworkMonitor instance.
    ///    - A publisher sink that watches for (.online, .online) tuples.
    /// - When:
    ///    - updateState(.online) is called twice consecutively.
    /// - Then:
    ///    - The publisher emits an (.online, .online) tuple via its scan —
    ///      confirming this is the exact signal WebSocketClient must handle.
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


private final class AtomicInt: @unchecked Sendable {
    private var value: Int = 0
    private let lock = NSLock()
    func increment() -> Int {
        lock.lock()
        defer { lock.unlock() }
        value += 1
        return value
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
