//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

@_spi(PredictionsFaceLiveness)
public struct FaceDetection {
    let boundingBox: FaceLivenessSession.BoundingBox
    let startTimestamp: UInt64

    public init(boundingBox: FaceLivenessSession.BoundingBox, startTimestamp: UInt64) {
        self.boundingBox = boundingBox
        self.startTimestamp = startTimestamp
    }
}
