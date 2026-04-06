//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

@_spi(PredictionsFaceLiveness)
public struct FinalClientEvent {
    public init(
        initialClientEvent: InitialClientEvent,
        targetFace: CompletedEvent<FaceDetection>,
        videoEndTimeStamp: UInt64
    ) {
        self.initialClientEvent = initialClientEvent
        self.targetFace = targetFace
        self.videoEndTimeStamp = videoEndTimeStamp
    }

    let initialClientEvent: InitialClientEvent
    let targetFace: CompletedEvent<FaceDetection>
    let videoEndTimeStamp: UInt64
}

public extension LivenessEvent where T == FinalClientEvent {
    @_spi(PredictionsFaceLiveness)
    static func final(
        event: FinalClientEvent,
        challenge: Challenge
    ) throws -> Self {
        let clientChallengeType: ClientChallenge.ChallengeType
        switch challenge {
        case .faceMovementAndLightChallenge:
            clientChallengeType = .faceMovementAndLightChallenge(
                challenge: .init(
                    challengeID: event.initialClientEvent.challengeID,
                    targetFace: .init(
                        boundingBox: .init(boundingBox: event.targetFace.initialEvent.boundingBox),
                        faceDetectedInTargetPositionStartTimestamp: event.targetFace.initialEvent.startTimestamp,
                        faceDetectedInTargetPositionEndTimestamp: event.targetFace.endTimestamp
                    ),
                    initialFace: .init(
                        boundingBox: .init(boundingBox: event.initialClientEvent.initialFaceLocation.boundingBox),
                        initialFaceDetectedTimeStamp: event.initialClientEvent.initialFaceLocation.startTimestamp
                    ),
                    videoStartTimestamp: nil,
                    colorDisplayed: nil,
                    videoEndTimeStamp: Date().epochMilliseconds
                )
            )
        case .faceMovementChallenge:
            clientChallengeType = .faceMovementChallenge(
                challenge: .init(
                    challengeID: event.initialClientEvent.challengeID,
                    targetFace: .init(
                        boundingBox: .init(boundingBox: event.targetFace.initialEvent.boundingBox),
                        faceDetectedInTargetPositionStartTimestamp: event.targetFace.initialEvent.startTimestamp,
                        faceDetectedInTargetPositionEndTimestamp: event.targetFace.endTimestamp
                    ),
                    initialFace: .init(
                        boundingBox: .init(boundingBox: event.initialClientEvent.initialFaceLocation.boundingBox),
                        initialFaceDetectedTimeStamp: event.initialClientEvent.initialFaceLocation.startTimestamp
                    ),
                    videoStartTimestamp: nil,
                    videoEndTimeStamp: Date().epochMilliseconds
                )
            )
        }

        let clientEvent = ClientSessionInformationEvent(challenge: .init(clientChallengeType: clientChallengeType))
        let payload = try JSONEncoder().encode(clientEvent)
        return .init(
            payload: payload,
            eventKind: .client(.final),
            eventTypeHeader: "ClientSessionInformationEvent"
        )
    }
}
