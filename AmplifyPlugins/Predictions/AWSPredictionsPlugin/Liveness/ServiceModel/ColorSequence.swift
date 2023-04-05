//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct ColorSequence: Codable {
    public let downscrollDuration: Float
    public let flatDisplayDuration: Float
    public let freshnessColor: FreshnessColor

    enum CodingKeys: String, CodingKey {
        case downscrollDuration = "DownscrollDuration"
        case flatDisplayDuration = "FlatDisplayDuration"
        case freshnessColor = "FreshnessColor"
    }
}
