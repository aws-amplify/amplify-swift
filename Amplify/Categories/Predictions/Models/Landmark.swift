//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import CoreGraphics

/// <#Description#>
public struct Landmark {

    /// <#Description#>
    public let type: LandmarkType

    /// <#Description#>
    public let points: [CGPoint]

    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - points: <#points description#>
    public init(type: LandmarkType, points: [CGPoint]) {
        self.type = type
        self.points = points
    }
}

/// <#Description#>
public enum LandmarkType {

    /// <#Description#>
    case allPoints

    /// <#Description#>
    case leftEye

    /// <#Description#>
    case rightEye

    /// <#Description#>
    case leftEyebrow

    /// <#Description#>
    case rightEyebrow

    /// <#Description#>
    case nose

    /// <#Description#>
    case noseCrest

    /// <#Description#>
    case medianLine

    /// <#Description#>
    case outerLips

    /// <#Description#>
    case innerLips

    /// <#Description#>
    case leftPupil

    /// <#Description#>
    case rightPupil

    /// <#Description#>
    case faceContour
}
