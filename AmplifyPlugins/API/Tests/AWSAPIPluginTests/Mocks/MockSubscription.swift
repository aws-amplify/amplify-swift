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

// `@unchecked Sendable`: the protocol it conforms to now requires `Sendable`. Test double driven

// by a single test at a time.

class MockAppSyncRealTimeClient: AppSyncRealTimeClientProtocol, @unchecked Sendable {

    /// Tracks the subscription lifecycle so `waitFor*` drives and awaits the real emission instead of
    /// racing fixed sleeps. Lifecycle events are sent on demand from the `waitFor*` methods — never
    /// automatically on attach — so a test always sends `.subscribing`/`.subscribed` *after* it has
    /// subscribed its consumer, which is what keeps `Amplify.Publisher.create`'s eager forwarding from
    /// dropping `.connecting` before the Combine sink is attached.
    private final class Lifecycle: @unchecked Sendable {
        enum Phase { case attached, subscribing, subscribed, unsubscribed }

        private let lock = NSLock()
        private var reached: Set<Phase> = []
        private var waiters: [Phase: [CheckedContinuation<Void, Never>]] = [:]
        private var claimedSends: Set<Phase> = []

        func mark(_ phase: Phase) {
            lock.lock()
            reached.insert(phase)
            let toResume = waiters.removeValue(forKey: phase) ?? []
            lock.unlock()
            toResume.forEach { $0.resume() }
        }

        func wait(for phase: Phase) async {
            await withCheckedContinuation { continuation in
                lock.lock()
                if reached.contains(phase) {
                    lock.unlock()
                    continuation.resume()
                } else {
                    waiters[phase, default: []].append(continuation)
                    lock.unlock()
                }
            }
        }

        /// Returns `true` only for the first caller for `phase`, so each event is sent exactly once.
        func claimSend(_ phase: Phase) -> Bool {
            lock.lock()
            defer { lock.unlock() }
            return claimedSends.insert(phase).inserted
        }
    }

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
        await sendSubscribing()
    }

    func waitForSubscirbed() async throws {
        await sendSubscribing()
        if lifecycle.claimSend(.subscribed) {
            subject.send(.subscribed)
            lifecycle.mark(.subscribed)
        }
        await lifecycle.wait(for: .subscribed)
    }

    func waitForUnsubscirbed() async throws {
        await lifecycle.wait(for: .unsubscribed)
    }

    /// Waits for the operation's sink to attach, then sends `.subscribing` exactly once and waits
    /// until it has been emitted.
    private func sendSubscribing() async {
        await lifecycle.wait(for: .attached)
        if lifecycle.claimSend(.subscribing) {
            subject.send(.subscribing)
            lifecycle.mark(.subscribing)
        }
        await lifecycle.wait(for: .subscribing)
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
