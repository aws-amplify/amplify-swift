//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import CoreGraphics

/// Describes the facial feature in a celebrity/entity
/// identified as a result of identify() API
public struct Landmark {
    public let type: LandmarkType
    public let points: [CGPoint]

    public init(type: LandmarkType, points: [CGPoint]) {
        self.type = type
        self.points = points
    }
}

/// different types of facial features
public enum LandmarkType {

    case allPoints
    case leftEye
    case rightEye
    case leftEyebrow
    case rightEyebrow
    case nose
    case noseCrest
    case medianLine
    case outerLips
    case innerLips
    case leftPupil
    case rightPupil
    case faceContour
}
