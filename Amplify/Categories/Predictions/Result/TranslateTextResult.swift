//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct TranslateTextResult: ConvertResult {
    let text: String
    let targetLanguage: LanguageType

    public init(text: String, targetLanguage: LanguageType) {
        self.text = text
        self.targetLanguage = targetLanguage
    }
}
