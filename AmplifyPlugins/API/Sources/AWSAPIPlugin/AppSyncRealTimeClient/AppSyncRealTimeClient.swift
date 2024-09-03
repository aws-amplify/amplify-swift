//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine
import Foundation
@_spi(WebSocket) import AWSPluginsCore

/**
 The AppSyncRealTimeClient conforms to the AppSync real-time WebSocket protocol.
 ref: https://docs.aws.amazon.com/appsync/latest/devguide/real-time-websocket-client.html
 */
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

    /// Internal state for tracking AppSync connection
    private let state = CurrentValueSubject<State, Never>(.none)
    /// Subscriptions created using this client
    private var subscriptions = [String: AppSyncRealTimeSubscription]()
    /// heart beat stream to keep connection alive
    private let heartBeats = PassthroughSubject<Void, Never>()
    /// Cancellables bind to instance life cycle
    private var cancellables = Set<AnyCancellable>()
    /// Cancellables bind to connection life cycle
    private var cancellablesBindToConnection = Set<AnyCancellable>()

    /// AppSync RealTime server endpoint
    let endpoint: URL
    /// Interceptor for decorating AppSyncRealTimeRequest
    let requestInterceptor: AppSyncRequestInterceptor

    /// WebSocketClient offering connections at the WebSocket protocol level
    var webSocketClient: AppSyncWebSocketClientProtocol
    /// Writable data stream convert WebSocketEvent to AppSyncRealTimeResponse
    let subject = PassthroughSubject<Result<AppSyncRealTimeResponse, Error>, Never>()

    var isConnected: Bool {
        state.value == .connected
    }

    var numberOfSubscriptions: Int {
        subscriptions.count
    }

    /**
     Creates a new AppSyncRealTimeClient with endpoint, requestInterceptor and webSocketClient.
     - Parameters:
        - endpoint: AppSync real-time server endpoint
        - requestInterceptor: Interceptor for decocating AppSyncRealTimeRequest
        - webSocketClient: WebSocketClient for reading/writing to connection
     */
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

    /**
     Connecting to remote AppSync real-time server.
     */
    func connect() async throws {
        switch state.value {
        case .connecting, .connected:
            log.debug("[AppSyncRealTimeClient] client is already connecting or connected")
            return
        case .disconnecting:
            try await waitForState(.disconnected)
        case .connectionDropped, .disconnected, .none:
            break
        }

        guard state.value != .connecting else {
            log.debug("[AppSyncRealTimeClient] actor reentry, state has been changed to connecting")
            return
        }

        state.send(.connecting)
        log.debug("[AppSyncRealTimeClient] client start connecting")

        try await RetryWithJitter.execute { [weak self] in
            guard let self else { return }
            await webSocketClient.connect(
                autoConnectOnNetworkStatusChange: true,
                autoRetryOnConnectionFailure: true
            )
            try await sendRequest(.connectionInit)
        }
    }

    /**
     Disconnect only when there are no subscriptions exist.
     */
    func disconnectWhenIdel() async {
        if subscriptions.isEmpty {
            log.debug("[AppSyncRealTimeClient] no subscription exist, client is trying to disconnect")
            await disconnect()
        } else {
            log.debug("[AppSyncRealTimeClient] client only try to disconnect when no subscriptions exist")
        }
    }

    /**
     Disconnect from AppSync real-time server.
     */
    func disconnect() async {
        guard state.value != .disconnecting else {
            log.debug("[AppSyncRealTimeClient] client already disconnecting")
            return
        }

        defer { self.state.send(.disconnected) }

        log.debug("[AppSyncRealTimeClient] client start disconnecting")
        state.send(.disconnecting)
        cancellablesBindToConnection = Set()
        await webSocketClient.disconnect()
        log.debug("[AppSyncRealTimeClient] client is disconnected")
    }

    /**
     Subscribing to a query with unique identifier.
     - Parameters:
        - id: unique identifier
        - query: GraphQL query for subscription

     -  Returns:
        A never fail data stream for AppSyncSubscriptionEvent.
     */
    func subscribe(id: String, query: String) async throws -> AnyPublisher<AppSyncSubscriptionEvent, Never> {
        log.debug("[AppSyncRealTimeClient] Received subscription request id: \(id), query: \(query)")
        let subscription = AppSyncRealTimeSubscription(id: id, query: query, appSyncRealTimeClient: self)
        subscriptions[id] = subscription


        // Placing the actual subscription work in a deferred task and
        // promptly returning the filtered publisher for downstream consumption of all error messages.
        defer {
            Task { [weak self] in
                guard let self else { return }
                if await !(self.isConnected) {
                    try await connect()
                    try await waitForState(.connected)
                }
                try await self.bindCancellableToConnection(self.startSubscription(id))
            }.toAnyCancellable.store(in: &cancellablesBindToConnection)
        }

        return await filterAppSyncSubscriptionEvent(with: id)
            .merge(with: (subscription.publisher).toAppSyncSubscriptionEventStream())
            .eraseToAnyPublisher()
    }

    private func waitForState(_ targetState: State) async throws {
        var cancellables = Set<AnyCancellable>()

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Swift.Error>) in
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

    /**
     Unsubscribe a subscription with unique identifier.
     - Parameters:
        - id: unique identifier of the subscription.
     */
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
        try await subscription.unsubscribe()
    }

    private func startSubscription(_ id: String) async throws -> AnyCancellable {
        guard let subscription = subscriptions[id] else {
            log.debug("[AppSyncRealTimeClient] start subscription failed, could not found subscription with id \(id) ")
            throw APIError.unknown("Could not find a subscription with id \(id)", "", nil)
        }

        try await subscription.subscribe()

        return AnyCancellable {
            Task {
                try await subscription.unsubscribe()
            }
        }

    }

    private func subscribeToWebSocketEvent() async {
        await webSocketClient.publisher.sink { [weak self] _ in
            self?.log.debug("[AppSyncRealTimeClient] WebSocketClient terminated")
        } receiveValue: { webSocketEvent in
            Task { [weak self] in
                await self?.onWebSocketEvent(webSocketEvent)
            }.toAnyCancellable.store(in: &self.cancellables)
        }
        .store(in: &cancellables)
    }

    private func resumeExistingSubscriptions() {
        log.debug("[AppSyncRealTimeClient] Resuming existing subscriptions")
        for (id, _) in subscriptions {
            Task {
                do {
                    try await self.startSubscription(id).store(in: &cancellablesBindToConnection)
                } catch {
                    log.debug("[AppSyncRealTimeClient] Failed to resume existing subscription with id: (\(id))")
                }
            }
        }

    }

    private nonisolated func writeAppSyncEvent(_ event: AppSyncRealTimeRequest) async throws {
        guard await webSocketClient.isConnected else {
            log.debug("[AppSyncRealTimeClient] Attempting to write to a webSocket haven't been connected.")
            return
        }

        let interceptedEvent = await requestInterceptor.interceptRequest(event: event, url: endpoint)
        let eventString = try String(data: Self.jsonEncoder.encode(interceptedEvent), encoding: .utf8)!
        log.debug("[AppSyncRealTimeClient] Writing AppSyncEvent \(eventString)")
        try await webSocketClient.write(message: eventString)
    }

    /**
     Filter response to downstream by id.
     - Parameters:
        - id: subscription identifier
     - Returns:
        - AppSyncSubscriptionEvent data stream related to subscription
     - important: connection errors will also be passed to downstreams
     */
    private func filterAppSyncSubscriptionEvent(
        with id: String
    ) -> AnyPublisher<AppSyncSubscriptionEvent, Never> {
        subject.filter {
            switch $0 {
            case .success(let response): return response.id == id || response.type == .connectionError
            case .failure(let error): return true
            }
        }
        .map { result -> AppSyncSubscriptionEvent? in
            switch result {
            case .success(let response):
                switch response.type {
                case .connectionError, .error:
                    return .error(Self.decodeAppSyncRealTimeResponseError(response.payload))
                case .data:
                    return response.payload.map { .data($0) }
                default:
                    return nil
                }
            case .failure(let error):
                return .error([error])
            }
        }
        .compactMap { $0 }
        .eraseToAnyPublisher()
    }

    private func reconnect() async {
        do {
            log.debug("[AppSyncRealTimeClient] Reconnecting")
            await disconnect()
            try await connect()
        } catch {
            log.debug("[AppSyncRealTimeClient] Failed to reconnect, error: \(error)")
        }
    }

    private static func decodeAppSyncRealTimeResponseError(_ data: JSONValue?) -> [Error] {
        let knownAppSyncRealTimeRequestErorrs =
            Self.decodeAppSyncRealTimeRequestError(data)
            .filter { !$0.isUnknown }
        if knownAppSyncRealTimeRequestErorrs.isEmpty {
            let graphQLErrors = Self.decodeGraphQLErrors(data)
            return graphQLErrors.isEmpty
                ? [APIError.operationError("Failed to decode AppSync error response", "", nil)]
                : graphQLErrors
        } else {
            return knownAppSyncRealTimeRequestErorrs
        }
    }

    private static func decodeGraphQLErrors(_ data: JSONValue?) -> [GraphQLError] {
        do {
            return try GraphQLErrorDecoder.decodeAppSyncErrors(data)
        } catch {
            log.debug("[AppSyncRealTimeClient] Failed to decode errors: \(error)")
            return []
        }
    }

    private static func decodeAppSyncRealTimeRequestError(_ data: JSONValue?) -> [AppSyncRealTimeRequest.Error] {
        guard let errorsJson = data?.errors else {
            log.error("[AppSyncRealTimeClient] No 'errors' field found in response json")
            return []
        }
        let errors = errorsJson.asArray ?? [errorsJson]
        return errors.compactMap(AppSyncRealTimeRequest.parseResponseError(error:))
    }

    private func bindCancellableToConnection(_ cancellable: AnyCancellable) {
        cancellable.store(in: &cancellablesBindToConnection)
    }

}

