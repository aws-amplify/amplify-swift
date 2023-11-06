//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import AWSPluginsCore

/// The order of interceptor decoration is as follows:
/// 1. **prelude interceptors**
/// 2. **cutomize headers**
/// 3. **customer interceptors**
/// 4. **postlude interceptors**
///
/// **Prelude** and **postlude** interceptors are used by library maintainers to
/// integrate essential functionality for a variety of authentication types.
struct AWSAPIEndpointInterceptors {
    // API name
    let apiEndpointName: APIEndpointName

    let apiAuthProviderFactory: APIAuthProviderFactory
    let authService: AWSAuthServiceBehavior?

    var preludeInterceptors: [URLRequestInterceptor] = []

    var interceptors: [URLRequestInterceptor] = []

    var postludeInterceptors: [URLRequestInterceptor] = []

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
            preludeInterceptors.append(interceptor)
        case .awsIAM(let iamConfig):
            guard let authService = authService else {
                throw PluginError.pluginConfigurationError("AuthService is not set for IAM",
                                                           "")
            }
            let provider = BasicIAMCredentialsProvider(authService: authService)
            let interceptor = IAMURLRequestInterceptor(iamCredentialsProvider: provider,
                                                       region: iamConfig.region,
                                                       endpointType: endpointType)
            postludeInterceptors.append(interceptor)
        case .amazonCognitoUserPools:
            guard let authService = authService else {
                throw PluginError.pluginConfigurationError("AuthService not set for cognito user pools",
                                                           "")
            }
            let provider = BasicUserPoolTokenProvider(authService: authService)
            let interceptor = AuthTokenURLRequestInterceptor(authTokenProvider: provider)
            preludeInterceptors.append(interceptor)
        case .openIDConnect:
            guard let oidcAuthProvider = apiAuthProviderFactory.oidcAuthProvider() else {
                throw PluginError.pluginConfigurationError("AuthService not set for OIDC",
                                                           "Provide an AmplifyOIDCAuthProvider via API plugin configuration")
            }
            let wrappedAuthProvider = AuthTokenProviderWrapper(tokenAuthProvider: oidcAuthProvider)
            let interceptor = AuthTokenURLRequestInterceptor(authTokenProvider: wrappedAuthProvider)
            preludeInterceptors.append(interceptor)
        case .function:
            guard let functionAuthProvider = apiAuthProviderFactory.functionAuthProvider() else {
                throw PluginError.pluginConfigurationError("AuthService not set for function auth",
                                                           "Provide an AmplifyFunctionAuthProvider via API plugin configuration")
            }
            let wrappedAuthProvider = AuthTokenProviderWrapper(tokenAuthProvider: functionAuthProvider)
            let interceptor = AuthTokenURLRequestInterceptor(authTokenProvider: wrappedAuthProvider)
            preludeInterceptors.append(interceptor)
        }
    }
}
