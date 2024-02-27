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
    private let state = CurrentValueSubject<State, Never>(.none)

    private let endpoint: URL
    private let requestInterceptor: AppSyncRequestInterceptor

    private var webSocketClient: AppSyncWebSocketClientProtocol
    private let subject = PassthroughSubject<AppSyncRealTimeResponse, Never>()
    private var subscriptions = [String: AppSyncRealTimeSubscription]()

    private let heartBeats = PassthroughSubject<Void, Never>()

    private var cancellables = Set<AnyCancellable>()
    private var cancellablesBindToConnection = Set<AnyCancellable>()

    var isConnected: Bool {
        self.state.value == .connected
    }

    init(
        endpoint: URL,
        requestInterceptor: AppSyncRequestInterceptor,
        webSocketClient: AppSyncWebSocketClientProtocol
    ) {
        self.endpoint = endpoint
        self.requestInterceptor = requestInterceptor

        self.webSocketClient = webSocketClient

        Task { await self.subscribeToWebSocketEvent() }
    }

    deinit {
        log.debug("Deinit AppSyncRealTimeClient")
        subject.send(completion: .finished)
        cancellables = Set()
        cancellablesBindToConnection = Set()
    }

    func connect() async throws {
        switch self.state.value {
        case .connecting, .connected:
            log.debug("[AppSyncRealTimeClient] client is already connecting or connected")
            return
        case .disconnecting:
            try await waitForState(.disconnected)
        case .connectionDropped, .disconnected, .none:
            break
        }

        guard self.state.value != .connecting else {
            log.debug("[AppSyncRealTimeClient] actor reentry, state has been changed to connecting")
            return
        }

        self.state.send(.connecting)
        log.debug("[AppSyncRealTimeClient] client start connecting")

        try await RetryWithJitter.execute { [weak self] in
            guard let self else { return }
            try await AppSyncRealTimeRequest.sendRequest(
                request: .connectionInit,
                responseStream: subject.eraseToAnyPublisher()
            ) { [weak self] _ in
                await self?.webSocketClient.connect(
                   autoConnectOnNetworkStatusChange: true,
                   autoRetryOnConnectionFailure: true
                )
            }
        }
    }

    func disconnect(onlyIdel: Bool = false) async {
        guard self.state.value != .disconnecting else {
            log.debug("[AppSyncRealTimeClient] client already disconnecting")
            return
        }

        if onlyIdel && !self.subscriptions.isEmpty {
            log.debug("[AppSyncRealTimeClient] client only try to disconnect when no subscriptions exist")
            return
        }

        defer { self.state.send(.disconnected) }

        log.debug("[AppSyncRealTimeClient] client start disconnecting")
        self.state.send(.disconnecting)
        self.cancellablesBindToConnection = Set()
        await self.webSocketClient.disconnect()
        log.debug("[AppSyncRealTimeClient] client is disconnected")
    }

    func subscribe(id: String, query: String) throws -> AnyPublisher<AppSyncSubscriptionEvent, Never> {
        log.debug("[AppSyncRealTimeClient] Received subscription request id: \(id), query: \(query)")
        subscriptions[id] = AppSyncRealTimeSubscription(id: id, query: query)
        // Initiate the subscription in a separate task and returning the filtered
        // publisher immediately for downstream to listen to all the error messages
        Task {
            if !self.isConnected {
                try await connect()
                try await waitForState(.connected)
            }
            try await self.startSubscription(id).store(in: &cancellablesBindToConnection)
        }
        return filterAppSyncSubscriptionEvent(with: id)
    }

    private func waitForState(_ targetState: State) async throws {
        var cancellables = Set<AnyCancellable>()

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Swift.Error>) -> Void in
            state.filter { $0 == targetState }
                .setFailureType(to: AppSyncRealTimeRequest.Error.self)
                .timeout(.seconds(10), scheduler: DispatchQueue.global())
                .first()
                .sink { completion in
                    switch completion {
                    case .finished:
                        continuation.resume(returning: ())
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                } receiveValue: { _ in }
                .store(in: &cancellables)
        }
    }

    func unsubscribe(id: String) async throws {
        defer {
            log.debug("[AppSyncRealTimeClient] deleted subscription with id: \(id)")
            subscriptions.removeValue(forKey: id)
        }

        guard let subscription = subscriptions[id] else {
            log.debug("[AppSyncRealTimeClient] start subscription failed, could not found subscription with id \(id) ")
            return
        }
        log.debug("[AppSyncRealTimeClient] unsubscribing: \(id)")
        try await subscription.unsubscribe(with: webSocketClient, responseStream: subject.eraseToAnyPublisher())
    }

    private func startSubscription(_ id: String) async throws -> AnyCancellable {
        guard let subscription = subscriptions[id] else {
            log.debug("[AppSyncRealTimeClient] start subscription failed, could not found subscription with id \(id) ")
            throw APIError.unknown("Could not find a subscription with id \(id)", "", nil)
        }

        log.debug("[AppSyncRealTimeClient] Starting subscription request \(subscription.id), query: \(subscription.query)")

        // TODO: (5d) it seems the current implementation is no retry on request level
        // we just pass down the errors to subscribers to handle
        let subscriptionRequest = await self.requestInterceptor.interceptRequest(
            event: .start(.init(id: subscription.id, data: subscription.query, auth: nil)),
            url: self.endpoint
        )

        try await subscription.subscribe(
            with: webSocketClient,
            request: subscriptionRequest,
            responseStream: subject.eraseToAnyPublisher()
        )

        return AnyCancellable {
            Task { [weak self] in
                guard let self else { return }
                try await subscription.unsubscribe(
                    with: self.webSocketClient,
                    responseStream: self.subject.eraseToAnyPublisher()
                )
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
        for (id, _) in self.subscriptions {
            Task {
                do {
                    try await self.startSubscription(id).store(in: &cancellablesBindToConnection)
                } catch {
                    log.debug("[AppSyncRealTimeClient] Failed to resume existing subscription with id: (\(id))")
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
        subject.filter { $0.id == id || $0.type == .connectionError }
        .map { response -> AppSyncSubscriptionEvent? in
            switch response.type {
            case .startAck: return .subscribed
            case .stopAck: return .unsubscribed
            case .connectionError, .error:
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
            if self.state.value != .disconnecting || self.state.value != .disconnected {
                self.state.send(.connectionDropped)
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
            self.state.send(.connected)
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

extension AppSyncRealTimeClient: DefaultLogger {
    static var log: Logger {
        Amplify.Logging.logger(forCategory: CategoryType.api.displayName, forNamespace: String(describing: self))
    }

    nonisolated var log: Logger { Self.log }
}

extension AppSyncRealTimeClient: Resettable {
    func reset() async {
        subject.send(completion: .finished)
        cancellables = Set()
        cancellablesBindToConnection = Set()

        if let resettableWebSocketClient = webSocketClient as? Resettable {
            await resettableWebSocketClient.reset()
        }
    }
}
