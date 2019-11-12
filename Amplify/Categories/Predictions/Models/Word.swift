//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct Word {
    public var text: String
    public var boundingBox: BoundingBox
    public var polygon: Polygon
    public var page: Int?

    public init(text: String, boundingBox: BoundingBox, polygon: Polygon) {
        self.text = text
        self.boundingBox = boundingBox
        self.polygon = polygon
    }
}
