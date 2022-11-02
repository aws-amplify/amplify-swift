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
    
    static let lastLocationUpdateTimeKey = "com.amazonaws.Amplify.AWSLocationGeoPlugin.lastLocationUpdateTime"
    static let lastUpdatedLocationKey = "com.amazonaws.Amplify.AWSLocationGeoPlugin.lastUpdatedLocation"
    static let deviceIDKey = "com.amazonaws.Amplify.AWSLocationGeoPlugin.deviceID"
    
    let locationManager: CLLocationManager
    let locationStore: LocationPersistenceBehavior
    var options: Geo.LocationManager.TrackingSessionOptions
    var networkMonitor: GeoNetworkMonitor
    
    init(options: Geo.LocationManager.TrackingSessionOptions, locationManager: CLLocationManager) throws {
        self.options = options
        self.locationManager = locationManager
        self.locationStore = try SQLiteLocationPersistenceAdapter(fileSystemBehavior: LocationFileSystem())
        self.networkMonitor = GeoNetworkMonitor()
    }
    
    func configure(with options: Geo.LocationManager.TrackingSessionOptions) {
        self.options = options
        locationManager.delegate = self
        configureLocationManager(with: options)
    }
    
    // setting `CLLocationManager` properties requires a UITest or running test in App mode
    // with appropriate location permissions. Moved out to separate method to facilitate
    // unit testing
    func configureLocationManager(with options: Geo.LocationManager.TrackingSessionOptions) {
        locationManager.desiredAccuracy = options.desiredAccuracy.clLocationAccuracy
        locationManager.allowsBackgroundLocationUpdates = options.allowsBackgroundLocationUpdates
        locationManager.pausesLocationUpdatesAutomatically = options.pausesLocationUpdatesAutomatically
        locationManager.activityType = options.activityType
        locationManager.showsBackgroundLocationIndicator = options.showsBackgroundLocationIndicator
        locationManager.distanceFilter = options.distanceFilter
    }
    
    func startTracking(for device: Geo.Device) throws {
        networkMonitor.start()
        UserDefaults.standard.removeObject(forKey: AWSDeviceTracker.deviceIDKey)
        UserDefaults.standard.set(device.id, forKey: AWSDeviceTracker.deviceIDKey)
        locationManager.delegate = self
        try checkPermissionsAndStartTracking()
    }
    
    func stopTracking() {
        // flush out stored events
        Task {
            do {
                try await sendStoredLocationsToService()
                UserDefaults.standard.removeObject(forKey: AWSDeviceTracker.deviceIDKey)
            } catch {
                // TODO: send error on Hub
            }
        }
        
        networkMonitor.cancel()
        locationManager.stopUpdatingLocation()
        locationManager.stopMonitoringSignificantLocationChanges()
        locationManager.delegate = nil
        UserDefaults.standard.removeObject(forKey: AWSDeviceTracker.lastLocationUpdateTimeKey)
        UserDefaults.standard.removeObject(forKey: AWSDeviceTracker.lastUpdatedLocationKey)
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let clError = error as? CLError {
                switch clError {
                case CLError.denied:
                    // user denied location services, stop tracking
                    stopTracking()
                default:
                    Amplify.log.error(error: error)
                }
            } else {
                Amplify.log.error(error: error)
            }
    }
    
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        do {
            try checkPermissionsAndStartTracking()
        } catch {
            Amplify.log.error(error: error)
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // if network is unreachable and `disregardLocationUpdatesWhenOffline` is set, don't store locations
        // in local database
        if options.disregardLocationUpdatesWhenOffline && !networkMonitor.networkConnected() {
            return
        }
        
        let currentTime = Date()
        // check if trackUntil time has elapsed
        if(options.trackUntil < currentTime) {
            // flush out all stored locations in local database
            Task {
                do {
                    try await sendStoredLocationsToService()
                    try await sendReceivedLocationsToService(locations: locations, options: Geo.UpdateLocationOptions(tracker: options.tracker!))
                } catch {
                    // TODO: send error on Hub
                }
            }
            stopTracking()
            return
        }
        
        // fetch last saved location and update time
        var lastUpdatedLocation : CLLocation?
        if let loadedLocation = UserDefaults.standard.data(forKey: AWSDeviceTracker.lastUpdatedLocationKey),
           let decodedLocation = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(loadedLocation) as? CLLocation {
            lastUpdatedLocation = decodedLocation
        }
        let lastLocationUpdateTime = UserDefaults.standard.object(forKey: AWSDeviceTracker.lastLocationUpdateTimeKey) as? Date
        
        let thresholdReached = options.batchingOption._thresholdReached(
            Geo.LocationManager.BatchingOption.LocationUpdate(timeStamp: lastLocationUpdateTime,
                                                              position: lastUpdatedLocation),
            Geo.LocationManager.BatchingOption.LocationUpdate(timeStamp: currentTime,
                                                              position: locations.last)
        )

        if thresholdReached {
            if let didUpdateLocations = options.locationProxyDelegate.didUpdateLocations {
                do {
                    guard let deviceId = UserDefaults.standard.object(forKey: AWSDeviceTracker.deviceIDKey) as? String else {
                        Amplify.log.error("Not able to fetch deviceId from UserDefaults")
                        return
                    }
                    let locationsReceived = locations.map( {
                        Position(timeStamp: currentTime,
                                 latitude: $0.coordinate.latitude,
                                 longitude: $0.coordinate.longitude,
                                 tracker: options.tracker!,
                                 deviceID: deviceId)
                    })
                    var locationsToSend = try getLocationsFromLocalStore().map( {
                        Position(timeStamp: $0.timeStamp,
                                 latitude: $0.latitude,
                                 longitude: $0.longitude,
                                 tracker: $0.tracker,
                                 deviceID: $0.deviceID)
                    } )
                    locationsToSend.append(contentsOf: locationsReceived)

                    didUpdateLocations(locationsToSend)
                } catch {
                    // TODO: send error on Hub
                }
            } else {
                // send to AWS Location
                Task {
                    do {
                        try await sendStoredLocationsToService()
                        try await sendReceivedLocationsToService(locations: locations,
                                                                 options: Geo.UpdateLocationOptions(tracker: options.tracker!))
                    } catch {
                        // TODO: send error on Hub
                    }
                }
            }
        }  else {
            // batch save the locations to local store
            guard let deviceId = UserDefaults.standard.object(forKey: AWSDeviceTracker.deviceIDKey) as? String else {
                Amplify.log.error("Not able to fetch deviceId from UserDefaults")
                return
            }

            let positions = locations.map({ PositionInternal(timeStamp: currentTime,
                                                             latitude: $0.coordinate.latitude,
                                                             longitude: $0.coordinate.longitude,
                                                             tracker: options.tracker!,
                                                             deviceID: deviceId) })
            do {
                try self.locationStore.insert(positions: positions)
            } catch {
                // TODO: send error on Hub
            }
        }
        
        // save lastLocation and last time a location update is received
        UserDefaults.standard.set(currentTime, forKey: AWSDeviceTracker.lastLocationUpdateTimeKey)
        if let lastReceivedLocation = locations.last,
            let encodedLocation = try? NSKeyedArchiver.archivedData(withRootObject: lastReceivedLocation, requiringSecureCoding: false) {
            UserDefaults.standard.set(encodedLocation, forKey: AWSDeviceTracker.lastUpdatedLocationKey)
        }
    }
    
    func getLocationsFromLocalStore() throws -> [PositionInternal] {
        let storedLocations = try locationStore.getAll()
        try locationStore.removeAll()
        return storedLocations
    }
    
    func sendReceivedLocationsToService(locations: [CLLocation], options: Geo.UpdateLocationOptions) async throws {
        guard let deviceId = UserDefaults.standard.object(forKey: AWSDeviceTracker.deviceIDKey) as? String else {
            Amplify.log.error("Not able to fetch deviceId from UserDefaults")
            return
        }
        
        for location in locations {
            try await Amplify.Geo.updateLocation(Geo.Location(clLocation: location.coordinate),
                                                 for: Geo.Device(id: deviceId),
                                                 with: Geo.UpdateLocationOptions(tracker: options.tracker!))
        }
    }
    
    func sendStoredLocationsToService() async throws {
        let positions = try getLocationsFromLocalStore()
        for position in positions {
            try await Amplify.Geo.updateLocation(
                Geo.Location(latitude: position.latitude, longitude: position.longitude),
                for: Geo.Device(id: position.id),
                with: Geo.UpdateLocationOptions(tracker: position.tracker))
        }
    }
    
    func checkPermissionsAndStartTracking() throws {
        let authorizationStatus: CLAuthorizationStatus

        if #available(iOS 14, *) {
            authorizationStatus = locationManager.authorizationStatus
        } else {
            authorizationStatus = CLLocationManager.authorizationStatus()
        }
        
        switch authorizationStatus {
        case .authorized, .authorizedAlways, .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
            if options.wakeAppForSignificantLocationChanges {
                locationManager.startMonitoringSignificantLocationChanges()
            }
        case .notDetermined:
            if options.requestAlwaysAuthorization {
                locationManager.requestAlwaysAuthorization()
            } else {
                locationManager.requestWhenInUseAuthorization()
            }
        case .restricted, .denied:
            throw Geo.Error.unknown(GeoPluginErrorConstants.missingPermissions.errorDescription,
                                    GeoPluginErrorConstants.missingPermissions.recoverySuggestion)
        @unknown default:
            throw Geo.Error.unknown(GeoPluginErrorConstants.missingPermissions.errorDescription,
                                    GeoPluginErrorConstants.missingPermissions.recoverySuggestion)
        }
    }
}
