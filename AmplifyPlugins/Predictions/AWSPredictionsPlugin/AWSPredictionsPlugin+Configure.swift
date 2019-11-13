//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSPluginsCore
import Amplify

extension AWSPredictionsPlugin {

    public func configure(using configuration: Any) throws {

        guard let config = configuration as? JSONValue else {
                  throw PluginError.pluginConfigurationError(PluginErrorConstants.decodeConfigurationError.errorDescription,
                                                             PluginErrorConstants.decodeConfigurationError.recoverySuggestion)
              }

              guard case let .object(configObject) = config else {
                  throw PluginError.pluginConfigurationError(
                      PluginErrorConstants.configurationObjectExpected.errorDescription,
                      PluginErrorConstants.configurationObjectExpected.recoverySuggestion)
              }

        let collectionId = try? AWSPredictionsPlugin.getCollection(configObject)
        let maxFaces = AWSPredictionsPlugin.getMaxFaces(configObject)
        let authService = AWSAuthService()
        let cognitoCredentialsProvider = authService.getCognitoCredentialsProvider()
        let predictionsService = try AWSPredictionsService(region: .USEast1,
                                                           collectionId: collectionId,
                                                           maxFaces: maxFaces,
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

    private static func getCollection(_ configuration: [String: JSONValue]) throws -> String? {

        guard let identifyConfig = configuration[PluginConstants.identify],
            case let .object(entityConfig) = identifyConfig,
            let config = entityConfig[PluginConstants.identifyEntities] ,
            case let .object(unwrappedConfig) = config,
            let collection = unwrappedConfig[PluginConstants.collectionId] else {
                return nil
        }
        
        guard case let .string(collectionId) = collection else {
            throw PluginError.pluginConfigurationError(PluginErrorConstants.invalidCollection.errorDescription,
                                                       PluginErrorConstants.invalidCollection.recoverySuggestion)
        }
        
        if collectionId.isEmpty {
            throw PluginError.pluginConfigurationError(PluginErrorConstants.emptyCollection.errorDescription,
                                                       PluginErrorConstants.emptyCollection.recoverySuggestion)
        }
        
        return collectionId
    }

    private static func getMaxFaces(_ configuration: [String: JSONValue]) -> Int {
        guard let maxFacesConfig = configuration[PluginConstants.maxFaces],
        case let .number(maxFaces) = maxFacesConfig else {
            return 50 //default
        }

        return Int(maxFaces)
    }
}
