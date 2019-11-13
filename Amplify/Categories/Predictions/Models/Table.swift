//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
public struct Table {
    public var rows: Int
    public var columns: Int
    public var cells: [TableCell]

    public init() {
        self.rows = 0
        self.columns = 0
        self.cells = [TableCell]()
    }
}

public struct TableCell {
    public var text: String
    public var boundingBox: BoundingBox
    public var polygon: Polygon
    public var selected: Bool
    public var rowSpan: Int
    public var columnSpan: Int

    public init(text: String,
                boundingBox: BoundingBox,
                polygon: Polygon,
                selected: Bool,
                rowSpan: Int,
                columnSpan: Int) {
        self.text = text
        self.boundingBox = boundingBox
        self.polygon = polygon
        self.selected = selected
        self.rowSpan = rowSpan
        self.columnSpan = columnSpan
    }
}
