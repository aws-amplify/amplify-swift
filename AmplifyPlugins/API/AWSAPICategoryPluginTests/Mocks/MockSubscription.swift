//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSAPIPlugin
import Amplify

import AWSPluginsCore
import AppSyncRealTimeClient

struct MockSubscriptionConnectionFactory: SubscriptionConnectionFactory {
    typealias OnGetOrCreateConnection = (
        AWSAPICategoryPluginConfiguration.EndpointConfig,
        AWSAuthServiceBehavior,
        AWSAuthorizationType?,
        APIAuthProviderFactory
    ) throws -> SubscriptionConnection

    let onGetOrCreateConnection: OnGetOrCreateConnection

    init(onGetOrCreateConnection: @escaping OnGetOrCreateConnection) {
        self.onGetOrCreateConnection = onGetOrCreateConnection
    }

    func getOrCreateConnection(
        for endpointConfig: AWSAPICategoryPluginConfiguration.EndpointConfig,
        authService: AWSAuthServiceBehavior,
        authType: AWSAuthorizationType?,
        apiAuthProviderFactory: APIAuthProviderFactory
    ) throws -> SubscriptionConnection {
        try onGetOrCreateConnection(endpointConfig, authService, authType, apiAuthProviderFactory)
    }

}

struct MockSubscriptionConnection: SubscriptionConnection {
    typealias OnSubscribe = (
        String,
        [String: Any?]?,
        @escaping SubscriptionEventHandler
    ) -> SubscriptionItem

    typealias OnUnsubscribe = (SubscriptionItem) -> Void

    let onSubscribe: OnSubscribe
    let onUnsubscribe: OnUnsubscribe

    init(onSubscribe: @escaping OnSubscribe, onUnsubscribe: @escaping OnUnsubscribe) {
        self.onSubscribe = onSubscribe
        self.onUnsubscribe = onUnsubscribe
    }

    func subscribe(
        requestString: String,
        variables: [String: Any?]?,
        eventHandler: @escaping SubscriptionEventHandler
    ) -> SubscriptionItem {
        onSubscribe(requestString, variables, eventHandler)
    }

    func unsubscribe(item: SubscriptionItem) {
        onUnsubscribe(item)
    }

}
