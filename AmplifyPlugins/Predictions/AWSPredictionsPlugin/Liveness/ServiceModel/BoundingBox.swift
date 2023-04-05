//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct BoundingBox: Codable {
    let width: Double
    let height: Double
    let left: Double
    let top: Double

    init(width: Double, height: Double, left: Double, top: Double) {
        self.width = width
        self.height = height
        self.left = left
        self.top = top
    }

    enum CodingKeys: String, CodingKey {
        case width = "Width"
        case height = "Height"
        case left = "Left"
        case top = "Top"
    }

    init(boundingBox: FaceLivenessSession.BoundingBox) {
        self.width = boundingBox.width
        self.height = boundingBox.height
        self.left = boundingBox.x
        self.top = boundingBox.y
    }
}
