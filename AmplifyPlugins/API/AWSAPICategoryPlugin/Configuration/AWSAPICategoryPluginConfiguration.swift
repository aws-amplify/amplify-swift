//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import AWSPluginsCore

public struct AWSAPICategoryPluginConfiguration {
    typealias APIEndpointName = String

    var endpoints: [APIEndpointName: EndpointConfig]
    private var interceptors: [APIEndpointName: EndpointInterceptorsConfig]

    private var apiAuthProviderFactory: APIAuthProviderFactory?
    private var authService: AWSAuthServiceBehavior?

    internal init(endpoints: [APIEndpointName: EndpointConfig],
                  interceptors: [APIEndpointName: EndpointInterceptorsConfig] = [:]) {
        self.endpoints = endpoints
        self.interceptors = interceptors
    }

    init(jsonValue: JSONValue,
         apiAuthProviderFactory: APIAuthProviderFactory,
         authService: AWSAuthServiceBehavior) throws {
        guard case .object(let config) = jsonValue else {
            throw PluginError.pluginConfigurationError(
                "Could not cast incoming configuration to a JSONValue `.object`",
                """
                The specified configuration is not convertible to a JSONValue. Review the configuration and ensure it \
                contains the expected values, and does not use any types that aren't convertible to a corresponding \
                JSONValue:
                \(jsonValue)
                """
            )
        }

        let endpoints = try AWSAPICategoryPluginConfiguration.endpointsFromConfig(config: config,
                                                                                  apiAuthProviderFactory: apiAuthProviderFactory,
                                                                                  authService: authService)
        let interceptors = try AWSAPICategoryPluginConfiguration.interceptorsForEndpoints(endpoints,
                                                     apiAuthProviderFactory: apiAuthProviderFactory,
                                                     authService: authService)

        self.init(endpoints: endpoints, interceptors: interceptors)

        self.apiAuthProviderFactory = apiAuthProviderFactory
        self.authService = authService

    }

    /// Registers an interceptor for the provided API endpoint
    /// - Parameter interceptor: operation interceptor used to decorate API requests
    /// - Parameter toEndpoint: API endpoint name
    mutating func addInterceptor(_ interceptor: URLRequestInterceptor,
                                 toEndpoint apiName: APIEndpointName) {
        interceptors[apiName]?.addInterceptor(interceptor)
    }

    /// Returns all the interceptors registered for `apiName` API endpoint
    /// - Parameter apiName: API endpoint name
    /// - Returns: request interceptors
    internal func interceptorsForEndpoint(named apiName: APIEndpointName?) -> [URLRequestInterceptor] {
        guard let apiName = apiName, let interceptorsConfig = interceptors[apiName] else {
            return []
        }
        return interceptorsConfig.interceptors
    }

    /// Returns or create interceptors for the provided endpointConfig
    /// - Parameters:
    ///   - endpointConfig: endpoint configuration
    ///   - authType: if provided override the registered auth interceptor
    /// - Throws: PluginConfigurationError in case of failure building an instance of AWSAuthorizationConfiguration
    /// - Returns: An array of URLRequestInterceptor
    internal func interceptorsForEndpoint(withConfig endpointConfig: EndpointConfig,
                                          authType: AWSAuthorizationType? = nil) throws -> [URLRequestInterceptor] {

        guard let authType = authType, let apiAuthProviderFactory = self.apiAuthProviderFactory else {
            return interceptorsForEndpoint(named: endpointConfig.name)
        }

        var config = EndpointInterceptorsConfig(endpointName: endpointConfig.name,
                                                apiAuthProviderFactory: apiAuthProviderFactory,
                                                authService: authService)
        let authConfiguration = try AWSAuthorizationConfiguration.makeConfiguration(authType: authType,
                                                                       region: endpointConfig.region,
                                                                       apiKey: endpointConfig.apiKey)
        try config.addAuthInterceptorsToEndpoint(endpointType: endpointConfig.endpointType,
                                                 authConfiguration: authConfiguration)

        // retrieve current interceptors and replace auth interceptor
        let currentInterceptors = interceptorsForEndpoint(named: endpointConfig.name).filter {
            !isAuthInterceptor($0)
        }
        config.interceptors.append(contentsOf: currentInterceptors)

        return config.interceptors
    }

    // MARK: Private


    /// Returns true if the provided interceptor is an auth interceptor
    /// - Parameter interceptor: interceptors
    private func isAuthInterceptor(_ interceptor: URLRequestInterceptor) -> Bool {
        return interceptor as? APIKeyURLRequestInterceptor != nil ||
            interceptor as? UserPoolURLRequestInterceptor != nil ||
            interceptor as? IAMURLRequestInterceptor != nil
    }

    private static func endpointsFromConfig(
        config: [String: JSONValue],
        apiAuthProviderFactory: APIAuthProviderFactory,
        authService: AWSAuthServiceBehavior
    ) throws -> [APIEndpointName: EndpointConfig] {
        var endpoints = [APIEndpointName: EndpointConfig]()

        for (key, jsonValue) in config {
            let name = key
            let endpointConfig = try EndpointConfig(name: name,
                                                    jsonValue: jsonValue,
                                                    apiAuthProviderFactory: apiAuthProviderFactory,
                                                    authService: authService)
            endpoints[name] = endpointConfig
        }

        return endpoints
    }

    /// Given a dictionary of EndpointConfig indexed by API endpoint name, builds a dictionary of EndpointInterceptorsConfig
    /// - Parameters:
    ///   - endpoints: dictionary of EndpointConfig
    ///   - apiAuthProviderFactory: apiAuthProviderFactory
    ///   - authService: authService
    /// - Throws:
    /// - Returns: dictionary of EndpointInterceptorsConfig indexed by API endpoint name
    private static func interceptorsForEndpoints(_ endpoints: [APIEndpointName: EndpointConfig],
                                                 apiAuthProviderFactory: APIAuthProviderFactory,
                                                 authService: AWSAuthServiceBehavior) throws -> [APIEndpointName: EndpointInterceptorsConfig] {
        var interceptors: [APIEndpointName: EndpointInterceptorsConfig] = [:]
        for (name, config) in endpoints {
            var interceptorsConfig = EndpointInterceptorsConfig(endpointName: name,
                               apiAuthProviderFactory: apiAuthProviderFactory,
                               authService: authService)
            try interceptorsConfig.addAuthInterceptorsToEndpoint(endpointType: config.endpointType,
                                                                 authConfiguration: config.authorizationConfiguration)
            interceptors[name] = interceptorsConfig
        }

        return interceptors
    }
}
