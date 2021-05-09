//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// <#Description#>
public struct IdentifyDocumentTextResult: IdentifyResult {

    /// <#Description#>
    public let fullText: String

    /// <#Description#>
    public let words: [IdentifiedWord]

    /// <#Description#>
    public let rawLineText: [String]

    /// <#Description#>
    public let identifiedLines: [IdentifiedLine]

    /// <#Description#>
    public let selections: [Selection]

    /// <#Description#>
    public let tables: [Table]

    /// <#Description#>
    public let keyValues: [BoundedKeyValue]

    /// <#Description#>
    /// - Parameters:
    ///   - fullText: <#fullText description#>
    ///   - words: <#words description#>
    ///   - rawLineText: <#rawLineText description#>
    ///   - identifiedLines: <#identifiedLines description#>
    ///   - selections: <#selections description#>
    ///   - tables: <#tables description#>
    ///   - keyValues: <#keyValues description#>
    public init(fullText: String,
                words: [IdentifiedWord],
                rawLineText: [String],
                identifiedLines: [IdentifiedLine],
                selections: [Selection],
                tables: [Table],
                keyValues: [BoundedKeyValue]) {

        self.fullText = fullText
        self.words = words
        self.rawLineText = rawLineText
        self.identifiedLines = identifiedLines
        self.selections = selections
        self.tables = tables
        self.keyValues = keyValues
    }
}
