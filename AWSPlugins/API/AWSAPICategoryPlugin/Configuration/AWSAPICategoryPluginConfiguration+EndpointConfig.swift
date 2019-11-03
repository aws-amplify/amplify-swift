//
// Copyright 2018-2019 Amazon.com,
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
        var interceptors = [URLRequestInterceptor]()

        public init(name: String,
                    baseURL: URL,
                    region: AWSRegionType?,
                    authorizationType: AWSAuthorizationType,
                    authorizationConfiguration: AWSAuthorizationConfiguration,
                    authService: AWSAuthService) {
            self.name = name
            self.baseURL = baseURL
            self.region = region
            self.authorizationType = authorizationType
            self.authorizationConfiguration = authorizationConfiguration
            addInterceptors(authService: authService)
        }

        public init(name: String, jsonValue: JSONValue, authService: AWSAuthService) throws {
            self.name = name

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

            self.authorizationType = try EndpointConfig.authorizationType(from: endpointJSON)
            self.authorizationConfiguration = try EndpointConfig.authorizationConfiguration(from: endpointJSON)
            self.baseURL = try EndpointConfig.baseURL(from: endpointJSON)
            self.region = try EndpointConfig.region(from: endpointJSON)
            addInterceptors(authService: authService)
        }

        public mutating func addInterceptor(interceptor: URLRequestInterceptor) {
            interceptors.append(interceptor)
        }

        /// Adds auto-discovered interceptors. Currently only works for authorization interceptors
        private mutating func addInterceptors(authService: AWSAuthService) {
            switch authorizationConfiguration {
            case .none:
                // No interceptors needed
                break
            case .apiKey(let apiKeyConfig):
                let provider = BasicAPIKeyProvider(apiKey: apiKeyConfig.apiKey)
                let interceptor = APIKeyURLRequestInterceptor(apiKeyProvider: provider)
                addInterceptor(interceptor: interceptor)
            case .awsIAM:
                guard let region = region else {
                    fatalError("Region not set for IAM")
                }
                let provider = BasicIAMCredentialsProvider(authService: authService)
                let interceptor = IAMURLRequestInterceptor(iamCredentialsProvider: provider, region: region)
                addInterceptor(interceptor: interceptor)
            case .amazonCognitoUserPools:
                let provider = BasicUserPoolTokenProvider(authService: authService)
                let interceptor = UserPoolURLRequestInterceptor(userPoolTokenProvider: provider)
                addInterceptor(interceptor: interceptor)
            default:
                fatalError("No other types configured")
            }
        }

        // MARK: - Configuration file helpers

        private static func baseURL(from endpointJSON: [String: JSONValue]) throws -> URL {
            guard case .string(let baseURLString) = endpointJSON["Endpoint"] else {
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
                    The "Endpoint" value in the specified configuration cannot be converted to a URL. Review the \
                    configuration and ensure it contains the expected values:
                    \(endpointJSON)
                    """
                )
            }

            return baseURL
        }

        private static func region(from endpointJSON: [String: JSONValue]) throws -> AWSRegionType? {
            let region: AWSRegionType?

            if case .string(let endpointRegion) = endpointJSON["Region"] {
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

        private static func authorizationType(from endpointJSON: [String: JSONValue]) throws -> AWSAuthorizationType {
            guard case .string(let authorizationTypeString) = endpointJSON["AuthorizationType"] else {
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
                    The "AuthorizationType" value in the specified configuration cannot be converted to an \
                    AWSAuthorizationType. Review the configuration and ensure it contains a valid value \
                    (\(authTypes)):
                    \(endpointJSON)
                    """
                )
            }

            return authorizationType
        }

        private static func authorizationConfiguration(from endpointJSON: [String: JSONValue])
            throws -> AWSAuthorizationConfiguration {
            let authType = try authorizationType(from: endpointJSON)

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

                guard case .string(let apiKey) = endpointJSON["ApiKey"] else {
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

        private static func awsIAMAuthorizationConfiguration(from endpointJSON: [String: JSONValue])
            throws -> AWSAuthorizationConfiguration {
                return .awsIAM(AWSIAMConfiguration())
        }

        private static func oidcAuthorizationConfiguration(from endpointJSON: [String: JSONValue])
            throws -> AWSAuthorizationConfiguration {
                return .openIDConnect(OIDCConfiguration())
        }

        private static func userPoolsAuthorizationConfiguration(from endpointJSON: [String: JSONValue])
            throws -> AWSAuthorizationConfiguration {
                return .amazonCognitoUserPools(CognitoUserPoolsConfiguration())
        }

    }
}
