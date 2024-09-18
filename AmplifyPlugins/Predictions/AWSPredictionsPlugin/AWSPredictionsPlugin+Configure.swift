//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(InternalAmplifyConfiguration) import Amplify
import Foundation
import AWSPluginsCore

extension AWSPredictionsPlugin {
    /// Configures AWSPredictionsPlugin with the specified configuration.
    ///
    /// This method will be invoked as part of the Amplify configuration flow. Retrieves region, and
    /// default configuration values to allow overrides on plugin API calls.
    ///
    /// - Parameter configuration: The configuration specified for this plugin
    /// - Throws:
    ///   - PluginError.pluginConfigurationError: If one of the configuration values is invalid or empty
    public func configure(using configuration: Any?) throws {
        let predictionsConfiguration: PredictionsPluginConfiguration
        if configuration is AmplifyOutputsData {
            throw PluginError.pluginConfigurationError(
                PluginErrorMessage.amplifyOutputsConfigurationNotSupportedError.errorDescription,
                PluginErrorMessage.amplifyOutputsConfigurationNotSupportedError.recoverySuggestion
            )
        } else if let jsonValueConfiguration = configuration as? JSONValue {
            let configurationData = try JSONEncoder().encode(jsonValueConfiguration)
            predictionsConfiguration = try JSONDecoder().decode(
                PredictionsPluginConfiguration.self,
                from: configurationData
            )
        } else {
            throw PluginError.pluginConfigurationError(
                PluginErrorMessage.decodeConfigurationError.errorDescription,
                PluginErrorMessage.decodeConfigurationError.recoverySuggestion
            )
        }

        let authService = AWSAuthService()
        let credentialIdentityResolver = authService.getCredentialIdentityResolver()
        let coremlService: CoreMLPredictionBehavior?
    #if canImport(Speech) && canImport(Vision)
        coremlService = try CoreMLPredictionService(configuration: configuration)
    #else
        coremlService = nil
    #endif

        let predictionsService = try AWSPredictionsService(
            configuration: predictionsConfiguration,
            credentialIdentityResolver: credentialIdentityResolver,
            identifier: key
        )

        configure(
            predictionsService: predictionsService,
            coreMLSerivce: coremlService,
            authService: authService,
            config: predictionsConfiguration
        )
    }

    func configure(
        predictionsService: AWSPredictionsService,
        coreMLSerivce: CoreMLPredictionBehavior?,
        authService: AWSAuthServiceBehavior,
        config: PredictionsPluginConfiguration
    ) {
        self.predictionsService = predictionsService
        self.coreMLService = coreMLSerivce
        self.authService = authService
        self.config = config
    }
}
