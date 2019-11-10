//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct PartOfSpeech {
    let tag: SpeechType
    let score: Float?

    public init(tag: SpeechType, score: Float?) {
        self.tag = tag
        self.score = score
    }
}
