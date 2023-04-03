//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct ClientChallenge: Codable {
    let faceMovementAndLightChallenge: FaceMovementAndLightClientChallenge?

    enum CodingKeys: String, CodingKey {
        case faceMovementAndLightChallenge = "FaceMovementAndLightChallenge"
    }
}
