//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import CoreGraphics
import Amplify

extension AWSPredictionsPlugin {
    
    public func convert(textToTranslate: String,
                        language: LanguageType,
                        targetLanguage: LanguageType,
                        listener: PredictionsTranslateTextOperation.EventListener? = nil,
                        options: PredictionsTranslateTextRequest.Options) -> PredictionsTranslateTextOperation {

        let options = options
        let request = PredictionsTranslateTextRequest(textToTranslate: textToTranslate, targetLanguage: targetLanguage, language: language, options: options)
        let convertOperation = AWSTranslateOperation(request,
                                                     translateService: translateService,
                                                     authService: authService,
                                                     listener: listener)
        queue.addOperation(convertOperation)
        return convertOperation
    }

    public func identify(type: IdentifyType,
                         image: CGImage,
                         options: Any?) -> PredictionsIdentifyOperation {
        fatalError("Not implemented")
    }
}
