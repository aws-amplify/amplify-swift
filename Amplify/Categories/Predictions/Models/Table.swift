//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import CoreGraphics

/// <#Description#>
public struct Table {

    /// <#Description#>
    public var rows: Int

    /// <#Description#>
    public var columns: Int

    /// <#Description#>
    public var cells: [Cell]

    /// <#Description#>
    public init() {
        self.rows = 0
        self.columns = 0
        self.cells = [Cell]()
    }
}

public extension Table {

    /// <#Description#>
    struct Cell {

        /// <#Description#>
        public let text: String

        /// The location of the recognized text on the image. It includes an axis-aligned,
        /// coarse bounding box that surrounds the text in the table
        public let boundingBox: CGRect

        /// The location of the recognized text on the image in a finer-grain polygon than
        /// the bounding box for more accurate spatial information of where the text is in the table
        public let polygon: Polygon

        /// <#Description#>
        public let isSelected: Bool

        /// <#Description#>
        public let rowIndex: Int

        /// <#Description#>
        public let columnIndex: Int

        /// <#Description#>
        public let rowSpan: Int

        /// <#Description#>
        public let columnSpan: Int

        /// <#Description#>
        /// - Parameters:
        ///   - text: <#text description#>
        ///   - boundingBox: <#boundingBox description#>
        ///   - polygon: <#polygon description#>
        ///   - isSelected: <#isSelected description#>
        ///   - rowIndex: <#rowIndex description#>
        ///   - columnIndex: <#columnIndex description#>
        ///   - rowSpan: <#rowSpan description#>
        ///   - columnSpan: <#columnSpan description#>
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
