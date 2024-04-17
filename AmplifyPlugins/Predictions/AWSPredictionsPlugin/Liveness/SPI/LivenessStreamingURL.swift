//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

func streamingSessionURL(for region: String) throws -> URL {
    let urlString = "wss://streaming-rekognition.\(region).amazonaws.com/start-face-liveness-session-websocket"
    guard let url = URL(string: urlString) else {
        throw FaceLivenessSessionError.invalidRegion
    }
    return url
}
