//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine

public typealias PredictionsPublisher<Output> = AnyPublisher<Output, PredictionsError>

public extension PredictionsCategoryBehavior {

    /// Convert audio file containing speech to text
    ///
    /// - Parameter speechToText: The url of the audio to be transcribed
    /// - Parameter options: Parameters to specific plugin behavior
    func convert(
        speechToText: URL,
        options: PredictionsSpeechToTextRequest.Options? = nil
    ) -> PredictionsPublisher<SpeechToTextResult> {
        Future { promise in
            _ = self.convert(speechToText: speechToText, options: options) { promise($0) }
        }.eraseToAnyPublisher()
    }

    /// Convert the text to audio
    ///
    /// - Parameter textToSpeech: The text to be synthesized to audio
    /// - Parameter options: Parameters to specific plugin behavior
    func convert(
        textToSpeech: String,
        options: PredictionsTextToSpeechRequest.Options? = nil
    ) -> PredictionsPublisher<TextToSpeechResult> {
        Future { promise in
            _ = self.convert(textToSpeech: textToSpeech, options: options) { promise($0) }
        }.eraseToAnyPublisher()
    }

    /// Translate the text to the language specified
    ///
    /// - Parameter textToTranslate: The text to translate
    /// - Parameter language: The language of the text given
    /// - Parameter targetLanguage: The language to which the text should be translated
    /// - Parameter options: Parameters to specific plugin behavior
    func convert(
        textToTranslate: String,
        language: LanguageType?,
        targetLanguage: LanguageType?,
        options: PredictionsTranslateTextRequest.Options? = nil
    ) -> PredictionsPublisher<TranslateTextResult> {
        Future { promise in
            _ = self.convert(textToTranslate: textToTranslate,
                             language: language,
                             targetLanguage: targetLanguage,
                             options: options) { promise($0) }
        }.eraseToAnyPublisher()
    }

    /// Identify entites in an image
    ///
    /// - Parameter type: The type of image detection you want to perform
    /// - Parameter image: The image you are sending
    /// - Parameter options: Parameters to specific plugin behavior
    func identify(
        type: IdentifyAction,
        image: URL,
        options: PredictionsIdentifyRequest.Options? = nil
    ) -> PredictionsPublisher<IdentifyResult> {
        Future { promise in
            _ = self.identify(type: type, image: image, options: options) { promise($0) }
        }.eraseToAnyPublisher()
    }

    /// Interpret the text and return sentiment analysis, entity detection, language detection,
    /// syntax detection, key phrases detection
    ///
    /// - Parameter text: Text to interpret
    /// - Parameter options:Parameters to specific plugin behavior
    func interpret(
        text: String,
        options: PredictionsInterpretRequest.Options? = nil
    ) -> PredictionsPublisher<InterpretResult> {
        Future { promise in
            _ = self.interpret(text: text, options: options) { promise($0) }
        }.eraseToAnyPublisher()
    }

}
