//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSRekognition
import Amplify

enum IdentifyLabelsResultTransformers { 
    static func processLabels(
        _ rekognitionLabels: [RekognitionClientTypes.Label]
    ) -> [Predictions.Label] {
        var labels = [Predictions.Label]()
        for rekognitionLabel in rekognitionLabels {

            guard let name = rekognitionLabel.name else {
                continue
            }

            let parents = processParents(rekognitionLabel.parents)

            let metadata = Predictions.Label.Metadata(
                confidence: Double(rekognitionLabel.confidence ?? 0.0),
                parents: parents
            )

            let boundingBoxes = processInstances(rekognitionLabel.instances)

            let label = Predictions.Label(
                name: name,
                metadata: metadata,
                boundingBoxes: boundingBoxes
            )
            labels.append(label)
        }

        return labels
    }

    static func processModerationLabels(
        _ rekognitionLabels: [RekognitionClientTypes.ModerationLabel]
    ) -> [Predictions.Label] {
        var labels = [Predictions.Label]()
        for rekognitionLabel in rekognitionLabels {

            guard let name = rekognitionLabel.name else {
                continue
            }
            var parents = [Predictions.Parent]()
            if let parentName = rekognitionLabel.parentName {
                let parent = Predictions.Parent(name: parentName)
                parents.append(parent)
            }
            let metadata = Predictions.Label.Metadata(
                confidence: Double(rekognitionLabel.confidence ?? 0), parents: parents
            )

            let label = Predictions.Label(name: name, metadata: metadata, boundingBoxes: nil)

            labels.append(label)
        }
        return labels
    }

    static func processParents(
        _ rekognitionParents: [RekognitionClientTypes.Parent]?
    ) -> [Predictions.Parent] {
        var parents = [Predictions.Parent]()
        guard let rekognitionParents = rekognitionParents else {
            return parents
        }

        for parent in rekognitionParents {
            if let name = parent.name {
                parents.append(Predictions.Parent(name: name))
            }
        }
        return parents
    }

    static func processInstances(
        _ rekognitionInstances: [RekognitionClientTypes.Instance]?
    ) -> [CGRect] {
        var boundingBoxes = [CGRect]()
        guard let rekognitionInstances = rekognitionInstances else {
            return boundingBoxes
        }
        for rekognitionInstance in rekognitionInstances {
            guard let boundingBox = IdentifyResultTransformers.processBoundingBox(rekognitionInstance.boundingBox) else {
                continue
            }
            boundingBoxes.append(boundingBox)
        }

        return boundingBoxes
    }
}
