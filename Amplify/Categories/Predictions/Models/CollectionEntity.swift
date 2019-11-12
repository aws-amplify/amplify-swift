//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct CollectionEntity {
    public var boundingBox: BoundingBox
    public var metadata: CollectionEntityMetadata

    public init(boundingBox: BoundingBox, metadata: CollectionEntityMetadata) {
        self.boundingBox = boundingBox
        self.metadata = metadata
    }
}

public struct CollectionEntityMetadata {
    public var externalImageId: String
    public var similarity: Double

    public init(externalImageId: String, similarity: Double) {
        self.externalImageId = externalImageId
        self.similarity = similarity
    }
}
