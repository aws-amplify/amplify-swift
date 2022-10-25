//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Foundation
import CoreLocation

class AWSDeviceTracker: NSObject, CLLocationManagerDelegate, DeviceTrackingBehavior {
    let locationManager: CLLocationManager
    var wakeAppForSignificantLocationUpdates = true
    var trackUntil: Date = .distantFuture
    var batchingOptions: Geo.LocationManager.BatchingOptions = .none
    var proxyDelegate: LocationProxyDelegate?
    
    init(locationManager: CLLocationManager) {
        self.locationManager = locationManager
    }
    
    func configure(with options: Geo.LocationManager.TrackingSessionOptions) {
        self.wakeAppForSignificantLocationUpdates = options.wakeAppForSignificantLocationChanges
        self.trackUntil = options.trackUntil
        self.batchingOptions = options.batchingOptions
        self.proxyDelegate = options.proxyDelegate
        locationManager.delegate = self
        configureLocationManager(with: options)
    }
    
    // setting `CLLocationManager` properties requires a UITest or running test in App mode
    // with appropriate location permissions. Moved out to separate method to facilitate
    // unit testing
    func configureLocationManager(with options: Geo.LocationManager.TrackingSessionOptions) {
        locationManager.desiredAccuracy = options.desiredAccuracy.clLocationAccuracy
        if options.requestAlwaysAuthorization {
            locationManager.requestAlwaysAuthorization()
        }
        locationManager.allowsBackgroundLocationUpdates = options.allowsBackgroundLocationUpdates
        locationManager.pausesLocationUpdatesAutomatically = options.pausesLocationUpdatesAutomatically
        locationManager.activityType = options.activityType
        locationManager.showsBackgroundLocationIndicator = options.showsBackgroundLocationIndicator
        locationManager.distanceFilter = options.distanceFilter
    }
    
    func startTracking() {
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
        if self.wakeAppForSignificantLocationUpdates {
            locationManager.startMonitoringSignificantLocationChanges()
        }
    }
    
    func stopTracking() {
        locationManager.stopUpdatingLocation()
        locationManager.stopMonitoringSignificantLocationChanges()
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // TODO: Save position locally
        proxyDelegate?.didUpdateLocations(manager, locations)
    }
}
