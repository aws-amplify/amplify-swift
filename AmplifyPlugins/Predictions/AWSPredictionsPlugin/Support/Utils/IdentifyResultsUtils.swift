//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSRekognition

class IdentifyResultsUtils {

    static func processLabels(_ rekognitionLabels: [AWSRekognitionLabel]) -> [Label] {
        var labels = [Label]()
        for rekognitionLabel in rekognitionLabels {

            guard let name = rekognitionLabel.name else {
                continue
            }

            let parents = processParents(rekognitionLabel.parents)

            let metadata = LabelMetadata(confidence: Double(
                truncating: rekognitionLabel.confidence ?? 0.0), parents: parents)

            let boundingBoxes = processInstances(rekognitionLabel.instances)

            let label = Label(name: name, metadata: metadata, boundingBoxes: boundingBoxes)

            labels.append(label)
        }
        return labels
    }

    static func processParents(_ rekognitionParents: [AWSRekognitionParent]?) -> [Parent] {
        var parents = [Parent]()
        guard let rekognitionParents = rekognitionParents else {
            return parents
        }

        for parent in rekognitionParents {
            if let name = parent.name {
                parents.append(Parent(name: name))
            }
        }
        return parents
    }

    static func processInstances(_ rekognitionInstances: [AWSRekognitionInstance]?) -> [BoundingBox] {
        var boundingBoxes = [BoundingBox]()
        guard let rekognitionInstances = rekognitionInstances else {
            return boundingBoxes
        }
        for rekognitionInstance in rekognitionInstances {
            guard let height = rekognitionInstance.boundingBox?.height,
                let left = rekognitionInstance.boundingBox?.left,
                let top = rekognitionInstance.boundingBox?.top,
                let width = rekognitionInstance.boundingBox?.width else {
                    continue
            }
            let boundingBox = BoundingBox(
                height: Double(truncating: height),
                left: Double(truncating: left),
                top: Double(truncating: top),
                width: Double(truncating: width))
            boundingBoxes.append(boundingBox)
        }

        return boundingBoxes
    }

    static func processCelebs(_ rekognitionCelebs: [AWSRekognitionCelebrity]) -> [Celebrity] {
        var celebs = [Celebrity]()
        for rekognitionCeleb in rekognitionCelebs {

            guard let name = rekognitionCeleb.name,
                let identifier = rekognitionCeleb.identifier,
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

            let pose = Pose(
                pitch: Double(truncating: pitch),
                roll: Double(truncating: roll),
                yaw: Double(truncating: yaw))

            let metadata = CelebMetadata(name: name, identifier: identifier, urls: urls, pose: pose)

            guard let height = face.boundingBox?.height,
                let left = face.boundingBox?.left,
                let top = face.boundingBox?.top,
                let width = face.boundingBox?.width else {
                    continue
            }

            let boundingBox = BoundingBox(
                height: Double(truncating: height),
                left: Double(truncating: left),
                top: Double(truncating: top),
                width: Double(truncating: width))

            let landmarks = processLandmarks(face.landmarks)

            let celeb = Celebrity(metadata: metadata, boundingBox: boundingBox, landmarks: landmarks)

            celebs.append(celeb)
        }

        return celebs
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
