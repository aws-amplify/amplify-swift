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
        var fullText = ""
        var words = [IdentifiedWord]()
        var lines = [String]()
        var linesDetailed = [IdentifiedLine]()
        var selections = [Selection]()
        var tables = [Table]()
        var keyValues = [BoundedKeyValue]()
        var tableBlocks = [AWSTextractBlock]()
        var keyValueBlocks = [AWSTextractBlock]()
        var blockMap = [String: AWSTextractBlock]()

        for block in textractTextBlocks {
            guard let identifier = block.identifier else {
                continue
            }

            blockMap[identifier] = block

            switch block.blockType {
            case .line:
                if let line = parseLineBlock(block: block) {
                    lines.append(line.text)
                    linesDetailed.append(line)
                }
            case .word:
                if let word = parseWordBlock(block: block) {
                    fullText += word.text + " "
                    words.append(word)
                    blockMap[identifier] = block
                }
            case .selectionElement:
                if let selection = parseSelectionElementBlock(block: block) {
                    selections.append(selection)
                    blockMap[identifier] = block
                }
            case .table:
                tableBlocks.append(block)
            case .keyValueSet:
                keyValueBlocks.append(block)
            default:
                continue
            }
        }

        tables = processTables(tableBlocks: tableBlocks, blockMap: blockMap)
        keyValues = processKeyValues(keyValueBlocks: keyValueBlocks, blockMap: blockMap)

        return IdentifyDocumentTextResult(
            fullText: fullText,
            words: words,
            rawLineText: lines,
            identifiedLines: linesDetailed,
            selections: selections,
            tables: tables,
            keyValues: keyValues)
    }

    static func processTables(tableBlocks: [AWSTextractBlock],
                              blockMap: [String: AWSTextractBlock]) -> [Table] {
        var tables = [Table]()
        for tableBlock in tableBlocks {
            if let table = processTable(tableBlock, blockMap: blockMap) {
                tables.append(table)
            }
        }
        return tables
    }

    static func processKeyValues(keyValueBlocks: [AWSTextractBlock],
                                 blockMap: [String: AWSTextractBlock]) -> [BoundedKeyValue] {
        var keyValues =  [BoundedKeyValue]()
        for keyValueBlock in keyValueBlocks where keyValueBlock.entityTypes?.contains("KEY") ?? false {
            if let keyValue = processKeyValue(keyValueBlock, blockMap: blockMap) {
                keyValues.append(keyValue)
            }
        }
        return keyValues
    }

    // https://docs.aws.amazon.com/textract/latest/dg/how-it-works-tables.html
    /**
    * Converts a given Amazon Textract block into Amplify-compatible
    * table object.
    * @param block Textract text block
    * @param blockMap map of Textract blocks by their IDs
    * @return Amplify Table instance
    */
    static func processTable(_ tableBlock: AWSTextractBlock,
                             blockMap: [String: AWSTextractBlock]) -> Table? {

        guard let relationships = tableBlock.relationships else {
            return nil
        }
        var table = Table()
        var rows = Set<Int>()
        var cols = Set<Int>()

        // Each TABLE block contains CELL blocks
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
                if let cell = constructTableCell(cellBlock, blockMap) {
                    table.cells.append(cell)
                }
            }

        }
        table.rows = rows.count
        table.columns = cols.count
        return table
    }

    static func constructTableCell(_ block: AWSTextractBlock?, _ blockMap: [String: AWSTextractBlock]) -> Table.Cell? {
        guard let selectionStatus = block?.selectionStatus,
            let rowSpan = block?.rowSpan,
            let columnSpan = block?.columnSpan,
            let geometry = block?.geometry,
            let textractBoundingBox = geometry.boundingBox,
            let texttractPolygon = geometry.polygon,
            let relationships = block?.relationships
            else {
                return nil
        }

        var words = ""
        var isSelected = false

        // Each CELL block consists of WORD and/or SELECTION_ELEMENT blocks
        for cellRelation in relationships {
            guard let ids = cellRelation.ids else {
                continue
            }

            for wordId in ids {
                let wordBlock = blockMap[wordId]

                switch wordBlock?.blockType {
                case .word:
                    guard let text = wordBlock?.text else {
                        return nil
                    }
                    words += text + " "
                case .selectionElement:
                    isSelected = selectionStatus == .selected ? true : false
                default:
                    break
                }
            }
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

    // https://docs.aws.amazon.com/textract/latest/dg/how-it-works-kvp.html
    /**
    * Converts a given Amazon Textract block into Amplify-compatible
    * key-value pair feature. Returns null if not a valid table.
    * @param block Textract text block
    * @param blockMap map of Textract blocks by their IDs
    * @return Amplify KeyValue instance
    */
    static func processKeyValue(_ keyBlock: AWSTextractBlock?,
                                blockMap: [String: AWSTextractBlock]) -> BoundedKeyValue? {
        var keyText = ""
        var valueText = ""
        var valueSelected = false

        guard let keyBlock = keyBlock,
            let relationships = keyBlock.relationships else {
            return nil
        }

        // KEY_VALUE_SET block contains CHILD and VALUE entity type blocks
        for keyBlockRelationship in relationships {

            guard let ids = keyBlockRelationship.ids else {
                continue
            }

            switch keyBlockRelationship.types {
            case .child:
                keyText = processChild(ids: ids, blockMap: blockMap)
            case .value:
                let valueResult = processValue(ids: ids, blockMap: blockMap)
                valueText = valueResult.0
                valueSelected = valueResult.1
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
