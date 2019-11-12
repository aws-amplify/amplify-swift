//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
public struct Landmark {
    public var type: String
    public var xPosition: Double
    public var yPosition: Double

    public init(type: String, xPosition: Double, yPosition: Double) {
        self.type = type
        self.xPosition = xPosition
        self.yPosition = yPosition
    }
}
