//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import CoreGraphics

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
    public let boundingBoxes: [CGRect]?

    public init(name: String,
                metadata: LabelMetadata? = nil,
                boundingBoxes: [CGRect]? = nil) {
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
