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

    static func processText(textractTextBlocks: [AWSTextractBlock]?) -> IdentifyDocumentTextResult? {

        var words = [Word]()
        var lines = [String]()
        var linesDetailed = [Word]()
        var selections = [Selection]()
        var fullText = ""
        var table: Table?
        var keyValues = [KeyValue]()

        guard let blocks = textractTextBlocks else {
            return nil
        }

        for block in blocks {
            guard let text = block.text else {
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
            case .selectionElement:
                let selectionStatus = block.selectionStatus == .selected ? true : false
                let selection = Selection(boundingBox: boundingBox, polygon: polygon, selectionStatus: selectionStatus)
                selections.append(selection)

            case .table:
                table = processTable(block, boundingBox: boundingBox, polygon: polygon)

            case .keyValueSet: break
            case .unknown:
                break
            case .page:
                break
            case .cell:
                break
            @unknown default:
                break
            }
        }

        return IdentifyDocumentTextResult(
            fullText: fullText,
            words: words,
            lines: lines,
            linesDetailed: linesDetailed,
            selections: selections,
            table: table!,
            keyValues: keyValues)
    }

    static func processTable(_ block: AWSTextractBlock, boundingBox: BoundingBox, polygon: Polygon) -> Table? {

        var cells = [TableCell]()
        guard let relationships = block.relationships,
            let text = block.text,
            let rowSpan = block.rowSpan,
            let columnSpan = block.columnSpan else {
            return nil
        }
        for _ in relationships {
             let selectionStatus = block.selectionStatus == .selected ? true : false
            let cell = TableCell(text: text,
                                 boundingBox: boundingBox,
                                 polygon: polygon,
                                 selected: selectionStatus,
                                 rowSpan: Int(truncating: rowSpan),
                                 columnSpan: Int(truncating: columnSpan))
            cells.append(cell)
        }
        return Table(rows: Int(truncating: rowSpan), columns: Int(truncating: columnSpan), cells: cells)

    }
}
