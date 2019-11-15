//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Struct that holds the entity detection result for a string of text for the Predictions category
public struct EntityDetectionResult {
    let type: EntityType
    let targetText: String
    let score: Float?
    let range: Range<String.Index>

    public init(type: EntityType,
                targetText: String,
                score: Float?,
                range: Range<String.Index>) {
        self.type = type
        self.targetText = targetText
        self.score = score
        self.range = range
    }
}
