//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// <#Description#>
public struct SyntaxToken {

    /// <#Description#>
    public let tokenId: Int

    /// <#Description#>
    public let text: String

    /// <#Description#>
    public let range: Range<String.Index>

    /// <#Description#>
    public let partOfSpeech: PartOfSpeech

    /// <#Description#>
    /// - Parameters:
    ///   - tokenId: <#tokenId description#>
    ///   - text: <#text description#>
    ///   - range: <#range description#>
    ///   - partOfSpeech: <#partOfSpeech description#>
    public init(tokenId: Int,
                text: String,
                range: Range<String.Index>,
                partOfSpeech: PartOfSpeech) {
        self.tokenId = tokenId
        self.text = text
        self.range = range
        self.partOfSpeech = partOfSpeech
    }
}
