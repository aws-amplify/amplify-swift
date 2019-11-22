//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension PredictionsCategory: PredictionsCategoryClientBehavior {

    public func convert(textToSpeech: String,
                        options: PredictionsTextToSpeechRequest.Options? = nil,
                        listener: PredictionsTextToSpeechOperation.EventListener?) -> PredictionsTextToSpeechOperation {
        plugin.convert(textToSpeech: textToSpeech,
                       options: options,
                       listener: listener)
    }

    public func convert(textToTranslate: String,
                        language: LanguageType?,
                        targetLanguage: LanguageType?,
                        options: PredictionsTranslateTextRequest.Options? = nil,
                        listener: PredictionsTranslateTextOperation.EventListener?)
        -> PredictionsTranslateTextOperation {
        plugin.convert(textToTranslate: textToTranslate,
                       language: language,
                       targetLanguage: targetLanguage,
                       options: options,
                       listener: listener)
    }

    public func identify(type: IdentifyAction,
                         image: URL,
                         options: PredictionsIdentifyRequest.Options? = nil,
                         listener: PredictionsIdentifyOperation.EventListener?) -> PredictionsIdentifyOperation {
        plugin.identify(type: type,
                        image: image,
                        options: options,
                        listener: listener)
    }

    public func interpret(text: String,
                          options: PredictionsInterpretRequest.Options? = nil,
                          listener: PredictionsInterpretOperation.EventListener?) -> PredictionsInterpretOperation {
        plugin.interpret(text: text,
                         options: options,
                         listener: listener)
    }
}
