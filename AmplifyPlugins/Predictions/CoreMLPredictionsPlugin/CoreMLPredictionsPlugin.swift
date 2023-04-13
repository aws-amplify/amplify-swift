//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

/// Predictions plugin that uses CoreML service to get results.
final public class CoreMLPredictionsPlugin: PredictionsCategoryPlugin {
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

    public init() {}

    // TODO: Implement
    public func reset() async {}
}

extension CoreMLPredictionsPlugin: AmplifyVersionable { }
