//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import XCTest
@testable import AWSPredictionsPlugin
@_spi(PredictionsFaceLiveness) import AWSPredictionsPlugin

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class LivenessChallengeTests: XCTestCase, @unchecked Sendable {

    func testFaceMovementChallengeQueryParamterString() {
        let challenge: Challenge = .faceMovementChallenge("1.0.0")
        XCTAssertEqual(challenge.queryParameterString(), "FaceMovementChallenge_1.0.0")
    }

    func testFaceMovementAndLightChallengeQueryParamterString() {
        let challenge: Challenge = .faceMovementAndLightChallenge("2.0.0")
        XCTAssertEqual(challenge.queryParameterString(), "FaceMovementAndLightChallenge_2.0.0")
    }
}
