//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import CoreGraphics

public struct Celebrity {
    public let metadata: CelebrityMetadata
    public let boundingBox: CGRect
    public let landmarks: [Landmark]

    public init(metadata: CelebrityMetadata, boundingBox: CGRect, landmarks: [Landmark]) {
        self.metadata = metadata
        self.boundingBox = boundingBox
        self.landmarks = landmarks
    }
}

public struct CelebrityMetadata {
    public let name: String
    public let identifier: String
    public let urls: [URL]
    public let pose: Pose

    public init(name: String, identifier: String, urls: [URL], pose: Pose) {
        self.name = name
        self.identifier = identifier
        self.urls = urls
        self.pose = pose
    }
}
