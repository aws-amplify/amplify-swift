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

extension AWSPredictionsPlugin {

    /// Configures AWSPredictionsPlugin with the specified configuration.
    ///
    /// This method will be invoked as part of the Amplify configuration flow. Retrieves  region, and
    /// default configuration values to allow overrides on plugin API calls.
    ///
    /// - Parameter configuration: The configuration specified for this plugin
    /// - Throws:
    ///   - PluginError.pluginConfigurationError: If one of the configuration values is invalid or empty
    public func configure(using configuration: Any) throws {

        guard let config =  try? JSONSerialization.data(withJSONObject: configuration) else {
            throw PluginError.pluginConfigurationError(PluginErrorMessage.decodeConfigurationError.errorDescription,
                                                       PluginErrorMessage.decodeConfigurationError.recoverySuggestion)
        }

        let decoder = JSONDecoder()
        guard let predictionsConfig = try? decoder.decode(PredictionsPluginConfiguration.self, from: config) else {
            throw PluginError.pluginConfigurationError(PluginErrorMessage.decodeConfigurationError.errorDescription,
                                                       PluginErrorMessage.decodeConfigurationError.recoverySuggestion)
        }

        let authService = AWSAuthService()
        let cognitoCredentialsProvider = authService.getCognitoCredentialsProvider()
        let coremlService = try CoreMLPredictionService(config: configuration)
        let predictionsService = try AWSPredictionsService(config: predictionsConfig,
                                                           cognitoCredentialsProvider: cognitoCredentialsProvider,
                                                           identifier: key)

        configure(predictionsService: predictionsService,
                  coreMLSerivce: coremlService,
                  authService: authService,
                  config: predictionsConfig)
    }

    func configure(predictionsService: AWSPredictionsService,
                   coreMLSerivce: CoreMLPredictionBehavior,
                   authService: AWSAuthServiceBehavior,
                   config: PredictionsPluginConfiguration,
                   queue: OperationQueue = OperationQueue()) {
        self.predictionsService = predictionsService
        coreMLService = coreMLSerivce
        self.authService = authService
        self.config = config
        self.queue = queue
    }
}
