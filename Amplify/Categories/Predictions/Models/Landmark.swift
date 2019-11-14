//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


public struct Landmark {
    public let type: String
    public let xPosition: Double
    public let yPosition: Double

    public init(type: String, xPosition: Double, yPosition: Double) {
        self.type = type
        self.xPosition = xPosition
        self.yPosition = yPosition
    }
}
