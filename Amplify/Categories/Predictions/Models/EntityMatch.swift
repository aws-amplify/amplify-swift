//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import CoreGraphics

/// Struct that holds the result for an entity matched from an entity collection
/// created on Rekogniton and detected from Predictions Identify methods.
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
