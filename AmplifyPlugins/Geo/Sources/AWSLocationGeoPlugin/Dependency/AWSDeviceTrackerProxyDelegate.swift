//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import CoreLocation

class AWSDeviceTrackerProxyDelegate: ProxyDelegate {
    
    let deviceTrackingBehavior: DeviceTrackingBehavior
    
    internal init(deviceTrackingBehavior: DeviceTrackingBehavior) {
        self.deviceTrackingBehavior = deviceTrackingBehavior
    }
    
    var didUpdateLocations: (CLLocationManager, [CLLocation]) -> Void = {
        manager, locations in
        
        // Batching / Persistence
        // Call deviceTrackingBehavior.updateLocation()
    }
    
    
}
