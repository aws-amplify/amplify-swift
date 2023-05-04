//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct TargetFace: Codable {
    let boundingBox: BoundingBox
    let faceDetectedInTargetPositionStartTimestamp: UInt64
    let faceDetectedInTargetPositionEndTimestamp: UInt64

    enum CodingKeys: String, CodingKey {
        case boundingBox = "BoundingBox"
        case faceDetectedInTargetPositionStartTimestamp = "FaceDetectedInTargetPositionStartTimestamp"
        case faceDetectedInTargetPositionEndTimestamp = "FaceDetectedInTargetPositionEndTimestamp"
    }
}
