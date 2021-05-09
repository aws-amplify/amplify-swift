//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import CoreGraphics

/// Struct that holds the result of an entity detected from an image per the Identify method
public struct Entity {

    /// <#Description#>
    public let boundingBox: CGRect

    /// <#Description#>
    public let landmarks: [Landmark]

    /// <#Description#>
    public let ageRange: AgeRange?

    /// <#Description#>
    public let attributes: [Attribute]?

    /// <#Description#>
    public let gender: GenderAttribute?

    /// <#Description#>
    public let metadata: EntityMetadata

    /// <#Description#>
    public let emotions: [Emotion]?

    /// <#Description#>
    /// - Parameters:
    ///   - boundingBox: <#boundingBox description#>
    ///   - landmarks: <#landmarks description#>
    ///   - ageRange: <#ageRange description#>
    ///   - attributes: <#attributes description#>
    ///   - gender: <#gender description#>
    ///   - metadata: <#metadata description#>
    ///   - emotions: <#emotions description#>
    public init(boundingBox: CGRect,
                landmarks: [Landmark],
                ageRange: AgeRange?,
                attributes: [Attribute]?,
                gender: GenderAttribute?,
                metadata: EntityMetadata,
                emotions: [Emotion]?) {
        self.boundingBox = boundingBox
        self.landmarks = landmarks
        self.ageRange = ageRange
        self.attributes = attributes
        self.gender = gender
        self.metadata = metadata
        self.emotions = emotions
    }
}

/// <#Description#>
public struct EntityMetadata {

    /// <#Description#>
    public let confidence: Double

    /// <#Description#>
    public let pose: Pose

    /// <#Description#>
    /// - Parameters:
    ///   - confidence: <#confidence description#>
    ///   - pose: <#pose description#>
    public init(confidence: Double, pose: Pose) {
        self.confidence = confidence
        self.pose = pose
    }
}
