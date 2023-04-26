//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

extension AWSPredictionsPlugin {

    public func convert<Input, Options, Output>(
        _ request: Predictions.Convert.Request<Input, Options, Output>,
        options: Options?
    ) async throws -> Output {
        fatalError()
    }

    public func convert(
        textToSpeech: String,
        options: PredictionsTextToSpeechRequest.Options?,
        listener: PredictionsTextToSpeechOperation.ResultListener? = nil
    )
    -> PredictionsTextToSpeechOperation {
        fatalError()
    }

    public func convert(
        speechToText: URL,
        options: PredictionsSpeechToTextRequest.Options?,
        listener: PredictionsSpeechToTextOperation.ResultListener?
    ) -> PredictionsSpeechToTextOperation {
        fatalError()
    }

    public func identify<Output>(
        _ request: Predictions.Identify.Request<Output>,
        in image: URL,
        options: Predictions.Identify.Options?
    ) async throws -> Output {
        fatalError()
    }

    /// Interprets the input text and detects sentiment, language, syntax, and key phrases
    ///
    /// - Parameter text: input text
    /// - Parameter options: Option for the plugin
    /// - Parameter resultListener: Listener to which events are send
    public func interpret(
        text: String,
        options: Predictions.Interpret.Options?
    ) async throws -> Predictions.Interpret.Result {
        fatalError()
    }
}
