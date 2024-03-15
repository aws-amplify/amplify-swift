//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import XCTest
import Combine
import Amplify
@_spi(WebSocket) import AWSPluginsCore
@testable import AWSAPIPlugin

class AppSyncRealTimeClientTests: XCTestCase {

    func testSendRequestWithTimeout_withNoResponse_failedWithTimeOutError() async {
        let timeout = 1.0
        let mockWebSocketClient = MockWebSocketClient()
        let mockAppSyncRequestInterceptor = MockAppSyncRequestInterceptor()
        let appSyncClient = AppSyncRealTimeClient(
            endpoint: URL(string: "https://example.com")!,
            requestInterceptor: mockAppSyncRequestInterceptor,
            webSocketClient: mockWebSocketClient
        )

        let requestFailedExpectation = expectation(description: "Request should be failed with error")
        Task {
            do {
                try await appSyncClient.sendRequest(.connectionInit, timeout: timeout)
                XCTFail("The operation should be failed with time out")
            } catch {
                let requestError = error as! AppSyncRealTimeRequest.Error
                XCTAssert(requestError == .timeout)
                requestFailedExpectation.fulfill()
            }
        }
        await fulfillment(of: [requestFailedExpectation], timeout: timeout + 1)
    }

    func testSendRequestWithTimeout_withCorrectResponse_succeed() async {
        let timeout = 1.0
        let mockWebSocketClient = MockWebSocketClient()
        let mockAppSyncRequestInterceptor = MockAppSyncRequestInterceptor()
        let appSyncClient = AppSyncRealTimeClient(
            endpoint: URL(string: "https://example.com")!,
            requestInterceptor: mockAppSyncRequestInterceptor,
            webSocketClient: mockWebSocketClient
        )

        let finishExpectation = expectation(description: "Request finished successfully")
        Task {
            do {
                try await appSyncClient.sendRequest(.connectionInit, timeout: timeout)
                finishExpectation.fulfill()
            } catch {
                XCTFail("Operation shouldn't fail with error \(error)")
            }
        }
        Task {
            try await Task.sleep(nanoseconds: 80 * 1000)
            await appSyncClient.subject.send(.init(id: nil, payload: nil, type: .connectionAck))
        }
        await fulfillment(of: [finishExpectation], timeout: timeout + 1)
    }

    func testSendRequestWithTimeout_withErrorResponse_transformLimitExceededError() async {
        let timeout = 1.0
        let mockWebSocketClient = MockWebSocketClient()
        let mockAppSyncRequestInterceptor = MockAppSyncRequestInterceptor()
        let appSyncClient = AppSyncRealTimeClient(
            endpoint: URL(string: "https://example.com")!,
            requestInterceptor: mockAppSyncRequestInterceptor,
            webSocketClient: mockWebSocketClient
        )

        let limitExceededErrorExpectation = expectation(description: "Request should be failed with limitExceeded error")
        let id = UUID().uuidString
        Task {
            do {
                try await appSyncClient.sendRequest(
                    .start(.init(id: id, data: "", auth: nil)),
                    timeout: timeout
                )
                XCTFail("Operation should be failed")
            } catch {
                let requestError = error as! AppSyncRealTimeRequest.Error
                XCTAssertEqual(requestError, .limitExceeded)
                limitExceededErrorExpectation.fulfill()
            }
        }
        Task {
            try await Task.sleep(nanoseconds: 80 * 1000)
            await appSyncClient.subject.send(.init(
                id: id,
                payload: .object([
                    "errors": .array([
                        .object([
                            "errorType": "LimitExceededError"
                        ])
                    ])
                ]),
                type: .error
            ))
        }
        await fulfillment(of: [limitExceededErrorExpectation], timeout: timeout + 1)
    }

