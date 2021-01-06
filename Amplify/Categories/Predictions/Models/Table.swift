//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import CoreGraphics

public struct Table {
    public var rows: Int
    public var columns: Int
    public var cells: [Cell]

    public init() {
        self.rows = 0
        self.columns = 0
        self.cells = [Cell]()
    }
}
public extension Table {
    struct Cell {

        public let text: String

        /// The location of the recognized text on the image. It includes an axis-aligned,
        /// coarse bounding box that surrounds the text in the table
        public let boundingBox: CGRect

        /// The location of the recognized text on the image in a finer-grain polygon than
        /// the bounding box for more accurate spatial information of where the text is in the table
        public let polygon: Polygon

        public let isSelected: Bool
        public let rowIndex: Int
        public let columnIndex: Int
        public let rowSpan: Int
        public let columnSpan: Int

        public init(text: String,
                    boundingBox: CGRect,
                    polygon: Polygon,
                    isSelected: Bool,
                    rowIndex: Int,
                    columnIndex: Int,
                    rowSpan: Int,
                    columnSpan: Int) {
            self.text = text
            self.boundingBox = boundingBox
            self.polygon = polygon
            self.isSelected = isSelected
            self.rowIndex = rowIndex
            self.columnIndex = columnIndex
            self.rowSpan = rowSpan
            self.columnSpan = columnSpan
        }

    }
}
