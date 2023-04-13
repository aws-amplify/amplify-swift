//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import CoreGraphics

/// Result returned as part of identify() API call with
/// `IdentifyAction.detectEntities` type parameter
public struct Entity {
    public let boundingBox: CGRect
    public let landmarks: [Landmark]
    public let ageRange: AgeRange?
    public let attributes: [Attribute]?
    public let gender: GenderAttribute?
    public let metadata: EntityMetadata
    public let emotions: [Emotion]?

    public init(
        boundingBox: CGRect,
        landmarks: [Landmark],
        ageRange: AgeRange?,
        attributes: [Attribute]?,
        gender: GenderAttribute?,
        metadata: EntityMetadata,
        emotions: [Emotion]?
    ) {
        self.boundingBox = boundingBox
        self.landmarks = landmarks
        self.ageRange = ageRange
        self.attributes = attributes
        self.gender = gender
        self.metadata = metadata
        self.emotions = emotions
    }
}

public struct EntityMetadata {
    public let confidence: Double
    public let pose: Pose

    public init(confidence: Double, pose: Pose) {
        self.confidence = confidence
        self.pose = pose
    }
}
