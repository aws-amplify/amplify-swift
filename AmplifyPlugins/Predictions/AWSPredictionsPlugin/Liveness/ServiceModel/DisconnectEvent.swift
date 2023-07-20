//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct DisconnectEvent: Codable {
    let timestampMillis: UInt64

    enum CodingKeys: String, CodingKey {
        case timestampMillis = "TimestampMillis"
    }
}
