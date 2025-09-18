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

class LivenessDecodingTests: XCTestCase {

    // MARK: - ChallengeEvent
    /// - Given: A valid json payload depicting a FaceMovementChallenge
    /// - When: The payload is decoded
    /// - Then: The payload is decoded successfully
    func testFacemovementChallengeEventDecodeSuccess() {
        let jsonString =
        """
        {"Type":"FaceMovementChallenge","Version":"1.0.0"}
        """

        do {
            let data = jsonString.data(using: .utf8)
            guard let data = data else {
                XCTFail("Input JSON is invalid")
                return
            }
            let challengeEvent = try JSONDecoder().decode(
                ChallengeEvent.self, from: data
            )

            XCTAssertEqual(challengeEvent.type, ChallengeType.faceMovementChallenge)
            XCTAssertEqual(challengeEvent.version, "1.0.0")
        } catch {
            XCTFail("Decoding failed with error: \(error)")
        }
    }

    /// - Given: A valid json payload depicting a FaceMovementAndLightChallenge
    /// - When: The payload is decoded
    /// - Then: The payload is decoded successfully
    func testFacemovementAndLightChallengeEventDecodeSuccess() {
        let jsonString =
        """
        {"Type":"FaceMovementAndLightChallenge","Version":"1.0.0"}
        """

        do {
            let data = jsonString.data(using: .utf8)
            guard let data = data else {
                XCTFail("Input JSON is invalid")
                return
            }
            let challengeEvent = try JSONDecoder().decode(
                ChallengeEvent.self, from: data
            )

            XCTAssertEqual(challengeEvent.type, ChallengeType.faceMovementAndLightChallenge)
            XCTAssertEqual(challengeEvent.version, "1.0.0")
        } catch {
            XCTFail("Decoding failed with error: \(error)")
        }
    }

