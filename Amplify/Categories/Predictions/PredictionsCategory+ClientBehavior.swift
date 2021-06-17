//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension PredictionsCategory: PredictionsCategoryBehavior {

    /// Synthesize the text to audio
    /// - Parameter textToSpeech: The text to be synthesized to audio
    /// - Parameter listener: Triggered when the event occurs
    /// - Parameter options: Parameters to specific plugin behavior
    @discardableResult
    public func convert(textToSpeech: String,
                        options: PredictionsTextToSpeechRequest.Options? = nil,
                        listener: PredictionsTextToSpeechOperation.ResultListener?
    ) -> PredictionsTextToSpeechOperation {
        plugin.convert(textToSpeech: textToSpeech,
                       options: options,
                       listener: listener)
    }

    /// Translate the text to the language specified.
    /// - Parameter textToTranslate: The text to translate
    /// - Parameter language: The language of the text given
    /// - Parameter targetLanguage: The language to which the text should be translated
    /// - Parameter options: Parameters to specific plugin behavior
    /// - Parameter listener: Triggered when the event occurs
    @discardableResult
    public func convert(textToTranslate: String,
                        language: LanguageType?,
                        targetLanguage: LanguageType?,
                        options: PredictionsTranslateTextRequest.Options? = nil,
                        listener: PredictionsTranslateTextOperation.ResultListener?
    ) -> PredictionsTranslateTextOperation {
        plugin.convert(textToTranslate: textToTranslate,
                           language: language,
                           targetLanguage: targetLanguage,
                           options: options,
                           listener: listener)
    }

    /// Transcribe audio to text
    /// - Parameter speechToText: The url of the audio to be transcribed
    /// - Parameter listener: Triggered when the event occurs
    /// - Parameter options: Parameters to specific plugin behavior
    @discardableResult
    public func convert(speechToText: URL,
                        options: PredictionsSpeechToTextRequest.Options?,
                        listener: PredictionsSpeechToTextOperation.ResultListener?
    ) -> PredictionsSpeechToTextOperation {
        plugin.convert(speechToText: speechToText, options: options, listener: listener)
    }

    /// Detect contents of an image based on `IdentifyAction`
    /// - Parameter type: The type of image detection you want to perform
    /// - Parameter image: The image you are sending
    /// - Parameter options: Parameters to specific plugin behavior
    /// - Parameter listener: Triggered when the event occurs
    @discardableResult
    public func identify(type: IdentifyAction,
                         image: URL,
                         options: PredictionsIdentifyRequest.Options? = nil,
                         listener: PredictionsIdentifyOperation.ResultListener?
    ) -> PredictionsIdentifyOperation {
        plugin.identify(type: type,
                        image: image,
                        options: options,
                        listener: listener)
    }

    /// Interpret the text and return sentiment analysis, entity detection, language detection,
    /// syntax detection, key phrases detection
    /// - Parameter text: Text to interpret
    /// - Parameter options:Parameters to specific plugin behavior
    /// - Parameter options:Parameters to specific plugin behavior
    @discardableResult
    public func interpret(text: String,
                          options: PredictionsInterpretRequest.Options? = nil,
                          listener: PredictionsInterpretOperation.ResultListener?
    ) -> PredictionsInterpretOperation {
        plugin.interpret(text: text,
                         options: options,
                         listener: listener)
    }
}