    func testSendRequestWithTimeout_withErrorResponse_transformMaxSubscriptionsReachedError() async {
        let timeout = 1.0
        let mockWebSocketClient = MockWebSocketClient()
        let mockAppSyncRequestInterceptor = MockAppSyncRequestInterceptor()
        let appSyncClient = AppSyncRealTimeClient(
            endpoint: URL(string: "https://example.com")!,
            requestInterceptor: mockAppSyncRequestInterceptor,
            webSocketClient: mockWebSocketClient
        )
        let maxSubscriptionsReachedExpectation =
            expectation(description: "Request should be failed with maxSubscriptionsReached error")
        let id = UUID().uuidString
        Task {
            do {
                try await appSyncClient.sendRequest(
                    .start(.init(id: id, data: "", auth: nil)),
                    timeout: timeout
                )
                XCTFail("Operation should be failed")
            } catch {
                let requestError = error as! AppSyncRealTimeRequest.Error
                XCTAssertEqual(requestError, .maxSubscriptionsReached)
                maxSubscriptionsReachedExpectation.fulfill()
            }
        }

        Task {
            try await Task.sleep(nanoseconds: 80 * 1000)
            await appSyncClient.subject.send(.init(
                id: id,
                payload: .object([
                    "errors": .array([
                        .object([
                            "errorType": "MaxSubscriptionsReachedError"
                        ])
                    ])
                ]),
                type: .error
            ))
        }
        await fulfillment(of: [
            maxSubscriptionsReachedExpectation
        ], timeout: timeout + 1)
    }

    func testSendRequestWithTimeout_withErrorResponse_triggerErrorForUnknow() async {
        let timeout = 1.0
        let mockWebSocketClient = MockWebSocketClient()
        let mockAppSyncRequestInterceptor = MockAppSyncRequestInterceptor()
        let appSyncClient = AppSyncRealTimeClient(
            endpoint: URL(string: "https://example.com")!,
            requestInterceptor: mockAppSyncRequestInterceptor,
            webSocketClient: mockWebSocketClient
        )
        let triggerUnknownErrorExpectation =
            expectation(description: "Request should trigger unknown errors")
        let id = UUID().uuidString
        Task {
            do {
                try await appSyncClient.sendRequest(
                    .start(.init(id: id, data: "", auth: nil)),
                    timeout: timeout
                )
            } catch {
                let requestError = error as! AppSyncRealTimeRequest.Error
                guard case .unknown = requestError else {
                    XCTFail("The error should in unknown case")
                    return
                }
                triggerUnknownErrorExpectation.fulfill()
            }
        }

        Task {
            try await Task.sleep(nanoseconds: 80 * 1000)
            await appSyncClient.subject.send(.init(
                id: id,
                payload: .object([
                    "errors": .array([
                        .object([
                            "errorType": "OtherError"
                        ])
                    ])
                ]),
                type: .error
            ))
        }
        await fulfillment(of: [
            triggerUnknownErrorExpectation
        ], timeout: timeout + 1)
    }

    func testConnect_AppSyncRealTimeClient_triggersWebSocketConnection() async throws {
        var cancellables = Set<AnyCancellable>()
        let mockWebSocketClient = MockWebSocketClient()
        let mockAppSyncRequestInterceptor = MockAppSyncRequestInterceptor()
        let appSyncClient = AppSyncRealTimeClient(
            endpoint: URL(string: "https://example.com")!,
            requestInterceptor: mockAppSyncRequestInterceptor,
            webSocketClient: mockWebSocketClient
        )

        let connectTriggered = expectation(description: "webSocket connect API should be invoked")
        await mockWebSocketClient.setStateToConnected()
        await mockWebSocketClient.actionSubject
            .sink { action in
                if case let .connect(param1, param2) = action {
                    XCTAssertEqual(param1, true)
                    XCTAssertEqual(param2, true)
                    connectTriggered.fulfill()
                } else if case let .write(message) = action {
                    XCTAssertEqual(message, """
                    {"type":"connection_init"}
                    """)
                } else {
                    XCTFail("No other actions should be invoked")
                }
            }
            .store(in: &cancellables)
        Task { try await appSyncClient.connect() }
        Task {
            try await Task.sleep(nanoseconds: 50 * 1_000_000)
            await mockWebSocketClient.subject.send(.connected)
            try await Task.sleep(nanoseconds: 50 * 1_000_000)
            await mockWebSocketClient.subject.send(.string("""
                {"type": "connection_ack", "payload": { "connectionTimeoutMs": 300000 }}
            """))
        }

        await fulfillment(of: [connectTriggered], timeout: 1)
    }

