//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import CoreGraphics

/// <#Description#>
public struct Celebrity {

    /// <#Description#>
    public let metadata: CelebrityMetadata

    /// <#Description#>
    public let boundingBox: CGRect

    /// <#Description#>
    public let landmarks: [Landmark]

    /// <#Description#>
    /// - Parameters:
    ///   - metadata: <#metadata description#>
    ///   - boundingBox: <#boundingBox description#>
    ///   - landmarks: <#landmarks description#>
    public init(metadata: CelebrityMetadata, boundingBox: CGRect, landmarks: [Landmark]) {
        self.metadata = metadata
        self.boundingBox = boundingBox
        self.landmarks = landmarks
    }
}

/// <#Description#>
public struct CelebrityMetadata {

    /// <#Description#>
    public let name: String

    /// <#Description#>
    public let identifier: String

    /// <#Description#>
    public let urls: [URL]

    /// <#Description#>
    public let pose: Pose

    /// <#Description#>
    /// - Parameters:
    ///   - name: <#name description#>
    ///   - identifier: <#identifier description#>
    ///   - urls: <#urls description#>
    ///   - pose: <#pose description#>
    public init(name: String, identifier: String, urls: [URL], pose: Pose) {
        self.name = name
        self.identifier = identifier
        self.urls = urls
        self.pose = pose
    }
}
