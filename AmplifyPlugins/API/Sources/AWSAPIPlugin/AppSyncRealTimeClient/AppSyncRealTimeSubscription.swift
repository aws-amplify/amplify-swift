//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import Foundation
import Combine
import Amplify

/**
 AppSyncRealTimeSubscription reprensents one realtime subscription to AppSync realtime server.
 */
actor AppSyncRealTimeSubscription {
    static let jsonEncoder = JSONEncoder()

    enum State {
        case none
        case subscribing
        case subscribed
        case unsubscribing
        case unsubscribed
        case failure
    }

    /// internal state for tracking subscription status
    private let state = CurrentValueSubject<State, Never>(.none)

    /// publisher for monitoring subscription status
    public var publisher: AnyPublisher<State, Never> {
        state.eraseToAnyPublisher()
    }
    public let id: String
    public let query: String
    public let endpoint: URL

    init(id: String, query: String, endpoint: URL) {
        self.id = id
        self.query = query
        self.endpoint = endpoint
    }

    deinit {
        self.state.send(completion: .finished)
    }

    func subscribe(
        with webSocketClient: AppSyncWebSocketClientProtocol,
        requestInterceptor: AppSyncRequestInterceptor,
        responseStream: AnyPublisher<AppSyncRealTimeResponse, Never>
    ) async throws {
        guard self.state.value != .subscribing else {
            log.debug("[AppSyncRealTimeSubscription-\(id)] Subscription already in subscribing state")
            return
        }

        guard self.state.value != .subscribed else {
            log.debug("[AppSyncRealTimeSubscription-\(id)] Subscription already in subscribed state")
            return
        }

        log.debug("[AppSyncRealTimeSubscription-\(id)] Start subscribing")
        self.state.send(.subscribing)

        let request = await requestInterceptor.interceptRequest(
            event: .start(.init(id: id, data: query, auth: nil)),
            url: endpoint
        )

        do {
            try await AppSyncRealTimeRequest.sendRequest(
                request: request,
                responseStream: responseStream
            ) { [weak webSocketClient] request in
                guard let webSocketClient else { return }
                try await Self.sendSubscriptionRequest(request, with: webSocketClient)
            }
        } catch {
            log.debug("[AppSyncRealTimeSubscription-\(id)] Failed to subscribe, error: \(error)")
            self.state.send(.failure)
            throw error
        }

        log.debug("[AppSyncRealTimeSubscription-\(id)] Subscribed")
        self.state.send(.subscribed)
    }

    func unsubscribe(
        with webSocketClient: AppSyncWebSocketClientProtocol,
        responseStream: AnyPublisher<AppSyncRealTimeResponse, Never>
    ) async throws {
        guard self.state.value == .subscribed else {
            log.debug("[AppSyncRealTimeSubscription-\(id)] Subscription should be subscribed to be unsubscribed")
            return
        }

        log.debug("[AppSyncRealTimeSubscription-\(id)] Unsubscribing")
        self.state.send(.unsubscribing)

        do {
            try await AppSyncRealTimeRequest.sendRequest(
                request: AppSyncRealTimeRequest.stop(id),
                responseStream: responseStream
            ) { [weak webSocketClient] request in
                guard let webSocketClient else { return }
                try await Self.sendSubscriptionRequest(request, with: webSocketClient)
            }
        } catch {
            log.debug("[AppSyncRealTimeSubscription-\(id)] Failed to unsubscribe, error \(error)")
            self.state.send(.failure)
            throw error
        }

        log.debug("[AppSyncRealTimeSubscription-\(id)] Unsubscribed")
        self.state.send(.unsubscribed)
    }

    private static func sendSubscriptionRequest(
        _ request: AppSyncRealTimeRequest,
        with webSocketClient: AppSyncWebSocketClientProtocol
    ) async throws {
        guard let requestJson = try String(
            data: Self.jsonEncoder.encode(request),
            encoding: .utf8
        ) else {
            return
        }

        try await webSocketClient.write(message: requestJson)
    }
}

extension AppSyncRealTimeSubscription: DefaultLogger {
    static var log: Logger {
        Amplify.Logging.logger(forCategory: CategoryType.api.displayName, forNamespace: String(describing: self))
    }

    nonisolated var log: Logger { Self.log }
}