    /// - Given: A valid json payload depicting an unknown challenge
    /// - When: The payload is decoded
    /// - Then: Error is thrown
    func testUnknownChallengeEventDecodeFailure() {
        let jsonString =
        """
        {"Type":"UnknownChallenge","Version":"1.0.0"}
        """

        do {
            let data = jsonString.data(using: .utf8)
            guard let data = data else {
                XCTFail("Input JSON is invalid")
                return
            }
            _ = try JSONDecoder().decode(
                ChallengeEvent.self, from: data
            )

            XCTFail("Decoding should fail for unknown challenge")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    // MARK: - ServerSessionInformationEvent

    /// - Given: A valid json payload depicting a ServerSessionInformation
    ///          containing FaceMovementChallenge
    /// - When: The payload is decoded
    /// - Then: The payload is decoded successfully
    func testFaceMovementChallengeServerSessionInformationEventDecodeSuccess() {
        let jsonString =
        """
        {\"SessionInformation\":{\"Challenge\":{\"FaceMovementChallenge\":{\"OvalParameters\":{\"Width\":0.1,\"Height\":0.1,\"CenterY\":0.1,\"CenterX\":0.1},\"ChallengeConfig\":{\"BlazeFaceDetectionThreshold\":0.1,\"FaceIouHeightThreshold\":0.1,\"OvalHeightWidthRatio\":0.1,\"OvalIouHeightThreshold\":0.1,\"OvalFitTimeout\":1,\"OvalIouWidthThreshold\":0.1,\"OvalIouThreshold\":0.1,\"FaceDistanceThreshold\":0.1,\"FaceDistanceThresholdMax\":0.1,\"FaceIouWidthThreshold\":0.1,\"FaceDistanceThresholdMin\":0.1}}}}}
        """

        do {
            let data = jsonString.data(using: .utf8)
            guard let data = data else {
                XCTFail("Input JSON is invalid")
                return
            }
            let serverSessionInformationEvent = try JSONDecoder().decode(
                ServerSessionInformationEvent.self, from: data
            )

            guard case let .faceMovementChallenge(challenge: recoveredChallenge) =
                    serverSessionInformationEvent.sessionInformation.challenge.type else {
                XCTFail("Cannot decode event from the input JSON")
                return
            }

            XCTAssertEqual(recoveredChallenge.ovalParameters.height, 0.1)
            XCTAssertEqual(recoveredChallenge.ovalParameters.width, 0.1)
            XCTAssertEqual(recoveredChallenge.ovalParameters.centerX, 0.1)
            XCTAssertEqual(recoveredChallenge.ovalParameters.centerY, 0.1)

            XCTAssertEqual(recoveredChallenge.challengeConfig.blazeFaceDetectionThreshold, 0.1)
            XCTAssertEqual(recoveredChallenge.challengeConfig.faceDistanceThreshold, 0.1)
            XCTAssertEqual(recoveredChallenge.challengeConfig.faceDistanceThresholdMax, 0.1)
            XCTAssertEqual(recoveredChallenge.challengeConfig.faceDistanceThresholdMin, 0.1)
            XCTAssertEqual(recoveredChallenge.challengeConfig.faceIouHeightThreshold, 0.1)
            XCTAssertEqual(recoveredChallenge.challengeConfig.faceIouWidthThreshold, 0.1)
            XCTAssertEqual(recoveredChallenge.challengeConfig.ovalHeightWidthRatio, 0.1)
            XCTAssertEqual(recoveredChallenge.challengeConfig.ovalIouHeightThreshold, 0.1)
            XCTAssertEqual(recoveredChallenge.challengeConfig.ovalIouThreshold, 0.1)
            XCTAssertEqual(recoveredChallenge.challengeConfig.ovalIouWidthThreshold, 0.1)
            XCTAssertEqual(recoveredChallenge.challengeConfig.ovalFitTimeout, 1)
        } catch {
            XCTFail("Decoding failed with error: \(error)")
        }
    }

    /// - Given: A valid json payload depicting a ServerSessionInformation
    ///          containing FaceMovementAndLightChallenge
    /// - When: The payload is decoded
    /// - Then: The payload is decoded successfully
    func testFaceMovementAndLightChallengeServerSessionInformationEventDecodeSuccess() {
        let jsonString =
        """
        {\"SessionInformation\":{\"Challenge\":{\"FaceMovementAndLightChallenge\":{\"OvalParameters\":{\"Height\":0.1,\"CenterX\":0.1,\"Width\":0.1,\"CenterY\":0.1},\"ColorSequences\":[{\"FreshnessColor\":{\"RGB\":[255,255,255]},\"DownscrollDuration\":0.1,\"FlatDisplayDuration\":0.1}],\"ChallengeConfig\":{\"OvalIouWidthThreshold\":0.1,\"FaceDistanceThreshold\":0.1,\"OvalFitTimeout\":1,\"FaceIouHeightThreshold\":0.1,\"FaceDistanceThresholdMax\":0.1,\"FaceDistanceThresholdMin\":0.1,\"OvalIouHeightThreshold\":0.1,\"FaceIouWidthThreshold\":0.1,\"OvalIouThreshold\":0.1,\"BlazeFaceDetectionThreshold\":0.1,\"OvalHeightWidthRatio\":0.1}}}}}
        """

        do {
            let data = jsonString.data(using: .utf8)
            guard let data = data else {
                XCTFail("Input JSON is invalid")
                return
            }
            let serverSessionInformationEvent = try JSONDecoder().decode(
                ServerSessionInformationEvent.self, from: data
            )

            guard case let .faceMovementAndLightChallenge(challenge: recoveredChallenge) =
                    serverSessionInformationEvent.sessionInformation.challenge.type else {
                XCTFail("Cannot decode event from the input JSON")
                return
            }

            XCTAssertEqual(recoveredChallenge.ovalParameters.height, 0.1)
            XCTAssertEqual(recoveredChallenge.ovalParameters.width, 0.1)
            XCTAssertEqual(recoveredChallenge.ovalParameters.centerX, 0.1)
            XCTAssertEqual(recoveredChallenge.ovalParameters.centerY, 0.1)

            XCTAssertEqual(recoveredChallenge.challengeConfig.blazeFaceDetectionThreshold, 0.1)
            XCTAssertEqual(recoveredChallenge.challengeConfig.faceDistanceThreshold, 0.1)
            XCTAssertEqual(recoveredChallenge.challengeConfig.faceDistanceThresholdMax, 0.1)
            XCTAssertEqual(recoveredChallenge.challengeConfig.faceDistanceThresholdMin, 0.1)
            XCTAssertEqual(recoveredChallenge.challengeConfig.faceIouHeightThreshold, 0.1)
            XCTAssertEqual(recoveredChallenge.challengeConfig.faceIouWidthThreshold, 0.1)
            XCTAssertEqual(recoveredChallenge.challengeConfig.ovalHeightWidthRatio, 0.1)
            XCTAssertEqual(recoveredChallenge.challengeConfig.ovalIouHeightThreshold, 0.1)
            XCTAssertEqual(recoveredChallenge.challengeConfig.ovalIouThreshold, 0.1)
            XCTAssertEqual(recoveredChallenge.challengeConfig.ovalIouWidthThreshold, 0.1)
            XCTAssertEqual(recoveredChallenge.challengeConfig.ovalFitTimeout, 1)

            XCTAssertEqual(recoveredChallenge.colorSequences.count, 1)
            XCTAssertEqual(recoveredChallenge.colorSequences.first?.downscrollDuration, 0.1)
            XCTAssertEqual(recoveredChallenge.colorSequences.first?.flatDisplayDuration, 0.1)
            XCTAssertEqual(recoveredChallenge.colorSequences.first?.freshnessColor.rgb, [255, 255, 255])
        } catch {
            XCTFail("Decoding failed with error: \(error)")
        }
    }

    /// - Given: A valid json payload depicting a ServerSessionInformation
    ///          containing unknown challenge
    /// - When: The payload is decoded
    /// - Then: Error should be thrown
    func testUnknownChallengeServerSessionInformationEventDecodeFailure() {
        let jsonString =
        """
        {\"SessionInformation\":{\"Challenge\":{\"UnknownChallenge\":{\"OvalParameters\":{\"Height\":0.1,\"CenterX\":0.1,\"Width\":0.1,\"CenterY\":0.1},\"ColorSequences\":[{\"FreshnessColor\":{\"RGB\":[255,255,255]},\"DownscrollDuration\":0.1,\"FlatDisplayDuration\":0.1}],\"ChallengeConfig\":{\"OvalIouWidthThreshold\":0.1,\"FaceDistanceThreshold\":0.1,\"OvalFitTimeout\":1,\"FaceIouHeightThreshold\":0.1,\"FaceDistanceThresholdMax\":0.1,\"FaceDistanceThresholdMin\":0.1,\"OvalIouHeightThreshold\":0.1,\"FaceIouWidthThreshold\":0.1,\"OvalIouThreshold\":0.1,\"BlazeFaceDetectionThreshold\":0.1,\"OvalHeightWidthRatio\":0.1}}}}}
        """

        do {
            let data = jsonString.data(using: .utf8)
            guard let data = data else {
                XCTFail("Input JSON is invalid")
                return
            }
            _ = try JSONDecoder().decode(
                ServerSessionInformationEvent.self, from: data
            )

            XCTFail("Decoding should fail for unknown challenge")
        } catch {
            XCTAssertNotNil(error)
        }
    }
}
