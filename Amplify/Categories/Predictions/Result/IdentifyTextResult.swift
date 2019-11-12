//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct IdentifyTextResult: IdentifyResult {
    public var fullText: String
    public var words: [Word]
    public var lines: [String]
    public var linesDetailed: [Word]

    public init(fullText: String, words: [Word], lines: [String], linesDetailed: [Word]) {
        self.fullText = fullText
        self.words = words
        self.lines = lines
        self.linesDetailed = linesDetailed
    }
}
