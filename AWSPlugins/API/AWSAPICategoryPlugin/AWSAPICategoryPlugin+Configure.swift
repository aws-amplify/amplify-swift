//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore

public extension AWSAPICategoryPlugin {

    /// Configures AWSAPICategoryPlugin
    ///
    /// This method will be invoked as part of the Amplify configuration flow.
    ///
    /// - Parameter configuration: The configuration specified for this plugin
    /// - Throws:
    ///   - PluginError.pluginConfigurationError: If one of the required configuration values is invalid or empty
    func configure(using configuration: Any) throws {

        guard let jsonValue = configuration as? JSONValue else {
            throw PluginError.pluginConfigurationError(
                "Could not cast incoming configuration to JSONValue",
                """
                The specified configuration is not convertible to a JSONValue. Review the configuration and ensure it \
                contains the expected values, and does not use any types that aren't convertible to a corresponding \
                JSONValue:
                \(configuration)
                """
            )
        }

        let pluginConfig = try AWSAPICategoryPluginConfig(jsonValue: jsonValue)

        let authService = AWSAuthService()

        configure(authService: authService, pluginConfig: pluginConfig)
    }

}

// MARK: Internal

extension AWSAPICategoryPlugin {

    /// Internal configure method to set the properties of the plugin
    ///
    /// Called from the configure method which implements the Plugin protocol. Useful for testing by passing in mocks.
    ///
    /// - Parameters:
    ///   - storageService: The S3 storage service object.
    ///   - authService: The authentication service object.
    ///   - defaultAccessLevel: The access level to be used for all API calls by default.
    ///   - queue: The queue which operations are stored and dispatched for asychronous processing.
    func configure(authService: AWSAuthServiceBehavior,
                   pluginConfig: AWSAPICategoryPluginConfig) {
        self.authService = authService
        self.pluginConfig = pluginConfig
    }

}

public struct AWSAPICategoryPluginConfig {
    let endpoints: [String: EndpointConfig]

    init(endpoints: [String: EndpointConfig]) {
        self.endpoints = endpoints
    }

    init(jsonValue: JSONValue) throws {
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

        let endpoints = try AWSAPICategoryPluginConfig.endpointsFromConfig(config: config)
        self.init(endpoints: endpoints)
    }

    private static func endpointsFromConfig(config: [String: JSONValue]) throws -> [String: EndpointConfig] {
        var endpoints = [String: EndpointConfig]()

        for (key, jsonValue) in config {
            let name = key
            guard case .object(let endpointJSON) = jsonValue else {
                throw PluginError.pluginConfigurationError(
                    "Could not cast incoming configuration to a JSONValue `.object`",
                    """
                    The specified configuration is not convertible to a JSONValue. Review the configuration and ensure \
                    it contains the expected values, and does not use any types that aren't convertible to a \
                    corresponding JSONValue:
                    \(jsonValue)
                    """
                )
            }

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

            let region: String?
            if case .string(let endpointRegion) = endpointJSON["Region"] {
                region = endpointRegion
            } else {
                region = nil
            }

            let endpointConfig = EndpointConfig(name: name,
                                                baseURL: baseURL,
                                                region: region)
            endpoints[name] = endpointConfig
        }

        return endpoints
    }
}

public extension AWSAPICategoryPluginConfig {
    struct EndpointConfig {
        let name: String
        let baseURL: URL
        let region: String?
    }
}
