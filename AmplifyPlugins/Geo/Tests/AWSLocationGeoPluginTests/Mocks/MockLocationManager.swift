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
    
    var locations : [CLLocation] = [CLLocation(latitude: 20, longitude: 30)]
    var mockAuthorizationStatus: CLAuthorizationStatus = .authorizedAlways
    
    override var authorizationStatus: CLAuthorizationStatus {
        return mockAuthorizationStatus
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
