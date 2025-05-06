//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct FaceMovementClientChallenge: Codable {
    let challengeID: String
    let targetFace: TargetFace?
    let initialFace: InitialFace?
    let videoStartTimestamp: UInt64?
    let videoEndTimeStamp: UInt64?

    enum CodingKeys: String, CodingKey {
        case challengeID = "ChallengeId"
        case targetFace = "TargetFace"
        case initialFace = "InitialFace"
        case videoStartTimestamp = "VideoStartTimestamp"
        case videoEndTimeStamp = "VideoEndTimestamp"
    }
}
