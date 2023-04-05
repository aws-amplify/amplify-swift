//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension FaceLivenessSession {
    @_spi(PredictionsFaceLiveness)
    public struct ColorChallenge {
        public let colors: [DisplayColor]

        public init(colors: [DisplayColor]) {
            self.colors = colors
        }
    }
}

extension FaceLivenessSession {
    @_spi(PredictionsFaceLiveness)
    public struct DisplayColor {
        public let rgb: RGB
        public let duration: Double
        public let shouldScroll: Bool

        public init(rgb: RGB, duration: Double, shouldScroll: Bool) {
            self.rgb = rgb
            self.duration = duration
            self.shouldScroll = shouldScroll
        }
    }

    @_spi(PredictionsFaceLiveness)
    public struct RGB {
        public let _values: [Int]
        public let red: Double
        public let green: Double
        public let blue: Double

        public init(red: Double, green: Double, blue: Double, _values: [Int]) {
            self.red = red
            self.green = green
            self.blue = blue
            self._values = _values
        }
    }
}
