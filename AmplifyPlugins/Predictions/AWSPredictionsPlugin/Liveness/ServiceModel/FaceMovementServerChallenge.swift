//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct FaceMovementServerChallenge: Codable {
    let ovalParameters: OvalParameters
    let challengeConfig: ChallengeConfig

    enum CodingKeys: String, CodingKey {
        case challengeConfig = "ChallengeConfig"
        case ovalParameters = "OvalParameters"
    }
}
