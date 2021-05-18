//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// struct holding `SpeechType` and a confidence score detected in a text
public struct PartOfSpeech {
    public let tag: SpeechType
    public let score: Float?

    public init(tag: SpeechType, score: Float?) {
        self.tag = tag
        self.score = score
    }
}
