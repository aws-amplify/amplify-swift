//
// Copyright 2018-2019 Amazon.com,
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
        // In the default Core Graphics coordinate space, the origin is located in the lower-left
        // corner of the rectangle and the rectangle extends towards the upper-right corner.
        let cgCoordinateY = 1 - top - height
        return CGRect(x: left, y: cgCoordinateY, width: width, height: height)
    }

    static func processBoundingBox(_ textractBoundingBox: AWSTextractBoundingBox?) -> CGRect? {
        guard let height = textractBoundingBox?.height?.doubleValue,
            let left = textractBoundingBox?.left?.doubleValue,
            let top = textractBoundingBox?.top?.doubleValue,
            let width = textractBoundingBox?.width?.doubleValue else {
                return nil
        }
        // In the default Core Graphics coordinate space, the origin is located in the lower-left
        // corner of the rectangle and the rectangle extends towards the upper-right corner.
        let cgCoordinateY = 1 - top - height
        return CGRect(x: left, y: cgCoordinateY, width: width, height: height)
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

    static func processLandmarks(_ rekognitionLandmarks: [AWSRekognitionLandmark]?) -> [Landmark] {
        var landmarks = [Landmark]()
        guard let rekognitionLandmarks = rekognitionLandmarks else {
            return landmarks
        }

        for rekognitionLandmark in rekognitionLandmarks {
            guard let xPosition = rekognitionLandmark.x, let yPosition = rekognitionLandmark.y else {
                continue
            }
            let landmark = Landmark(
                type: String(rekognitionLandmark.types.rawValue),
                xPosition: Double(truncating: xPosition),
                yPosition: Double(truncating: yPosition))

            landmarks.append(landmark)

        }

        return landmarks
    }
}
