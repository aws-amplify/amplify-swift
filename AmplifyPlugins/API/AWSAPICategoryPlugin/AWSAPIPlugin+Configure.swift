//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
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
    func configure(using configuration: Any?) throws {

        guard let jsonValue = configuration as? JSONValue else {
            throw PluginError.pluginConfigurationError(
                "Could not cast incoming configuration to JSONValue",
                """
                The specified configuration is either nil, or not convertible to a JSONValue. Review the configuration \
                and ensure it contains the expected values, and does not use any types that aren't convertible to a \
                corresponding JSONValue:
                \(String(describing: configuration))
                """
            )
        }

        let dependencies = try ConfigurationDependencies(configurationValues: jsonValue,
                                                         apiAuthProviderFactory: authProviderFactory)
        configure(using: dependencies)

        log.info("Configure finished")
    }
}

// MARK: Internal

extension AWSAPIPlugin {

    /// A holder for AWSAPIPlugin dependencies that provides sane defaults for
    /// production
    struct ConfigurationDependencies {
        let authService: AWSAuthServiceBehavior
        let pluginConfig: AWSAPICategoryPluginConfiguration
        let subscriptionConnectionFactory: SubscriptionConnectionFactory

        init(
            configurationValues: JSONValue,
            apiAuthProviderFactory: APIAuthProviderFactory,
            authService: AWSAuthServiceBehavior? = nil,
            subscriptionConnectionFactory: SubscriptionConnectionFactory? = nil
        ) throws {
            let authService = authService
                ?? AWSAuthService()

            let pluginConfig = try AWSAPICategoryPluginConfiguration(
                jsonValue: configurationValues,
                apiAuthProviderFactory: apiAuthProviderFactory,
                authService: authService
            )

            let subscriptionConnectionFactory = subscriptionConnectionFactory
                ?? AWSSubscriptionConnectionFactory()

            self.init(
                pluginConfig: pluginConfig,
                authService: authService,
                subscriptionConnectionFactory: subscriptionConnectionFactory
            )
        }

        init(
            pluginConfig: AWSAPICategoryPluginConfiguration,
            authService: AWSAuthServiceBehavior,
            subscriptionConnectionFactory: SubscriptionConnectionFactory
        ) {
            self.pluginConfig = pluginConfig
            self.authService = authService
            self.subscriptionConnectionFactory = subscriptionConnectionFactory
        }

    }

    /// Internal configure method to set the properties of the plugin
    ///
    /// Called from the configure method which implements the Plugin protocol. Useful for testing by passing in mocks.
    ///
    /// - Parameters:
    ///   - dependencies: The dependencies needed to complete plugin configuration
    func configure(using dependencies: ConfigurationDependencies) {
        authService = dependencies.authService
        pluginConfig = dependencies.pluginConfig
        subscriptionConnectionFactory = dependencies.subscriptionConnectionFactory
    }

}
