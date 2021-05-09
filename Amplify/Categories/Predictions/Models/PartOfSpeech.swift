//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// <#Description#>
public struct PartOfSpeech {

    /// <#Description#>
    public let tag: SpeechType

    /// <#Description#>
    public let score: Float?

    /// <#Description#>
    /// - Parameters:
    ///   - tag: <#tag description#>
    ///   - score: <#score description#>
    public init(tag: SpeechType, score: Float?) {
        self.tag = tag
        self.score = score
    }
}
