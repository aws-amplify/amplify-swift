//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct IdentifyLabelsResult: IdentifyResult {
    public let labels: [Label]

    public init(labels: [Label]) {
        self.labels = labels
    }
}

public struct Label {
    public let boundingBoxes: [BoundingBox]
    public let metadata: LabelMetadata
    public let name: String

    public init(name: String, metadata: LabelMetadata, boundingBoxes: [BoundingBox]) {
        self.name = name
        self.metadata = metadata
        self.boundingBoxes = boundingBoxes
    }
}

public struct Parent {
    public let name: String

    public init(name: String) {
        self.name = name
    }
}

public struct LabelMetadata {
   public let confidence: Double
   public let parents: [Parent]

    public init(confidence: Double, parents: [Parent]) {
        self.confidence = confidence
        self.parents = parents
    }
}

public struct BoundingBox {
    public let height: Double
    public let left: Double
    public let top: Double
    public let width: Double

    public init(height: Double, left: Double, top: Double, width: Double) {
        self.height = height
        self.left = left
        self.top = top
        self.width = width
    }

}
