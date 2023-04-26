//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSRekognition
import Amplify

enum IdentifyCelebritiesResultTransformers { //: IdentifyResultTransformers {

    static func processCelebs(
        _ rekognitionCelebs: [RekognitionClientTypes.Celebrity]
    ) -> [Predictions.Celebrity] {
        var celebs = [Predictions.Celebrity]()
        for rekognitionCeleb in rekognitionCelebs {

            guard let name = rekognitionCeleb.name,
                let identifier = rekognitionCeleb.id,
                let face = rekognitionCeleb.face,
                let stringUrls = rekognitionCeleb.urls else {
                continue
            }
            var urls = [URL]()
            for url in stringUrls {
                guard let newUrl = URL(string: url) else { continue }

                urls.append(newUrl)
            }

            guard let pitch = face.pose?.pitch, let roll = face.pose?.roll, let yaw = face.pose?.yaw else {
                continue
            }

            let pose = Predictions.Pose(
                pitch: Double(pitch),
                roll: Double(roll),
                yaw: Double(yaw)
            )

            let metadata = Predictions.Celebrity.Metadata(name: name, identifier: identifier, urls: urls, pose: pose)

            guard let boundingBox = IdentifyResultTransformers.processBoundingBox(face.boundingBox) else {
                continue
            }

            let landmarks = IdentifyResultTransformers.processLandmarks(face.landmarks)
            let celeb = Predictions.Celebrity(metadata: metadata, boundingBox: boundingBox, landmarks: landmarks)
            celebs.append(celeb)
        }

        return celebs
    }
}
