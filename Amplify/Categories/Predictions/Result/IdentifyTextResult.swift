//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// <#Description#>
public struct IdentifyTextResult: IdentifyResult {

    /// <#Description#>
    public let fullText: String?

    /// <#Description#>
    public let words: [IdentifiedWord]?

    /// <#Description#>
    public let rawLineText: [String]?

    /// <#Description#>
    public let identifiedLines: [IdentifiedLine]?

    /// <#Description#>
    /// - Parameters:
    ///   - fullText: <#fullText description#>
    ///   - words: <#words description#>
    ///   - rawLineText: <#rawLineText description#>
    ///   - identifiedLines: <#identifiedLines description#>
    public init(fullText: String?,
                words: [IdentifiedWord]?,
                rawLineText: [String]?,
                identifiedLines: [IdentifiedLine]?) {
        self.fullText = fullText
        self.words = words
        self.rawLineText = rawLineText
        self.identifiedLines = identifiedLines
    }
}
