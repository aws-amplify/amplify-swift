//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
@_spi(PredictionsConvertRequestKind) import Amplify

extension AWSPredictionsPlugin {
    /// Interprets the input text and detects sentiment, language, syntax, and key phrases
    ///
    /// - Parameter text: input text
    /// - Parameter options: Option for the plugin
    /// - Parameter resultListener: Listener to which events are send
    public func interpret(
        text: String,
        options: Predictions.Interpret.Options?
    ) async throws -> Predictions.Interpret.Result {
        let options = options ?? .init()
        let multiService = InterpretTextMultiService(
            coreMLService: coreMLService,
            predictionsService: predictionsService,
            textToInterpret: text
        )

        switch options.defaultNetworkPolicy {
        case .online:
            let onlineResult = try await multiService.fetchOnlineResult()
            return onlineResult
        case .offline:
            let offlineResposne = try await multiService.fetchOfflineResult()
            return offlineResposne
        case .auto:
            let multiServiceResposne = try await multiService.fetchMultiServiceResult()
            return multiServiceResposne
        }
    }
}
