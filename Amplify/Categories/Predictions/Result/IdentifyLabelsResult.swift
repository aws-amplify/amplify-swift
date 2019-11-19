//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct IdentifyLabelsResult: IdentifyResult {
    public let labels: [Label]
    public let unsafeContent: Bool?

    public init(labels: [Label], unsafeContent: Bool? = nil) {
        self.labels = labels
        self.unsafeContent = unsafeContent
    }
}

public struct Label {
    public let name: String
    public let metadata: LabelMetadata?
    public let boundingBoxes: [BoundingBox]?

    public init(name: String,
                metadata: LabelMetadata? = nil,
                boundingBoxes: [BoundingBox]? = nil) {
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
   public let parents: [Parent]?

    public init(confidence: Double, parents: [Parent]? = nil) {
        self.confidence = confidence
        self.parents = parents
    }
}

public struct BoundingBox {
    public let left: Double
    public let top: Double
    public let width: Double
    public let height: Double

    public init(left: Double, top: Double, width: Double, height: Double) {
        self.height = height
        self.left = left
        self.top = top
        self.width = width
    }

}
