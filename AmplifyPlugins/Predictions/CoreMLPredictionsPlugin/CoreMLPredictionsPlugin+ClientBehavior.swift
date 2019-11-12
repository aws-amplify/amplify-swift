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
        fatalError("Incomplete implementation")
    }

    public func identify(type: IdentifyType,
                         image: CGImage,
                         options: PredictionsIdentifyRequest.Options?,
                         listener: PredictionsIdentifyOperation.EventListener?) -> PredictionsIdentifyOperation {
        fatalError("Incomplete implementation")
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
