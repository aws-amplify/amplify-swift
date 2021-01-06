//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import CoreGraphics
import Amplify

extension CoreMLPredictionsPlugin {

    public func convert(
        textToTranslate: String,
        language: LanguageType?,
        targetLanguage: LanguageType?,
        options: PredictionsTranslateTextRequest.Options?,
        listener: PredictionsTranslateTextOperation.ResultListener?
    ) -> PredictionsTranslateTextOperation {

        let options = options ?? PredictionsTranslateTextRequest.Options()
        let request = PredictionsTranslateTextRequest(textToTranslate: textToTranslate,
                                                      targetLanguage: targetLanguage,
                                                      language: language,
                                                      options: options)
        let operation = CoreMLTranslateTextOperation(request, resultListener: listener)
        queue.addOperation(operation)
        return operation
    }

    public func convert(
        textToSpeech: String,
        options: PredictionsTextToSpeechRequest.Options? = nil,
        listener: PredictionsTextToSpeechOperation.ResultListener?
    ) -> PredictionsTextToSpeechOperation {
        let options = options ?? PredictionsTextToSpeechRequest.Options()
        let request = PredictionsTextToSpeechRequest(textToSpeech: textToSpeech,
                                                     options: options)
        let operation = CoreMLTextToSpeechOperation(request, resultListener: listener)
        queue.addOperation(operation)
        return operation
    }

    public func convert(
        speechToText: URL,
        options: PredictionsSpeechToTextRequest.Options?,
        listener: PredictionsSpeechToTextOperation.ResultListener?
    ) -> PredictionsSpeechToTextOperation {
        let options = options ?? PredictionsSpeechToTextRequest.Options()
        let request = PredictionsSpeechToTextRequest(speechToText: speechToText, options: options)
        let operation = CoreMLSpeechToTextOperation(request, coreMLSpeech: coreMLSpeech, resultListener: listener)
        queue.addOperation(operation)
        return operation
    }

    public func identify(type: IdentifyAction,
                         image: URL,
                         options: PredictionsIdentifyRequest.Options?,
                         listener: PredictionsIdentifyOperation.ResultListener?) -> PredictionsIdentifyOperation {
        let options = options ?? PredictionsIdentifyRequest.Options()
        let request = PredictionsIdentifyRequest(image: image,
                                                 identifyType: type,
                                                 options: options)
        let operation = CoreMLIdentifyOperation(request,
                                                coreMLVision: coreMLVision,
                                                resultListener: listener)
        queue.addOperation(operation)
        return operation
    }

    public func interpret(text: String,
                          options: PredictionsInterpretRequest.Options?,
                          listener: PredictionsInterpretOperation.ResultListener?) -> PredictionsInterpretOperation {
        let options = options ?? PredictionsInterpretRequest.Options()
        let request = PredictionsInterpretRequest(textToInterpret: text, options: options)
        let interpretOperation = CoreMLInterpretTextOperation(request,
                                                              coreMLNaturalLanguage: coreMLNaturalLanguage,
                                                              resultListener: listener)
        queue.addOperation(interpretOperation)
        return interpretOperation
    }

}
