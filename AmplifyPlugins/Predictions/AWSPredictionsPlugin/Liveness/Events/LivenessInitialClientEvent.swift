//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

@_spi(PredictionsFaceLiveness)
public struct InitialClientEvent {
    public init(
        challengeID: String,
        initialFaceLocation: FaceDetection,
        videoStartTime: UInt64
    ) {
        self.challengeID = challengeID
        self.initialFaceLocation = initialFaceLocation
        self.videoStartTimestamp = videoStartTime
    }

    let challengeID: String
    let initialFaceLocation: FaceDetection
    let videoStartTimestamp: UInt64
}

extension LivenessEvent where T == InitialClientEvent {
    @_spi(PredictionsFaceLiveness)
    public static func initialFaceDetected(event: InitialClientEvent) throws -> Self {
        let initialFace = InitialFace(
            boundingBox: .init(boundingBox: event.initialFaceLocation.boundingBox),
            initialFaceDetectedTimeStamp: event.initialFaceLocation.startTimestamp
        )

        let clientSessionInformationEvent = ClientSessionInformationEvent(
            challenge: .init(
                faceMovementAndLightChallenge: .init(
                    challengeID: event.challengeID,
                    targetFace: nil,
                    initialFace: initialFace,
                    videoStartTimestamp: event.videoStartTimestamp,
                    colorDisplayed: nil,
                    videoEndTimeStamp: nil
                )
            )
        )

        let payload = try JSONEncoder().encode(clientSessionInformationEvent)
        return .init(
            payload: payload,
            eventKind: .client(.initialFaceDetected),
            eventTypeHeader: "ClientSessionInformationEvent"
        )
    }
}
