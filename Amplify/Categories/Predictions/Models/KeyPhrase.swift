//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct KeyPhrase {

    public let score: Float?
    public let text: String
    public let range: Range<String.Index>

    public init(text: String, range: Range<String.Index>, score: Float?) {
        self.text = text
        self.range = range
        self.score = score
    }
}
