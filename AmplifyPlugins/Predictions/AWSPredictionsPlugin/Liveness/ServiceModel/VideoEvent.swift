//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct LivenessVideoEvent: Codable {
    let timestampMillis: UInt64
    let videoChunk: Data

    enum CodingKeys: String, CodingKey {
        case timestampMillis = "TimestampMillis"
        case videoChunk = "VideoChunk"
    }
}
