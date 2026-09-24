//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import Amplify
@preconcurrency import Combine
@testable import AWSAPIPlugin
@_spi(WebSocket) import AWSPluginsCore
import InternalAmplifyCredentials

struct MockSubscriptionConnectionFactory: AppSyncRealTimeClientFactoryProtocol {

    typealias OnGetOrCreateConnection = (
        AWSAPICategoryPluginConfiguration.EndpointConfig,
        URL,
        AWSAuthCredentialsProviderBehavior,
        AWSAuthorizationType?,
        APIAuthProviderFactory
    ) async throws -> AppSyncRealTimeClientProtocol

    let onGetOrCreateConnection: OnGetOrCreateConnection

    init(onGetOrCreateConnection: @escaping OnGetOrCreateConnection) {
        self.onGetOrCreateConnection = onGetOrCreateConnection
    }

    func getAppSyncRealTimeClient(
        for endpointConfig: AWSAPICategoryPluginConfiguration.EndpointConfig,
        endpoint: URL,
        authService: AWSAuthCredentialsProviderBehavior,
        authType: AWSAuthorizationType?,
        apiAuthProviderFactory: APIAuthProviderFactory
    ) async throws -> AppSyncRealTimeClientProtocol {
        try await onGetOrCreateConnection(endpointConfig, endpoint, authService, authType, apiAuthProviderFactory)
    }
}

// `@unchecked Sendable`: the protocol it conforms to now requires `Sendable`; driven by a single
// test at a time.
class MockAppSyncRealTimeClient: AppSyncRealTimeClientProtocol, @unchecked Sendable {

    /// Emits lifecycle events only after the consumer attaches, preventing eager forwarding from
    /// dropping `.connecting`. Waits are bounded so a never-arriving phase fails the test rather
    /// than hanging the shard.
    private final class Lifecycle: @unchecked Sendable {
        enum Phase { case attached, subscribing, subscribed, unsubscribed }
        struct TimedOut: Error { let phase: Phase }

        private let lock = NSLock()
        private var reached: Set<Phase> = []
        private var claimedSends: Set<Phase> = []

        func mark(_ phase: Phase) {
            lock.withLock { _ = reached.insert(phase) }
        }

        /// Waits until `phase` is reached, throwing `TimedOut` after `timeout` so a regression is a
        /// bounded failure, not a hang.
        func wait(for phase: Phase, timeout: TimeInterval) async throws {
            let deadline = Date().addingTimeInterval(timeout)
            while !lock.withLock({ reached.contains(phase) }) {
                if Date() >= deadline { throw TimedOut(phase: phase) }
                try? await Task.sleep(nanoseconds: 5_000_000)
            }
        }

        /// Returns `true` only for the first caller for `phase`, so each event is sent exactly once.
        func claimSend(_ phase: Phase) -> Bool {
            lock.withLock { claimedSends.insert(phase).inserted }
        }
    }

    /// Generous upper bound for lifecycle waits; the deterministic mock reaches each phase far sooner,
    /// so this only bounds a genuine regression.
    private static let waitTimeout: TimeInterval = 10

    private let subject = PassthroughSubject<AppSyncSubscriptionEvent, Never>()
    private let lifecycle = Lifecycle()

    func subscribe(id: String, query: String) async throws -> AnyPublisher<AppSyncSubscriptionEvent, Never> {
        let lifecycle = lifecycle
        // `.buffer` keeps demand on the subject so a send is never silently dropped when the
        // subscriber hasn't yet requested demand; events are held and delivered FIFO. `receiveRequest`
        // then signals readiness so the `waitFor*` methods only send once the operation's sink is
        // attached. Together these make lifecycle delivery deterministic (no fixed-sleep slack).
        return subject
            .buffer(size: 1_024, prefetch: .keepFull, whenFull: .dropOldest)
            .handleEvents(receiveRequest: { _ in
                lifecycle.mark(.attached)
            })
            .eraseToAnyPublisher()
    }

    func unsubscribe(id: String) async throws {
        subject.send(.unsubscribed)
        lifecycle.mark(.unsubscribed)
    }

    func connect() async throws { }

    func disconnectWhenIdel() async { }

    func disconnect() async { }

    func triggerEvent(_ event: AppSyncSubscriptionEvent) {
        subject.send(event)
        if case .unsubscribed = event {
            lifecycle.mark(.unsubscribed)
        }
    }

    func waitForSubscirbing() async throws {
        try await sendSubscribing()
    }

    func waitForSubscirbed() async throws {
        try await sendSubscribing()
        if lifecycle.claimSend(.subscribed) {
            subject.send(.subscribed)
            lifecycle.mark(.subscribed)
        }
        try await lifecycle.wait(for: .subscribed, timeout: Self.waitTimeout)
    }

    func waitForUnsubscirbed() async throws {
        try await lifecycle.wait(for: .unsubscribed, timeout: Self.waitTimeout)
    }

    /// Waits for the operation's sink to attach, then sends `.subscribing` exactly once and waits
    /// until it has been emitted.
    private func sendSubscribing() async throws {
        try await lifecycle.wait(for: .attached, timeout: Self.waitTimeout)
        if lifecycle.claimSend(.subscribing) {
            subject.send(.subscribing)
            lifecycle.mark(.subscribing)
        }
        try await lifecycle.wait(for: .subscribing, timeout: Self.waitTimeout)
    }
}

// `@unchecked Sendable`: the protocol it conforms to now requires `Sendable`. Test double driven

// by a single test at a time.

class MockAppSyncRequestInterceptor: AppSyncRequestInterceptor, @unchecked Sendable {
    func interceptRequest(event: AppSyncRealTimeRequest, url: URL) async -> AppSyncRealTimeRequest {
        return event
    }
}

actor MockWebSocketClient: AppSyncWebSocketClientProtocol {
    enum State {
        case none
        case connected
    }

    enum Action {
        case connect(Bool, Bool)
        case disconnect
        case write(String)
    }

    var actionSubject = PassthroughSubject<Action, Never>()
    var subject = PassthroughSubject<WebSocketEvent, Never>()
    var state: State

    var isConnected: Bool {
        state == .connected
    }

    var publisher: AnyPublisher<WebSocketEvent, Never> {
        subject.eraseToAnyPublisher()
    }

    init() {
        self.state = .none
    }

    deinit {
        subject.send(completion: .finished)
        actionSubject.send(completion: .finished)
    }

    func connect(autoConnectOnNetworkStatusChange: Bool, autoRetryOnConnectionFailure: Bool) {
        actionSubject.send(.connect(autoConnectOnNetworkStatusChange, autoRetryOnConnectionFailure))
    }

    func disconnect() {
        actionSubject.send(.disconnect)
    }

    func write(message: String) throws {
        actionSubject.send(.write(message))
    }

    func setStateToConnected() {
        state = .connected
    }
}
