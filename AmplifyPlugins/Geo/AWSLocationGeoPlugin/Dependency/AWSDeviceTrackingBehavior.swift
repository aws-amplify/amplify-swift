//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Foundation

/// Behavior that `AWSDeviceTracker` will use.
/// This protocol allows a way to create a Mock and ensure the plugin implementation is testable.
protocol AWSDeviceTrackingBehavior {

    func configure(with options: Geo.LocationManager.TrackingSessionOptions)
    
    func startTracking()
    
    func stopTracking()
}
