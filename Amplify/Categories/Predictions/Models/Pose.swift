//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// <#Description#>
public struct Pose {

    /// <#Description#>
    public let pitch: Double

    /// <#Description#>
    public let roll: Double

    /// <#Description#>
    public let yaw: Double

    /// <#Description#>
    /// - Parameters:
    ///   - pitch: <#pitch description#>
    ///   - roll: <#roll description#>
    ///   - yaw: <#yaw description#>
    public init(pitch: Double, roll: Double, yaw: Double) {
        self.pitch = pitch
        self.roll = roll
        self.yaw = yaw
    }
}
