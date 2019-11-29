//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore

public extension AWSAPIPlugin {

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

        let authService = AWSAuthService()

        let pluginConfig = try AWSAPICategoryPluginConfiguration(jsonValue: jsonValue, authService: authService)

        configure(authService: authService,
                  pluginConfig: pluginConfig)

        log.info("Configure finished")
    }
}

// MARK: Internal

extension AWSAPIPlugin {

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
                   pluginConfig: AWSAPICategoryPluginConfiguration,
                   subscriptionConnectionFactory: SubscriptionConnectionFactory = AWSSubscriptionConnectionFactory()) {
        self.authService = authService
        self.pluginConfig = pluginConfig
        self.subscriptionConnectionFactory = subscriptionConnectionFactory
    }

}
