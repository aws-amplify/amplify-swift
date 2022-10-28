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
@_spi(KeychainStore) import AWSPluginsCore

class AWSDeviceTracker: NSObject, CLLocationManagerDelegate, DeviceTrackingBehavior {
    
    static let service = "com.amplify.AWSLocationGeoPlugin"
    static let deviceIdKey = "com.amplify.AWSLocationGeoPluginDeviceIdKey"
    
    let locationManager: CLLocationManager
    let locationStore: LocationPersistenceBehavior
    let keychain: KeychainStoreBehavior
    
    var wakeAppForSignificantLocationUpdates = true
    var trackUntil: Date = .distantFuture
    var batchingOptions: Geo.LocationManager.BatchingOptions = .none
    var proxyDelegate: LocationProxyDelegate?
    
    var options: Geo.LocationManager.TrackingSessionOptions
    var lastLocationUpdateTime: Date?
    var lastUpdatedLocation: CLLocation?
    var device: Geo.Device?
    
    init(options: Geo.LocationManager.TrackingSessionOptions, locationManager: CLLocationManager) throws {
        self.options = options
        self.locationManager = locationManager
        self.locationStore = try SQLiteLocationPersistenceAdapter(fileSystemBehavior: LocationFileSystem())
        self.keychain = KeychainStore(service: AWSDeviceTracker.service)
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
        if options.requestAlwaysAuthorization {
            locationManager.requestAlwaysAuthorization()
        }
        locationManager.allowsBackgroundLocationUpdates = options.allowsBackgroundLocationUpdates
        locationManager.pausesLocationUpdatesAutomatically = options.pausesLocationUpdatesAutomatically
        locationManager.activityType = options.activityType
        locationManager.showsBackgroundLocationIndicator = options.showsBackgroundLocationIndicator
        locationManager.distanceFilter = options.distanceFilter
    }
    
    func startTracking(for device: Geo.Device) {
        do {
            // add / update deviceId in keychain
            try keychain._set(device.id, key: AWSDeviceTracker.deviceIdKey)
        } catch {
            // TODO: send error on hub
        }
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
        if self.wakeAppForSignificantLocationUpdates {
            locationManager.startMonitoringSignificantLocationChanges()
        }
    }
    
    func stopTracking() {
        locationManager.stopUpdatingLocation()
        locationManager.stopMonitoringSignificantLocationChanges()
        locationManager.delegate = nil
        lastUpdatedLocation = nil
        lastLocationUpdateTime = nil
        do {
            try keychain._remove(AWSDeviceTracker.deviceIdKey)
        } catch {
            // TODO: send error on hub
        }
        Task {
            do {
                try await sendStoredLocationsToService()
            } catch {
                // TODO: send error on Hub
            }
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // if network is unreachable and `disregardLocationUpdatesWhenOffline` is set, don't store locations
        // in local database
        if options.disregardLocationUpdatesWhenOffline && !DeviceTrackingHelper.networkReachable() {
            return
        }
        
        if(DeviceTrackingHelper.trackUntilTimeElapsed(trackUntil: options.trackUntil, currentTime: Date())) {
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
            if let proxyDelegate = proxyDelegate {
                do {
                    let locationsReceived: [Geo.Location] = locations.map( {Geo.Location(clLocation: $0.coordinate)})
                    var locationsToSend = try getLocationsFromLocalStore().map( {Geo.Location(latitude: $0.latitude, longitude: $0.longitude)} )
                    locationsToSend.append(contentsOf: locationsReceived)
                    
                    // TODO: update the signature and call
                    proxyDelegate.didUpdateLocations(manager, locations)
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
            let positions = locations.map({ Position(timeStamp: Temporal.Date.now().iso8601String,
                                                      latitude: $0.coordinate.latitude,
                                                      longitude: $0.coordinate.longitude,
                                                      tracker: options.tracker!)})
            do {
                try self.locationStore.insert(positions: positions)
            } catch {
                // TODO: send error on Hub
            }
        }
        
        // save lastLocation and last time a location update is received
        lastUpdatedLocation = locations.last
        lastLocationUpdateTime = Date()
    }
    
    private func batchingCriteriaMet(position: CLLocation?, time: Date?) -> Bool {
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
        let deviceID = try keychain._getString(AWSDeviceTracker.deviceIdKey)
        for location in locations {
            try await Amplify.Geo.updateLocation(Geo.Location(clLocation: location.coordinate),
                                                 for: Geo.Device(id: deviceID),
                                                 with: Geo.UpdateLocationOptions(tracker: options.tracker!))
        }
    }
    
    private func sendStoredLocationsToService() async throws {
        // TODO: decide on sending concurrently or serially
        let deviceID = try keychain._getString(AWSDeviceTracker.deviceIdKey)
        let positions = try getLocationsFromLocalStore()
        for position in positions {
            try await Amplify.Geo.updateLocation(
                Geo.Location(latitude: position.latitude, longitude: position.longitude),
                for: Geo.Device(id: deviceID),
                with: Geo.UpdateLocationOptions(tracker: position.tracker))
        }
    }
}
