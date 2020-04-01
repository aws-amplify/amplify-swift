//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct SyntaxToken {

    public let tokenId: Int
    public let text: String
    public let range: Range<String.Index>
    public let partOfSpeech: PartOfSpeech

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
