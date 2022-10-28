//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Behavior that a concrete implementation for device tracking will use.
/// This protocol allows a way to create a Mock and ensure the plugin implementation is testable.
public protocol DeviceTrackingBehavior {

    func configure(with options: Geo.LocationManager.TrackingSessionOptions)

    func startTracking(for device: Geo.Device)
    
    func stopTracking()
}
