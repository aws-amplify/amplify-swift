//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct BoundedKeyValue {
    public let key: String
    public let value: String
    public let isSelected: Bool
    public let boundingBox: BoundingBox
    public let polygon: Polygon

    public init(key: String, value: String, isSelected: Bool, boundingBox: BoundingBox, polygon: Polygon) {
        self.key = key
        self.value = value
        self.isSelected = isSelected
        self.boundingBox = boundingBox
        self.polygon = polygon
    }
}
