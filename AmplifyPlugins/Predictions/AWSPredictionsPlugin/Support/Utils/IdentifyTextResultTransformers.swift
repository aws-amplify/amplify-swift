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

// swiftlint:disable type_body_length
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
        var blockMap = [String: AWSTextractBlock]()
        for block in textractTextBlocks {
            guard let identifier = block.identifier else {
                continue
            }
            blockMap[identifier] = block
        }
        return processTextBlocks(blockMap)
    }

    static func processTextBlocks(_ blockMap: [String: AWSTextractBlock]) -> IdentifyDocumentTextResult {
        var fullText = ""
        var words = [IdentifiedWord]()
        var lines = [String]()
        var linesDetailed = [IdentifiedLine]()
        var selections = [Selection]()
        var tables = [Table]()
        var keyValues = [BoundedKeyValue]()
        var tableBlocks = [AWSTextractBlock]()
        var keyValueBlocks = [AWSTextractBlock]()

        for block in blockMap.values {
            switch block.blockType {
            case .line:
                if let line = processLineBlock(block: block) {
                    lines.append(line.text)
                    linesDetailed.append(line)
                }
            case .word:
                if let word = processWordBlock(block: block) {
                    fullText += word.text + " "
                    words.append(word)
                }
            case .selectionElement:
                if let selection = processSelectionElementBlock(block: block) {
                    selections.append(selection)
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
        for keyValueBlock in keyValueBlocks {
            if let keyValue = processKeyValue(keyValueBlock, blockMap: blockMap) {
                keyValues.append(keyValue)
            }
        }
        return keyValues
    }

    static func processTable(_ tableBlock: AWSTextractBlock,
                             blockMap: [String: AWSTextractBlock]) -> Table? {

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
                let row = Int(truncating: rowIndex) - 1
                let col = Int(truncating: colIndex) - 1

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

    static func constructTableCell(_ block: AWSTextractBlock, _ blockMap: [String: AWSTextractBlock]) -> Table.Cell? {
        guard block.blockType == .cell,
            let relationships = block.relationships,
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
                    let result = processSelectionElement(selectionItemFound, selectionStatus: selectionStatus)
                    isSelected = result.0
                    selectionItemFound = result.1
                default:
                    break
                }
            }
        }

        guard let boundingBox = processBoundingBox(textractBoundingBox),
            let polygon = processPolygon(texttractPolygon) else {
            return nil
        }

        return Table.Cell(text: words,
                          boundingBox: boundingBox,
                          polygon: polygon,
                          isSelected: isSelected,
                          rowSpan: Int(truncating: rowSpan),
                          columnSpan: Int(truncating: columnSpan))
    }

    static func processKeyValue(_ keyBlock: AWSTextractBlock,
                                blockMap: [String: AWSTextractBlock]) -> BoundedKeyValue? {
        guard keyBlock.blockType == .keyValueSet,
            keyBlock.entityTypes?.contains("KEY") ?? false,
            let relationships = keyBlock.relationships else {
            return nil
        }

        var keyText = ""
        var valueText = ""
        var valueSelected = false

        for keyBlockRelationship in relationships {
            guard let ids = keyBlockRelationship.ids else {
                continue
            }

            switch keyBlockRelationship.types {
            case .child:
                keyText = processChildOfKeyValueSet(ids: ids, blockMap: blockMap)
            case .value:
                let valueResult = processValueOfKeyValueSet(ids: ids, blockMap: blockMap)
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

    static func processChildOfKeyValueSet(ids: [String],
                                          blockMap: [String: AWSTextractBlock]) -> String {
        var keyText = ""
        for keyId in ids {
            guard let keyBlock = blockMap[keyId],
                let text = keyBlock.text,
                case .word = keyBlock.blockType else {
                continue
            }
            keyText += text + " "
        }
        return keyText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func processValueOfKeyValueSet(ids: [String],
                                          blockMap: [String: AWSTextractBlock]) -> (String, Bool) {
        var valueText = ""
        var isSelected = false
        var selectionItemFound = false

        for valueId in ids {
            guard let valueBlock = blockMap[valueId],
                let valueBlockRelations = valueBlock.relationships else {
                continue
            }

            for valueBlockRelation in valueBlockRelations {
                guard let wordBlockIds = valueBlockRelation.ids else {
                    break
                }

                for wordBlockId in wordBlockIds {
                    guard let wordBlock = blockMap[wordBlockId] else {
                        continue
                    }
                    let wordValueBlockType = wordBlock.blockType
                    let selectionStatus = wordBlock.selectionStatus

                    switch wordValueBlockType {
                    case .word:
                        if let text = wordBlock.text {
                            valueText += text + " "
                        }
                    case .selectionElement:
                        let result = processSelectionElement(selectionItemFound, selectionStatus: selectionStatus)
                        isSelected = result.0
                        selectionItemFound = result.1
                    default: break
                    }
                }
            }
        }
        return (valueText.trimmingCharacters(in: .whitespacesAndNewlines), isSelected)
    }

    static func processSelectionElement(_ selectionItemFoundOld: Bool,
                                        selectionStatus: AWSTextractSelectionStatus) -> (Bool, Bool) {
        var selectionItemFound = selectionItemFoundOld
        var isSelected = false
        if !selectionItemFound {
            selectionItemFound = true
            //TODO: Support multiple selection items found in a single cell
            isSelected = selectionStatus == .selected
        } else {
            Amplify.log.error("Multiple selection items found in single cell")
        }
        return (isSelected, selectionItemFound)
    }

    static func processLineBlock(block: AWSTextractBlock) -> IdentifiedLine? {
        guard let text = block.text,
            let boundingBox = processBoundingBox(block.geometry?.boundingBox),
            let polygon = processPolygon(block.geometry?.polygon) else {
                return nil
        }

        return IdentifiedLine(text: text,
                              boundingBox: boundingBox,
                              polygon: polygon,
                              page: Int(truncating: block.page ?? 0))
    }

    static func processWordBlock(block: AWSTextractBlock) -> IdentifiedWord? {
        guard let text = block.text,
            let boundingBox = processBoundingBox(block.geometry?.boundingBox),
            let polygon = processPolygon(block.geometry?.polygon) else {
                return nil
        }

         return IdentifiedWord(text: text,
                               boundingBox: boundingBox,
                               polygon: polygon,
                               page: Int(truncating: block.page ?? 0))
    }

    static func processSelectionElementBlock(block: AWSTextractBlock) -> Selection? {
        guard let boundingBox = processBoundingBox(block.geometry?.boundingBox),
            let polygon = processPolygon(block.geometry?.polygon) else {
                return nil
        }
        let selectionStatus = block.selectionStatus == .selected
        return Selection(boundingBox: boundingBox, polygon: polygon, isSelected: selectionStatus)
    }
}
