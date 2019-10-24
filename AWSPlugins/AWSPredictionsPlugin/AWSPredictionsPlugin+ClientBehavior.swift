//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import CoreGraphics
import Amplify
import AWSTranslate

extension AWSPredictionsPlugin {

    public func convert(textToTranslate: String,
                        language: LanguageType,
                        targetLanguage: LanguageType,
                        options: Any?) -> PredictionsConvertOperation {
        let translate = AWSTranslate.default()
        
        fatalError("Not implemented")
    }

    public func identify(type: IdentifyType,
                         image: CGImage,
                         options: Any?) -> PredictionsIdentifyOperation {
        fatalError("Not implemented")
    }
}
