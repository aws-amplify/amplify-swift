//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import CoreGraphics

/// Struct that holds the result for an entity matched from an entity collection
/// created on Rekogniton and detected from Predictions Identify methods.
public struct EntityMatch {

    /// <#Description#>
    public let boundingBox: CGRect

    /// <#Description#>
    public let metadata: EntityMatchMetadata

    /// <#Description#>
    /// - Parameters:
    ///   - boundingBox: <#boundingBox description#>
    ///   - metadata: <#metadata description#>
    public init(boundingBox: CGRect, metadata: EntityMatchMetadata) {
        self.boundingBox = boundingBox
        self.metadata = metadata
    }
}

/// <#Description#>
public struct EntityMatchMetadata {
    /// <#Description#>
    public let externalImageId: String?

    /// <#Description#>
    public let similarity: Double

    /// <#Description#>
    /// - Parameters:
    ///   - externalImageId: <#externalImageId description#>
    ///   - similarity: <#similarity description#>
    public init(externalImageId: String?, similarity: Double) {
        self.externalImageId = externalImageId
        self.similarity = similarity
    }
}
