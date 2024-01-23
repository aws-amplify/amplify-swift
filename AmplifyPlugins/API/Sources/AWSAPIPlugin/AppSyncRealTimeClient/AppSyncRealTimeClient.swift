//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import Foundation
import Amplify
import Combine

fileprivate let jsonEncoder = JSONEncoder()
fileprivate let jsonDecoder = JSONDecoder()

protocol AppSyncRequestInterceptor {
    func interceptRequest(event: AppSyncRealTimeRequest, url: URL) async -> AppSyncRealTimeRequest
}

actor AppSyncRealTimeClient {

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

    private var webSocketClient: WebSocketClient
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
        connectionInterceptor: WebSocketInterceptor,
        requestInterceptor: AppSyncRequestInterceptor
    ) {
        self.state = .none
        self.endpoint = endpoint
        self.requestInterceptor = requestInterceptor

        self.webSocketClient = WebSocketClient(
            url: appSyncRealTimeEndpoint(endpoint),
            protocols: ["graphql-ws"],
            interceptor: connectionInterceptor
        )
        
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

        await self.webSocketClient.connect(
            autoConnectOnNetworkStatusChange: true,
            autoRetryOnConnectionFailure: true
        )
    }

    func disconnect() async {
        log.debug("[AppSyncRealTimeClient] client start disconnecting")
        self.state = .disconnecting
        self.cancellablesBindToConnection = Set()
        await self.webSocketClient.disconnect()
        self.state = .disconnected
        log.debug("[AppSyncRealTimeClient] client is disconnected")
    }

    func subscribe(id: String, query: String) async throws -> AnyPublisher<AppSyncSubscriptionEvent, Never> {
        log.debug("[AppSyncRealTimeClient] Received subscription request id: \(id), query: \(query)")
        try await connect()
        if self.isConnected {
            try await startSubscription(id: id, query: query).store(in: &cancellablesBindToConnection)
        }
        subscriptions[id] = query
        return filterAppSyncSubscriptionEvent(with: id)
    }

    func unsubscribe(id: String) async throws {
        log.debug("[AppSyncRealTimeClient] unsubscribing: \(id)")
        subscriptions.removeValue(forKey: id)
        try await self.writeAppSyncEvent(.stop(id))
    }

    private func startSubscription(id: String, query: String) async throws -> AnyCancellable {
        log.debug("[AppSyncRealTimeClient] Starting subscription request \(id), query: \(query)")
        try await self.writeAppSyncEvent(
            .start(.init(id: id, data: query, auth: nil))
        )

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
        Task {
            do {
                for (id, query) in self.subscriptions {
                    try await startSubscription(id: id, query: query).store(in: &cancellablesBindToConnection)
                }
            } catch {
                log.debug("[AppSyncRealTimeClient] Failed to resume existing subscriptions(count=\(subscriptions.count))")
            }
        }
    }

    nonisolated private func writeAppSyncEvent(_ event: AppSyncRealTimeRequest) async throws {
        guard await self.webSocketClient.isConnected else {
            log.debug("[AppSyncRealTimeClient] Attempting to write to a webSocket haven't been connected.")
            return
        }

        let interceptedEvent = await self.requestInterceptor.interceptRequest(event: event, url: self.endpoint)
        let eventString = try String(data: jsonEncoder.encode(interceptedEvent), encoding: .utf8)!
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
        subject.filter {
            guard let eventId = $0.id else {
                return false
            }

            return eventId == id
        }
        .map { [weak self] response -> AppSyncSubscriptionEvent? in
            switch response.type {
            case .startAck: return .subscribed
            case .stopAck: return .unsubscribed
            case .error:
                // TODO: (5d) better error types
                guard let errors = try? GraphQLErrorDecoder.decodeAppSyncErrors(response.payload)
                else {
                    self?.log.debug("[AppSyncRealTimeClient] Failed to decode errors")
                    return nil
                }
                return .error(errors)
            case .data:
                return response.payload.map { .data($0) }
            default: 
                return nil
            }
        }
        .compactMap { $0 }
        .eraseToAnyPublisher()
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
            // TODO: (5d) propagate error
            log.debug("[AppSyncRealTimeClient] WebSocket error event: \(error)")
        case .string(let string):
            guard let data = string.data(using: .utf8) else {
                log.debug("[AppSyncRealTimeClient] Failed to decode string \(string)")
                return
            }
            guard let response = try? jsonDecoder.decode(AppSyncRealTimeResponse.self, from: data) else {
                log.debug("[AppSyncRealTimeClient] Failed to decode string to AppSync event")
                return
            }
            self.onAppSyncRealTimeResponse(response)

        case .data(let data):
            guard let response = try? jsonDecoder.decode(AppSyncRealTimeResponse.self, from: data) else {
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
            self.state = .connected
            log.debug("[AppSyncRealTimeClient] AppSync connected: \(String(describing: event.payload))")
            self.resumeExistingSubscriptions()
            self.monitorHeartBeats(event.payload)

        case .keepAlive:
            self.heartBeats.send(())

        default:
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

fileprivate func appSyncRealTimeEndpoint(_ url: URL) -> URL {
    let customDomainURL = url.appendingPathComponent("realtime")
    guard let host = url.host, host.hasSuffix("amazonaws.com") else {
        return customDomainURL
    }

    guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
        return customDomainURL
    }

    urlComponents.host = host.replacingOccurrences(of: "appsync-api", with: "appsync-realtime-api")
    guard let realTimeUrl = urlComponents.url else {
        return customDomainURL
    }
    return realTimeUrl
}
