//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation
import AWSCore
import AWSPluginsCore

/// Protocol for the subscription factory
protocol SubscriptionConnectionFactory {

    /// Get connection based on the connection type
    /// - Parameter connectionType:
    func connection(endpointConfiguration: AWSAPICategoryPluginConfiguration.EndpointConfig,
                    authService: AWSAuthServiceBehavior) -> SubscriptionConnection?
}

protocol SubscriptionConnectionPool {
    func connection(for url: URL) -> SubscriptionConnection
}

class BasicSubscriptionConnectionFactory: SubscriptionConnectionFactory {

    private var apiKeyBasedConnectionPool: APIKeyBasedConnectionPool?
    private var userPoolsBasedConnectionPool: UserPoolsBasedConnectionPool?
    private var iamBasedConnectionPool: IAMBasedConnectionPool?
    private var oidcBasedConnectionPool: OIDCBasedConnectionPool?

    let retryStrategy: AWSAppSyncRetryStrategy

    init() {
        self.retryStrategy = .exponential
    }

    func connection(endpointConfiguration: AWSAPICategoryPluginConfiguration.EndpointConfig,
                    authService: AWSAuthServiceBehavior) -> SubscriptionConnection? {

        let pool: SubscriptionConnectionPool

        switch endpointConfiguration.authorizationConfiguration {
        case .apiKey(let apiKeyConfiguration):
            let apiKeyProvider = BasicAPIKeyProvider(apiKey: apiKeyConfiguration.apiKey)
            pool = getOrCreateAPIKeyBasedConnectionPool(apiKeyProvider: apiKeyProvider)
        case .amazonCognitoUserPools:
            let userPoolAuthTokenProvider = BasicUserPoolTokenProvider(authService: authService)
            pool = getOrCreateUserPoolsBasedConnectionPool(userPoolAuthTokenProvider: userPoolAuthTokenProvider)
        case .awsIAM(let awsIAMConfiguration):
            let iamCredentialsProvider = BasicIAMCredentialsProvider(authService: authService)
            pool = getOrCreateIAMBasedConnectionPool(iamCredentialsProvider: iamCredentialsProvider,
                                                     region: awsIAMConfiguration.region)
        case .openIDConnect:
            // TODO: retrieve OIDC Token Provider from somewhere else that the developer added.
            let oidcAuthTokenProvider = BasicUserPoolTokenProvider(authService: authService)
            pool = getOrCreateOIDCBasedConnectionPool(authTokenProvider: oidcAuthTokenProvider)
        case .none:
            return nil
        }

        return pool.connection(for: endpointConfiguration.baseURL)
    }

    func getOrCreateAPIKeyBasedConnectionPool(apiKeyProvider: APIKeyProvider) -> APIKeyBasedConnectionPool {
        if let apiKeyBasedConnectionPool = apiKeyBasedConnectionPool {
            return apiKeyBasedConnectionPool
        } else {
            let apiKeyBasedConnectionPool = APIKeyBasedConnectionPool(apiKeyProvider)
            self.apiKeyBasedConnectionPool = apiKeyBasedConnectionPool
            return apiKeyBasedConnectionPool
        }
    }
    func getOrCreateUserPoolsBasedConnectionPool(userPoolAuthTokenProvider: BasicUserPoolTokenProvider) ->
        UserPoolsBasedConnectionPool {
        if let userPoolsBasedConnectionPool = userPoolsBasedConnectionPool {
            return userPoolsBasedConnectionPool
        } else {
            let userPoolsBasedConnectionPool = UserPoolsBasedConnectionPool(userPoolAuthTokenProvider)
            self.userPoolsBasedConnectionPool = userPoolsBasedConnectionPool
            return userPoolsBasedConnectionPool
        }
    }

    func getOrCreateIAMBasedConnectionPool(iamCredentialsProvider: BasicIAMCredentialsProvider,
                                           region: AWSRegionType) -> IAMBasedConnectionPool {
        if let iamBasedConnectionPool = iamBasedConnectionPool {
            return iamBasedConnectionPool
        } else {
            let iamBasedConnectionPool = IAMBasedConnectionPool(iamCredentialsProvider, region: region)
            self.iamBasedConnectionPool = iamBasedConnectionPool
            return iamBasedConnectionPool
        }
    }

    func getOrCreateOIDCBasedConnectionPool(authTokenProvider: AuthTokenProvider) -> OIDCBasedConnectionPool {
        if let oidcBasedConnectionPool = oidcBasedConnectionPool {
            return oidcBasedConnectionPool
        } else {
            let oidcBasedConnectionPool = OIDCBasedConnectionPool(authTokenProvider)
            self.oidcBasedConnectionPool = oidcBasedConnectionPool
            return oidcBasedConnectionPool
        }
    }
}
