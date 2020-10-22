//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import AWSPluginsCore
import AWSCore

public extension AWSAPICategoryPluginConfiguration {

    struct EndpointConfig {

        let name: String
        let baseURL: URL
        let region: AWSRegionType?
        let authorizationType: AWSAuthorizationType
        let authorizationConfiguration: AWSAuthorizationConfiguration
        let endpointType: AWSAPICategoryPluginEndpointType
        // TODO: Refactor into an "Intercepting connection configuration" or similar --
        // EndpointConfig shouldn't be holding onto interceptors; it should just be a data holder.
        // https://github.com/aws-amplify/amplify-ios/issues/73
        var interceptors = [URLRequestInterceptor]()

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

            try self.init(name: name,
                          baseURL: EndpointConfig.getBaseURL(from: endpointJSON),
                          region: EndpointConfig.getRegion(from: endpointJSON),
                          authorizationType: EndpointConfig.getAuthorizationType(from: endpointJSON),
                          authorizationConfiguration: EndpointConfig.getAuthorizationConfiguration(from: endpointJSON),
                          endpointType: EndpointConfig.getEndpointType(from: endpointJSON),
                          apiAuthProviderFactory: apiAuthProviderFactory,
                          authService: authService)
        }

        init(name: String,
             baseURL: URL,
             region: AWSRegionType?,
             authorizationType: AWSAuthorizationType,
             authorizationConfiguration: AWSAuthorizationConfiguration,
             endpointType: AWSAPICategoryPluginEndpointType,
             apiAuthProviderFactory: APIAuthProviderFactory,
             authService: AWSAuthServiceBehavior? = nil) throws {
            self.name = name
            self.baseURL = baseURL
            self.region = region
            self.authorizationType = authorizationType
            self.authorizationConfiguration = authorizationConfiguration
            self.endpointType = endpointType
            try addInterceptors(authService: authService, apiAuthProviderFactory: apiAuthProviderFactory)
        }

        public mutating func addInterceptor(interceptor: URLRequestInterceptor) {
            interceptors.append(interceptor)
        }

        // MARK: Private

        /// Adds auto-discovered interceptors. Currently only works for authorization interceptors
        private mutating func addInterceptors(authService: AWSAuthServiceBehavior? = nil,
                                              apiAuthProviderFactory: APIAuthProviderFactory) throws {
            switch authorizationConfiguration {
            case .none:
                // No interceptors needed
                break
            case .apiKey(let apiKeyConfig):
                let provider = BasicAPIKeyProvider(apiKey: apiKeyConfig.apiKey)
                let interceptor = APIKeyURLRequestInterceptor(apiKeyProvider: provider)
                addInterceptor(interceptor: interceptor)
            case .awsIAM(let iamConfig):
                guard let authService = authService else {
                    throw PluginError.pluginConfigurationError("AuthService is not set for IAM",
                                                               "")
                }
                let provider = BasicIAMCredentialsProvider(authService: authService)
                let interceptor = IAMURLRequestInterceptor(iamCredentialsProvider: provider,
                                                           region: iamConfig.region,
                                                           endpointType: endpointType)
                addInterceptor(interceptor: interceptor)
            case .amazonCognitoUserPools:
                guard let authService = authService else {
                    throw PluginError.pluginConfigurationError("AuthService not set for cognito user pools",
                                                               "")
                }
                let provider = BasicUserPoolTokenProvider(authService: authService)
                let interceptor = UserPoolURLRequestInterceptor(userPoolTokenProvider: provider)
                addInterceptor(interceptor: interceptor)
            case .openIDConnect:
                guard let oidcAuthProvider = apiAuthProviderFactory.oidcAuthProvider() else {
                    return
                }
                let wrappedAuthProvider = AuthTokenProviderWrapper(oidcAuthProvider: oidcAuthProvider)
                let interceptor = UserPoolURLRequestInterceptor(userPoolTokenProvider: wrappedAuthProvider)
                addInterceptor(interceptor: interceptor)
            }
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

        private static func getRegion(from endpointJSON: [String: JSONValue]) throws -> AWSRegionType? {
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

        private static func getAuthorizationType(
            from endpointJSON: [String: JSONValue]
        ) throws -> AWSAuthorizationType {
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

        // TODO: Refactor auth configuration creation into separate files--this file is for endpoint configs
        // https://github.com/aws-amplify/amplify-ios/issues/73
        private static func getAuthorizationConfiguration(from endpointJSON: [String: JSONValue])
            throws -> AWSAuthorizationConfiguration {
            let authType = try getAuthorizationType(from: endpointJSON)

            switch authType {
            case .none:
                return .none
            case .apiKey:
                return try apiKeyAuthorizationConfiguration(from: endpointJSON)
            case .awsIAM:
                return try awsIAMAuthorizationConfiguration(from: endpointJSON)
            case .openIDConnect:
                return try oidcAuthorizationConfiguration(from: endpointJSON)
            case .amazonCognitoUserPools:
                return try userPoolsAuthorizationConfiguration(from: endpointJSON)
            }

        }

        private static func apiKeyAuthorizationConfiguration(from endpointJSON: [String: JSONValue])
            throws -> AWSAuthorizationConfiguration {

                guard case .string(let apiKey) = endpointJSON["apiKey"] else {
                    throw PluginError.pluginConfigurationError(
                        "Could not get `ApiKey` from plugin configuration",
                        """
                        The specified configuration does not have a string with the key `ApiKey`. Review the \
                        configuration and ensure it contains the expected values:
                        \(endpointJSON)
                        """
                    )
                }

                let config = APIKeyConfiguration(apiKey: apiKey)
                return .apiKey(config)
        }

        static func awsIAMAuthorizationConfiguration(from endpointJSON: [String: JSONValue])
            throws -> AWSAuthorizationConfiguration {
                let regionOptional = try EndpointConfig.getRegion(from: endpointJSON)
                guard let region = regionOptional else {
                    throw PluginError.pluginConfigurationError("Region is not set for IAM",
                                                               "Set the region")
                }
                return .awsIAM(AWSIAMConfiguration(region: region))
        }

        static func oidcAuthorizationConfiguration(from endpointJSON: [String: JSONValue])
            throws -> AWSAuthorizationConfiguration {
                return .openIDConnect(OIDCConfiguration())
        }

        static func userPoolsAuthorizationConfiguration(from endpointJSON: [String: JSONValue])
            throws -> AWSAuthorizationConfiguration {
                return .amazonCognitoUserPools(CognitoUserPoolsConfiguration())
        }

    }
}

extension Dictionary where Key == String, Value == AWSAPICategoryPluginConfiguration.EndpointConfig {
    func getConfig(for apiName: String?,
                   endpointType: AWSAPICategoryPluginEndpointType) throws ->
        AWSAPICategoryPluginConfiguration.EndpointConfig {
        if let apiName = apiName {
            return try getConfig(for: apiName)
        }

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
}
