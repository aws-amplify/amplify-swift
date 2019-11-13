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

        guard let config = configuration as? JSONValue else {
            throw PluginError.pluginConfigurationError(PluginErrorMessage.decodeConfigurationError.errorDescription,
                                                       PluginErrorMessage.decodeConfigurationError.recoverySuggestion)
        }

        guard case let .object(configObject) = config else {
            throw PluginError.pluginConfigurationError(
                PluginErrorMessage.configurationObjectExpected.errorDescription,
                PluginErrorMessage.configurationObjectExpected.recoverySuggestion)
        }

        let authService = AWSAuthService()
        let cognitoCredentialsProvider = authService.getCognitoCredentialsProvider()

        let region = try AWSPredictionsPlugin.getRegionType(configObject)
        let predictionsService = try AWSPredictionsService(region: region,
                                                           cognitoCredentialsProvider: cognitoCredentialsProvider,
                                                           identifier: key)

        configure(predictionsService: predictionsService, authService: authService)
    }

    func configure(predictionsService: AWSPredictionsService,
                   authService: AWSAuthServiceBehavior,
                   queue: OperationQueue = OperationQueue()) {
        self.predictionsService = predictionsService
        self.authService = authService
        self.queue = queue
    }

    /// Retrieves the region from configuration, validates, and transforms to and returns the AWSRegionType
    private static func getRegionType(_ configuration: [String: JSONValue]) throws -> AWSRegionType {
        guard let region = configuration["region"] else {
            throw PluginError.pluginConfigurationError(PluginErrorMessage.missingRegion.errorDescription,
                                                       PluginErrorMessage.missingRegion.recoverySuggestion)
        }

        guard case let .string(regionValue) = region else {
            throw PluginError.pluginConfigurationError(PluginErrorMessage.invalidRegion.errorDescription,
                                                       PluginErrorMessage.invalidRegion.recoverySuggestion)
        }

        if regionValue.isEmpty {
            throw PluginError.pluginConfigurationError(PluginErrorMessage.emptyRegion.errorDescription,
                                                       PluginErrorMessage.emptyRegion.recoverySuggestion)
        }

        let regionType = regionValue.aws_regionTypeValue()
        guard regionType != AWSRegionType.Unknown else {
            throw PluginError.pluginConfigurationError(PluginErrorMessage.invalidRegion.errorDescription,
                                                       PluginErrorMessage.invalidRegion.recoverySuggestion)
        }

        return regionType
    }
}
