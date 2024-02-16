//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import Foundation
import Amplify
import Combine
@_spi(AmplifySwift) import AWSPluginsCore

protocol AppSyncRequestInterceptor {
    func interceptRequest(event: AppSyncRealTimeRequest, url: URL) async -> AppSyncRealTimeRequest
}

protocol AppSyncWebSocketClientProtocol {
    var isConnected: Bool { get async }
    var publisher: AnyPublisher<WebSocketEvent, Never> { get async }

    func connect(
        autoConnectOnNetworkStatusChange: Bool,
        autoRetryOnConnectionFailure: Bool
    ) async

    func disconnect() async

    func write(message: String) async throws
}

extension WebSocketClient: AppSyncWebSocketClientProtocol { }

actor AppSyncRealTimeClient: AppSyncRealTimeClientProtocol {

    static let jsonEncoder = JSONEncoder()
    static let jsonDecoder = JSONDecoder()

    enum State {
        case none
        case connecting
        case connected
        case connectionDropped
        case disconnecting
        case disconnected
    }

    // Internal state for tracking AppSync connection
    private var state: State

    private let endpoint: URL
    private let requestInterceptor: AppSyncRequestInterceptor

    private var webSocketClient: AppSyncWebSocketClientProtocol
    private let subject = PassthroughSubject<AppSyncRealTimeResponse, Never>()
    private var subscriptions = [String: String]()

    private let heartBeats = PassthroughSubject<Void, Never>()

    private var cancellables = Set<AnyCancellable>()
    private var cancellablesBindToConnection = Set<AnyCancellable>()

    var isConnected: Bool {
        self.state == .connected
    }

    init(
        endpoint: URL,
        requestInterceptor: AppSyncRequestInterceptor,
        webSocketClient: AppSyncWebSocketClientProtocol
    ) {
        self.state = .none
        self.endpoint = endpoint
        self.requestInterceptor = requestInterceptor

        self.webSocketClient = webSocketClient

        Task { await self.subscribeToWebSocketEvent() }
    }

    deinit {
        subject.send(completion: .finished)
        Task {
            await self.disconnect()
        }
    }

    func connect() async throws {
        if self.state == .connecting || self.state == .connected {
            log.debug("[AppSyncRealTimeClient] client is already connecting or connected")
            return
        }

        self.state = .connecting
        log.debug("[AppSyncRealTimeClient] client start connecting")

        try await RetryWithJitter.execute { [weak self] in
            guard let self else { return }
            try await Self.sendRequestWithTimeout(
                on: self.subject.eraseToAnyPublisher()
            ) {
                $0.type == .connectionAck
            } requestFactory: { [weak self] in
                await self?.webSocketClient.connect(
                   autoConnectOnNetworkStatusChange: true,
                   autoRetryOnConnectionFailure: true
                )
            }
        }
    }

    func disconnect() async {
        log.debug("[AppSyncRealTimeClient] client start disconnecting")
        self.state = .disconnecting
        self.cancellablesBindToConnection = Set()
        await self.webSocketClient.disconnect()
        self.state = .disconnected
        log.debug("[AppSyncRealTimeClient] client is disconnected")
    }

    func subscribe(id: String, query: String) throws -> AnyPublisher<AppSyncSubscriptionEvent, Never> {
        log.debug("[AppSyncRealTimeClient] Received subscription request id: \(id), query: \(query)")
        if self.isConnected {
            Task {
                try await startSubscription(id: id, query: query).store(in: &cancellablesBindToConnection)
                subscriptions[id] = query
            }
        } else {
            subscriptions[id] = query
            Task { try await connect() }
        }

        return filterAppSyncSubscriptionEvent(with: id)
    }

    func unsubscribe(id: String) async throws {
        defer { subscriptions.removeValue(forKey: id) }
        log.debug("[AppSyncRealTimeClient] unsubscribing: \(id)")

        try await RetryWithJitter.execute { [weak self] in
            guard let self else { return }
            try await Self.sendRequestWithTimeout(
                id: id,
                on: self.subject.eraseToAnyPublisher()
            ) {
                $0.id == id && $0.type == .stopAck
            } requestFactory: { [weak self] in
                try await self?.writeAppSyncEvent(.stop(id))
            }
        }
    }

    private func startSubscription(id: String, query: String) async throws -> AnyCancellable {
        log.debug("[AppSyncRealTimeClient] Starting subscription request \(id), query: \(query)")

        try await RetryWithJitter.execute { [weak self] in
            guard let self else { return }
            try await Self.sendRequestWithTimeout(
                id: id,
                on: self.subject.eraseToAnyPublisher()
            ) {
                $0.id == id && $0.type == .startAck
            } requestFactory: { [weak self] in
                // makeup and inject connecting event to conform GraphQLSubscriptionEvent
                self?.subject.send(.init(id: id, payload: nil, type: .starting))
                try await self?.writeAppSyncEvent(
                    .start(.init(id: id, data: query, auth: nil))
                )
            }
        }

        var isCancelled = false
        return AnyCancellable {
            guard !isCancelled else {
                return
            }

            isCancelled = true
            Task { [weak self] in
                try? await self?.writeAppSyncEvent(.stop(id))
            }
        }
    }

    private func subscribeToWebSocketEvent() async {
        await self.webSocketClient.publisher.sink { [weak self] _ in
            self?.log.debug("[AppSyncRealTimeClient] WebSocketClient terminated")
        } receiveValue: { webSocketEvent in
            Task { [weak self] in
                await self?.onWebSocketEvent(webSocketEvent)
            }
        }
        .store(in: &cancellables)
    }

    private func resumeExistingSubscriptions() {
        log.debug("[AppSyncRealTimeClient] Resuming existing subscriptions")
        for (id, query) in self.subscriptions {
            Task {
                do {
                    try await self.startSubscription(id: id, query: query).store(in: &cancellablesBindToConnection)
                } catch {
                    log.debug("[AppSyncRealTimeClient] Failed to resume existing subscription query: (\(query))")
                }
            }
        }
    }

    nonisolated private func writeAppSyncEvent(_ event: AppSyncRealTimeRequest) async throws {
        guard await self.webSocketClient.isConnected else {
            log.debug("[AppSyncRealTimeClient] Attempting to write to a webSocket haven't been connected.")
            return
        }

        let interceptedEvent = await self.requestInterceptor.interceptRequest(event: event, url: self.endpoint)
        let eventString = try String(data: Self.jsonEncoder.encode(interceptedEvent), encoding: .utf8)!
        log.debug("[AppSyncRealTimeClient] Writing AppSyncEvent \(eventString)")
        try await webSocketClient.write(message: eventString)
    }

    private func initAppSyncConnect() {
        log.debug("[AppSyncRealTimeClient] Sending connectionInit message")
        Task {
            do {
                try await writeAppSyncEvent(.connectionInit)
            } catch {
                log.debug("[AppSyncRealTimeClient] Failed to send connectInit message, error: \(error)")
            }
        }
    }

    private func filterAppSyncSubscriptionEvent(
        with id: String
    ) -> AnyPublisher<AppSyncSubscriptionEvent, Never> {
        subject.filter { $0.id == id }
        .map { response -> AppSyncSubscriptionEvent? in
            switch response.type {
            case .startAck: return .subscribed
            case .stopAck: return .unsubscribed
            case .error:
                return .error(Self.decodeGraphQLErrors(response.payload))
            case .data:
                return response.payload.map { .data($0) }
            case .starting: return .subscribing
            default:
                return nil
            }
        }
        .compactMap { $0 }
        .eraseToAnyPublisher()
    }

    private static func decodeGraphQLErrors(_ data: JSONValue?) -> [Error] {
        do {
            return try GraphQLErrorDecoder.decodeAppSyncErrors(data)
        } catch {
            log.debug("[AppSyncRealTimeClient] Failed to decode errors: \(error)")
            return [error]
        }
    }

}

