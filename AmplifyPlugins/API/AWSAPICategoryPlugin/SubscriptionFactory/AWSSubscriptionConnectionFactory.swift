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
                               authService: AWSAuthServiceBehavior,
                               apiAuthProviderFactory: APIAuthProviderFactory) throws -> SubscriptionConnection {
        return try concurrencyQueue.sync {
            let apiName = endpointConfig.name

            let url = endpointConfig.baseURL
            let authInterceptor = try getInterceptor(for: endpointConfig.authorizationConfiguration,
                                                     authService: authService,
                                                     apiAuthProviderFactory: apiAuthProviderFactory)

            // create or retrieve the connection provider. If creating, add interceptors onto the provider.
            let connectionProvider = apiToConnectionProvider[apiName] ??
                ConnectionProviderFactory.createConnectionProvider(for: url,
                                                                   authInterceptor: authInterceptor,
                                                                   connectionType: .appSyncRealtime)

            // store the connection provider for this api
            apiToConnectionProvider[apiName] = connectionProvider

            // create a subscription connection for subscribing and unsubscribing on the connection provider
            return AppSyncSubscriptionConnection(provider: connectionProvider)
        }
    }

    // MARK: Private methods

    private func getInterceptor(for authorizationConfiguration: AWSAuthorizationConfiguration,
                                authService: AWSAuthServiceBehavior,
                                apiAuthProviderFactory: APIAuthProviderFactory) throws -> AuthInterceptor {
        let authInterceptor: AuthInterceptor

        switch authorizationConfiguration {
        case .apiKey(let apiKeyConfiguration):
            authInterceptor = APIKeyAuthInterceptor(apiKeyConfiguration.apiKey)
        case .amazonCognitoUserPools:
            let provider = AWSOIDCAuthProvider(authService: authService)
            authInterceptor = OIDCAuthInterceptor(provider)
        case .awsIAM(let awsIAMConfiguration):
            authInterceptor = IAMAuthInterceptor(authService.getCredentialsProvider(),
                                                 region: awsIAMConfiguration.region)
        case .openIDConnect:
            guard let oidcAuthProvider = apiAuthProviderFactory.oidcAuthProvider() else {
                throw APIError.invalidConfiguration("Using openIDConnect requires passing in an APIAuthProvider with an OIDC AuthProvider",
                                                    "When instantiating AWSAPIPlugin pass in an instance of APIAuthProvider",
                                                    nil)
            }
            let wrappedProvider = OIDCAuthProviderWrapper(oidcAuthProvider: oidcAuthProvider)
            authInterceptor = OIDCAuthInterceptor(wrappedProvider)
        case .none:
            throw APIError.unknown("Cannot create AppSync subscription for none auth mode", "")
        }

        return authInterceptor
    }
}
