//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSRekognition
import Amplify
//
//extension Array where Element == CGRect {
//    init(rekognitionInstances: [RekognitionClientTypes.Instance]?) {
//        guard let rekognitionInstances = rekognitionInstances else {
//            self = []
//            return
//        }
//
//        var boundingBoxes = [CGRect]()
//        for rekognitionInstance in rekognitionInstances {
//            guard let boundingBox = CGRect(rekognitionBoundingBox: rekognitionInstance.boundingBox) else {
//                continue
//            }
//            boundingBoxes.append(boundingBox)
//        }
//
//        self = boundingBoxes
//    }
//}
//
//extension Array where Element == Parent {
//    init(rekognitionParents: [RekognitionClientTypes.Parent]?) {
//        var parents = [Parent]()
//        guard let rekognitionParents = rekognitionParents else {
//            self = parents
//            return
//        }
//
//        for parent in rekognitionParents {
//            if let name = parent.name {
//                parents.append(Parent(name: name))
//            }
//        }
//        self = parents
//    }
//}
//
//extension Array where Element == Label {
//    init(rekognitionLabels: [RekognitionClientTypes.ModerationLabel]) {
//        var labels = [Label]()
//        for rekognitionLabel in rekognitionLabels {
//
//            guard let name = rekognitionLabel.name else {
//                continue
//            }
//            var parents = [Parent]()
//            if let parentName = rekognitionLabel.parentName {
//                let parent = Parent(name: parentName)
//                parents.append(parent)
//            }
//            let metadata = LabelMetadata(
//                confidence: Double(rekognitionLabel.confidence ?? 0),
//                parents: parents
//            )
//
//            let label = Label(name: name, metadata: metadata, boundingBoxes: nil)
//
//            labels.append(label)
//        }
//        self = labels
//    }
//
//    init(rekognitionLabels: [RekognitionClientTypes.Label]) {
//        var labels = [Label]()
//        for rekognitionLabel in rekognitionLabels {
//
//            guard let name = rekognitionLabel.name else {
//                continue
//            }
//
//            let parents = [Parent](rekognitionParents: rekognitionLabel.parents)
//
//            let metadata = LabelMetadata(
//                confidence: Double(rekognitionLabel.confidence ?? 0.0),
//                parents: parents
//            )
//
//            let boundingBoxes = [CGRect](rekognitionInstances: rekognitionLabel.instances)
//
//            let label = Label(
//                name: name,
//                metadata: metadata,
//                boundingBoxes: boundingBoxes
//            )
//            labels.append(label)
//        }
//
//        self = labels
//    }
//}

enum IdentifyLabelsResultTransformers { //: IdentifyResultTransformers {
    static func processLabels(
        _ rekognitionLabels: [RekognitionClientTypes.Label]
    ) -> [Label] {
        var labels = [Label]()
        for rekognitionLabel in rekognitionLabels {

            guard let name = rekognitionLabel.name else {
                continue
            }

            let parents = processParents(rekognitionLabel.parents)

            let metadata = LabelMetadata(
                confidence: Double(rekognitionLabel.confidence ?? 0.0),
                parents: parents
            )

            let boundingBoxes = processInstances(rekognitionLabel.instances)

            let label = Label(
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
    ) -> [Label] {
        var labels = [Label]()
        for rekognitionLabel in rekognitionLabels {

            guard let name = rekognitionLabel.name else {
                continue
            }
            var parents = [Parent]()
            if let parentName = rekognitionLabel.parentName {
                let parent = Parent(name: parentName)
                parents.append(parent)
            }
            let metadata = LabelMetadata(confidence: Double(rekognitionLabel.confidence ?? 0), parents: parents)

            let label = Label(name: name, metadata: metadata, boundingBoxes: nil)

            labels.append(label)
        }
        return labels
    }

    static func processParents(
        _ rekognitionParents: [RekognitionClientTypes.Parent]?
    ) -> [Parent] {
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