// MARK: - On WebSocket Events
extension AppSyncRealTimeClient {
    private func onWebSocketEvent(_ event: WebSocketEvent) {
        log.debug("[AppSyncRealTimeClient] Received websocket event \(event)")
        switch event {
        case .connected:
            log.debug("[AppSyncRealTimeClient] WebSocket connected")
            if state.value == .connectionDropped {
                log.debug("[AppSyncRealTimeClient] reconnecting appSyncClient after connection drop")
                Task { [weak self] in
                    try? await self?.connect()
                }.toAnyCancellable.store(in: &cancellablesBindToConnection)
            }

        case let .disconnected(closeCode, reason): //
            log.debug("[AppSyncRealTimeClient] WebSocket disconnected with closeCode: \(closeCode), reason: \(String(describing: reason))")
            if state.value != .disconnecting || state.value != .disconnected {
                state.send(.connectionDropped)
            }
            cancellablesBindToConnection = Set()

        case .error(let error):
            // Propagate connection error to downstream for Sync engine to restart
            log.debug("[AppSyncRealTimeClient] WebSocket error event: \(error)")
            subject.send(.failure(error))
        case .string(let string):
            guard let data = string.data(using: .utf8) else {
                log.debug("[AppSyncRealTimeClient] Failed to decode string \(string)")
                return
            }
            guard let response = try? Self.jsonDecoder.decode(AppSyncRealTimeResponse.self, from: data) else {
                log.debug("[AppSyncRealTimeClient] Failed to decode string to AppSync event")
                return
            }
            onAppSyncRealTimeResponse(response)

        case .data(let data):
            guard let response = try? Self.jsonDecoder.decode(AppSyncRealTimeResponse.self, from: data) else {
                log.debug("[AppSyncRealTimeClient] Failed to decode data to AppSync event")
                return
            }
            onAppSyncRealTimeResponse(response)
        }
    }

}

