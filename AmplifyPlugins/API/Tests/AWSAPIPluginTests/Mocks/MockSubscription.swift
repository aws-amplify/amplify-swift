//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import Amplify
import Combine
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

class MockAppSyncRealTimeClient: AppSyncRealTimeClientProtocol  {


    private let subject = PassthroughSubject<AppSyncSubscriptionEvent, Never>()

    func subscribe(id: String, query: String) async throws -> AnyPublisher<AppSyncSubscriptionEvent, Never> {
        defer {

            Task {
                try await Task.sleep(seconds: 0.25)
                subject.send(.subscribing)
                try await Task.sleep(seconds: 0.45)
                subject.send(.subscribed)
            }
        }
        return subject.eraseToAnyPublisher()
    }
    
    func unsubscribe(id: String) async throws {
        try await Task.sleep(seconds: 0.45)
        subject.send(.unsubscribed)
    }
    
    func connect() async throws { }

    func disconnectWhenIdel() async { }

    func disconnect() async { }

    func triggerEvent(_ event: AppSyncSubscriptionEvent) {
        subject.send(event)
    }

    static func waitForSubscirbing() async throws {
        try await Task.sleep(seconds: 0.3)
    }

    static func waitForSubscirbed() async throws {
        try await Task.sleep(seconds: 0.5)
    }

    static func waitForUnsubscirbed() async throws {
        try await Task.sleep(seconds: 0.5)
    }
}

class MockAppSyncRequestInterceptor: AppSyncRequestInterceptor {
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
        self.state = .connected
    }
}
