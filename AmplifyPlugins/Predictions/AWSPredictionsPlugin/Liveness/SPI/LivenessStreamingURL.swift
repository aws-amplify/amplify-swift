//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

private let ISO_PARTITION_BASE_DOMAIN: String = "csp.hci.ic.gov"
private let DEFAULT_BASE_DOMAIN: String = "amazonaws.com"

func streamingSessionURL(for region: String) throws -> URL {

    // Determine the base domain based on the region
    let baseDomain: String
    if region.lowercased().starts(with: "us-isof") {
        baseDomain = ISO_PARTITION_BASE_DOMAIN
    } else {
        baseDomain = DEFAULT_BASE_DOMAIN
    }

    let urlString = "wss://streaming-rekognition.\(region).\(baseDomain)/start-face-liveness-session-websocket"
    guard let url = URL(string: urlString) else {
        throw FaceLivenessSessionError.invalidRegion
    }
    return url
}
