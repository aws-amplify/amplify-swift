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
@_spi(AmplifySwift) import AWSPluginsCore

struct MockSubscriptionConnectionFactory: AppSyncRealTimeClientFactoryProtocol {
    

    typealias OnGetOrCreateConnection = (
        AWSAPICategoryPluginConfiguration.EndpointConfig,
        URL,
        AWSAuthServiceBehavior,
        AWSAuthorizationType?,
        APIAuthProviderFactory
    ) async throws -> AppSyncRealTimeClient

    let onGetOrCreateConnection: OnGetOrCreateConnection

    init(onGetOrCreateConnection: @escaping OnGetOrCreateConnection) {
        self.onGetOrCreateConnection = onGetOrCreateConnection
    }

    func getAppSyncRealTimeClient(
        for endpointConfig: AWSAPICategoryPluginConfiguration.EndpointConfig,
        endpoint: URL,
        authService: AWSAuthServiceBehavior,
        authType: AWSAuthorizationType?,
        apiAuthProviderFactory: APIAuthProviderFactory
    ) async throws -> AppSyncRealTimeClientProtocol {
        try await onGetOrCreateConnection(endpointConfig, endpoint, authService, authType, apiAuthProviderFactory)
    }
}

struct MockAppSyncRealTimeClient  {
//    typealias OnSubscribe = (
//        String,
//        [String: Any?]?,
//        @escaping SubscriptionEventHandler
//    ) -> SubscriptionItem
//
//    typealias OnUnsubscribe = (SubscriptionItem) -> Void
//
//    let onSubscribe: OnSubscribe
//    let onUnsubscribe: OnUnsubscribe
//
//    init(onSubscribe: @escaping OnSubscribe, onUnsubscribe: @escaping OnUnsubscribe) {
//        self.onSubscribe = onSubscribe
//        self.onUnsubscribe = onUnsubscribe
//    }
//
//    func subscribe(
//        requestString: String,
//        variables: [String: Any?]?,
//        eventHandler: @escaping SubscriptionEventHandler
//    ) -> SubscriptionItem {
//        onSubscribe(requestString, variables, eventHandler)
//    }
//
//    func unsubscribe(item: SubscriptionItem) {
//        onUnsubscribe(item)
//    }

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
