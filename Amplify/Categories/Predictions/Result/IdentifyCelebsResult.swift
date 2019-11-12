//
//  IdentifyFacesResult.swift
//  Amplify
//
//  Created by Stone, Nicki on 11/8/19.
//

import Foundation

public struct IdentifyCelebsResult: IdentifyResult {
    public var celebrities: [Celebrity]

    public init(celebrities: [Celebrity]) {
        self.celebrities = celebrities
    }
}

public struct Celebrity {
    public var metadata: CelebMetadata
    public var boundingBox: BoundingBox
    public var landmarks: [Landmark]

    public init(metadata: CelebMetadata, boundingBox: BoundingBox, landmarks: [Landmark]) {
        self.metadata = metadata
        self.boundingBox = boundingBox
        self.landmarks = landmarks
    }
}

public struct Landmark {
    public var type: String
    public var xPosition: Double
    public var yPosition: Double

    public init(type: String, xPosition: Double, yPosition: Double) {
        self.type = type
        self.xPosition = xPosition
        self.yPosition = yPosition
    }
}

public struct CelebMetadata {
    public var name: String
    public var identifier: String
    public var urls: [URL]
    public var pose: Pose

    public init(name: String, identifier: String, urls: [URL], pose: Pose) {
        self.name = name
        self.identifier = identifier
        self.urls = urls
        self.pose = pose
    }
}

public struct Pose {
    public var pitch: Double
    public var roll: Double
    public var yaw: Double

    public init(pitch: Double, roll: Double, yaw: Double) {
        self.pitch = pitch
        self.roll = roll
        self.yaw = yaw
    }
}
