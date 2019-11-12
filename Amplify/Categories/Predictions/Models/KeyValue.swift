//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct KeyValue {
    public var key: String
    public var value: String
    public var valueSelected: Bool
    public var boundingBox: BoundingBox
    public var polygon: Polygon

    public init(key: String, value: String, valueSelected: Bool, boundingBox: BoundingBox, polygon: Polygon) {
        self.key = key
        self.value = value
        self.valueSelected = valueSelected
        self.boundingBox = boundingBox
        self.polygon = polygon
    }
}
