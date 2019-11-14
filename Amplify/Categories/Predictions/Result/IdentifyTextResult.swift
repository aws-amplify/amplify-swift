//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct IdentifyTextResult: IdentifyResult {
    public let fullText: String
    public let words: [IdentifiedWord]
    public let lines: [String]
    public let linesDetailed: [IdentifiedWord]

    public init(fullText: String, words: [IdentifiedWord], lines: [String], linesDetailed: [IdentifiedWord]) {
        self.fullText = fullText
        self.words = words
        self.lines = lines
        self.linesDetailed = linesDetailed
    }
}
