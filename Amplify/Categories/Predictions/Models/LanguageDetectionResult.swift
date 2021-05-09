//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// <#Description#>
public struct LanguageDetectionResult {

    /// <#Description#>
    public let languageCode: LanguageType

    /// <#Description#>
    public let score: Double?

    /// <#Description#>
    /// - Parameters:
    ///   - languageCode: <#languageCode description#>
    ///   - score: <#score description#>
    public init(languageCode: LanguageType, score: Double?) {
        self.languageCode = languageCode
        self.score = score
    }
}
