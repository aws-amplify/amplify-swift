//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

extension AWSPredictionsPlugin {

    public func convert(
        textToTranslate: String,
        language: LanguageType?,
        targetLanguage: LanguageType?,
        options: PredictionsTranslateTextRequest.Options?,
        listener: PredictionsTranslateTextOperation.ResultListener? = nil
    )
    -> PredictionsTranslateTextOperation {
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

    public func identify(
        type: IdentifyAction,
        image: URL,
        options: PredictionsIdentifyRequest.Options?,
        listener: PredictionsIdentifyOperation.ResultListener? = nil
    ) -> PredictionsIdentifyOperation {
        fatalError()
    }

    /// Interprets the input text and detects sentiment, language, syntax, and key phrases
    ///
    /// - Parameter text: input text
    /// - Parameter options: Option for the plugin
    /// - Parameter resultListener: Listener to which events are send
    public func interpret(
        text: String,
        options: PredictionsInterpretRequest.Options?,
        listener: PredictionsInterpretOperation.ResultListener?
    ) -> PredictionsInterpretOperation {
        fatalError()
    }
}
