//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct Entity {
    public var boundingBox: BoundingBox
    public var landmarks: [Landmark]
    public var ageRange: AgeRange
    public var attributes: [Attribute]
    public var gender: GenderAttribute
    public var metadata: EntityMetadata
    public var emotions: [Emotion]

    public init(boundingBox: BoundingBox, landmarks: [Landmark], ageRange: AgeRange, attributes: [Attribute], gender: GenderAttribute, metadata: EntityMetadata, emotions: [Emotion]) {
        self.boundingBox = boundingBox
        self.landmarks = landmarks
        self.ageRange = ageRange
        self.attributes = attributes
        self.gender = gender
        self.metadata = metadata
        self.emotions = emotions
    }
}

public struct EntityMetadata{
    public var confidence: Double
    public var pose: Pose

    public init(confidence: Double, pose: Pose) {
        self.confidence = confidence
        self.pose = pose
    }
}

