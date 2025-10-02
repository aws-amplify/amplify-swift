//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if canImport(Speech) && canImport(Vision)
import Amplify
import Foundation

/// Predictions plugin that uses CoreML service to get results.
public final class CoreMLPredictionsPlugin: PredictionsCategoryPlugin {

    let coreMLPredictionsPluginKey = "CoreMLPredictionsPlugin"

    var coreMLNaturalLanguage: CoreMLNaturalLanguageBehavior!

    var coreMLVision: CoreMLVisionBehavior!

    var coreMLSpeech: CoreMLSpeechBehavior!

    /// A queue that regulates the execution of operations.
    var queue: OperationQueue!

    /// The unique key of the plugin within the predictions category.
    public var key: PluginKey {
        return coreMLPredictionsPluginKey
    }

    public init() {
    }
}

extension CoreMLPredictionsPlugin: AmplifyVersionable { }
#endif
