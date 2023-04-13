//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSRekognition
import Amplify
import AWSTextract

class IdentifyTextResultTransformers: IdentifyResultTransformers {

    static func processText(_ rekognitionTextBlocks: [RekognitionClientTypes.TextDetection]) -> IdentifyTextResult {
        var words = [IdentifiedWord]()
        var lines = [String]()
        var identifiedLines = [IdentifiedLine]()
        var fullText = ""
        for rekognitionTextBlock in rekognitionTextBlocks {
            guard let detectedText = rekognitionTextBlock.detectedText else {
                continue
            }
            guard let boundingBox = processBoundingBox(rekognitionTextBlock.geometry?.boundingBox)
            else { continue }

            guard let polygon = processPolygon(rekognitionTextBlock.geometry?.polygon)
            else { continue }
            
            let word = IdentifiedWord(
                text: detectedText,
                boundingBox: boundingBox,
                polygon: polygon
            )

            let line = IdentifiedLine(
                text: detectedText,
                boundingBox: boundingBox,
                polygon: polygon
            )

            switch rekognitionTextBlock.type {
            case .line:
                lines.append(detectedText)
                identifiedLines.append(line)
            case .word:
                fullText += detectedText + " "
                words.append(word)
            case .sdkUnknown:
                break
            default:
                break
            }
        }

        return IdentifyTextResult(fullText: fullText,
                                  words: words,
                                  rawLineText: lines,
                                  identifiedLines: identifiedLines)
    }

    static func processText(_ textractTextBlocks: [TextractClientTypes.Block]) -> IdentifyDocumentTextResult {
        var blockMap = [String: TextractClientTypes.Block]()
        for block in textractTextBlocks {
            guard let identifier = block.id else {
                continue
            }
            blockMap[identifier] = block
        }
        return processTextBlocks(blockMap)
    }

    static func processTextBlocks(_ blockMap: [String: TextractClientTypes.Block]) -> IdentifyDocumentTextResult {
        var fullText = ""
        var words = [IdentifiedWord]()
        var lines = [String]()
        var linesDetailed = [IdentifiedLine]()
        var selections = [Selection]()
        var tables = [Table]()
        var keyValues = [BoundedKeyValue]()
        var tableBlocks = [TextractClientTypes.Block]()
        var keyValueBlocks = [TextractClientTypes.Block]()

        // TODO: rework to map / reduce
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
            keyValues: keyValues
        )
    }

    static func processLineBlock(block: TextractClientTypes.Block) -> IdentifiedLine? {
        guard let text = block.text,
            let boundingBox = processBoundingBox(block.geometry?.boundingBox),
            let polygon = processPolygon(block.geometry?.polygon) else {
                return nil
        }

        return IdentifiedLine(
            text: text,
            boundingBox: boundingBox,
            polygon: polygon,
            page: block.page ?? 0
        )
    }

    static func processWordBlock(block: TextractClientTypes.Block) -> IdentifiedWord? {
        guard let text = block.text,
            let boundingBox = processBoundingBox(block.geometry?.boundingBox),
            let polygon = processPolygon(block.geometry?.polygon) else {
                return nil
        }

         return IdentifiedWord(
            text: text,
            boundingBox: boundingBox,
            polygon: polygon,
            page: block.page ?? 0
         )
    }

    static func processSelectionElementBlock(block: TextractClientTypes.Block) -> Selection? {
        guard let boundingBox = processBoundingBox(block.geometry?.boundingBox),
            let polygon = processPolygon(block.geometry?.polygon) else {
                return nil
        }
        let selectionStatus = block.selectionStatus == .selected
        return Selection(boundingBox: boundingBox, polygon: polygon, isSelected: selectionStatus)
    }
}
