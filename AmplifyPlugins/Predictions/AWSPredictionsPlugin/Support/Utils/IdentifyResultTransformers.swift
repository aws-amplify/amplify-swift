//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSRekognition
import AWSTextract
import CoreGraphics

class IdentifyResultTransformers {

    static func processBoundingBox(_ rekognitionBoundingBox: AWSRekognitionBoundingBox?) -> CGRect? {
        guard let height = rekognitionBoundingBox?.height?.doubleValue,
            let left = rekognitionBoundingBox?.left?.doubleValue,
            let top = rekognitionBoundingBox?.top?.doubleValue,
            let width = rekognitionBoundingBox?.width?.doubleValue else {
                return nil
        }
        return CGRect(x: left, y: top, width: width, height: height)
    }

    static func processBoundingBox(_ textractBoundingBox: AWSTextractBoundingBox?) -> CGRect? {
        guard let height = textractBoundingBox?.height?.doubleValue,
            let left = textractBoundingBox?.left?.doubleValue,
            let top = textractBoundingBox?.top?.doubleValue,
            let width = textractBoundingBox?.width?.doubleValue else {
                return nil
        }
        return CGRect(x: left, y: top, width: width, height: height)
    }

    static func processPolygon(_ rekognitionPolygonPoints: [AWSRekognitionPoint]?) -> Polygon? {
        guard let rekognitionPolygonPoints = rekognitionPolygonPoints else {
            return nil
        }
        var points = [CGPoint]()
        for rekognitionPoint in rekognitionPolygonPoints {
            guard let xPosition = rekognitionPoint.x,
                let yPosition = rekognitionPoint.y else {
                    continue
            }
            let point = CGPoint(x: Double(truncating: xPosition), y: Double(truncating: yPosition))
            points.append(point)
        }
        return Polygon(points: points)

    }

    static func processPolygon(_ textractPolygonPoints: [AWSTextractPoint]?) -> Polygon? {
        guard let textractPolygonPoints = textractPolygonPoints else {
            return nil
        }
        var points = [CGPoint]()
        for textractPoint in textractPolygonPoints {
            guard let xPosition = textractPoint.x,
                let yPosition = textractPoint.y else {
                    continue
            }
            let point = CGPoint(x: Double(truncating: xPosition), y: Double(truncating: yPosition))
            points.append(point)
        }
        return Polygon(points: points)

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
        var valueSelected = false

        for valueId in ids {
            let valueBlock = blockMap[valueId]
            guard let valueBlockRelations = valueBlock?.relationships else {
                continue
            }
            for valueBlockRelation in valueBlockRelations {
                guard let wordBlockIds = valueBlockRelation.ids else {
                    break
                }
                for wordBlockId in wordBlockIds {
                    let wordBlock = blockMap[wordBlockId]
                    guard let wordValueBlockType = wordBlock?.blockType else {
                        continue
                    }
                    switch wordValueBlockType {
                    case .word:
                        if let text = wordBlock?.text {
                            valueText += text + " "
                        }
                    case .selectionElement:
                        valueSelected = wordBlock?.selectionStatus == .selected
                    default: break
                    }
                }
            }
        }
        return (valueText.trimmingCharacters(in: .whitespacesAndNewlines), valueSelected)
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
        let selectionStatus = block.selectionStatus == .selected ? true : false
        return Selection(boundingBox: boundingBox, polygon: polygon, isSelected: selectionStatus)
    }

    // swiftlint:disable cyclomatic_complexity
    static func processLandmarks(_ rekognitionLandmarks: [AWSRekognitionLandmark]?) -> [Landmark] {
        var landmarks = [Landmark]()
        guard let rekognitionLandmarks = rekognitionLandmarks else {
            return landmarks
        }

        var allPoints: [CGPoint] = []
        var leftEyePoints: [CGPoint] = []
        var rightEyePoints: [CGPoint] = []
        var leftEyeBrowPoints: [CGPoint] = []
        var rightEyeBrowPoints: [CGPoint] = []
        var nosePoints: [CGPoint] = []
        var noseCrestPoints: [CGPoint] = []
        var outerLipPoints: [CGPoint] = []
        var leftPupilPoints: [CGPoint] = []
        var rightPupilPoints: [CGPoint] = []
        var faceContourPoints: [CGPoint] = []
        for rekognitionLandmark in rekognitionLandmarks {
            guard let xPosition = rekognitionLandmark.x?.doubleValue,
                let yPosition = rekognitionLandmark.y?.doubleValue else {
                    continue
            }
            let point = CGPoint(x: xPosition, y: yPosition)
            allPoints.append(point)
            switch rekognitionLandmark.types {
            case .eyeLeft,
                 .leftEyeUp,
                 .leftEyeDown,
                 .leftEyeLeft,
                 .leftEyeRight:
                leftEyePoints.append(point)
            case .eyeRight,
                 .rightEyeLeft,
                 .rightEyeRight,
                 .rightEyeUp,
                 .rightEyeDown:
                rightEyePoints.append(point)
            case .leftEyeBrowLeft, .leftEyeBrowRight, .leftEyeBrowUp:
                leftEyeBrowPoints.append(point)
            case .rightEyeBrowLeft, .rightEyeBrowRight, .rightEyeBrowUp:
                rightEyeBrowPoints.append(point)
            case .nose:
                nosePoints.append(point)
            case .noseLeft, .noseRight:
                noseCrestPoints.append(point)
            case .mouthLeft, .mouthRight, .mouthUp, .mouthDown:
                outerLipPoints.append(point)
            case .leftPupil:
                leftPupilPoints.append(point)
            case .rightPupil:
                rightPupilPoints.append(point)
            case .upperJawlineLeft,
                 .midJawlineLeft,
                 .chinBottom,
                 .midJawlineRight,
                 .upperJawlineRight:
                faceContourPoints.append(point)
            case .unknown:
                continue
            @unknown default:
                continue
            }
        }
        landmarks.append(Landmark(type: .allPoints, points: allPoints))
        landmarks.append(Landmark(type: .leftEye, points: leftEyePoints))
        landmarks.append(Landmark(type: .rightEye, points: rightEyePoints))
        landmarks.append(Landmark(type: .leftEyebrow, points: leftEyeBrowPoints))
        landmarks.append(Landmark(type: .rightEyebrow, points: rightEyeBrowPoints))
        landmarks.append(Landmark(type: .nose, points: nosePoints))
        landmarks.append(Landmark(type: .noseCrest, points: noseCrestPoints))
        landmarks.append(Landmark(type: .outerLips, points: outerLipPoints))
        landmarks.append(Landmark(type: .leftPupil, points: leftPupilPoints))
        landmarks.append(Landmark(type: .rightPupil, points: rightPupilPoints))
        landmarks.append(Landmark(type: .faceContour, points: faceContourPoints))
        return landmarks
    }
}
