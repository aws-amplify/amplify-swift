//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct KeyPhrase {

    let score: Float?
    let text: String
    let range: Range<String.Index>

    public init(text: String, range: Range<String.Index>, score: Float?) {
        self.text = text
        self.range = range
        self.score = score
    }
}
