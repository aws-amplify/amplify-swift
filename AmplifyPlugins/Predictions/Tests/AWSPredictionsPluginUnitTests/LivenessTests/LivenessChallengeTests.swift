//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
@testable import AWSPredictionsPlugin
@_spi(PredictionsFaceLiveness) import AWSPredictionsPlugin

class LivenessChallengeTests: XCTestCase {
    
    func testFaceMovementChallengeQueryParamterString() {
        let challenge = Challenge(version: "1.0.0", type: .faceMovementChallenge)
        XCTAssertEqual(challenge.queryParameterString(), "FaceMovementChallenge_1.0.0")
    }
    
    func testFaceMovementAndLightChallengeQueryParamterString() {
        let challenge = Challenge(version: "2.0.0", type: .faceMovementAndLightChallenge)
        XCTAssertEqual(challenge.queryParameterString(), "FaceMovementAndLightChallenge_2.0.0")
    }
}
