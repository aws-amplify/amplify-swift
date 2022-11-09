//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

/// Behavior that a concrete implementation for device tracking will use.
/// This protocol allows a way to create a Mock and ensure the plugin implementation is testable.
protocol AWSDeviceTrackingBehavior {

    func configure(with options: Geo.TrackingSessionOptions)

    func startTracking(for device: Geo.Device) throws
    
    func stopTracking()
}
