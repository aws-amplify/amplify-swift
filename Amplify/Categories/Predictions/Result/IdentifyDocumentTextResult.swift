//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct IdentifyDocumentTextResult: IdentifyResult {

    public let fullText: String
    public let words: [IdentifiedWord]
    public let lines: [String]
    public let linesDetailed: [IdentifiedWord]
    public let selections: [Selection]
    public let tables: [Table]
    public let keyValues: [BoundedKeyValue]

    public init(fullText: String,
                words: [IdentifiedWord],
                lines: [String],
                linesDetailed: [IdentifiedWord],
                selections: [Selection],
                tables: [Table],
                keyValues: [BoundedKeyValue]) {

        self.fullText = fullText
        self.words = words
        self.lines = lines
        self.linesDetailed = linesDetailed
        self.selections = selections
        self.tables = tables
        self.keyValues = keyValues
    }
}
