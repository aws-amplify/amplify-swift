//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct Pose {
    public var pitch: Double
    public var roll: Double
    public var yaw: Double

    public init(pitch: Double, roll: Double, yaw: Double) {
        self.pitch = pitch
        self.roll = roll
        self.yaw = yaw
    }
}
