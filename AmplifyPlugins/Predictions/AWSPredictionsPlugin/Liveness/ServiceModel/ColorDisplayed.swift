//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct ColorDisplayed: Codable {
    let currentColor: FreshnessColor
    let sequenceNumber: Int
    let currentColorStartTimeStamp: UInt64
    let previousColor: FreshnessColor

    enum CodingKeys: String, CodingKey {
        case currentColor = "CurrentColor"
        case sequenceNumber = "SequenceNumber"
        case currentColorStartTimeStamp = "CurrentColorStartTimestamp"
        case previousColor = "PreviousColor"
    }
}
