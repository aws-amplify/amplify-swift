//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension FaceLivenessSession {
    @_spi(PredictionsFaceLiveness)
    public enum SessionConfiguration {
        case faceMovement(OvalMatchChallenge)
        case faceMovementAndLight(ColorChallenge, OvalMatchChallenge)
    }
}
