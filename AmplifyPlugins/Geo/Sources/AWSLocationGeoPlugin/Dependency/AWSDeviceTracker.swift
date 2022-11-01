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
    
    var wakeAppForSignificantLocationUpdates = true
    var trackUntil: Date = .distantFuture
    var batchingOptions: Geo.LocationManager.BatchingOptions = .none
    var proxyDelegate: LocationProxyDelegate?
    
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
        
        // check if trackUntil time has elapsed
        if(options.trackUntil < Date()) {
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
        
        // no batching, send to location service
        if case .none = options.batchingOptions {
            Task {
                do {
                    try await sendStoredLocationsToService()
                    try await sendReceivedLocationsToService(locations: locations,
                                                             options: Geo.UpdateLocationOptions(tracker: options.tracker!))
                } catch {
                    // TODO: send error on Hub
                }
            }
            return
        }
        
        if batchingCriteriaMet(position: locations.last, time: Date()) {
            if let didUpdateLocations = options.proxyDelegate.didUpdateLocations {
                do {
                    let locationsReceived: [Geo.Location] = locations.map( {Geo.Location(clLocation: $0.coordinate)})
                    var locationsToSend = try getLocationsFromLocalStore().map( {Geo.Location(latitude: $0.latitude, longitude: $0.longitude)} )
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
            
        } else {
            // batch save the locations to local store
            guard let deviceId = UserDefaults.standard.object(forKey: AWSDeviceTracker.deviceIDKey) as? String else {
                Amplify.log.error("Not able to fetch deviceId from UserDefaults")
                return
            }
            
            let positions = locations.map({ Position(timeStamp: Temporal.Date.now().iso8601String,
                                                     latitude: $0.coordinate.latitude,
                                                     longitude: $0.coordinate.longitude,
                                                     tracker: options.tracker!,
                                                     deviceID: deviceId)})
            do {
                try self.locationStore.insert(positions: positions)
            } catch {
                // TODO: send error on Hub
            }
        }
        
        // save lastLocation and last time a location update is received
        UserDefaults.standard.set(Date(), forKey: AWSDeviceTracker.lastLocationUpdateTimeKey)
        UserDefaults.standard.set(locations.last, forKey: AWSDeviceTracker.lastUpdatedLocationKey)
    }
    
    private func batchingCriteriaMet(position: CLLocation?, time: Date?) -> Bool {
        let lastLocationUpdateTime = UserDefaults.standard.object(forKey: AWSDeviceTracker.lastLocationUpdateTimeKey) as? Date
        let lastUpdatedLocation = UserDefaults.standard.object(forKey: AWSDeviceTracker.lastUpdatedLocationKey) as? CLLocation
        switch options.batchingOptions {
        case .distanceTravelledInMeters(let distance):
            guard let lastPosition = lastUpdatedLocation, let position = position else {
                // there is no last location saved, returning true
                return true
            }
            return Int(position.distance(from: lastPosition)) >= distance
        case .secondsElapsed(let seconds):
            guard let lastLocationUpdateTime = lastLocationUpdateTime, let time = time else {
                // there is no last update time saved, returning true
                return true
            }
            return Int(time.timeIntervalSince(lastLocationUpdateTime)) >= seconds
        case .none:
            return false
        }
    }
    
    private func getLocationsFromLocalStore() throws -> [Position] {
        let storedLocations = try locationStore.getAll()
        try locationStore.removeAll()
        return storedLocations
    }
    
    private func sendReceivedLocationsToService(locations: [CLLocation], options: Geo.UpdateLocationOptions) async throws {
        // TODO: decide on sending concurrently or serially
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
    
    private func sendStoredLocationsToService() async throws {
        // TODO: decide on sending concurrently or serially
        let positions = try getLocationsFromLocalStore()
        for position in positions {
            try await Amplify.Geo.updateLocation(
                Geo.Location(latitude: position.latitude, longitude: position.longitude),
                for: Geo.Device(id: position.id),
                with: Geo.UpdateLocationOptions(tracker: position.tracker))
        }
    }
    
    private func checkPermissionsAndStartTracking() throws {
        let authorizationStatus: CLAuthorizationStatus

        if #available(iOS 14, *) {
            authorizationStatus = locationManager.authorizationStatus
        } else {
            authorizationStatus = CLLocationManager.authorizationStatus()
        }
        
        switch authorizationStatus {
        case .authorized, .authorizedAlways, .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
            if self.wakeAppForSignificantLocationUpdates {
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
