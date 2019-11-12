//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct Celebrity {
    public var metadata: CelebMetadata
    public var boundingBox: BoundingBox
    public var landmarks: [Landmark]

    public init(metadata: CelebMetadata, boundingBox: BoundingBox, landmarks: [Landmark]) {
        self.metadata = metadata
        self.boundingBox = boundingBox
        self.landmarks = landmarks
    }
}



public struct CelebMetadata {
    public var name: String
    public var identifier: String
    public var urls: [URL]
    public var pose: Pose

    public init(name: String, identifier: String, urls: [URL], pose: Pose) {
        self.name = name
        self.identifier = identifier
        self.urls = urls
        self.pose = pose
    }
}
