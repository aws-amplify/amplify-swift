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
                        language: LanguageType,
                        targetLanguage: LanguageType,
                        options: Any?) -> PredictionsConvertOperation {
        plugin.convert(textToTranslate: textToTranslate,
                       language: language,
                       targetLanguage: targetLanguage,
                       options: options)
    }

    public func identify(type: IdentifyType,
                         image: CGImage,
                         options: Any?) -> PredictionsIdentifyOperation {
        plugin.identify(type: type,
                        image: image,
                        options: options)
    }
}
