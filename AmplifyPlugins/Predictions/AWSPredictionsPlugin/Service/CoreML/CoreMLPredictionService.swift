//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import CoreMLPredictionsPlugin

class CoreMLPredictionService: CoreMLPredictionBehavior {


    let coreMLPlugin: CoreMLPredictionsPlugin

    init(configuration: Any?) throws {
        self.coreMLPlugin = CoreMLPredictionsPlugin()
        try coreMLPlugin.configure(using: configuration)
    }

    func comprehend(
        text: String
    ) async throws -> Predictions.Interpret.Result {
        return try await coreMLPlugin.interpret(
            text: text,
            options: Predictions.Interpret.Options()
        )
    }


    func identify<Output>(
        _ type: Predictions.Identify.Request<Output>,
        in imageURL: URL
    ) async throws -> Output {
        try await coreMLPlugin.identify(type, in: imageURL, options: .init())
    }

    // TODO: Transribe
//    func transcribe(
//        _ speechToText: URL
//    ) async throws -> SpeechToTextResult {
//        try await coreMLPlugin.convert(
//            speechToText: speechToText,
//            options: PredictionsSpeechToTextRequest.Options()
//        )
//    }
}
