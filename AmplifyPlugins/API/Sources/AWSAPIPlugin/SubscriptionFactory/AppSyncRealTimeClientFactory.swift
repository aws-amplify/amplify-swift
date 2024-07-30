//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import Foundation
import Amplify
import Combine
import InternalAmplifyCredentials
@_spi(WebSocket) import AWSPluginsCore

protocol AppSyncRealTimeClientFactoryProtocol {
    func getAppSyncRealTimeClient(
        for endpointConfig: AWSAPICategoryPluginConfiguration.EndpointConfig,
        endpoint: URL,
        authService: AWSAuthCredentialsProviderBehavior,
        authType: AWSAuthorizationType?,
        apiAuthProviderFactory: APIAuthProviderFactory
    ) async throws -> AppSyncRealTimeClientProtocol
}

protocol AppSyncRealTimeClientProtocol {
    func connect() async throws
    func disconnectWhenIdel() async
    func disconnect() async
    func subscribe(id: String, query: String) async throws -> AnyPublisher<AppSyncSubscriptionEvent, Never>
    func unsubscribe(id: String) async throws
}

actor AppSyncRealTimeClientFactory: AppSyncRealTimeClientFactoryProtocol {
    struct MapperCacheKey: Hashable {
        let apiName: String
        let authType: AWSAuthorizationType?
    }

    public private(set) var apiToClientCache = [MapperCacheKey: AppSyncRealTimeClientProtocol]()

    public func getAppSyncRealTimeClient(
        for endpointConfig: AWSAPICategoryPluginConfiguration.EndpointConfig,
        endpoint: URL,
        authService: AWSAuthCredentialsProviderBehavior,
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
                    handshakeHttpHeaders: [
                        URLRequestConstants.Header.webSocketSubprotocols: "graphql-ws",
                        URLRequestConstants.Header.userAgent: AmplifyAWSServiceConfiguration.userAgentLib
                    ],
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
        authService: AWSAuthCredentialsProviderBehavior,
        apiAuthProviderFactory: APIAuthProviderFactory
    ) throws -> AppSyncRequestInterceptor & WebSocketInterceptor {
        switch authorizationConfiguration {
        case .apiKey(let apiKeyConfiguration):
            return APIKeyAuthInterceptor(apiKey: apiKeyConfiguration.apiKey)
        case .amazonCognitoUserPools:
            let provider = AWSOIDCAuthProvider(authService: authService)
            return AuthTokenInterceptor(getLatestAuthToken: provider.getLatestAuthToken)
        case .awsIAM(let awsIAMConfiguration):
            return IAMAuthInterceptor(authService.getCredentialsProvider(),
                                                 region: awsIAMConfiguration.region)
        case .openIDConnect:
            guard let oidcAuthProvider = apiAuthProviderFactory.oidcAuthProvider() else {
                throw APIError.invalidConfiguration(
                    "Using openIDConnect requires passing in an APIAuthProvider with an OIDC AuthProvider",
                    "When instantiating AWSAPIPlugin pass in an instance of APIAuthProvider", nil)
            }
            return AuthTokenInterceptor(getLatestAuthToken: oidcAuthProvider.getLatestAuthToken)
        case .function:
            guard let functionAuthProvider = apiAuthProviderFactory.functionAuthProvider() else {
                throw APIError.invalidConfiguration(
                    "Using function as auth provider requires passing in an APIAuthProvider with a Function AuthProvider",
                    "When instantiating AWSAPIPlugin pass in an instance of APIAuthProvider", nil)
            }
            return AuthTokenInterceptor(authTokenProvider: functionAuthProvider)
        case .none:
            throw APIError.unknown("Cannot create AppSync subscription for none auth mode", "")
        }
    }
}


extension AppSyncRealTimeClientFactory {

    /**
     Converting appsync api url to realtime api url
     1. api.example.com/graphql -> api.example.com/graphql/realtime
     2. abc.appsync-api.us-east-1.amazonaws.com/graphql -> abc.appsync-realtime-api.us-east-1.amazonaws.com/graphql
     */
    static func appSyncRealTimeEndpoint(_ url: URL) -> URL {
        guard let host = url.host else {
            return url
        }

        guard host.hasSuffix("amazonaws.com") else {
            return url.appendingPathComponent("realtime")
        }

        guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url
        }

        urlComponents.host = host.replacingOccurrences(of: "appsync-api", with: "appsync-realtime-api")
        guard let realTimeUrl = urlComponents.url else {
            return url
        }

        return realTimeUrl
    }

    /**
     Converting appsync realtime api url to api url
     1. api.example.com/graphql/realtime -> api.example.com/graphql
     2. abc.appsync-realtime-api.us-east-1.amazonaws.com/graphql -> abc.appsync-api.us-east-1.amazonaws.com/graphql
     */
    static func appSyncApiEndpoint(_ url: URL) -> URL {
        guard let host = url.host else {
            return url
        }

        guard host.hasSuffix("amazonaws.com") else {
            if url.lastPathComponent == "realtime" {
                return url.deletingLastPathComponent()
            }
            return url
        }

        guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url
        }

        urlComponents.host = host.replacingOccurrences(of: "appsync-realtime-api", with: "appsync-api")
        guard let apiUrl = urlComponents.url else {
            return url
        }
        return apiUrl
    }
}

extension AppSyncRealTimeClientFactory: Resettable {
    func reset() async {
        await withTaskGroup(of: Void.self) { taskGroup in
            self.apiToClientCache.values
                .compactMap { $0 as? Resettable }
                .forEach { resettable in
                    taskGroup.addTask { await resettable.reset()}
                }
            await taskGroup.waitForAll()
        }
    }
}
