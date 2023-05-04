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

enum IdentifyTextResultTransformers {

    static func processText(_ rekognitionTextBlocks: [RekognitionClientTypes.TextDetection]) -> Predictions.Identify.Text.Result {
        var words = [Predictions.IdentifiedWord]()
        var lines = [String]()
        var identifiedLines = [Predictions.IdentifiedLine]()
        var fullText = ""
        for rekognitionTextBlock in rekognitionTextBlocks {
            guard let detectedText = rekognitionTextBlock.detectedText else {
                continue
            }
            guard let boundingBox = IdentifyResultTransformers.processBoundingBox(rekognitionTextBlock.geometry?.boundingBox)
            else { continue }

            guard let polygon = IdentifyResultTransformers.processPolygon(rekognitionTextBlock.geometry?.polygon)
            else { continue }
            
            let word = Predictions.IdentifiedWord(
                text: detectedText,
                boundingBox: boundingBox,
                polygon: polygon
            )

            let line = Predictions.IdentifiedLine(
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

        return Predictions.Identify.Text.Result(
            fullText: fullText,
            words: words,
            rawLineText: lines,
            identifiedLines: identifiedLines
        )
    }

    static func processText(_ textractTextBlocks: [TextractClientTypes.Block]) -> Predictions.Identify.DocumentText.Result {
        var blockMap = [String: TextractClientTypes.Block]()
        for block in textractTextBlocks {
            guard let identifier = block.id else {
                continue
            }
            blockMap[identifier] = block
        }
        return processTextBlocks(blockMap)
    }

    static func processTextBlocks(_ blockMap: [String: TextractClientTypes.Block]) -> Predictions.Identify.DocumentText.Result {
        var fullText = ""
        var words = [Predictions.IdentifiedWord]()
        var lines = [String]()
        var linesDetailed = [Predictions.IdentifiedLine]()
        var selections = [Predictions.Selection]()
        var tables = [Predictions.Table]()
        var keyValues = [Predictions.BoundedKeyValue]()
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

        return Predictions.Identify.DocumentText.Result(
            fullText: fullText,
            words: words,
            rawLineText: lines,
            identifiedLines: linesDetailed,
            selections: selections,
            tables: tables,
            keyValues: keyValues
        )
    }

    static func processLineBlock(block: TextractClientTypes.Block) -> Predictions.IdentifiedLine? {
        guard let text = block.text,
              let boundingBox = IdentifyResultTransformers.processBoundingBox(block.geometry?.boundingBox),
              let polygon = IdentifyResultTransformers.processPolygon(block.geometry?.polygon) else {
                return nil
        }

        return Predictions.IdentifiedLine(
            text: text,
            boundingBox: boundingBox,
            polygon: polygon,
            page: block.page ?? 0
        )
    }

    static func processWordBlock(block: TextractClientTypes.Block) -> Predictions.IdentifiedWord? {
        guard let text = block.text,
              let boundingBox = IdentifyResultTransformers.processBoundingBox(block.geometry?.boundingBox),
              let polygon = IdentifyResultTransformers.processPolygon(block.geometry?.polygon) else {
                return nil
        }

        return Predictions.IdentifiedWord(
            text: text,
            boundingBox: boundingBox,
            polygon: polygon,
            page: block.page ?? 0
         )
    }

    static func processSelectionElementBlock(block: TextractClientTypes.Block) -> Predictions.Selection? {
        guard let boundingBox = IdentifyResultTransformers.processBoundingBox(block.geometry?.boundingBox),
              let polygon = IdentifyResultTransformers.processPolygon(block.geometry?.polygon) else {
                return nil
        }
        let selectionStatus = block.selectionStatus == .selected
        return Predictions.Selection(boundingBox: boundingBox, polygon: polygon, isSelected: selectionStatus)
    }
}
