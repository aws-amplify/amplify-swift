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
                        listener: PredictionsTranslateTextOperation.EventListener?,
                        options: PredictionsTranslateTextRequest.Options?) -> PredictionsTranslateTextOperation {
        // TODO: Remove the below and add proper message
        fatalError("Incomplete implementation")
    }

    public func convert(textToSpeech: String,
                        options: PredictionsTextToSpeechRequest.Options? = nil,
                        listener: PredictionsTextToSpeechOperation.EventListener?) -> PredictionsTextToSpeechOperation {
        // TODO: Remove the below and add proper message
        fatalError("Incomplete implementation")
    }

    public func identify(type: IdentifyAction,
                         image: URL,
                         options: PredictionsIdentifyRequest.Options?,
                         listener: PredictionsIdentifyOperation.EventListener?) -> PredictionsIdentifyOperation {
        let options = options
        let request = PredictionsIdentifyRequest(image: image,
                                                 identifyType: type,
                                                 options: options ?? PredictionsIdentifyRequest.Options())
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