// MARK: - On AppSyncServer Event
extension AppSyncRealTimeClient {
    /// handles connection level response and passes request level response to downstream
    private func onAppSyncRealTimeResponse(_ event: AppSyncRealTimeResponse) {
        switch event.type {
        case .connectionAck:
            log.debug("[AppSyncRealTimeClient] AppSync connected: \(String(describing: event.payload))")
            subject.send(.success(event))

            resumeExistingSubscriptions()
            state.send(.connected)
            monitorHeartBeats(event.payload)

        case .keepAlive:
            heartBeats.send(())

        default:
            log.debug("[AppSyncRealTimeClient] AppSync received response: \(event)")
            subject.send(.success(event))
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
                Task { [weak self] in
                    await self?.reconnect()
                }.toAnyCancellable.store(in: &self.cancellables)
            })
            .store(in: &cancellablesBindToConnection)
        // start counting down
        heartBeats.send(())
    }
}

extension Publisher where Output == AppSyncRealTimeSubscription.State, Failure == Never {
    func toAppSyncSubscriptionEventStream() -> AnyPublisher<AppSyncSubscriptionEvent, Never> {
        compactMap { subscriptionState -> AppSyncSubscriptionEvent? in
            switch subscriptionState {
            case .subscribing: return .subscribing
            case .subscribed: return .subscribed
            case .unsubscribed: return .unsubscribed
            default: return nil
            }
        }
        .eraseToAnyPublisher()
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

private extension Task {
    var toAnyCancellable: AnyCancellable {
        AnyCancellable {
            if !self.isCancelled {
                self.cancel()
            }
        }
    }
}
