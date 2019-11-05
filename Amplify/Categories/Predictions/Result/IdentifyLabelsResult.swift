//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct IdentifyLabelsResult: IdentifyResult {
    var labels: [Label]

    public init(labels: [Label]) {
        self.labels = labels
    }
}

public struct Label {
    var boundingBoxes: [BoundingBox]
    var metadata: LabelMetadata
    var name: String

    public init(name: String, metadata: LabelMetadata, boundingBoxes: [BoundingBox]) {
        self.name = name
        self.metadata = metadata
        self.boundingBoxes = boundingBoxes
    }
}

public struct Parent {
    var name: String

    public init(name: String) {
        self.name = name
    }
}

public struct LabelMetadata {
    var confidence: Double
    var parents: [Parent]

    public init(confidence: Double, parents: [Parent]) {
        self.confidence = confidence
        self.parents = parents
    }
}

public struct BoundingBox {
    var height: Double
    var left: Double
    var top: Double
    var width: Double

    public init(height: Double, left: Double, top: Double, width: Double) {
        self.height = height
        self.left = left
        self.top = top
        self.width = width
    }

}
