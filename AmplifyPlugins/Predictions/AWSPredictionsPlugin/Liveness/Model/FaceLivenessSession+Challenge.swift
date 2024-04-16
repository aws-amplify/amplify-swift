//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension FaceLivenessSession {
    public static let supportedChallenges: [Challenge] = [
        Challenge(version: "2.0.0", type: .faceMovementAndLightChallenge),
        Challenge(version:"1.0.0", type: .faceMovementChallenge)
    ]
}
