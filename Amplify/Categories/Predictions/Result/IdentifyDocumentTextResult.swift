//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct IdentifyDocumentTextResult: IdentifyResult {

    public var fullText: String
    public var words: [Word]
    public var lines: [String]
    public var linesDetailed: [Word]
    public var selections: [Selection]
    public var table: Table
    public var keyValues: [KeyValue]

    public init(fullText: String,
                words: [Word],
                lines: [String],
                linesDetailed: [Word],
                selections: [Selection],
                table: Table,
                keyValues: [KeyValue]) {

        self.fullText = fullText
        self.words = words
        self.lines = lines
        self.linesDetailed = linesDetailed
        self.selections = selections
        self.table = table
        self.keyValues = keyValues
    }
}
