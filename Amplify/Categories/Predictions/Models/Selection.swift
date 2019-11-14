//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


public struct Selection {
    public let boundingBox: BoundingBox
    public let polygon: Polygon
    public let selectionStatus: Bool

    public init(boundingBox: BoundingBox, polygon: Polygon, selectionStatus: Bool) {
        self.boundingBox = boundingBox
        self.polygon = polygon
        self.selectionStatus = selectionStatus
    }
}
