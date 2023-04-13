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

class IdentifyResultTransformers {

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

    static func processPolygon(_ rekognitionPolygonPoints: [RekognitionClientTypes.Point]?) -> Polygon? {
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
        return Polygon(points: points)
    }

    static func processPolygon(_ textractPolygonPoints: [TextractClientTypes.Point]?) -> Polygon? {
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

        return Polygon(points: points)
    }

    // swiftlint:disable cyclomatic_complexity
    static func processLandmarks(_ rekognitionLandmarks: [RekognitionClientTypes.Landmark]?) -> [Landmark] {
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
