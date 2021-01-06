//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

// No-listener versions of the public APIs, to clean call sites that use Combine
// publishers to get results

public extension PredictionsCategoryBehavior {

    /// Translate the text to the language specified.
    /// - Parameter textToTranslate: The text to translate
    /// - Parameter language: The language of the text given
    /// - Parameter targetLanguage: The language to which the text should be translated
    /// - Parameter options: Parameters to specific plugin behavior
    func convert(
        textToTranslate: String,
        language: LanguageType? = nil,
        targetLanguage: LanguageType? = nil,
        options: PredictionsTranslateTextRequest.Options? = nil
    ) -> PredictionsTranslateTextOperation {
        convert(
            textToTranslate: textToTranslate,
            language: language,
            targetLanguage: targetLanguage,
            options: options,
            listener: nil
        )
    }

    /// - Parameter textToSpeech: The text to be synthesized to audio
    /// - Parameter options: Parameters to specific plugin behavior
    func convert(
        textToSpeech: String,
        options: PredictionsTextToSpeechRequest.Options? = nil
    ) -> PredictionsTextToSpeechOperation {
        convert(textToSpeech: textToSpeech, options: options, listener: nil)
    }

    /// - Parameter speechToText: The url of the audio to be transcribed
    /// - Parameter options: Parameters to specific plugin behavior
    func convert(
        speechToText: URL,
        options: PredictionsSpeechToTextRequest.Options? = nil
    ) -> PredictionsSpeechToTextOperation {
        convert(speechToText: speechToText, options: options, listener: nil)
    }

    /// Translate the text to the language specified.
    /// - Parameter type: The type of image detection you want to perform
    /// - Parameter image: The image you are sending
    /// - Parameter options: Parameters to specific plugin behavior
    func identify(
        type: IdentifyAction,
        image: URL,
        options: PredictionsIdentifyRequest.Options? = nil
    ) -> PredictionsIdentifyOperation {
        identify(type: type, image: image, options: options, listener: nil)
    }

    /// Interpret the text and return sentiment analysis, entity detection, language detection,
    /// syntax detection, key phrases detection
    /// - Parameter text: Text to interpret
    /// - Parameter options:Parameters to specific plugin behavior
    /// - Parameter options:Parameters to specific plugin behavior
    func interpret(
        text: String,
        options: PredictionsInterpretRequest.Options? = nil
    ) -> PredictionsInterpretOperation {
        interpret(text: text, options: options, listener: nil)
    }
}
