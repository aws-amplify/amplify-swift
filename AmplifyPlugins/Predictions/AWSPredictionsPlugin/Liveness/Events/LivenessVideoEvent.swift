//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

@_spi(PredictionsFaceLiveness)
public struct VideoEvent {
    let chunk: Data
    let timestamp: UInt64

    public init(chunk: Data, timestamp: UInt64) {
        self.chunk = chunk
        self.timestamp = timestamp
    }
}

extension LivenessEvent where T == VideoEvent {
    @_spi(PredictionsFaceLiveness)
    public static func video(event: VideoEvent) throws -> Self {
        let clientEvent = LivenessVideoEvent(
            timestampMillis: event.timestamp,
            videoChunk: event.chunk
        )
        let payload = try JSONEncoder().encode(clientEvent)
        return .init(
            payload: payload,
            eventKind: .client(.video),
            eventTypeHeader: "VideoEvent"
        )
    }
}