// MARK: - On WebSocket Events
extension AppSyncRealTimeClient {
    private func onWebSocketEvent(_ event: WebSocketEvent) {
        log.debug("[AppSyncRealTimeClient] Received websocket event \(event)")
        switch event {
        case .connected:
            log.debug("[AppSyncRealTimeClient] WebSocket connected")
            self.initAppSyncConnect()

        case let .disconnected(closeCode, reason): //
            log.debug("[AppSyncRealTimeClient] WebSocket disconnected with closeCode: \(closeCode), reason: \(String(describing: reason))")
            if self.state != .disconnecting || self.state != .disconnected {
                self.state = .connectionDropped
            }
            self.cancellablesBindToConnection = Set()

        case .error(let error):
            // Since we've activated auto-reconnect functionality in WebSocketClient upon connection failure,
            // we only record errors here for debugging purposes.
            log.debug("[AppSyncRealTimeClient] WebSocket error event: \(error)")
        case .string(let string):
            guard let data = string.data(using: .utf8) else {
                log.debug("[AppSyncRealTimeClient] Failed to decode string \(string)")
                return
            }
            guard let response = try? Self.jsonDecoder.decode(AppSyncRealTimeResponse.self, from: data) else {
                log.debug("[AppSyncRealTimeClient] Failed to decode string to AppSync event")
                return
            }
            self.onAppSyncRealTimeResponse(response)

        case .data(let data):
            guard let response = try? Self.jsonDecoder.decode(AppSyncRealTimeResponse.self, from: data) else {
                log.debug("[AppSyncRealTimeClient] Failed to decode data to AppSync event")
                return
            }
            self.onAppSyncRealTimeResponse(response)
        }
    }

}

