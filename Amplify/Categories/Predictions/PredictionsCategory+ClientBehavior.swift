//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension PredictionsCategory: PredictionsCategoryBehavior {

    @discardableResult
    public func convert(textToSpeech: String,
                        options: PredictionsTextToSpeechRequest.Options? = nil,
                        listener: PredictionsTextToSpeechOperation.ResultListener?
    ) -> PredictionsTextToSpeechOperation {
        plugin.convert(textToSpeech: textToSpeech,
                       options: options,
                       listener: listener)
    }

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

    @discardableResult
    public func convert(speechToText: URL,
                        options: PredictionsSpeechToTextRequest.Options?,
                        listener: PredictionsSpeechToTextOperation.ResultListener?
    ) -> PredictionsSpeechToTextOperation {
        plugin.convert(speechToText: speechToText, options: options, listener: listener)
    }

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
