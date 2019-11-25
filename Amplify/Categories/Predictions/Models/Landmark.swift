//
// Copyright 2018-2019 Amazon.com
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct Landmark {
    public let type: LandmarkType
    public let xPosition: Double
    public let yPosition: Double

    public init(type: LandmarkType, xPosition: Double, yPosition: Double) {
        self.type = type
        self.xPosition = xPosition
        self.yPosition = yPosition
    }
}

public enum LandmarkType {
    case unknown
    case eyeLeft
    case eyeRight
    case nose
    case mouthLeft
    case mouthRight
    case leftEyeBrowLeft
    case leftEyeBrowRight
    case leftEyeBrowUp
    case rightEyeBrowLeft
    case rightEyeBrowRight
    case rightEyeBrowUp
    case leftEyeLeft
    case leftEyeRight
    case leftEyeUp
    case leftEyeDown
    case rightEyeLeft
    case rightEyeRight
    case rightEyeUp
    case rightEyeDown
    case noseLeft
    case noseRight
    case mouthUp
    case mouthDown
    case leftPupil
    case rightPupil
    case upperJawlineLeft
    case midJawlineLeft
    case chinBottom
    case midJawlineRight
    case upperJawlineRight
}
