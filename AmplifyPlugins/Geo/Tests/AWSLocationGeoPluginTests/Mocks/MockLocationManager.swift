//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import CoreLocation

// Mock `CLLocationManager` class for simulating location update events from OS
class MockLocationManager : CLLocationManager {
    
    let locations : [CLLocation] = [CLLocation(latitude: 20, longitude: 30)]
    
    override var authorizationStatus: CLAuthorizationStatus {
        .authorizedAlways
    }
    
    override func startUpdatingLocation() {
        delegate?.locationManager?(self, didUpdateLocations: locations)
    }
    
    override func startMonitoringSignificantLocationChanges() {
        
    }
    
    override func stopUpdatingLocation() {
        
    }
    
    override func stopMonitoringSignificantLocationChanges() {
        
    }
}
