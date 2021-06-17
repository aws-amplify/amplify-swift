//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Result describing language identified in a text
/// from interpret() API call
public struct LanguageDetectionResult {
    public let languageCode: LanguageType
    public let score: Double?

    public init(languageCode: LanguageType, score: Double?) {
        self.languageCode = languageCode
        self.score = score
    }
}
