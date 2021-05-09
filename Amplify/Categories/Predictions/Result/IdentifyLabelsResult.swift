//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import CoreGraphics

/// <#Description#>
public struct IdentifyLabelsResult: IdentifyResult {

    /// <#Description#>
    public let labels: [Label]

    /// <#Description#>
    public let unsafeContent: Bool?

    /// <#Description#>
    /// - Parameters:
    ///   - labels: <#labels description#>
    ///   - unsafeContent: <#unsafeContent description#>
    public init(labels: [Label], unsafeContent: Bool? = nil) {
        self.labels = labels
        self.unsafeContent = unsafeContent
    }
}

/// <#Description#>
public struct Label {

    /// <#Description#>
    public let name: String

    /// <#Description#>
    public let metadata: LabelMetadata?

    /// <#Description#>
    public let boundingBoxes: [CGRect]?

    /// <#Description#>
    /// - Parameters:
    ///   - name: <#name description#>
    ///   - metadata: <#metadata description#>
    ///   - boundingBoxes: <#boundingBoxes description#>
    public init(name: String,
                metadata: LabelMetadata? = nil,
                boundingBoxes: [CGRect]? = nil) {
        self.name = name
        self.metadata = metadata
        self.boundingBoxes = boundingBoxes
    }
}

/// <#Description#>
public struct Parent {

    /// <#Description#>
    public let name: String

    /// <#Description#>
    /// - Parameter name: <#name description#>
    public init(name: String) {
        self.name = name
    }
}

/// <#Description#>
public struct LabelMetadata {

    /// <#Description#>
    public let confidence: Double

    /// <#Description#>
    public let parents: [Parent]?

    /// <#Description#>
    /// - Parameters:
    ///   - confidence: <#confidence description#>
    ///   - parents: <#parents description#>
    public init(confidence: Double, parents: [Parent]? = nil) {
        self.confidence = confidence
        self.parents = parents
    }
}
