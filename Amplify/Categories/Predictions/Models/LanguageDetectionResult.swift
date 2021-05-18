//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// struct holding information about a language detection for an interpret query
public struct LanguageDetectionResult {
    public let languageCode: LanguageType
    public let score: Double?

    public init(languageCode: LanguageType, score: Double?) {
        self.languageCode = languageCode
        self.score = score
    }
}
