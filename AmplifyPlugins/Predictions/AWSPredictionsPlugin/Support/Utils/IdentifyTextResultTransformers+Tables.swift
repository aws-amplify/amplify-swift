//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSTextract

extension IdentifyTextResultTransformers {

    static func processTables(
        tableBlocks: [TextractClientTypes.Block],
        blockMap: [String: TextractClientTypes.Block]
    ) -> [Table] {
        var tables = [Table]()
        for tableBlock in tableBlocks {
            if let table = processTable(tableBlock, blockMap: blockMap) {
                tables.append(table)
            }
        }
        return tables
    }

    static func processTable(
        _ tableBlock: TextractClientTypes.Block,
        blockMap: [String: TextractClientTypes.Block]
    ) -> Table? {

        guard let relationships = tableBlock.relationships,
            case .table = tableBlock.blockType else {
                return nil
        }
        var table = Table()
        var rows = Set<Int>()
        var cols = Set<Int>()

        for tableRelation in relationships {
            guard let cellIds = tableRelation.ids else {
                continue
            }

            for cellId in cellIds {
                guard let cellBlock = blockMap[cellId],
                    let rowIndex = cellBlock.rowIndex,
                    let colIndex = cellBlock.columnIndex
                    else {
                        continue
                }

                // textract starts indexing at 1, so subtract it by 1.
                let row = rowIndex - 1
                let col = colIndex - 1

                if !rows.contains(row),
                    !cols.contains(row),
                    let cell = constructTableCell(cellBlock, blockMap) {
                    table.cells.append(cell)
                    rows.insert(row)
                    cols.insert(col)
                }
            }
        }
        table.rows = rows.count
        table.columns = cols.count
        return table
    }

    static func constructTableCell(
        _ block: TextractClientTypes.Block,
        _ blockMap: [String: TextractClientTypes.Block]
    ) -> Table.Cell? {
        guard block.blockType == .cell,
            let relationships = block.relationships,
            let rowIndex = block.rowIndex,
            let columnIndex = block.columnIndex,
            let rowSpan = block.rowSpan,
            let columnSpan = block.columnSpan,
            let geometry = block.geometry,
            let textractBoundingBox = geometry.boundingBox,
            let texttractPolygon = geometry.polygon
            else {
                return nil
        }

        let selectionStatus = block.selectionStatus
        var words = ""
        var isSelected = false
        var selectionItemFound = false

        for cellRelation in relationships {
            guard let wordOrSelectionIds = cellRelation.ids else {
                continue
            }

            for wordOrSelectionId in wordOrSelectionIds {
                let wordOrSelectionBlock = blockMap[wordOrSelectionId]

                switch wordOrSelectionBlock?.blockType {
                case .word:
                    guard let text = wordOrSelectionBlock?.text else {
                        return nil
                    }
                    words += text + " "
                case .selectionElement:
                    if !selectionItemFound {
                        selectionItemFound = true
                        // TODO: https://github.com/aws-amplify/amplify-ios/issues/695
                        // Support multiple selection items found in a KeyValueSet
                        isSelected = selectionStatus == .selected
                    } else {
                        Amplify.log.error("Multiple selection items found in KeyValueSet")
                    }
                default:
                    break
                }
            }
        }

        guard let boundingBox = processBoundingBox(textractBoundingBox),
            let polygon = processPolygon(texttractPolygon) else {
                return nil
        }

        return Table.Cell(
            text: words.trimmingCharacters(in: .whitespacesAndNewlines),
            boundingBox: boundingBox,
            polygon: polygon,
            isSelected: isSelected,
            rowIndex: rowIndex,
            columnIndex: columnIndex,
            rowSpan: rowSpan,
            columnSpan: columnSpan
        )
    }
}
