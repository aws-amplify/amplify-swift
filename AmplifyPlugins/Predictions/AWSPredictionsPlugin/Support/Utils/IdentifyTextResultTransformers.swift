//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSRekognition
import Amplify
import AWSTextract

class IdentifyTextResultTransformers: IdentifyResultTransformers {

    static func processText(_ rekognitionTextBlocks: [AWSRekognitionTextDetection]) -> IdentifyTextResult {
        var words = [IdentifiedWord]()
        var lines = [String]()
        var identifiedLines = [IdentifiedLine]()
        var fullText = ""
        for rekognitionTextBlock in rekognitionTextBlocks {
            guard let detectedText = rekognitionTextBlock.detectedText else {
                continue
            }
            guard let boundingBox = processBoundingBox(rekognitionTextBlock.geometry?.boundingBox) else { continue }
            guard let polygon = processPolygon(rekognitionTextBlock.geometry?.polygon) else {
                continue
            }
            let word = IdentifiedWord(text: detectedText,
                            boundingBox: boundingBox,
                            polygon: polygon)
            let line = IdentifiedLine(text: detectedText,
                                      boundingBox: boundingBox,
                                      polygon: polygon)
            switch rekognitionTextBlock.types {
            case .line:
                lines.append(detectedText)
                identifiedLines.append(line)

            case .word:
                fullText += detectedText + " "
                words.append(word)
            case .unknown:
                break
            @unknown default:
                break
            }
        }

        return IdentifyTextResult(fullText: fullText,
                                  words: words,
                                  rawLineText: lines,
                                  identifiedLines: identifiedLines)
    }

    static func processText(_ textractTextBlocks: [AWSTextractBlock]) -> IdentifyDocumentTextResult {

        var words = [IdentifiedWord]()
        var lines = [String]()
        var linesDetailed = [IdentifiedLine]()
        var selections = [Selection]()
        var fullText = ""
        var tables = [Table]()
        var keyValues = [BoundedKeyValue]()
        var blockMap = [String: AWSTextractBlock]()
        var tableBlocks = [AWSTextractBlock]()
        var keyValueBlocks = [AWSTextractBlock]()

        for block in textractTextBlocks {
            guard let text = block.text, let identifier = block.identifier else {
                continue
            }

            guard let boundingBox = processBoundingBox(block.geometry?.boundingBox) else {
                continue
            }

            guard let polygon = processPolygon(block.geometry?.polygon) else {
                continue
            }
            let word = IdentifiedWord(text: text,
                                      boundingBox: boundingBox,
                                      polygon: polygon,
                                      page: Int(truncating: block.page ?? 0))

            let line = IdentifiedLine(text: text,
                                      boundingBox: boundingBox,
                                      polygon: polygon,
                                      page: Int(truncating: block.page ?? 0))

            switch block.blockType {
            case .line:
                lines.append(text)
                linesDetailed.append(line)
            case .word:
                fullText += text + " "
                words.append(word)
                blockMap[identifier] = block
            case .selectionElement:
                let selectionStatus = block.selectionStatus == .selected ? true : false
                let selection = Selection(boundingBox: boundingBox, polygon: polygon, isSelected: selectionStatus)
                selections.append(selection)
                blockMap[identifier] = block
            case .table:
                tableBlocks.append(block)
            case .keyValueSet:
                keyValueBlocks.append(block)
                blockMap[identifier] = block
            default:
                blockMap[identifier] = block

            }
        }

        if !tableBlocks.isEmpty {
            for tableBlock in tableBlocks {
                if let table = processTable(tableBlock, blockMap: blockMap) {
                    tables.append(table)
                }
            }
        }

        if !keyValueBlocks.isEmpty {
            for keyValueBlock in keyValueBlocks where keyValueBlock.entityTypes?.contains("KEY") ?? false {
                if let keyValue = processKeyValue(keyValueBlock, blockMap: blockMap) {
                    keyValues.append(keyValue)
                }
            }
        }

        return IdentifyDocumentTextResult(
            fullText: fullText,
            words: words,
            rawLineText: lines,
            identifiedLines: linesDetailed,
            selections: selections,
            tables: tables,
            keyValues: keyValues)
    }

