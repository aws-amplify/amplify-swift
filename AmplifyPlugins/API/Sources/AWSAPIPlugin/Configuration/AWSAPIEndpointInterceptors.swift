//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import AWSPluginsCore

struct AWSAPIEndpointInterceptors {
    // API name
    let apiEndpointName: APIEndpointName

    let apiAuthProviderFactory: APIAuthProviderFactory
    let authService: AWSAuthServiceBehavior?

    var interceptors: [URLRequestInterceptor] = []

    init(endpointName: APIEndpointName,
         apiAuthProviderFactory: APIAuthProviderFactory,
         authService: AWSAuthServiceBehavior? = nil) {
        self.apiEndpointName = endpointName
        self.apiAuthProviderFactory = apiAuthProviderFactory
        self.authService = authService
    }

    /// Registers an interceptor
    /// - Parameter interceptor: operation interceptor used to decorate API requests
    public mutating func addInterceptor(_ interceptor: URLRequestInterceptor) {
        interceptors.append(interceptor)
    }

    /// Initialize authorization interceptors
    mutating func addAuthInterceptorsToEndpoint(endpointType: AWSAPICategoryPluginEndpointType,
                                                authConfiguration: AWSAuthorizationConfiguration) throws {
        switch authConfiguration {
        case .none:
            // No interceptors needed
            break
        case .apiKey(let apiKeyConfig):
            let provider = BasicAPIKeyProvider(apiKey: apiKeyConfig.apiKey)
            let interceptor = APIKeyURLRequestInterceptor(apiKeyProvider: provider)
            addInterceptor(interceptor)
        case .awsIAM(let iamConfig):
            guard let authService = authService else {
                throw PluginError.pluginConfigurationError("AuthService is not set for IAM",
                                                           "")
            }
            let provider = BasicIAMCredentialsProvider(authService: authService)
            let interceptor = IAMURLRequestInterceptor(iamCredentialsProvider: provider,
                                                       region: iamConfig.region,
                                                       endpointType: endpointType)
            addInterceptor(interceptor)
        case .amazonCognitoUserPools:
            guard let authService = authService else {
                throw PluginError.pluginConfigurationError("AuthService not set for cognito user pools",
                                                           "")
            }
            let provider = BasicUserPoolTokenProvider(authService: authService)
            let interceptor = AuthTokenURLRequestInterceptor(authTokenProvider: provider)
            addInterceptor(interceptor)
        case .openIDConnect:
            guard let oidcAuthProvider = apiAuthProviderFactory.oidcAuthProvider() else {
                throw PluginError.pluginConfigurationError("AuthService not set for OIDC",
                                                           "Provide an AmplifyOIDCAuthProvider via API plugin configuration")
            }
            let wrappedAuthProvider = AuthTokenProviderWrapper(tokenAuthProvider: oidcAuthProvider)
            let interceptor = AuthTokenURLRequestInterceptor(authTokenProvider: wrappedAuthProvider)
            addInterceptor(interceptor)
        case .function:
            guard let functionAuthProvider = apiAuthProviderFactory.functionAuthProvider() else {
                throw PluginError.pluginConfigurationError("AuthService not set for function auth",
                                                           "Provide an AmplifyFunctionAuthProvider via API plugin configuration")
            }
            let wrappedAuthProvider = AuthTokenProviderWrapper(tokenAuthProvider: functionAuthProvider)
            let interceptor = AuthTokenURLRequestInterceptor(authTokenProvider: wrappedAuthProvider)
            addInterceptor(interceptor)
        }
    }
}
