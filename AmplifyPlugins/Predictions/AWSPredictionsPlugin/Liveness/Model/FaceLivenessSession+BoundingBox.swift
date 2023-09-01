//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension FaceLivenessSession {
    @_spi(PredictionsFaceLiveness)
    public struct BoundingBox: Codable {
        public let x: Double
        public let y: Double
        public let width: Double
        public let height: Double

        public init(
            x: Double,
            y: Double,
            width: Double,
            height: Double
        ) {
            self.x = x
            self.y = y
            self.width = width
            self.height = height
        }
    }
}
