//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSRekognition

class IdentifyLabelsResultUtils {

   static func process(_ rekogLabels: [AWSRekognitionLabel]) -> [Label] {
       var labels = [Label]()
        for label in rekogLabels {

            guard let name = label.name else {
                continue
            }

            let parents = processParent(rekogParents: label.parents)

            let metadata = LabelMetadata(confidence: Double(
                truncating: label.confidence ?? 0.0), parents: parents)

            let boundingBoxes = processBoundingBoxes(instances: label.instances)

            let newLabel = Label(name: name, metadata: metadata, boundingBoxes: boundingBoxes)

            labels.append(newLabel)
        }
        return labels
    }

    static func processParent(rekogParents: [AWSRekognitionParent]?) -> [Parent] {
        var parents = [Parent]()
        guard let rekogParents = rekogParents else {
            return parents
        }

        for parent in rekogParents {
            if let name = parent.name {
                parents.append(Parent(name: name))
            }
        }
        return parents
    }

    static func processBoundingBoxes(instances: [AWSRekognitionInstance]?) -> [BoundingBox] {
        var boundingBoxes = [BoundingBox]()
        guard let instances = instances else {
            return boundingBoxes
        }
        for instance in instances {
            guard let height = instance.boundingBox?.height,
                let left = instance.boundingBox?.left,
                let top = instance.boundingBox?.top,
                let width = instance.boundingBox?.width else {
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
}
