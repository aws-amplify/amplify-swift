//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSRekognition
import Amplify
import AWSTextract

class IdentifyTextResultUtils: IdentifyResultUtils {

    static func processText(rekognitionTextBlocks: [AWSRekognitionTextDetection]) -> IdentifyTextResult {
        var words = [Word]()
        var lines = [String]()
        var linesDetailed = [Word]()
        var fullText = ""
        for rekognitionTextBlock in rekognitionTextBlocks {
            guard let detectedText = rekognitionTextBlock.detectedText else {
                continue
            }
            guard let boundingBox = processBoundingBox(rekognitionTextBlock.geometry?.boundingBox) else { continue }
            let polygon = Polygon(
                xPosition: Double(truncating: rekognitionTextBlock.geometry?.polygon?[0].x ?? 0),
                yPosition: Double(truncating: rekognitionTextBlock.geometry?.polygon?[0].y ?? 0))
            let word = Word(text: detectedText,
                            boundingBox: boundingBox,
                            polygon: polygon)
            switch rekognitionTextBlock.types {
            case .line:
                lines.append(detectedText)
                linesDetailed.append(word)

            case .word:
                fullText += detectedText + " "
                words.append(word)
            case .unknown:
                break
            @unknown default:
                break
            }
        }

        return IdentifyTextResult(fullText: fullText, words: words, lines: lines, linesDetailed: linesDetailed)
    }

    static func processText(textractTextBlocks: [AWSTextractBlock]) -> IdentifyDocumentTextResult {

        var words = [Word]()
        var lines = [String]()
        var linesDetailed = [Word]()
        var selections = [Selection]()
        var fullText = ""
        var tables = [Table]()
        var keyValues = [KeyValue]()
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

            let polygon = Polygon(
                xPosition: Double(truncating: block.geometry?.polygon?[0].x ?? 0),
                yPosition: Double(truncating: block.geometry?.polygon?[0].y ?? 0))
            var word = Word(text: text, boundingBox: boundingBox, polygon: polygon)

            switch block.blockType {
            case .line:
                lines.append(text)
                word.page = Int(truncating: block.page ?? 0)
                linesDetailed.append(word)
            case .word:
                fullText += text + " "
                words.append(word)
                blockMap[identifier] = block
            case .selectionElement:
                let selectionStatus = block.selectionStatus == .selected ? true : false
                let selection = Selection(boundingBox: boundingBox, polygon: polygon, selectionStatus: selectionStatus)
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
            lines: lines,
            linesDetailed: linesDetailed,
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

    static func constructTableCell(_ block: AWSTextractBlock?) -> TableCell? {
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

        let polygon = Polygon(
                       xPosition: Double(truncating: texttractPolygon[0].x ?? 0),
                       yPosition: Double(truncating: texttractPolygon[0].y ?? 0))
        let cell = TableCell(text: words,
                              boundingBox: boundingBox,
                              polygon: polygon,
                              selected: isSelected,
                              rowSpan: Int(truncating: rowSpan),
                              columnSpan: Int(truncating: columnSpan))

        return cell
    }

    static func processKeyValue(_ keyBlock: AWSTextractBlock?, blockMap: [String: AWSTextractBlock]) -> KeyValue? {
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
        let polygon = Polygon(
                       xPosition: Double(truncating: keyBlock.geometry?.polygon?[0].x ?? 0),
                       yPosition: Double(truncating: keyBlock.geometry?.polygon?[0].y ?? 0))

        return KeyValue(key: keyText,
                        value: valueText,
                        valueSelected: valueSelected,
                        boundingBox: boundingBox,
                        polygon: polygon)
    }
}
