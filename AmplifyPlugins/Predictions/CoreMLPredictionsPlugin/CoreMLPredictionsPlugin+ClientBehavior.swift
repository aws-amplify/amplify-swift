//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import CoreGraphics
import Amplify

extension CoreMLPredictionsPlugin {

    public func convert(textToTranslate: String,
                        language: LanguageType?,
                        targetLanguage: LanguageType?,
                        options: PredictionsTranslateTextRequest.Options?,
                        listener: PredictionsTranslateTextOperation.EventListener?) -> PredictionsTranslateTextOperation {

        let options = options ?? PredictionsTranslateTextRequest.Options()
        let request = PredictionsTranslateTextRequest(textToTranslate: textToTranslate,
                                                      targetLanguage: targetLanguage,
                                                      language: language,
                                                      options: options)
        let operation = CoreMLTranslateTextOperation(request, listener: listener)
        queue.addOperation(operation)
        return operation
    }

    public func convert(textToSpeech: String,
                        options: PredictionsTextToSpeechRequest.Options? = nil,
                        listener: PredictionsTextToSpeechOperation.EventListener?) -> PredictionsTextToSpeechOperation {
        let options = options ?? PredictionsTextToSpeechRequest.Options()
        let request = PredictionsTextToSpeechRequest(textToSpeech: textToSpeech,
                                                     options: options)
        let operation = CoreMLTextToSpeechOperation(request, listener: listener)
        queue.addOperation(operation)
        return operation
    }

    public func convert(speechToText: URL,
                        options: PredictionsSpeechToTextRequest.Options?,
                        listener: PredictionsSpeechToTextOperation.EventListener?) -> PredictionsSpeechToTextOperation {
        let options = options ?? PredictionsSpeechToTextRequest.Options()
        let request = PredictionsSpeechToTextRequest(speechToText: speechToText, options: options)
        let operation = CoreMLSpeechToTextOperation(request, coreMLSpeech: coreMLSpeech, listener: listener)
        queue.addOperation(operation)
        return operation
    }

    public func identify(type: IdentifyAction,
                         image: URL,
                         options: PredictionsIdentifyRequest.Options?,
                         listener: PredictionsIdentifyOperation.EventListener?) -> PredictionsIdentifyOperation {
        let options = options ?? PredictionsIdentifyRequest.Options()
        let request = PredictionsIdentifyRequest(image: image,
                                                 identifyType: type,
                                                 options: options)
        let operation = CoreMLIdentifyOperation(request,
                                                coreMLVision: coreMLVision,
                                                listener: listener)
        queue.addOperation(operation)
        return operation
    }

    public func interpret(text: String,
                          options: PredictionsInterpretRequest.Options?,
                          listener: PredictionsInterpretOperation.EventListener?) -> PredictionsInterpretOperation {
        let options = options ?? PredictionsInterpretRequest.Options()
        let request = PredictionsInterpretRequest(textToInterpret: text, options: options)
        let interpretOperation = CoreMLInterpretTextOperation(request,
                                                              coreMLNaturalLanguage: coreMLNaturalLanguage,
                                                              listener: listener)
        queue.addOperation(interpretOperation)
        return interpretOperation
    }

}
