//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct IdentifyLabelsResult: IdentifyResult {
    public var labels: [Label]

    public init(labels: [Label]) {
        self.labels = labels
    }
}

public struct Label {
    public var boundingBoxes: [BoundingBox]
    public var metadata: LabelMetadata
    public var name: String

    public init(name: String, metadata: LabelMetadata, boundingBoxes: [BoundingBox]) {
        self.name = name
        self.metadata = metadata
        self.boundingBoxes = boundingBoxes
    }
}

public struct Parent {
    public var name: String

    public init(name: String) {
        self.name = name
    }
}

public struct LabelMetadata {
   public var confidence: Double
   public var parents: [Parent]

    public init(confidence: Double, parents: [Parent]) {
        self.confidence = confidence
        self.parents = parents
    }
}

public struct BoundingBox {
    public var height: Double
    public var left: Double
    public var top: Double
    public var width: Double

    public init(height: Double, left: Double, top: Double, width: Double) {
        self.height = height
        self.left = left
        self.top = top
        self.width = width
    }

}
