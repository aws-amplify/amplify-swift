//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public extension Predictions.Entity {
    struct Metadata {
        public let confidence: Double
        public let pose: Predictions.Pose

        public init(confidence: Double, pose: Predictions.Pose) {
            self.confidence = confidence
            self.pose = pose
        }
    }
}
