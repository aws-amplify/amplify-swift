//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

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