    func testDisconnect_AppSyncRealTimeClient_triggersWebSocketDisconnect() async throws {
        var cancellables = Set<AnyCancellable>()
        let mockWebSocketClient = MockWebSocketClient()
        let mockAppSyncRequestInterceptor = MockAppSyncRequestInterceptor()
        let appSyncClient = AppSyncRealTimeClient(
            endpoint: URL(string: "https://example.com")!,
            requestInterceptor: mockAppSyncRequestInterceptor,
            webSocketClient: mockWebSocketClient
        )

        let disconnectTriggered = expectation(description: "webSocket disconnect API should be invoked")
        await mockWebSocketClient.setStateToConnected()
        await mockWebSocketClient.actionSubject
            .sink { action in
                if case .disconnect = action {
                    disconnectTriggered.fulfill()
                } else {
                    XCTFail("No other actions should be invoked")
                }
            }
            .store(in: &cancellables)
        Task { await appSyncClient.disconnect() }

        await fulfillment(of: [disconnectTriggered], timeout: 1)
    }

    func testUnsubscribe_withAppSyncRealTimeClientAlreadyConnected_triggersWebSocketStopEvent() async throws {
        var cancellables = Set<AnyCancellable>()
        let mockWebSocketClient = MockWebSocketClient()
        let mockAppSyncRequestInterceptor = MockAppSyncRequestInterceptor()
        let appSyncClient = AppSyncRealTimeClient(
            endpoint: URL(string: "https://example.com")!,
            requestInterceptor: mockAppSyncRequestInterceptor,
            webSocketClient: mockWebSocketClient
        )
        let id = UUID().uuidString

        let connectTriggered = expectation(description: "connect websocket")
        let startTriggered = expectation(description: "webSocket start subscription")
        let stopTriggered = expectation(description: "webSocket writing stop event to connection")

        await mockWebSocketClient.setStateToConnected()

        await mockWebSocketClient.actionSubject
            .sink { action in
                switch action {
                case .connect:
                    Task  {
                        await mockWebSocketClient.subject.send(.connected)
                    }

                case .write(let message):
                    guard let response = try? JSONDecoder().decode(
                        JSONValue.self,
                        from: message.data(using: .utf8)!
                    ) else {
                        XCTFail("Response should be able to decode to AppSyncRealTimeResponse")
                        return
                    }

                    switch response.type?.stringValue {
                    case .some("stop"):
                        XCTAssertEqual(response.id?.stringValue, id)
                        stopTriggered.fulfill()

                    case .some("start"):
                        XCTAssertEqual(response.id?.stringValue, id)
                        startTriggered.fulfill()
                        Task {
                            try await Task.sleep(nanoseconds: 80 * 1_000_000)
                            await mockWebSocketClient.subject.send(.string("""
                                {"type": "start_ack", "id": "\(id)"}
                            """))
                            try await Task.sleep(nanoseconds: 80 * 1_000_000)
                            try await appSyncClient.unsubscribe(id: id)
                        }

                    case .some("connection_init"):
                        connectTriggered.fulfill()
                        Task {
                            try await Task.sleep(nanoseconds: 80 * 1_000_000)
                            await mockWebSocketClient.subject.send(.string("""
                                {"type": "connection_ack", "payload": { "connectionTimeoutMs": 300000 }}
                            """))
                        }
                    default:
                        XCTFail("No other message should be written")
                    }

                default:
                    XCTFail("No other actions should be invoked")
                }
            }
            .store(in: &cancellables)

        Task {
            _ = try await appSyncClient.subscribe(id: id, query: "")
        }

        await fulfillment(
            of: [connectTriggered, startTriggered, stopTriggered],
            timeout: 2,
            enforceOrder: true
        )
    }

    func testUnsubscribe_withAppSyncRealTimeClientNotConnected_doesNotTriggerWebSocketStopEvent() async throws {
        var cancellables = Set<AnyCancellable>()
        let mockWebSocketClient = MockWebSocketClient()
        let mockAppSyncRequestInterceptor = MockAppSyncRequestInterceptor()
        let appSyncClient = AppSyncRealTimeClient(
            endpoint: URL(string: "https://example.com")!,
            requestInterceptor: mockAppSyncRequestInterceptor,
            webSocketClient: mockWebSocketClient
        )
        let id = UUID().uuidString

        let stopTriggered = expectation(description: "webSocket writing stop event to connection")
        stopTriggered.isInverted = true
        await mockWebSocketClient.actionSubject
            .sink { action in
                if case .write = action {
                    stopTriggered.fulfill()
                } else {
                    XCTFail("No other actions should be invoked")
                }
            }
            .store(in: &cancellables)
        Task { try await appSyncClient.unsubscribe(id: id) }

        await fulfillment(of: [stopTriggered], timeout: 1)
    }

