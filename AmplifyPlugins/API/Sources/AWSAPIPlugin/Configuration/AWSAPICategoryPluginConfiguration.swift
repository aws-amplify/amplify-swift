//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import AWSPluginsCore

// Convenience typealias
typealias APIEndpointName = String

public struct AWSAPICategoryPluginConfiguration {
    var endpoints: [APIEndpointName: EndpointConfig]
    private var interceptors: [APIEndpointName: AWSAPIEndpointInterceptors]

    private var apiAuthProviderFactory: APIAuthProviderFactory?
    private var authService: AWSAuthServiceBehavior?

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
        let interceptors = try AWSAPICategoryPluginConfiguration.makeInterceptors(forEndpoints: endpoints,
                                                                                  apiAuthProviderFactory: apiAuthProviderFactory,
                                                                                  authService: authService)

        self.init(endpoints: endpoints,
                  interceptors: interceptors,
                  apiAuthProviderFactory: apiAuthProviderFactory,
                  authService: authService)

    }

    /// Used for testing
    /// - Parameters:
    ///   - endpoints: dictionary of EndpointConfig whose keys are the API endpoint name
    ///   - interceptors: dictionary of AWSAPIEndpointInterceptors whose keys are the API endpoint name
    internal init(endpoints: [APIEndpointName: EndpointConfig],
                  interceptors: [APIEndpointName: AWSAPIEndpointInterceptors] = [:]) {
        self.endpoints = endpoints
        self.interceptors = interceptors
    }

    /// Used for testing
    /// - Parameters:
    ///   - endpoints: dictionary of EndpointConfig whose keys are the API endpoint name
    ///   - interceptors: dictionary of AWSAPIEndpointInterceptors whose keys are the API endpoint name
    internal init(endpoints: [APIEndpointName: EndpointConfig],
                  interceptors: [APIEndpointName: AWSAPIEndpointInterceptors] = [:],
                  apiAuthProviderFactory: APIAuthProviderFactory,
                  authService: AWSAuthServiceBehavior) {
        self.endpoints = endpoints
        self.interceptors = interceptors
        self.apiAuthProviderFactory = apiAuthProviderFactory
        self.authService = authService
    }

    /// Registers an customer interceptor for the provided API endpoint
    /// - Parameter interceptor: operation interceptor used to decorate API requests
    /// - Parameter toEndpoint: API endpoint name
    mutating func addInterceptor(_ interceptor: URLRequestInterceptor,
                                 toEndpoint apiName: APIEndpointName) {
        guard interceptors[apiName] != nil else {
            log.error("No interceptors configuration found for \(apiName)")
            return
        }
        interceptors[apiName]?.addInterceptor(interceptor)
    }

    /// Returns all the interceptors registered for `apiName` API endpoint
    /// - Parameter apiName: API endpoint name
    /// - Returns: Optional AWSAPIEndpointInterceptors for the apiName
    internal func interceptorsForEndpoint(named apiName: APIEndpointName) -> AWSAPIEndpointInterceptors? {
        return interceptors[apiName]
    }

    /// Returns the interceptors for the provided endpointConfig
    /// - Parameters:
    ///   - endpointConfig: endpoint configuration
    /// - Returns: Optional AWSAPIEndpointInterceptors for the endpointConfig
    internal func interceptorsForEndpoint(withConfig endpointConfig: EndpointConfig) -> AWSAPIEndpointInterceptors? {
        return interceptorsForEndpoint(named: endpointConfig.name)
    }

    /// Returns or create interceptors for the provided endpointConfig
    /// - Parameters:
    ///   - endpointConfig: endpoint configuration
    ///   - authType: overrides the registered auth interceptor
    /// - Throws: PluginConfigurationError in case of failure building an instance of AWSAuthorizationConfiguration
    /// - Returns: Optional AWSAPIEndpointInterceptors for the endpointConfig and authType
    internal func interceptorsForEndpoint(
        withConfig endpointConfig: EndpointConfig,
        authType: AWSAuthorizationType
    ) throws -> AWSAPIEndpointInterceptors? {

        guard let apiAuthProviderFactory = self.apiAuthProviderFactory else {
            return interceptorsForEndpoint(named: endpointConfig.name)
        }

        var config = AWSAPIEndpointInterceptors(endpointName: endpointConfig.name,
                                                apiAuthProviderFactory: apiAuthProviderFactory,
                                                authService: authService)
        let authConfiguration = try AWSAuthorizationConfiguration.makeConfiguration(authType: authType,
                                                                       region: endpointConfig.region,
                                                                       apiKey: endpointConfig.apiKey)
        try config.addAuthInterceptorsToEndpoint(endpointType: endpointConfig.endpointType,
                                                 authConfiguration: authConfiguration)

        // retrieve current interceptors and replace auth interceptor
        let currentInterceptors = interceptorsForEndpoint(named: endpointConfig.name)
        config.interceptors.append(contentsOf: currentInterceptors?.interceptors ?? [])

        return config
    }

    // MARK: Private

    /// Returns true if the provided interceptor is an auth interceptor
    /// - Parameter interceptor: interceptors
    private func isAuthInterceptor(_ interceptor: URLRequestInterceptor) -> Bool {
        return interceptor as? APIKeyURLRequestInterceptor != nil ||
            interceptor as? AuthTokenURLRequestInterceptor != nil ||
            interceptor as? IAMURLRequestInterceptor != nil
    }

    // MARK: Private
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

    /// Given a dictionary of EndpointConfig indexed by API endpoint name,
    /// builds a dictionary of AWSAPIEndpointInterceptors.
    /// - Parameters:
    ///   - forEndpoints: dictionary of EndpointConfig
    ///   - apiAuthProviderFactory: apiAuthProviderFactory
    ///   - authService: authService
    /// - Throws:
    /// - Returns: dictionary of AWSAPIEndpointInterceptors indexed by API endpoint name
    private static func makeInterceptors(forEndpoints endpoints: [APIEndpointName: EndpointConfig],
                                         apiAuthProviderFactory: APIAuthProviderFactory,
                                         authService: AWSAuthServiceBehavior) throws -> [APIEndpointName: AWSAPIEndpointInterceptors] {
        var interceptors: [APIEndpointName: AWSAPIEndpointInterceptors] = [:]
        for (name, config) in endpoints {
            var interceptorsConfig = AWSAPIEndpointInterceptors(endpointName: name,
                               apiAuthProviderFactory: apiAuthProviderFactory,
                               authService: authService)
            try interceptorsConfig.addAuthInterceptorsToEndpoint(endpointType: config.endpointType,
                                                                 authConfiguration: config.authorizationConfiguration)
            interceptors[name] = interceptorsConfig
        }

        return interceptors
    }
}

// MARK: AWSAPICategoryPluginConfiguration + DefaultLogger
extension AWSAPICategoryPluginConfiguration: DefaultLogger {
    public static var log: Logger {
        Amplify.Logging.logger(forCategory: CategoryType.api.displayName, forNamespace: String(describing: self))
    }
    public var log: Logger {
        Self.log
    }
}
