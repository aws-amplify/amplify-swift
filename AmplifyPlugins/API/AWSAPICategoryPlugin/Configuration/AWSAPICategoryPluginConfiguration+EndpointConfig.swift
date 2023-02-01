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
    struct EndpointConfig {
        // API name
        let name: String

        let baseURL: URL
        let region: AWSRegionType?

        // default authorization type
        let authorizationType: AWSAuthorizationType

        // default authorization configuration
        let authorizationConfiguration: AWSAuthorizationConfiguration

        let endpointType: AWSAPICategoryPluginEndpointType

        var apiKey: String?

        public init(name: String,
                    jsonValue: JSONValue,
                    apiAuthProviderFactory: APIAuthProviderFactory,
                    authService: AWSAuthServiceBehavior? = nil) throws {

            guard case .object(let endpointJSON) = jsonValue else {
                throw PluginError.pluginConfigurationError(
                    "Could not cast incoming configuration to a JSONValue `.object`",
                    """
                    The specified configuration is not convertible to a JSONValue. Review the configuration and \
                    ensure it contains the expected values, and does not use any types that aren't convertible to a \
                    corresponding JSONValue:
                    \(jsonValue)
                    """
                )
            }

            var apiKeyValue: String?
            if case .string(let apiKey) = endpointJSON["apiKey"] {
                apiKeyValue = apiKey
            }

            try self.init(name: name,
                          baseURL: EndpointConfig.getBaseURL(from: endpointJSON),
                          region: AWSRegionType.region(from: endpointJSON),
                          authorizationType: AWSAuthorizationType.from(endpointJSON: endpointJSON),
                          endpointType: EndpointConfig.getEndpointType(from: endpointJSON),
                          apiKey: apiKeyValue,
                          apiAuthProviderFactory: apiAuthProviderFactory,
                          authService: authService)
        }

        init(name: String,
             baseURL: URL,
             region: AWSRegionType?,
             authorizationType: AWSAuthorizationType,
             endpointType: AWSAPICategoryPluginEndpointType,
             apiKey: String? = nil,
             apiAuthProviderFactory: APIAuthProviderFactory,
             authService: AWSAuthServiceBehavior? = nil) throws {
            self.name = name
            self.baseURL = baseURL
            self.region = region
            self.authorizationType = authorizationType
            self.authorizationConfiguration = try AWSAuthorizationConfiguration.makeConfiguration(
                authType: authorizationType,
                region: region,
                apiKey: apiKey
            )
            self.endpointType = endpointType
            self.apiKey = apiKey
        }

        public func authorizationConfigurationFor(authType: AWSAuthorizationType) throws -> AWSAuthorizationConfiguration {
            // swiftlint:disable:previous line_length
            return try AWSAuthorizationConfiguration.makeConfiguration(authType: authType,
                                                              region: region,
                                                              apiKey: apiKey)
        }

        // MARK: - Configuration file helpers

        private static func getBaseURL(from endpointJSON: [String: JSONValue]) throws -> URL {
            guard case .string(let baseURLString) = endpointJSON["endpoint"] else {
                throw PluginError.pluginConfigurationError(
                    "Could not get `Endpoint` from plugin configuration",
                    """
                    The specified configuration does not have a string with the key `Endpoint`. Review the \
                    configuration and ensure it contains the expected values:
                    \(endpointJSON)
                    """
                )
            }

            guard let baseURL = URL(string: baseURLString) else {
                throw PluginError.pluginConfigurationError(
                    "Could not convert `\(baseURLString)` to a URL",
                    """
                    The "endpoint" value in the specified configuration cannot be converted to a URL. Review the \
                    configuration and ensure it contains the expected values:
                    \(endpointJSON)
                    """
                )
            }

            return baseURL
        }

        private static func getEndpointType(from endpointJSON: [String: JSONValue]) throws ->
            AWSAPICategoryPluginEndpointType {

            guard case .string(let endpointTypeValue) = endpointJSON["endpointType"] else {
                throw PluginError.pluginConfigurationError(
                    "Could not get `EndpointType` from plugin configuration",
                    """
                    The specified configuration does not have a string with the key `EndpointType`. Review the \
                    configuration and sure it contains the expected values:
                    \(endpointJSON)
                    """
                )
            }

            let endpointTypeOptional = AWSAPICategoryPluginEndpointType(rawValue: endpointTypeValue)

            guard let endpointType = endpointTypeOptional else {
                throw PluginError.pluginConfigurationError(
                    "The `EndpointType` should be either `GraphQL` or `REST`.",
                    """
                    Review the configuration and sure it contains the expected values:
                    \(endpointJSON)
                    """
                )
            }

            return endpointType
        }
    }
}

// MARK: - AWSRegionType + fromEndpointJSON

