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

class IdentifyResultUtils {

    static func processBoundingBox(_ rekognitionBoundingBox: AWSRekognitionBoundingBox?) -> BoundingBox? {
        guard let height = rekognitionBoundingBox?.height,
            let left = rekognitionBoundingBox?.left,
            let top = rekognitionBoundingBox?.top,
            let width = rekognitionBoundingBox?.width else {
                return nil
        }
        return BoundingBox(
            height: Double(truncating: height),
            left: Double(truncating: left),
            top: Double(truncating: top),
            width: Double(truncating: width))
    }

    static func processBoundingBox(_ textractBoundingBox: AWSTextractBoundingBox?) -> BoundingBox? {
        guard let height = textractBoundingBox?.height,
            let left = textractBoundingBox?.left,
            let top = textractBoundingBox?.top,
            let width = textractBoundingBox?.width else {
                return nil
        }
        return BoundingBox(
            height: Double(truncating: height),
            left: Double(truncating: left),
            top: Double(truncating: top),
            width: Double(truncating: width))
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
