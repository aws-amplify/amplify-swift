//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Struct that holds the entity detection result for a string of text for the Predictions category
public struct EntityDetectionResult {
    public let type: EntityType
    public let targetText: String
    public let score: Float?
    public let range: Range<String.Index>

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