// MARK: - On AppSyncServer Event
extension AppSyncRealTimeClient {
    // handles connection level response
    // passes request level response to downstream
    private func onAppSyncRealTimeResponse(_ event: AppSyncRealTimeResponse) {
        switch event.type {
        case .connectionAck:
            log.debug("[AppSyncRealTimeClient] AppSync connected: \(String(describing: event.payload))")
            subject.send(event)

            self.resumeExistingSubscriptions()
            self.state = .connected
            self.monitorHeartBeats(event.payload)

        case .keepAlive:
            self.heartBeats.send(())

        default:
            log.debug("[AppSyncRealTimeClient] AppSync received response: \(event)")
            subject.send(event)
        }
    }

    private func monitorHeartBeats(_ connectionAck: JSONValue?) {
        let timeoutMs = connectionAck?.connectionTimeoutMs?.intValue ?? 0
        log.debug("[AppSyncRealTimeClient] Starting heart beat monitor with interval \(timeoutMs) ms")
        heartBeats.eraseToAnyPublisher()
            .debounce(for: .milliseconds(timeoutMs), scheduler: DispatchQueue.global())
            .first()
            .sink(receiveValue: {
                self.log.debug("[AppSyncRealTimeClient] KeepAlive timed out, disconnecting")
                Task { [weak self] in await self?.disconnect() }
            })
            .store(in: &cancellablesBindToConnection)
        // start counting down
        heartBeats.send(())
    }
}

extension AppSyncRealTimeClient {
    private static func recoverableErrorOrValidatedResponse(
        _ response: AppSyncRealTimeResponse,
        id: String?,
        validation: @escaping (AppSyncRealTimeResponse) -> Bool
    ) -> AnyPublisher<AppSyncRealTimeResponse, AppSyncRealTimeRequest.Error> {
        let limitExceededErrorString = "LimitExceededError"
        let maxSubscriptionsReachedErrorString = "MaxSubscriptionsReachedError"
        if validation(response) {
            return Just(response).setFailureType(to: AppSyncRealTimeRequest.Error.self).eraseToAnyPublisher()
        }

        if id != nil && response.id == id,
           response.type == .error,
           let errors = response.payload?.errors?.asArray {

            let errorTypes = errors.map { $0.errorType?.stringValue }.compactMap { $0 }
            if errorTypes.contains(where: { $0.contains(limitExceededErrorString) }) {
                return Fail(
                    outputType: AppSyncRealTimeResponse.self,
                    failure: AppSyncRealTimeRequest.Error.limitExceeded
                ).eraseToAnyPublisher()
            } else if errorTypes.contains(where: { $0.contains(maxSubscriptionsReachedErrorString) }) {
                return Fail(
                    outputType: AppSyncRealTimeResponse.self,
                    failure: AppSyncRealTimeRequest.Error.maxSubscriptionsReached
                ).eraseToAnyPublisher()
            } else {
                return Fail(
                    outputType: AppSyncRealTimeResponse.self,
                    failure: AppSyncRealTimeRequest.Error.unknown
                ).eraseToAnyPublisher()
            }
        }

        return Empty(
            outputType: AppSyncRealTimeResponse.self,
            failureType: AppSyncRealTimeRequest.Error.self
        ).eraseToAnyPublisher()
    }

    /**

     */
    static func sendRequestWithTimeout(
        _ timeout: TimeInterval = 2,
        id: String? = nil,
        on responseStream: AnyPublisher<AppSyncRealTimeResponse, Never>,
        filter validateResponse: @escaping (AppSyncRealTimeResponse) -> Bool,
        requestFactory: @escaping () async throws -> Void
    ) async throws {
        var cancellables = Set<AnyCancellable>()
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Swift.Error>) in
            responseStream
                .setFailureType(to: AppSyncRealTimeRequest.Error.self)
                .flatMap { Self.recoverableErrorOrValidatedResponse($0, id: id, validation: validateResponse) }
                .timeout(.seconds(timeout), scheduler: DispatchQueue.global(qos: .userInitiated), customError: { .timeout })
                .first() // only take one valid response and finish
                .catch {
                    $0 == AppSyncRealTimeRequest.Error.unknown
                    ? Empty(
                        outputType: AppSyncRealTimeResponse.self,
                        failureType: AppSyncRealTimeRequest.Error.self
                      ).eraseToAnyPublisher()
                    : Fail(error: $0).eraseToAnyPublisher()
                }
                .sink { completion in
                    switch completion {
                    case .finished:
                        log.debug("[AppSyncRealTimeClient] request finished successfully")
                        continuation.resume(returning: ())
                    case .failure(let error):
                        // TODO: we should not consider unknown error as a failure to trigger the retry
                        log.debug("[AppSyncRealTimeClient] request failed, error: \(error)")
                        continuation.resume(throwing: error)
                    }
                } receiveValue: { _ in }
                .store(in: &cancellables)

            Task { try? await requestFactory() }
        }
    }
}

extension AppSyncRealTimeClient: DefaultLogger {
    static var log: Logger {
        Amplify.Logging.logger(forCategory: CategoryType.api.displayName, forNamespace: String(describing: self))
    }

    nonisolated var log: Logger { Self.log }
}
