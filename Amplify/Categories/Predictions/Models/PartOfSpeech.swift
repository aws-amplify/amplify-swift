//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Part of speech identified in a text from interpret() API
public struct PartOfSpeech {
    public let tag: SpeechType
    public let score: Float?

    public init(
        tag: SpeechType,
        score: Float?
    ) {
        self.tag = tag
        self.score = score
    }
}
