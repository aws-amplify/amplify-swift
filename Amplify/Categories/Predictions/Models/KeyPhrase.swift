//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// <#Description#>
public struct KeyPhrase {

    /// <#Description#>
    public let score: Float?

    /// <#Description#>
    public let text: String

    /// <#Description#>
    public let range: Range<String.Index>

    /// <#Description#>
    /// - Parameters:
    ///   - text: <#text description#>
    ///   - range: <#range description#>
    ///   - score: <#score description#>
    public init(text: String, range: Range<String.Index>, score: Float?) {
        self.text = text
        self.range = range
        self.score = score
    }
}
