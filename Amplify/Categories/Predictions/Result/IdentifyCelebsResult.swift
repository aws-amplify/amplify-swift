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
    var metadata: CelebMetadata
    var boundingBox: BoundingBox
    var landmarks: [Landmark]

    public init(metadata: CelebMetadata, boundingBox: BoundingBox, landmarks: [Landmark]) {
        self.metadata = metadata
        self.boundingBox = boundingBox
        self.landmarks = landmarks
    }
}

public struct Landmark {
    var type: String
    var xPosition: Double
    var yPosition: Double

    public init(type: String, xPosition: Double, yPosition: Double) {
        self.type = type
        self.xPosition = xPosition
        self.yPosition = yPosition
    }
}

public struct CelebMetadata {
    var name: String
    var identifier: String
    var urls: [URL]
    var pose: Pose

    public init(name: String, identifier: String, urls: [URL], pose: Pose) {
        self.name = name
        self.identifier = identifier
        self.urls = urls
        self.pose = pose
    }
}

public struct Pose {
    var pitch: Double
    var roll: Double
    var yaw: Double

    public init(pitch: Double, roll: Double, yaw: Double) {
        self.pitch = pitch
        self.roll = roll
        self.yaw = yaw
    }
}
