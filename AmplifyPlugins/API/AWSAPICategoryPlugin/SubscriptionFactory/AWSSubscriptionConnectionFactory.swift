//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSCore
import AWSPluginsCore
import Amplify
import AppSyncRealTimeClient

class AWSSubscriptionConnectionFactory: SubscriptionConnectionFactory {
    /// Key used to map an API to a ConnectionProvider
    private struct MapperCacheKey: Hashable {
        let apiName: String
        let authType: AWSAuthorizationType?
    }

    private let concurrencyQueue = DispatchQueue(label: "com.amazonaws.amplify.AWSSubscriptionConnectionFactory",
                                                 target: DispatchQueue.global())

    private var apiToConnectionProvider: [MapperCacheKey: ConnectionProvider] = [:]

    func getOrCreateConnection(for endpointConfig: AWSAPICategoryPluginConfiguration.EndpointConfig,
                               urlRequest: URLRequest,
                               authService: AWSAuthServiceBehavior,
                               authType: AWSAuthorizationType? = nil,
                               apiAuthProviderFactory: APIAuthProviderFactory) throws -> SubscriptionConnection {
        return try concurrencyQueue.sync {
            let apiName = endpointConfig.name

            let authInterceptor = try self.getInterceptor(for: self.getOrCreateAuthConfiguration(from: endpointConfig,
                                                                                       authType: authType),
                                                     authService: authService,
                                                     apiAuthProviderFactory: apiAuthProviderFactory)

            // create or retrieve the connection provider. If creating, add interceptors onto the provider.
            let connectionProvider = apiToConnectionProvider[MapperCacheKey(apiName: apiName, authType: authType)] ??
            ConnectionProviderFactory.createConnectionProvider(for: urlRequest,
                                                                   authInterceptor: authInterceptor,
                                                                   connectionType: .appSyncRealtime)

            // store the connection provider for this api
            apiToConnectionProvider[MapperCacheKey(apiName: apiName, authType: authType)] = connectionProvider

            // create a subscription connection for subscribing and unsubscribing on the connection provider
            return AppSyncSubscriptionConnection(provider: connectionProvider)
        }
    }

    // MARK: Private methods

    private func getOrCreateAuthConfiguration(from endpointConfig: AWSAPICategoryPluginConfiguration.EndpointConfig,
                                              authType: AWSAuthorizationType?) throws -> AWSAuthorizationConfiguration {
        // create a configuration if there's an override auth type
        if let authType = authType {
            return try endpointConfig.authorizationConfigurationFor(authType: authType)
        }

        return endpointConfig.authorizationConfiguration
    }

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
                throw APIError.invalidConfiguration(
                    "Using openIDConnect requires passing in an APIAuthProvider with an OIDC AuthProvider",
                    "When instantiating AWSAPIPlugin pass in an instance of APIAuthProvider", nil)
            }
            let wrappedProvider = OIDCAuthProviderWrapper(authTokenProvider: oidcAuthProvider)
            authInterceptor = OIDCAuthInterceptor(wrappedProvider)
        case .function:
            guard let functionAuthProvider = apiAuthProviderFactory.functionAuthProvider() else {
                throw APIError.invalidConfiguration(
                    "Using function as auth provider requires passing in an APIAuthProvider with a Function AuthProvider",
                    "When instantiating AWSAPIPlugin pass in an instance of APIAuthProvider", nil)
            }
            authInterceptor = AuthenticationTokenAuthInterceptor(authTokenProvider: functionAuthProvider)
        case .none:
            throw APIError.unknown("Cannot create AppSync subscription for none auth mode", "")
        }

        return authInterceptor
    }
}
