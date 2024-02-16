//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import Foundation
import Amplify
import Combine
@_spi(AmplifySwift) import AWSPluginsCore

protocol AppSyncRealTimeClientFactoryProtocol {
    func getAppSyncRealTimeClient(
        for endpointConfig: AWSAPICategoryPluginConfiguration.EndpointConfig,
        endpoint: URL,
        authService: AWSAuthServiceBehavior,
        authType: AWSAuthorizationType?,
        apiAuthProviderFactory: APIAuthProviderFactory
    ) async throws -> AppSyncRealTimeClientProtocol
}

protocol AppSyncRealTimeClientProtocol {
    func connect() async throws
    func disconnect() async
    func subscribe(id: String, query: String) async throws -> AnyPublisher<AppSyncSubscriptionEvent, Never>
    func unsubscribe(id: String) async throws
}

actor AppSyncRealTimeClientFactory: AppSyncRealTimeClientFactoryProtocol {
    private struct MapperCacheKey: Hashable {
        let apiName: String
        let authType: AWSAuthorizationType?
    }

    private var apiToClientCache = [MapperCacheKey: AppSyncRealTimeClientProtocol]()

    public func getAppSyncRealTimeClient(
        for endpointConfig: AWSAPICategoryPluginConfiguration.EndpointConfig,
        endpoint: URL,
        authService: AWSAuthServiceBehavior,
        authType: AWSAuthorizationType? = nil,
        apiAuthProviderFactory: APIAuthProviderFactory
    ) throws -> AppSyncRealTimeClientProtocol {
        let apiName = endpointConfig.name

        let authInterceptor = try self.getInterceptor(
            for: self.getOrCreateAuthConfiguration(from: endpointConfig, authType: authType),
            authService: authService,
            apiAuthProviderFactory: apiAuthProviderFactory
        )

        // create or retrieve the connection provider. If creating, add interceptors onto the provider.
        if let appSyncClient = apiToClientCache[MapperCacheKey(apiName: apiName, authType: authType)] {
            return appSyncClient
        } else {
            let appSyncClient = AppSyncRealTimeClient(
                endpoint: endpoint,
                requestInterceptor: authInterceptor,
                webSocketClient: WebSocketClient(
                    url: Self.appSyncRealTimeEndpoint(endpoint),
                    protocols: ["graphql-ws"],
                    interceptor: authInterceptor
                )
            )

            // store the connection provider for this api
            apiToClientCache[MapperCacheKey(apiName: apiName, authType: authType)] = appSyncClient
            // create a subscription connection for subscribing and unsubscribing on the connection provider
            return appSyncClient
        }
    }

    private func getOrCreateAuthConfiguration(
        from endpointConfig: AWSAPICategoryPluginConfiguration.EndpointConfig,
        authType: AWSAuthorizationType?
    ) throws -> AWSAuthorizationConfiguration {
        // create a configuration if there's an override auth type
        if let authType = authType {
            return try endpointConfig.authorizationConfigurationFor(authType: authType)
        }

        return endpointConfig.authorizationConfiguration
    }

    private func getInterceptor(
        for authorizationConfiguration: AWSAuthorizationConfiguration,
        authService: AWSAuthServiceBehavior,
        apiAuthProviderFactory: APIAuthProviderFactory
    ) throws -> AppSyncRequestInterceptor & WebSocketInterceptor {
        switch authorizationConfiguration {
        case .apiKey(let apiKeyConfiguration):
            return APIKeyAuthInterceptor(apiKey: apiKeyConfiguration.apiKey)
        case .amazonCognitoUserPools:
            let provider = AWSOIDCAuthProvider(authService: authService)
            return CognitoAuthInterceptor(getLatestAuthToken: provider.getLatestAuthToken)
        case .awsIAM(let awsIAMConfiguration):
            return IAMAuthInterceptor(authService.getCredentialsProvider(),
                                                 region: awsIAMConfiguration.region)
        case .openIDConnect:
            guard let oidcAuthProvider = apiAuthProviderFactory.oidcAuthProvider() else {
                throw APIError.invalidConfiguration(
                    "Using openIDConnect requires passing in an APIAuthProvider with an OIDC AuthProvider",
                    "When instantiating AWSAPIPlugin pass in an instance of APIAuthProvider", nil)
            }
            return CognitoAuthInterceptor(getLatestAuthToken: oidcAuthProvider.getLatestAuthToken)
        case .function:
            guard let functionAuthProvider = apiAuthProviderFactory.functionAuthProvider() else {
                throw APIError.invalidConfiguration(
                    "Using function as auth provider requires passing in an APIAuthProvider with a Function AuthProvider",
                    "When instantiating AWSAPIPlugin pass in an instance of APIAuthProvider", nil)
            }
            return CognitoAuthInterceptor(authTokenProvider: functionAuthProvider)
        case .none:
            throw APIError.unknown("Cannot create AppSync subscription for none auth mode", "")
        }
    }
}


extension AppSyncRealTimeClientFactory {
    static func appSyncRealTimeEndpoint(_ url: URL) -> URL {
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

}