private extension AWSRegionType {
    static func region(from endpointJSON: [String: JSONValue]) throws -> AWSRegionType? {
        let region: AWSRegionType?

        if case .string(let endpointRegion) = endpointJSON["region"] {
            let regionType = endpointRegion.aws_regionTypeValue()
            guard regionType != AWSRegionType.Unknown else {
                return nil
            }

            region = regionType
        } else {
            region = nil
        }

        return region
    }
}

// MARK: - AWSAuthorizationType + fromEndpointJSON

private extension AWSAuthorizationType {
    static func from(endpointJSON: [String: JSONValue]) throws -> AWSAuthorizationType {
        guard case .string(let authorizationTypeString) = endpointJSON["authorizationType"] else {
            throw PluginError.pluginConfigurationError(
                "Could not get `AuthorizationType` from plugin configuration",
                """
                The specified configuration does not have a string with the key `AuthorizationType`. Review the \
                configuration and ensure it contains the expected values:
                \(endpointJSON)
                """
            )
        }

        guard let authorizationType = AWSAuthorizationType(rawValue: authorizationTypeString) else {
            let authTypes = AWSAuthorizationType.allCases.map { $0.rawValue }.joined(separator: ", ")
            throw PluginError.pluginConfigurationError(
                "Could not convert `\(authorizationTypeString)` to an AWSAuthorizationType",
                """
                The "authorizationType" value in the specified configuration cannot be converted to an \
                AWSAuthorizationType. Review the configuration and ensure it contains a valid value \
                (\(authTypes)):
                \(endpointJSON)
                """
            )
        }

        return authorizationType
    }
}

// MARK: - Dictionary + AWSAPICategoryPluginConfiguration.EndpointConfig

extension Dictionary where Key == String, Value == AWSAPICategoryPluginConfiguration.EndpointConfig {

    /// Getting the `EndpointConfig` resolves to the following rules:
    /// 1. If `apiName` is specified, retrieve the endpoint configuration for this api
    /// 2. If `apiName` is not specified, and `endpointType` is, retrieve the endpoint if there is only one.
    /// 3. If nothing is specified, return the endpoint only if there is a single one, with GraphQL taking precedent
    /// over REST.
    func getConfig(for apiName: String? = nil,
                   endpointType: AWSAPICategoryPluginEndpointType? = nil) throws ->
        AWSAPICategoryPluginConfiguration.EndpointConfig {
        if let apiName = apiName {
            return try getConfig(for: apiName)
        }
        if let endpointType = endpointType {
            return try getConfig(for: endpointType)
        }

        return try getConfig()
    }

    private func getConfig(for apiName: String) throws -> AWSAPICategoryPluginConfiguration.EndpointConfig {
        guard let endpointConfig = self[apiName] else {

            let error = APIError.invalidConfiguration(
                "Unable to get an endpoint configuration for \(apiName)",
                """
                Review your API plugin configuration and ensure \(apiName) has a valid configuration.
                """
            )

            throw error

        }

        return endpointConfig
    }

    /// Retrieve the endpoint configuration when there is only one endpoint of the specified `endpointType`
    private func getConfig(for endpointType: AWSAPICategoryPluginEndpointType) throws ->
        AWSAPICategoryPluginConfiguration.EndpointConfig {
            let apiForEndpointType = filter { (_, endpointConfig) -> Bool in
                return endpointConfig.endpointType == endpointType
            }

            guard let endpointConfig = apiForEndpointType.first else {
                throw APIError.invalidConfiguration("Missing API for \(endpointType) endpointType",
                                                    "Add the \(endpointType) API to configuration.")
            }

            if apiForEndpointType.count > 1 {
                throw APIError.invalidConfiguration(
                    "More than one \(endpointType) API configured. Could not infer which API to call",
                    "Use the apiName to specify which API to call")
            }
            return endpointConfig.value
    }

    /// Retrieve the endpoint only if there is a single one, with GraphQL taking precedent over REST.
    private func getConfig() throws -> AWSAPICategoryPluginConfiguration.EndpointConfig {
        let graphQLEndpoints = filter { (_, endpointConfig) -> Bool in
            return endpointConfig.endpointType == .graphQL
        }

        if graphQLEndpoints.count == 1, let endpoint = graphQLEndpoints.first {
            return endpoint.value
        }

        let restEndpoints = filter { (_, endpointConfig) -> Bool in
            return endpointConfig.endpointType == .rest
        }

        if restEndpoints.count == 1, let endpoint = restEndpoints.first {
            return endpoint.value
        }

        throw APIError.invalidConfiguration("Unable to resolve endpoint configuration",
                                            """
                                            Pass in the apiName to specify the endpoint you are
                                            retrieving the config for
                                            """)
    }
}
