//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct ServerChallenge: Codable {
    let faceMovementAndLightChallenge: FaceMovementAndLightServerChallenge

    enum CodingKeys: String, CodingKey {
        case faceMovementAndLightChallenge = "FaceMovementAndLightChallenge"
    }
}
