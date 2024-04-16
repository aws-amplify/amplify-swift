//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

func streamingSessionURL(for region: String) throws -> URL {
    // TODO: change this before merge to `main`
    let urlString = "wss://alankrp-moa.dev.streaming.reventlov.rekognition.aws.dev/start-face-liveness-session-websocket"
    guard let url = URL(string: urlString) else {
        throw FaceLivenessSessionError.invalidRegion
    }
    return url
}
