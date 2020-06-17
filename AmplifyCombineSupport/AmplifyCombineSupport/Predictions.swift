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
    func convert(
        speechToText: URL,
        options: PredictionsSpeechToTextRequest.Options? = nil
    ) -> PredictionsPublisher<SpeechToTextResult> {
        Future { promise in
            _ = self.convert(speechToText: speechToText, options: options) { promise($0) }
        }.eraseToAnyPublisher()
    }

    func convert(
        textToSpeech: String,
        options: PredictionsTextToSpeechRequest.Options? = nil
    ) -> PredictionsPublisher<TextToSpeechResult> {
        Future { promise in
            _ = self.convert(textToSpeech: textToSpeech, options: options) { promise($0) }
        }.eraseToAnyPublisher()
    }

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

    func identify(
        type: IdentifyAction,
        image: URL,
        options: PredictionsIdentifyRequest.Options? = nil
    ) -> PredictionsPublisher<IdentifyResult> {
        Future { promise in
            _ = self.identify(type: type, image: image, options: options) { promise($0) }
        }.eraseToAnyPublisher()
    }

    func interpret(
        text: String,
        options: PredictionsInterpretRequest.Options? = nil
    ) -> PredictionsPublisher<InterpretResult> {
        Future { promise in
            _ = self.interpret(text: text, options: options) { promise($0) }
        }.eraseToAnyPublisher()
    }

}
