//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSCore
import AWSPluginsCore
import Amplify

class AWSSubscriptionConnectionFactory: SubscriptionConnectionFactory {
    private let concurrencyQueue = DispatchQueue(label: "com.amazonaws.amplify.AWSSubscriptionConnectionFactory",
                                                 target: DispatchQueue.global())

    let retryStrategy: AWSAppSyncRetryStrategy
    var apiToSubscriptionConnections: [String: SubscriptionConnection] = [:]

    init(retryStrategy: AWSAppSyncRetryStrategy = .exponential) {
        self.retryStrategy = retryStrategy
    }

    func getOrCreateConnection(for endpointConfig: AWSAPICategoryPluginConfiguration.EndpointConfig,
                               authService: AWSAuthServiceBehavior) throws -> SubscriptionConnection {
        return try concurrencyQueue.sync {
            let apiName = endpointConfig.name
            if let connection = apiToSubscriptionConnections[apiName] {
                return connection
            }

            let url = endpointConfig.baseURL
            let interceptor = try getInterceptor(for: endpointConfig.authorizationConfiguration,
                                                 authService: authService)
            let connection = AppSyncSubscriptionConnection(url: url, interceptor: interceptor)

            apiToSubscriptionConnections[apiName] = connection
            return connection
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
}