    func testSubscribe_withAppSyncRealTimeClientAlreadyConnected_triggersWebSocketStartEvent() async throws {
        var cancellables = Set<AnyCancellable>()
        let mockWebSocketClient = MockWebSocketClient()
        let mockAppSyncRequestInterceptor = MockAppSyncRequestInterceptor()
        let appSyncClient = AppSyncRealTimeClient(
            endpoint: URL(string: "https://example.com")!,
            requestInterceptor: mockAppSyncRequestInterceptor,
            webSocketClient: mockWebSocketClient
        )
        let id = UUID().uuidString
        let query = UUID().uuidString

        let startTriggered = expectation(description: "webSocket writing start event to connection")

        await mockWebSocketClient.setStateToConnected()
        Task {
            try await Task.sleep(nanoseconds: 80 * 1_000_000)
            await mockWebSocketClient.subject.send(.connected)
            try await Task.sleep(nanoseconds: 80 * 1_000_000)
            await mockWebSocketClient.subject.send(.string("""
                {"type": "connection_ack", "payload": { "connectionTimeoutMs": 300000 }}
            """))
        }
        try await appSyncClient.connect()
        await mockWebSocketClient.actionSubject
            .sink { action in
                switch action {
                case .write(let message):
                    guard let response = try? JSONDecoder().decode(
                        JSONValue.self,
                        from: message.data(using: .utf8)!
                    ) else {
                        XCTFail("Response should be able to decode to AppSyncRealTimeResponse")
                        return
                    }

                    if response.type?.stringValue == "start" {
                        XCTAssertEqual(response.id?.stringValue, id)
                        XCTAssertEqual(response.payload?.asObject?["data"]?.stringValue, query)
                        startTriggered.fulfill()
                    } else {
                        XCTFail("No other message should be written")
                    }

                default:
                    XCTFail("No other actions should be invoked")
                }
            }
            .store(in: &cancellables)


        Task { try await appSyncClient.subscribe(id: id, query: query) }

        await fulfillment(of: [startTriggered], timeout: 2)
    }

    func testSubscribe_withAppSyncRealTimeClientNotConnected_triggersWebSocketStartEvent() async throws {
        var cancellables = Set<AnyCancellable>()
        let mockWebSocketClient = MockWebSocketClient()
        let mockAppSyncRequestInterceptor = MockAppSyncRequestInterceptor()
        let appSyncClient = AppSyncRealTimeClient(
            endpoint: URL(string: "https://example.com")!,
            requestInterceptor: mockAppSyncRequestInterceptor,
            webSocketClient: mockWebSocketClient
        )
        let id = UUID().uuidString
        let query = UUID().uuidString

        let connectTriggered = expectation(description: "webSocket connection is invoked")
        let sendingConnectInit = expectation(description: "Sending connection_init message")
        let startTriggered = expectation(description: "webSocket writing start event to connection")
        await mockWebSocketClient.actionSubject
            .sink { action in
                switch action {
                case .connect:
                    connectTriggered.fulfill()
                case .write(let message):
                    guard let response = try? JSONDecoder().decode(
                        JSONValue.self,
                        from: message.data(using: .utf8)!
                    ) else {
                        XCTFail("Response should be able to decode to AppSyncRealTimeResponse")
                        return
                    }

                    if response.type?.stringValue == "connection_init" {
                        sendingConnectInit.fulfill()
                    } else if response.type?.stringValue == "start" {
                        XCTAssertEqual(response.id?.stringValue, id)
                        XCTAssertEqual(response.payload?.asObject?["data"]?.stringValue, query)
                        startTriggered.fulfill()
                    } else {
                        XCTFail("No other message should be written")
                    }

                default:
                    XCTFail("No other actions should be invoked")
                }
            }
            .store(in: &cancellables)
        Task { try await appSyncClient.subscribe(id: id, query: query) }
        Task {
            try await Task.sleep(nanoseconds: 50 * 1_000_000)
            await mockWebSocketClient.setStateToConnected()
            try await Task.sleep(nanoseconds: 50 * 1_000_000)
            await mockWebSocketClient.subject.send(.string("""
                {"type": "connection_ack", "payload": { "connectionTimeoutMs": 300000 }}
            """))
        }

        await fulfillment(of: [
            connectTriggered,
            sendingConnectInit,
            startTriggered
        ], timeout: 3, enforceOrder: true)
    }
}
