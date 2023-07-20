//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSRekognition
import AWSTextract
import CoreGraphics

enum IdentifyResultTransformers {
    static func processBoundingBox(_ rekognitionBoundingBox: RekognitionClientTypes.BoundingBox?) -> CGRect? {
        guard let height = rekognitionBoundingBox?.height.map(Double.init),
              let left = rekognitionBoundingBox?.left.map(Double.init),
              let top = rekognitionBoundingBox?.top.map(Double.init),
              let width = rekognitionBoundingBox?.width.map(Double.init)
        else { return nil }
        return CGRect(x: left, y: top, width: width, height: height)
    }

    static func processBoundingBox(_ textractBoundingBox: TextractClientTypes.BoundingBox?) -> CGRect? {
        guard let height = (textractBoundingBox?.height).map(Double.init),
              let left = (textractBoundingBox?.left).map(Double.init),
              let top = (textractBoundingBox?.top).map(Double.init),
              let width = (textractBoundingBox?.width).map(Double.init)
        else { return nil }
        return CGRect(x: left, y: top, width: width, height: height)
    }

    static func processPolygon(_ rekognitionPolygonPoints: [RekognitionClientTypes.Point]?) -> Predictions.Polygon? {
        guard let rekognitionPolygonPoints = rekognitionPolygonPoints else {
            return nil
        }
        var points = [CGPoint]()
        for rekognitionPoint in rekognitionPolygonPoints {
            guard let xPosition = rekognitionPoint.x,
                  let yPosition = rekognitionPoint.y else {
                continue
            }
            let point = CGPoint(x: Double(xPosition), y: Double(yPosition)) // TODO: What about Truncating???
            points.append(point)
        }
        return Predictions.Polygon(points: points)
    }

    static func processPolygon(_ textractPolygonPoints: [TextractClientTypes.Point]?) -> Predictions.Polygon? {
        guard let textractPolygonPoints = textractPolygonPoints else {
            return nil
        }

        var points = [CGPoint]()
        for textractPoint in textractPolygonPoints {
            let xPosition = textractPoint.x
            let yPosition = textractPoint.y
            let point = CGPoint(x: Double(xPosition), y: Double(yPosition))
            points.append(point)
        }

        return Predictions.Polygon(points: points)
    }

    // swiftlint:disable cyclomatic_complexity
    static func processLandmarks(_ rekognitionLandmarks: [RekognitionClientTypes.Landmark]?) -> [Predictions.Landmark] {
        var landmarks = [Predictions.Landmark]()
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
            guard let xPosition = rekognitionLandmark.x.map(Double.init),
                  let yPosition = rekognitionLandmark.y.map(Double.init) else {
                continue
            }
            let point = CGPoint(x: xPosition, y: yPosition)
            allPoints.append(point)
            switch rekognitionLandmark.type {
            case .eyeleft,
                    .lefteyeup,
                    .lefteyedown,
                    .lefteyeleft,
                    .lefteyeright:
                leftEyePoints.append(point)
            case .eyeright,
                    .righteyeleft,
                    .righteyeright,
                    .righteyeup,
                    .righteyedown:
                rightEyePoints.append(point)
            case .lefteyebrowleft, .lefteyebrowright, .lefteyebrowup:
                leftEyeBrowPoints.append(point)
            case .righteyebrowleft, .righteyebrowright, .righteyebrowup:
                rightEyeBrowPoints.append(point)
            case .nose:
                nosePoints.append(point)
            case .noseleft, .noseright:
                noseCrestPoints.append(point)
            case .mouthleft, .mouthright, .mouthup, .mouthdown:
                outerLipPoints.append(point)
            case .leftpupil:
                leftPupilPoints.append(point)
            case .rightpupil:
                rightPupilPoints.append(point)
            case .upperjawlineleft,
                    .midjawlineleft,
                    .chinbottom,
                    .midjawlineright,
                    .upperjawlineright:
                faceContourPoints.append(point)
            case .none, .sdkUnknown:
                continue
            }
        }
        landmarks.append(Predictions.Landmark(kind: .allPoints, points: allPoints))
        landmarks.append(Predictions.Landmark(kind: .leftEye, points: leftEyePoints))
        landmarks.append(Predictions.Landmark(kind: .rightEye, points: rightEyePoints))
        landmarks.append(Predictions.Landmark(kind: .leftEyebrow, points: leftEyeBrowPoints))
        landmarks.append(Predictions.Landmark(kind: .rightEyebrow, points: rightEyeBrowPoints))
        landmarks.append(Predictions.Landmark(kind: .nose, points: nosePoints))
        landmarks.append(Predictions.Landmark(kind: .noseCrest, points: noseCrestPoints))
        landmarks.append(Predictions.Landmark(kind: .outerLips, points: outerLipPoints))
        landmarks.append(Predictions.Landmark(kind: .leftPupil, points: leftPupilPoints))
        landmarks.append(Predictions.Landmark(kind: .rightPupil, points: rightPupilPoints))
        landmarks.append(Predictions.Landmark(kind: .faceContour, points: faceContourPoints))
        return landmarks
    }
}
