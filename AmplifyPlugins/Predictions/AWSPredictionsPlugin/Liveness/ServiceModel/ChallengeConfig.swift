//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct ChallengeConfig: Codable {
    let blazeFaceDetectionThreshold: Double
    let faceDistanceThreshold: Double
    let faceDistanceThresholdMax: Double
    let faceDistanceThresholdMin: Double
    let faceIouHeightThreshold: Double
    let faceIouWidthThreshold: Double
    let ovalHeightWidthRatio: Double
    let ovalIouHeightThreshold: Double
    let ovalIouThreshold: Double
    let ovalIouWidthThreshold: Double

    enum CodingKeys: String, CodingKey {
        case blazeFaceDetectionThreshold = "BlazeFaceDetectionThreshold"
        case faceDistanceThreshold = "FaceDistanceThreshold"
        case faceDistanceThresholdMax = "FaceDistanceThresholdMax"
        case faceDistanceThresholdMin = "FaceDistanceThresholdMin"
        case faceIouHeightThreshold = "FaceIouHeightThreshold"
        case faceIouWidthThreshold = "FaceIouWidthThreshold"
        case ovalHeightWidthRatio = "OvalHeightWidthRatio"
        case ovalIouHeightThreshold = "OvalIouHeightThreshold"
        case ovalIouThreshold = "OvalIouThreshold"
        case ovalIouWidthThreshold = "OvalIouWidthThreshold"
    }
}
