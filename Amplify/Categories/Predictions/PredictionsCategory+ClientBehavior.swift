//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import CoreImage

extension PredictionsCategory: PredictionsCategoryClientBehavior {

    public func convert(textToTranslate: String,
                        language: LanguageType?,
                        targetLanguage: LanguageType?,
                        listener: PredictionsTranslateTextOperation.EventListener?,
                        options: PredictionsTranslateTextRequest.Options?) -> PredictionsTranslateTextOperation {
        plugin.convert(textToTranslate: textToTranslate,
                       language: language,
                       targetLanguage: targetLanguage,
                       listener: listener,
                       options: options)
    }

    public func identify(type: IdentifyType,
                         image: CGImage,
                         options: PredictionsIdentifyRequest.Options,
                         listener: PredictionsIdentifyOperation.EventListener?) -> PredictionsIdentifyOperation {
        plugin.identify(type: type,
                        image: image,
                        options: options,
                        listener: listener)
    }
}
