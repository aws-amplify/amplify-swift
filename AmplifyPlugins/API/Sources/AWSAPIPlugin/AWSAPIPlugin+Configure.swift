//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(InternalAmplifyConfiguration) import Amplify
import AWSPluginsCore
import InternalAmplifyCredentials
import AwsCommonRuntimeKit

public extension AWSAPIPlugin {

    /// Configures AWSAPICategoryPlugin
    ///
    /// This method will be invoked as part of the Amplify configuration flow.
    ///
    /// - Parameter configuration: The configuration specified for this plugin
    /// - Throws:
    ///   - PluginError.pluginConfigurationError: If one of the required configuration values is invalid or empty
    func configure(using configuration: Any?) throws {
        let dependencies: ConfigurationDependencies
        if let configuration = configuration as? AmplifyOutputsData {
            dependencies = try ConfigurationDependencies(configuration: configuration,
                                                         apiAuthProviderFactory: authProviderFactory)
        } else if let jsonValue = configuration as? JSONValue {
            dependencies = try ConfigurationDependencies(configurationValues: jsonValue,
                                                         apiAuthProviderFactory: authProviderFactory)

        } else {
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

        configure(using: dependencies)

        // Initialize SwiftSDK's CRT dependency for SigV4 signing functionality
        CommonRuntimeKit.initialize()

        log.info("Configure finished")
    }
}

// MARK: Internal

extension AWSAPIPlugin {

    /// A holder for AWSAPIPlugin dependencies that provides sane defaults for
    /// production
    struct ConfigurationDependencies {
        let authService: AWSAuthCredentialsProviderBehavior
        let pluginConfig: AWSAPICategoryPluginConfiguration
        let appSyncRealTimeClientFactory: AppSyncRealTimeClientFactoryProtocol
        let logLevel: Amplify.LogLevel

        init(
            configurationValues: JSONValue,
            apiAuthProviderFactory: APIAuthProviderFactory,
            authService: AWSAuthCredentialsProviderBehavior? = nil,
            appSyncRealTimeClientFactory: AppSyncRealTimeClientFactoryProtocol? = nil,
            logLevel: Amplify.LogLevel? = nil
        ) throws {
            let authService = authService
            ?? AWSAuthService()

            let pluginConfig = try AWSAPICategoryPluginConfiguration(
                jsonValue: configurationValues,
                apiAuthProviderFactory: apiAuthProviderFactory,
                authService: authService
            )

            let logLevel = logLevel ?? Amplify.Logging.logLevel

            self.init(
                pluginConfig: pluginConfig,
                authService: authService,
                appSyncRealTimeClientFactory: appSyncRealTimeClientFactory
                ?? AppSyncRealTimeClientFactory(),
                logLevel: logLevel
            )
        }

        init(
            configuration: AmplifyOutputsData,
            apiAuthProviderFactory: APIAuthProviderFactory,
            authService: AWSAuthCredentialsProviderBehavior = AWSAuthService(),
            appSyncRealTimeClientFactory: AppSyncRealTimeClientFactoryProtocol? = nil,
            logLevel: Amplify.LogLevel = Amplify.Logging.logLevel
        ) throws {
            let pluginConfig = try AWSAPICategoryPluginConfiguration(
                configuration: configuration,
                apiAuthProviderFactory: apiAuthProviderFactory,
                authService: authService
            )

            self.init(
                pluginConfig: pluginConfig,
                authService: authService,
                appSyncRealTimeClientFactory: appSyncRealTimeClientFactory
                ?? AppSyncRealTimeClientFactory(),
                logLevel: logLevel
            )
        }

        init(
            pluginConfig: AWSAPICategoryPluginConfiguration,
            authService: AWSAuthCredentialsProviderBehavior,
            appSyncRealTimeClientFactory: AppSyncRealTimeClientFactoryProtocol,
            logLevel: Amplify.LogLevel
        ) {
            self.pluginConfig = pluginConfig
            self.authService = authService
            self.appSyncRealTimeClientFactory = appSyncRealTimeClientFactory
            self.logLevel = logLevel
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
        appSyncRealTimeClientFactory = dependencies.appSyncRealTimeClientFactory
    }
}
