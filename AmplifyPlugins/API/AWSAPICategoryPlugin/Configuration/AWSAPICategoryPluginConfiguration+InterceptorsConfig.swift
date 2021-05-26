//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import AWSPluginsCore
import AWSCore


public extension AWSAPICategoryPluginConfiguration {
    typealias APIEndpointName = String
    
    struct InterceptorsConfig {
        let apiAuthProviderFactory: APIAuthProviderFactory
        let authService: AWSAuthServiceBehavior?
        
        var interceptors: [APIEndpointName: [URLRequestInterceptor]] = [:]
        
        init(apiAuthProviderFactory: APIAuthProviderFactory,
             authService: AWSAuthServiceBehavior? = nil) {
            self.apiAuthProviderFactory = apiAuthProviderFactory
            self.authService = authService
        }
        
        /// Registers an interceptor for the provided API endpoint
        /// - Parameter interceptor: operation interceptor used to decorate API requests
        /// - Parameter toEndpoint: API endpoint name
        public mutating func addInterceptor(_ interceptor: URLRequestInterceptor,
                                            toEndpoint apiName: APIEndpointName) {
            self.interceptors[apiName]?.append(interceptor)
        }
        
        
        /// Returns all the interceptors registered for `apiName` API endpoint
        /// - Parameter apiName: API endpoint name
        /// - Returns: request interceptors
        public func interceptorsForEndpoint(named apiName: APIEndpointName) -> [URLRequestInterceptor] {
            guard let interceptors = interceptors[apiName] else {
                return []
            }
            return interceptors
        }
        

        /// Initialize authorization interceptors
        mutating func addAuthInterceptorsToEndpoint(named apiName: APIEndpointName,
                                                           ofType endpointType: AWSAPICategoryPluginEndpointType,
                                                           authConfiguration: AWSAuthorizationConfiguration) throws {
            switch authConfiguration {
            case .none:
                // No interceptors needed
                break
            case .apiKey(let apiKeyConfig):
                let provider = BasicAPIKeyProvider(apiKey: apiKeyConfig.apiKey)
                let interceptor = APIKeyURLRequestInterceptor(apiKeyProvider: provider)
                addInterceptor(interceptor, toEndpoint: apiName)
            case .awsIAM(let iamConfig):
                guard let authService = authService else {
                    throw PluginError.pluginConfigurationError("AuthService is not set for IAM",
                                                               "")
                }
                let provider = BasicIAMCredentialsProvider(authService: authService)
                let interceptor = IAMURLRequestInterceptor(iamCredentialsProvider: provider,
                                                           region: iamConfig.region,
                                                           endpointType: endpointType)
                addInterceptor(interceptor, toEndpoint: apiName)
            case .amazonCognitoUserPools:
                guard let authService = authService else {
                    throw PluginError.pluginConfigurationError("AuthService not set for cognito user pools",
                                                               "")
                }
                let provider = BasicUserPoolTokenProvider(authService: authService)
                let interceptor = UserPoolURLRequestInterceptor(userPoolTokenProvider: provider)
                addInterceptor(interceptor, toEndpoint: apiName)
            case .openIDConnect:
                guard let oidcAuthProvider = apiAuthProviderFactory.oidcAuthProvider() else {
                    return
                }
                let wrappedAuthProvider = AuthTokenProviderWrapper(oidcAuthProvider: oidcAuthProvider)
                let interceptor = UserPoolURLRequestInterceptor(userPoolTokenProvider: wrappedAuthProvider)
                addInterceptor(interceptor, toEndpoint: apiName)
            }
        }
    }
}
