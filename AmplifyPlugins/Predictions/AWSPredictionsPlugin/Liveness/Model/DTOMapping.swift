//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

func ovalChallenge(from event: ServerSessionInformationEvent) -> FaceLivenessSession.OvalMatchChallenge {
    let challengeConfig: ChallengeConfig
    let ovalParameters: OvalParameters

    switch event.sessionInformation.challenge.type {
    case .faceMovementAndLightChallenge(let challenge):
        challengeConfig = challenge.challengeConfig
        ovalParameters = challenge.ovalParameters
    case .faceMovementChallenge(let challenge):
        challengeConfig = challenge.challengeConfig
        ovalParameters = challenge.ovalParameters
    }

    let ovalBoundingBox = FaceLivenessSession.BoundingBox.init(
        x: Double(ovalParameters.centerX - ovalParameters.width / 2),
        y: Double(ovalParameters.centerY - ovalParameters.height / 2),
        width: Double(ovalParameters.width),
        height: Double(ovalParameters.height)
    )

    return .init(
        faceDetectionThreshold: challengeConfig.blazeFaceDetectionThreshold,
        face: .init(
            distanceThreshold: challengeConfig.faceDistanceThreshold,
            distanceThresholdMax: challengeConfig.faceDistanceThresholdMax,
            distanceThresholdMin: challengeConfig.faceDistanceThresholdMin,
            iouWidthThreshold: challengeConfig.faceIouWidthThreshold,
            iouHeightThreshold: challengeConfig.faceIouHeightThreshold
        ),
        oval: .init(
            boundingBox: ovalBoundingBox,
            heightWidthRatio: challengeConfig.ovalHeightWidthRatio,
            iouThreshold: challengeConfig.ovalIouThreshold,
            iouWidthThreshold: challengeConfig.ovalIouWidthThreshold,
            iouHeightThreshold: challengeConfig.ovalIouHeightThreshold,
            ovalFitTimeout: challengeConfig.ovalFitTimeout
        )
    )
}

func colorChallenge(from challenge: FaceMovementAndLightServerChallenge) -> FaceLivenessSession.ColorChallenge {
    let displayColors = challenge.colorSequences
        .map { color -> FaceLivenessSession.DisplayColor in

            let duration: Double
            let shouldScroll: Bool
            switch (color.downscrollDuration, color.flatDisplayDuration) {
            case (...0, 0...):
                duration = Double(color.flatDisplayDuration)
                shouldScroll = false
            default:
                duration = Double(color.downscrollDuration)
                shouldScroll = true
            }

            precondition(
                color.freshnessColor.rgb.count == 3,
                """
                    Received invalid freshness colors.
                    Expected 3 values (r, g, b), received: \(color.freshnessColor.rgb.count)
                    """
            )

            return .init(
                rgb: .init(
                    red: Double(color.freshnessColor.rgb[0]) / 255,
                    green: Double(color.freshnessColor.rgb[1]) / 255,
                    blue: Double(color.freshnessColor.rgb[2]) / 255,
                    _values: color.freshnessColor.rgb
                ),
                duration: duration,
                shouldScroll: shouldScroll
            )
        }
    return .init(colors: displayColors)
}

func sessionConfiguration(from event: ServerSessionInformationEvent) -> FaceLivenessSession.SessionConfiguration {
    switch event.sessionInformation.challenge.type {
    case .faceMovementAndLightChallenge(let challenge):
        return .faceMovementAndLight(colorChallenge(from: challenge), ovalChallenge(from: event))
    case .faceMovementChallenge:
        return .faceMovement(ovalChallenge(from: event))
    }
}

func challenge(from event: ChallengeEvent) -> Challenge {
    switch event.type {
    case .faceMovementAndLightChallenge:
        return .faceMovementAndLightChallenge(event.version)
    case .faceMovementChallenge:
        return .faceMovementChallenge(event.version)
    }
}
