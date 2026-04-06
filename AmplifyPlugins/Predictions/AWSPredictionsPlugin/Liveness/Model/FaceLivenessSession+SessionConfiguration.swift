//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public extension FaceLivenessSession {
    @_spi(PredictionsFaceLiveness)
    enum SessionConfiguration {
        case faceMovement(OvalMatchChallenge)
        case faceMovementAndLight(ColorChallenge, OvalMatchChallenge)
    }
}
