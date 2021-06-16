//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Results are mapped to TranslateTextResult when convert() API is
/// called to translate a text into another language
public struct TranslateTextResult: ConvertResult {

    /// Translated text
    public let text: String

    /// Language to which the text was translated.
    public let targetLanguage: LanguageType

    public init(text: String, targetLanguage: LanguageType) {
        self.text = text
        self.targetLanguage = targetLanguage
    }
}
