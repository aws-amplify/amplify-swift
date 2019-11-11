//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct SyntaxToken {
    let tokenId: Int
    let text: String
    let range: Range<String.Index>
    let partOfSpeech: PartOfSpeech

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
