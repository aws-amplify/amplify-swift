//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// <#Description#>
public struct Emotion {

    /// <#Description#>
    public let emotion: EmotionType

    /// <#Description#>
    public let confidence: Double

    /// <#Description#>
    /// - Parameters:
    ///   - emotion: <#emotion description#>
    ///   - confidence: <#confidence description#>
    public init(emotion: EmotionType, confidence: Double) {
        self.emotion = emotion
        self.confidence = confidence
    }
}
