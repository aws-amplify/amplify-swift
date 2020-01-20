//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import CoreGraphics

public struct BoundedKeyValue {
    public let key: String
    public let value: String
    public let isSelected: Bool
    public let boundingBox: CGRect
    public let polygon: Polygon

    public init(key: String, value: String, isSelected: Bool, boundingBox: CGRect, polygon: Polygon) {
        self.key = key
        self.value = value
        self.isSelected = isSelected
        self.boundingBox = boundingBox
        self.polygon = polygon
    }
}
