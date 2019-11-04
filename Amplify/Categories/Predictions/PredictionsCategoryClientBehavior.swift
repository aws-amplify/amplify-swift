//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import CoreGraphics

/// Behavior of the Predictions category that clients will use
public protocol PredictionsCategoryClientBehavior {

    //TOOD: Update the api names after final review
    // translate
    func convert(textToTranslate: String,
                 language: LanguageType?,
                 targetLanguage: LanguageType?,
                 listener: PredictionsTranslateTextOperation.EventListener?,
                 options: PredictionsTranslateTextRequest.Options?) -> PredictionsTranslateTextOperation
}

// TODO: Move these enums to a separate file
public enum LanguageType: String {
    case english = "en"
    case italian = "it"
}

public enum IdentifyType {
    case detectCelebrity
    case detectLabels
    case detectEntities
    case detectText
}
