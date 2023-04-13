//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Describes the result of interpret() API when the analyzed text
/// contains a person/place
public struct EntityDetectionResult {
    public let type: EntityType
    public let targetText: String
    public let score: Float?
    public let range: Range<String.Index>

    public init(
        type: EntityType,
        targetText: String,
        score: Float?,
        range: Range<String.Index>
    ) {
        self.type = type
        self.targetText = targetText
        self.score = score
        self.range = range
    }
}
