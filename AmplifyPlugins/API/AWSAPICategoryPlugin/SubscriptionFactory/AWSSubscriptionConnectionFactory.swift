//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSCore
import AWSPluginsCore
import Amplify
import AppSyncRealTimeClient

class AWSSubscriptionConnectionFactory: SubscriptionConnectionFactory {

    private let concurrencyQueue = DispatchQueue(label: "com.amazonaws.amplify.AWSSubscriptionConnectionFactory",
                                                 target: DispatchQueue.global())

    var apiToConnectionProvider: [String: ConnectionProvider] = [:]

    func getOrCreateConnection(for endpointConfig: AWSAPICategoryPluginConfiguration.EndpointConfig,
                               authService: AWSAuthServiceBehavior) throws -> SubscriptionConnection {
        return try concurrencyQueue.sync {
            let apiName = endpointConfig.name

            let url = endpointConfig.baseURL
            let authInterceptor = try getInterceptor(for: endpointConfig.authorizationConfiguration,
                                                     authService: authService)

            // create or retrieve the connection provider. If creating, add interceptors onto the provider.
            let connectionProvider = apiToConnectionProvider[apiName] ??
                createConnectionProvider(for: url, authInterceptor: authInterceptor, connectionType: .appSyncRealtime)

            // store the connection provider for this api
            apiToConnectionProvider[apiName] = connectionProvider

            // create a subscription connection for subscribing and unsubscribing on the connection provider
            return AppSyncSubscriptionConnection(provider: connectionProvider)
        }
    }

    // MARK: Private methods

    private func getInterceptor(for authorizationConfiguration: AWSAuthorizationConfiguration,
                                authService: AWSAuthServiceBehavior) throws -> AuthInterceptor {
        let authInterceptor: AuthInterceptor

        switch authorizationConfiguration {
        case .apiKey(let apiKeyConfiguration):
            let apiKeyProvider = BasicAPIKeyProvider(apiKey: apiKeyConfiguration.apiKey)
            authInterceptor = APIKeyAuthInterceptor(apiKeyProvider)
        case .amazonCognitoUserPools:
            let userPoolTokenProvider = BasicUserPoolTokenProvider(authService: authService)
            authInterceptor = CognitoUserPoolsAuthInterceptor(userPoolTokenProvider)
        case .awsIAM(let awsIAMConfiguration):
            let iamCredentialsProvider = BasicIAMCredentialsProvider(authService: authService)
            authInterceptor = IAMAuthInterceptor(iamCredentialsProvider, region: awsIAMConfiguration.region)
        case .openIDConnect:
            // TODO: retrieve OIDC Token Provider from somewhere else that the developer added.
            let tokenProvider = BasicUserPoolTokenProvider(authService: authService)
            // TODO: Need to run through OIDC use case to identify what is the Interceptor logic
            authInterceptor = CognitoUserPoolsAuthInterceptor(tokenProvider)
        case .none:
            throw APIError.unknown("Cannot create AppSync subscription for none auth mode", "")
        }

        return authInterceptor
    }

    private func createConnectionProvider(for url: URL, authInterceptor: AuthInterceptor, connectionType: SubscriptionConnectionType) -> ConnectionProvider {
        let provider = createConnectionProvider(for: url, connectionType: connectionType)

        if let messageInterceptable = provider as? MessageInterceptable {
            messageInterceptable.addInterceptor(authInterceptor)
        }
        if let connectionInterceptable = provider as? ConnectionInterceptable {
            connectionInterceptable.addInterceptor(RealtimeGatewayURLInterceptor())
            connectionInterceptable.addInterceptor(authInterceptor)
        }

        return provider
    }

    private func createConnectionProvider(for url: URL, connectionType: SubscriptionConnectionType) -> ConnectionProvider {
        switch connectionType {
        case .appSyncRealtime:
            let websocketProvider = StarscreamAdapter()
            let connectionProvider = RealtimeConnectionProvider(for: url, websocket: websocketProvider)
            return connectionProvider
        }
    }
}
