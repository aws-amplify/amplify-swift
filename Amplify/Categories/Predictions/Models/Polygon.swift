//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct Polygon {

    public let points: [Point]

    public init(points: [Point]) {
        self.points = points
    }

    public struct Point {
        public let xPosition: Double
        public let yPosition: Double

        public init(xPosition: Double, yPosition: Double) {
            self.xPosition = xPosition
            self.yPosition = yPosition
        }
    }
}
