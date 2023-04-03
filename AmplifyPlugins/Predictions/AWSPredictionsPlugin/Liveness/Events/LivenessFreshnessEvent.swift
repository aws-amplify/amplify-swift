//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

@_spi(PredictionsFaceLiveness)
public struct FreshnessEvent {
    let challengeID: String
    let color: [Int]
    let sequenceNumber: Int
    let timestamp: UInt64
    let previousColor: [Int]

    public init(challengeID: String, color: [Int], sequenceNumber: Int, timestamp: UInt64, previousColor: [Int]) {
        self.challengeID = challengeID
        self.color = color
        self.sequenceNumber = sequenceNumber
        self.timestamp = timestamp
        self.previousColor = previousColor
    }
}

extension LivenessEvent where T == FreshnessEvent {
    @_spi(PredictionsFaceLiveness)
    public static func freshness(event: FreshnessEvent) throws -> Self {
        let clientEvent = ClientSessionInformationEvent(
            challenge: .init(
                faceMovementAndLightChallenge: .init(
                    challengeID: event.challengeID,
                    targetFace: nil,
                    initialFace: nil,
                    videoStartTimestamp: nil,
                    colorDisplayed: .init(
                        currentColor: .init(rgb: event.color),
                        sequenceNumber: event.sequenceNumber,
                        currentColorStartTimeStamp: event.timestamp,
                        previousColor: .init(rgb: event.previousColor)
                    ),
                    videoEndTimeStamp: nil
                )
            )
        )
        let payload = try JSONEncoder().encode(clientEvent)
        return .init(
            payload: payload,
            eventKind: .client(.freshness),
            eventTypeHeader: "ClientSessionInformationEvent"
        )
    }
}
