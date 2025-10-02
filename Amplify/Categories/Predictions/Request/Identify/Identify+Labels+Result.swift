//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import CoreGraphics

public extension Predictions.Identify.Labels {
    /// Results are mapped to IdentifyLabelsResult when .labels in passed to .detectLabels
    /// in the type: field in identify() API
    struct Result {
        public let labels: [Predictions.Label]
        public let unsafeContent: Bool?

        public init(labels: [Predictions.Label], unsafeContent: Bool? = nil) {
            self.labels = labels
            self.unsafeContent = unsafeContent
        }
    }
}

public extension Predictions {
    /// Describes a real world object (e.g., chair, desk) identified in an image
    struct Label {
        public let name: String
        public let metadata: Metadata?
        public let boundingBoxes: [CGRect]?

        public init(
            name: String,
            metadata: Metadata? = nil,
            boundingBoxes: [CGRect]? = nil
        ) {
            self.name = name
            self.metadata = metadata
            self.boundingBoxes = boundingBoxes
        }
    }

    struct Parent {
        public let name: String

        public init(name: String) {
            self.name = name
        }
    }
}

public extension Predictions.Label {
    struct Metadata {
        public let confidence: Double
        public let parents: [Predictions.Parent]?

        public init(confidence: Double, parents: [Predictions.Parent]? = nil) {
            self.confidence = confidence
            self.parents = parents
        }
    }
}
