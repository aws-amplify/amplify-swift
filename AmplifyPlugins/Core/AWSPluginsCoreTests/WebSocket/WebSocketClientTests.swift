//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import XCTest
import Combine
@testable @_spi(WebSocket) import AWSPluginsCore

fileprivate let timeout: TimeInterval = 5

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


fileprivate class MockNetworkMonitor: WebSocketNetworkMonitorProtocol {
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
            return UInt8(self[startIndex..<endIndex], radix: 16)
        }
    }
}
