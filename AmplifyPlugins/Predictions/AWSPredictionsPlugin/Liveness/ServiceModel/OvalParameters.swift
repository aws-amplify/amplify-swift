//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct OvalParameters: Codable {
    public let centerX: Float
    public let centerY: Float
    public let height: Float
    public let width: Float

    enum CodingKeys: String, CodingKey {
        case centerX = "CenterX"
        case centerY = "CenterY"
        case height = "Height"
        case width = "Width"
    }
}
