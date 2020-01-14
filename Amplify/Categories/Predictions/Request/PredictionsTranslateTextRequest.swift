//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public class PredictionsTranslateTextRequest: PredictionsConvertRequest {

    /// The text to translate.
    public let textToTranslate: String

    /// The language to translate
    public let targetLanguage: LanguageType?

    /// Source language of the text given.
    public let language: LanguageType?

    public init(textToTranslate: String,
                targetLanguage: LanguageType?,
                language: LanguageType?,
                options: Options) {
        self.textToTranslate = textToTranslate
        self.language = language
        self.targetLanguage = targetLanguage
        super.init(type: .translateText, options: options)
    }
}