    static func processTable(_ block: AWSTextractBlock,
                             blockMap: [String: AWSTextractBlock]) -> Table? {

        guard let relationships = block.relationships else {
            return nil
        }
        var table = Table()
        var rows = Set<Int>()
        var cols = Set<Int>()
        for tableRelation in relationships {
            guard let ids = tableRelation.ids else {
                continue
            }

            for cellId in ids {
                let cellBlock = blockMap[cellId]

                guard let rowIndex = cellBlock?.rowIndex,
                    let colIndex = cellBlock?.columnIndex else {
                    continue
                }
                // textract starts indexing at 1, so subtract it by 1.
                let row = Int(truncating: rowIndex) - 1
                let col = Int(truncating: colIndex) - 1
                if !rows.contains(row) {
                rows.insert(row)
                }
                if !cols.contains(col) {
                cols.insert(col)
                }
                if let cell = constructTableCell(cellBlock) {
                table.cells.append(cell)
                }
            }

        }
        table.rows = rows.count
        table.columns = cols.count
        return table
    }

    static func constructTableCell(_ block: AWSTextractBlock?) -> Table.Cell? {
        guard let blockType = block?.blockType,
            let selectionStatus = block?.selectionStatus,
            let text = block?.text,
            let rowSpan = block?.rowSpan,
            let columnSpan = block?.columnSpan,
            let geometry = block?.geometry,
            let textractBoundingBox = geometry.boundingBox,
            let texttractPolygon = geometry.polygon
            else {
                return nil
        }
        var words = ""
        var isSelected = false

        switch blockType {
        case .word:
             words += text + " "
        case .selectionElement:
            isSelected = selectionStatus == .selected ? true : false
        default: break
        }

        guard let boundingBox = processBoundingBox(textractBoundingBox) else {
            return nil
        }

        guard let polygon = processPolygon(texttractPolygon) else {
            return nil
        }
        let cell = Table.Cell(text: words,
                              boundingBox: boundingBox,
                              polygon: polygon,
                              isSelected: isSelected,
                              rowSpan: Int(truncating: rowSpan),
                              columnSpan: Int(truncating: columnSpan))

        return cell
    }

    static func processKeyValue(_ keyBlock: AWSTextractBlock?,
                                blockMap: [String: AWSTextractBlock]) -> BoundedKeyValue? {
        var keyText = ""
        var valueText = ""
        var valueSelected = false

        guard let keyBlock = keyBlock,
            let relationships = keyBlock.relationships else {
            return nil
        }

        for keyBlockRelationship in relationships {
            guard let text = keyBlock.text,
                let ids = keyBlockRelationship.ids else {
                    continue
            }
            switch keyBlockRelationship.types {
            case .child where keyBlock.blockType == .word:
                     keyText += text + " "
            case .value:
                for valueId in ids {
                     let valueBlock = blockMap[valueId]
                    guard let valueBlockType = valueBlock?.blockType else {
                        continue
                    }
                    switch valueBlockType {
                    case .word:

                        if let text = valueBlock?.text {
                        valueText += text + " "
                        }
                    case .selectionElement:
                        valueSelected = keyBlock.selectionStatus == .selected ? true : false
                    default: break
                    }
                }

            default:
                break
            }
        }

        guard let boundingBox = processBoundingBox(keyBlock.geometry?.boundingBox) else {
            return nil
        }

        guard let polygon = processPolygon(keyBlock.geometry?.polygon) else {
            return nil
        }

        return BoundedKeyValue(key: keyText,
                        value: valueText,
                        isSelected: valueSelected,
                        boundingBox: boundingBox,
                        polygon: polygon)
    }
}
