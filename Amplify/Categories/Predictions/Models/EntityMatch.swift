//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import CoreGraphics

/// Describes the result for an entity matched in an entity collection
/// created on AWS Rekogniton and detected from identify() API call
public struct EntityMatch {
    public let boundingBox: CGRect
    public let metadata: EntityMatchMetadata

    public init(boundingBox: CGRect, metadata: EntityMatchMetadata) {
        self.boundingBox = boundingBox
        self.metadata = metadata
    }
}

public struct EntityMatchMetadata {
    public let externalImageId: String?
    public let similarity: Double

    public init(externalImageId: String?, similarity: Double) {
        self.externalImageId = externalImageId
        self.similarity = similarity
    }
}
