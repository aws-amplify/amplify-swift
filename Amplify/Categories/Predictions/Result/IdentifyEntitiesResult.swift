//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct IdentifyEntitiesResult: IdentifyResult {
    public var entities: [Entity]

    public init(entities: [Entity]) {
        self.entities = entities
    }
}

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

public struct AgeRange {
    public var low: Int
    public var high: Int

    public init(low: Int, high: Int) {
        self.low = low
        self.high = high
    }
}

public struct Attribute {
    public var name: String
    public var value: Bool
    public var confidence: Double

    public init(name: String, value: Bool, confidence: Double) {
        self.name = name
        self.value = value
        self.confidence = confidence
    }
}

public struct GenderAttribute {
    public var gender: GenderType
    public var confidence: Double

    public init(gender: GenderType, confidence: Double) {
        self.gender = gender
        self.confidence = confidence
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

public struct Emotion {
    public var emotion: EmotionType
    public var confidence: Double

    public init(emotion: EmotionType, confidence: Double) {
        self.emotion = emotion
        self.confidence = confidence
    }
}

public enum GenderType {
    case male
    case female
    case unknown
}
public enum EmotionType {
    case happy
    case sad
    case angry
    case confused
    case disgusted
    case surprised
    case calm
    case fear
    case unknown
}
