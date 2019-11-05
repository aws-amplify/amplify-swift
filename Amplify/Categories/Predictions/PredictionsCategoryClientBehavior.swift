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

    /// Translate the text to the language specified.
    /// - Parameter textToTranslate: The text to translate
    /// - Parameter language: The language of the text given
    /// - Parameter targetLanguage: The language to which the text should be translated
    /// - Parameter listener: Triggered when the event occurs
    /// - Parameter options: Parameters to specific plugin behavior
    func convert(textToTranslate: String,
                 language: LanguageType?,
                 targetLanguage: LanguageType?,
                 listener: PredictionsTranslateTextOperation.EventListener?,
                 options: PredictionsTranslateTextRequest.Options?) -> PredictionsTranslateTextOperation

    func identify(type: IdentifyType,
                   image: CGImage,
                   options: PredictionsIdentifyRequest.Options,
                   listener: PredictionsIdentifyOperation.EventListener?) -> PredictionsIdentifyOperation
}

// TODO: Move these enums to a separate file
/// Language type supported
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
