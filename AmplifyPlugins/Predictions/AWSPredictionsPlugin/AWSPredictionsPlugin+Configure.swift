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

        let predictionsConfig = try AWSPredictionsPlugin.createPredictionsConfiguration(configObject)
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
                   config: AWSPredictionsPluginConfiguration,
                   queue: OperationQueue = OperationQueue()) {
        self.predictionsService = predictionsService
        coreMLService = coreMLSerivce
        self.authService = authService
        self.config = config
        self.queue = queue
    }

    private static func createPredictionsConfiguration(_ configuration: [String: JSONValue])
        throws -> AWSPredictionsPluginConfiguration {

            var identifyConfig: AWSIdentifyConfig?
            var convertConfig: AWSConvertConfig?
            var interpretConfig: AWSInterpretConfig?
            var defaultProjectRegion: AWSRegionType = .USEast1

            if let identifyRegion = try? AWSPredictionsPlugin.getRegionType(configuration, api: .identify),
                let collectionId = try? AWSPredictionsPlugin.getCollectionId(configuration) {
                let maxEntities = AWSPredictionsPlugin.getMaxEntities(configuration)
                identifyConfig = AWSIdentifyConfig(region: identifyRegion,
                                                   collectionId: collectionId,
                                                   maxEntities: maxEntities)
            }

            if let convertRegion = try? AWSPredictionsPlugin.getRegionType(configuration, api: .convert),
                let voiceId = try? AWSPredictionsPlugin.getVoiceId(configuration) {
                convertConfig = AWSConvertConfig(region: convertRegion, voiceId: voiceId)
            }

            if let interpretRegion = try? AWSPredictionsPlugin.getRegionType(configuration, api: .interpret) {
                interpretConfig = AWSInterpretConfig(region: interpretRegion)
            }

            if let defaultRegion = try? AWSPredictionsPlugin.getProjectDefaultRegion(configuration) {
                defaultProjectRegion = defaultRegion
            }

            let config = AWSPredictionsPluginConfiguration(identifyConfig: identifyConfig,
                                                           interpretConfig: interpretConfig,
                                                           convertConfig: convertConfig, defaultProjectRegion: defaultProjectRegion)
            return config
    }

    private static func getProjectDefaultRegion(_ configuration: [String: JSONValue]) throws -> AWSRegionType {
        guard let config =
            configuration[AWSPredictionsPluginConfiguration.KeyName.defaultProjectRegion.rawValue],
            case let .string(regionValue) = config else {

                throw PluginError.pluginConfigurationError(
                    PluginErrorMessage.missingRegion.errorDescription,
                    PluginErrorMessage.missingRegion.recoverySuggestion)
            }

        if regionValue.isEmpty {
             throw PluginError.pluginConfigurationError(
                 PluginErrorMessage.emptyRegion.errorDescription,
                 PluginErrorMessage.emptyRegion.recoverySuggestion)
         }

         let regionType = regionValue.aws_regionTypeValue()
         guard regionType != AWSRegionType.Unknown else {
             throw PluginError.pluginConfigurationError(
                 PluginErrorMessage.invalidRegion.errorDescription,
                 PluginErrorMessage.invalidRegion.recoverySuggestion)
         }

         return regionType
    }

    private static func getCollectionId(_ configuration: [String: JSONValue]) throws -> String? {

        guard let identifyConfig = configuration[AWSPredictionsPluginConfiguration.KeyName.identify.rawValue],
            case let .object(entityConfig) = identifyConfig,
            let config = entityConfig[AWSPredictionsPluginConfiguration.KeyName.identifyEntities.rawValue],
            case let .object(unwrappedConfig) = config,
            let collection = unwrappedConfig[AWSPredictionsPluginConfiguration.KeyName.collectionId.rawValue] else {
                return nil
        }

        guard case let .string(collectionId) = collection else {
            throw PluginError.pluginConfigurationError(
                PluginErrorMessage.invalidCollection.errorDescription,
                PluginErrorMessage.invalidCollection.recoverySuggestion)
        }

        if collectionId.isEmpty {
            throw PluginError.pluginConfigurationError(
                PluginErrorMessage.emptyCollection.errorDescription,
                PluginErrorMessage.emptyCollection.recoverySuggestion)
        }

        return collectionId
    }

    private static func getMaxEntities(_ configuration: [String: JSONValue]) -> Int {

        guard let identifyConfig = configuration[AWSPredictionsPluginConfiguration.KeyName.identify.rawValue],
            case let .object(entityConfig) = identifyConfig,
            let config = entityConfig[AWSPredictionsPluginConfiguration.KeyName.identifyEntities.rawValue],
            case let .object(unwrappedConfig) = config,
            let maxFacesConfig = unwrappedConfig[AWSPredictionsPluginConfiguration.KeyName.maxFaces.rawValue] else {
                return rekognitionMaxEntitiesLimit
        }
        guard case let .number(maxFaces) = maxFacesConfig else {
            return rekognitionMaxEntitiesLimit
        }

        return Int(maxFaces)
    }

    private static func getVoiceId(_ configuration: [String: JSONValue]) throws -> String? {
        guard let convertConfig = configuration[AWSPredictionsPluginConfiguration.KeyName.convert.rawValue],
            case let .object(textToSpeechConfig) = convertConfig,
            let config = textToSpeechConfig[AWSPredictionsPluginConfiguration.KeyName.speechGenerator.rawValue],
            case let .object(unwrappedConfig) = config,
            let voice = unwrappedConfig[AWSPredictionsPluginConfiguration.KeyName.voiceId.rawValue] else {
                return nil
        }

        guard case let .string(voiceId) = voice else {
            throw PluginError.pluginConfigurationError(
                PluginErrorMessage.invalidCollection.errorDescription,
                PluginErrorMessage.invalidCollection.recoverySuggestion)
        }

        if voiceId.isEmpty {
            throw PluginError.pluginConfigurationError(
                PluginErrorMessage.emptyCollection.errorDescription,
                PluginErrorMessage.emptyCollection.recoverySuggestion)
        }

        return voiceId

    }

    /// Retrieves the region from configuration, validates, and transforms to and returns the AWSRegionType
    private static func getRegionType(_ configuration: [String: JSONValue], api: PredictionsAction)
        throws -> AWSRegionType {

        switch api {
        case .identify:
            guard let identifyConfig = configuration[AWSPredictionsPluginConfiguration.KeyName.identify.rawValue],
                case let .object(entityConfig) = identifyConfig,
                let config = entityConfig[AWSPredictionsPluginConfiguration.KeyName.identifyEntities.rawValue],
                case let .object(unwrappedConfig) = config,
                let region = unwrappedConfig[AWSPredictionsPluginConfiguration.KeyName.region.rawValue] else {
                    throw PluginError.pluginConfigurationError(PluginErrorMessage.missingRegion.errorDescription,
                    PluginErrorMessage.missingRegion.recoverySuggestion)
            }

            guard case let .string(regionValue) = region
                else {
                 throw PluginError.pluginConfigurationError(
                    PluginErrorMessage.missingRegion.errorDescription,
                    PluginErrorMessage.missingRegion.recoverySuggestion)
            }

           if regionValue.isEmpty {
                throw PluginError.pluginConfigurationError(
                    PluginErrorMessage.emptyRegion.errorDescription,
                    PluginErrorMessage.emptyRegion.recoverySuggestion)
            }

            let regionType = regionValue.aws_regionTypeValue()
            guard regionType != AWSRegionType.Unknown else {
                throw PluginError.pluginConfigurationError(
                    PluginErrorMessage.invalidRegion.errorDescription,
                    PluginErrorMessage.invalidRegion.recoverySuggestion)
            }

            return regionType

        case .convert:
            guard let convertConfig = configuration[AWSPredictionsPluginConfiguration.KeyName.convert.rawValue],
                 case let .object(translateConfig) = convertConfig,
                let config = translateConfig[AWSPredictionsPluginConfiguration.KeyName.translateText.rawValue],
                 case let .object(unwrappedConfig) = config,
                let region = unwrappedConfig[AWSPredictionsPluginConfiguration.KeyName.region.rawValue] else {
                     throw PluginError.pluginConfigurationError(
                        PluginErrorMessage.missingRegion.errorDescription,
                        PluginErrorMessage.missingRegion.recoverySuggestion)
             }

             guard case let .string(regionValue) = region else {
                  throw PluginError.pluginConfigurationError(
                    PluginErrorMessage.missingRegion.errorDescription,
                    PluginErrorMessage.missingRegion.recoverySuggestion)
             }

            if regionValue.isEmpty {
                 throw PluginError.pluginConfigurationError(
                    PluginErrorMessage.emptyRegion.errorDescription,
                    PluginErrorMessage.emptyRegion.recoverySuggestion)
             }

             let regionType = regionValue.aws_regionTypeValue()
             guard regionType != AWSRegionType.Unknown else {
                 throw PluginError.pluginConfigurationError(
                    PluginErrorMessage.invalidRegion.errorDescription,
                    PluginErrorMessage.invalidRegion.recoverySuggestion)
             }
            return regionType

        case .interpret:
            guard let interpretConfig = configuration[AWSPredictionsPluginConfiguration.KeyName.convert.rawValue],
                 case let .object(translateConfig) = interpretConfig,
                let config = translateConfig[AWSPredictionsPluginConfiguration.KeyName.interpretText.rawValue],
                 case let .object(unwrappedConfig) = config,
                let region = unwrappedConfig[AWSPredictionsPluginConfiguration.KeyName.region.rawValue] else {
                     throw PluginError.pluginConfigurationError(
                        PluginErrorMessage.missingRegion.errorDescription,
                        PluginErrorMessage.missingRegion.recoverySuggestion)
             }

             guard case let .string(regionValue) = region else {
                  throw PluginError.pluginConfigurationError(
                    PluginErrorMessage.missingRegion.errorDescription,
                    PluginErrorMessage.missingRegion.recoverySuggestion)
             }

            if regionValue.isEmpty {
                 throw PluginError.pluginConfigurationError(
                    PluginErrorMessage.emptyRegion.errorDescription,
                    PluginErrorMessage.emptyRegion.recoverySuggestion)
             }

             let regionType = regionValue.aws_regionTypeValue()
             guard regionType != AWSRegionType.Unknown else {
                 throw PluginError.pluginConfigurationError(
                    PluginErrorMessage.invalidRegion.errorDescription,
                    PluginErrorMessage.invalidRegion.recoverySuggestion)
             }
            return regionType
        }
    }
}
