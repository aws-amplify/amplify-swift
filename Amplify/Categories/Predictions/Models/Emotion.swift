//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct Emotion {
    public var emotion: EmotionType
    public var confidence: Double

    public init(emotion: EmotionType, confidence: Double) {
        self.emotion = emotion
        self.confidence = confidence
    }
}
