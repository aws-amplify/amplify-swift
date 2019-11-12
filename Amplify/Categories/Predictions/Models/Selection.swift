//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct Selection {
    public var boundingBox: BoundingBox
    public var polygon: Polygon
    public var selectionStatus: Bool

    public init(boundingBox: BoundingBox, polygon: Polygon, selectionStatus: Bool) {
        self.boundingBox = boundingBox
        self.polygon = polygon
        self.selectionStatus = selectionStatus
    }
}
