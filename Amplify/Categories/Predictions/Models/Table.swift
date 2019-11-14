//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


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
    
    public let text: String
    public let boundingBox: BoundingBox
    public let polygon: Polygon
    public let isSelected: Bool
    public let rowSpan: Int
    public let columnSpan: Int

    public init(text: String,
                boundingBox: BoundingBox,
                polygon: Polygon,
                isSelected: Bool,
                rowSpan: Int,
                columnSpan: Int) {
        self.text = text
        self.boundingBox = boundingBox
        self.polygon = polygon
        self.isSelected = isSelected
        self.rowSpan = rowSpan
        self.columnSpan = columnSpan
    }
    
}
