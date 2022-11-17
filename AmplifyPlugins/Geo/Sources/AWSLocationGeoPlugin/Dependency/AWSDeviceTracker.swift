//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import CoreLocation
import AWSLocation
@_spi(KeychainStore) import AWSPluginsCore

class AWSDeviceTracker: NSObject, CLLocationManagerDelegate, AWSDeviceTrackingBehavior {
    
    var options: Geo.TrackingSessionOptions
    let locationManager: CLLocationManager
    let locationService: AWSLocationBehavior
    let networkMonitor: GeoNetworkMonitorBehavior
    let locationStore: LocationPersistenceBehavior
    let keychainStore: KeychainStoreBehavior
    var unsubscribeToken: UnsubscribeToken?
    
    init(options: Geo.TrackingSessionOptions,
         locationManager: CLLocationManager,
         locationService: AWSLocationBehavior,
         networkMonitor: GeoNetworkMonitorBehavior,
         locationStore: LocationPersistenceBehavior,
         keychainStore: KeychainStoreBehavior = KeychainStore(service: AWSDeviceTracker.Constants.geoService)) throws {
        self.options = options
        self.locationManager = locationManager
        self.locationService = locationService
        self.networkMonitor = networkMonitor
        self.locationStore = locationStore
        self.keychainStore = keychainStore
    }
    
    
    // MARK: - AWSDeviceTrackingBehavior
    func configure(with options: Geo.TrackingSessionOptions) {
        self.options = options
        configureLocationManager(with: options)
    }
    
    // setting `CLLocationManager` properties requires a UITest or running test in App mode
    // with appropriate location permissions. Moved out to separate method to facilitate
    // unit testing
    func configureLocationManager(with options: Geo.TrackingSessionOptions) {
        locationManager.desiredAccuracy = options.desiredAccuracy.clLocationAccuracy
        locationManager.allowsBackgroundLocationUpdates = options.allowsBackgroundLocationUpdates
        locationManager.pausesLocationUpdatesAutomatically = options.pausesLocationUpdatesAutomatically
        locationManager.activityType = options.activityType
        #if !os(macOS)
        locationManager.showsBackgroundLocationIndicator = options.showsBackgroundLocationIndicator
        #endif
        locationManager.distanceFilter = options.distanceFilter
    }
    
    func startTracking(for deviceID: String) throws {
        // check if there is an existing tracking session
        if let savedDeviceID = try? keychainStore._getString(AWSDeviceTracker.Constants.deviceIDKey) {
            // if there is an existing session with a different device id, throw an error
            if savedDeviceID != deviceID {
                throw Geo.Error.internalPluginError(
                    GeoPluginErrorConstants.errorStartTrackingCalledBeforeStopTracking.errorDescription,
                    GeoPluginErrorConstants.errorStartTrackingCalledBeforeStopTracking.recoverySuggestion
                )
            }
        } else {
            // start a new session
            do {
                try keychainStore._set(deviceID, key: AWSDeviceTracker.Constants.deviceIDKey)
            } catch {
                throw Geo.Error.internalPluginError(GeoPluginErrorConstants.errorSavingDeviceIDToKeychain.errorDescription,
                                                    GeoPluginErrorConstants.errorSavingDeviceIDToKeychain.recoverySuggestion,
                                                    error)
            }
            
            networkMonitor.start()
            unsubscribeToken = Amplify.Hub.listen(to: .auth, eventName: HubPayload.EventName.Auth.signedOut) { payload in
                self.stopTracking()
            }
            locationManager.delegate = self
            try checkPermissionsAndStartTracking()
        }
    }
    
    func stopTracking() {
        stopTracking(with: [])
    }
    
    private func stopTracking(with receivedPositions: [Position]) {
        
        if let deviceID = try? keychainStore._getString(AWSDeviceTracker.Constants.deviceIDKey) {
            // flush out stored events
            if let didUpdatePositions = options.locationProxyDelegate.didUpdatePositions {
                batchSendStoredLocationsToProxyDelegate(with: receivedPositions,
                                                        deviceID: deviceID,
                                                        didUpdatePositions: didUpdatePositions)
            } else {
                // if network is unreachable, send errors on Hub
                batchSendStoredLocationsToService(with: receivedPositions, deviceID: deviceID)
            }
        } else {
            Amplify.log.error("stopTracking: Not able to fetch deviceId from Keychain")
        }
        
        networkMonitor.cancel()
        locationManager.stopUpdatingLocation()
        locationManager.stopMonitoringSignificantLocationChanges()
        locationManager.delegate = nil
        do {
            try keychainStore._remove(AWSDeviceTracker.Constants.deviceIDKey)
        } catch {
            Amplify.log.error("stopTracking: Error clearing deviceID from keychain: \(error)")
        }
        UserDefaults.standard.removeObject(forKey: AWSDeviceTracker.Constants.lastLocationUpdateTimeKey)
        UserDefaults.standard.removeObject(forKey: AWSDeviceTracker.Constants.lastUpdatedLocationKey)
        if let unsubscribeToken = unsubscribeToken {
            Amplify.Hub.removeListener(unsubscribeToken)
        }
    }
    
    // MARK: - CLLocationManagerDelegate
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
        
        guard let deviceID = try? keychainStore._getString(AWSDeviceTracker.Constants.deviceIDKey) else {
            Amplify.log.error("Not able to fetch deviceId from Keychain")
            let error = Geo.Error.internalPluginError(
                GeoPluginErrorConstants.errorFetchingDeviceIDFromKeychain.errorDescription,
                GeoPluginErrorConstants.errorFetchingDeviceIDFromKeychain.recoverySuggestion)
            sendHubErrorEvent(error: error, locations: locations)
            return
        }
        
        let currentTime = Date()
        // check if trackUntil time has elapsed
        if(options.trackUntil < currentTime) {
            let receivedPositions = mapReceivedLocationsToPositions(receivedLocations: locations,
                                                                    currentTime: currentTime,
                                                                    deviceID: deviceID)
            stopTracking(with: receivedPositions)
            return
        }
        
        // fetch last saved location and update time
        var lastUpdatedLocation : CLLocation?
        if let loadedLocation = UserDefaults.standard.data(forKey: AWSDeviceTracker.Constants.lastUpdatedLocationKey),
           let decodedLocation = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(loadedLocation) as? CLLocation {
            lastUpdatedLocation = decodedLocation
        }
        let lastLocationUpdateTime = UserDefaults.standard.object(forKey: AWSDeviceTracker.Constants.lastLocationUpdateTimeKey) as? Date
        
        let thresholdReached = DeviceTrackingHelper.batchingThresholdReached(
            old: LocationUpdate(timeStamp: lastLocationUpdateTime, location: lastUpdatedLocation),
            new: LocationUpdate(timeStamp: currentTime, location: locations.last),
            batchingOption: options.batchingOption)
        
        
        if thresholdReached {
            let receivedPositions = mapReceivedLocationsToPositions(receivedLocations: locations,
                                                                    currentTime: currentTime,
                                                                    deviceID: deviceID)
            if let didUpdatePositions = options.locationProxyDelegate.didUpdatePositions {
                batchSendStoredLocationsToProxyDelegate(with: receivedPositions,
                                                        deviceID: deviceID,
                                                        didUpdatePositions: didUpdatePositions)
                UserDefaults.standard.set(currentTime, forKey: AWSDeviceTracker.Constants.lastLocationUpdateTimeKey)
            } else {
                if networkMonitor.networkConnected() {
                    batchSendStoredLocationsToService(with: receivedPositions, deviceID: deviceID)
                    UserDefaults.standard.set(currentTime, forKey: AWSDeviceTracker.Constants.lastLocationUpdateTimeKey)
                } else {
                    // if network is unreachable and `disregardLocationUpdatesWhenOffline` is set,
                    // don't store locations in local database
                    if !options.disregardLocationUpdatesWhenOffline {
                        batchSaveLocationsToLocalStore(receivedLocations: locations, currentTime: currentTime)
                    }
                }
            }
        } else {
            batchSaveLocationsToLocalStore(receivedLocations: locations, currentTime: currentTime)
        }
        
        // first time a location update is received, set it as the first locationUpdateTime for
        // future comparisons to API/delegate update time
        if lastLocationUpdateTime == nil {
            UserDefaults.standard.set(currentTime, forKey: AWSDeviceTracker.Constants.lastLocationUpdateTimeKey)
        }
        
        // first time a location update is received, save the first element from `locations` received
        if lastUpdatedLocation == nil {
            if let lastReceivedLocation = locations.first,
                let encodedLocation = try? NSKeyedArchiver.archivedData(withRootObject: lastReceivedLocation,
                                                                        requiringSecureCoding: false) {
                UserDefaults.standard.set(encodedLocation, forKey: AWSDeviceTracker.Constants.lastUpdatedLocationKey)
            } else {
                Amplify.log.error("Error storing first received location in UserDefaults")
            }
        } else {
            // save the last element from `locations` received
            if let lastReceivedLocation = locations.last,
                let encodedLocation = try? NSKeyedArchiver.archivedData(withRootObject: lastReceivedLocation,
                                                                        requiringSecureCoding: false) {
                UserDefaults.standard.set(encodedLocation, forKey: AWSDeviceTracker.Constants.lastUpdatedLocationKey)
            } else {
                Amplify.log.error("Error storing last received location in UserDefaults")
            }
        }
    }
    
    // MARK: - Internal helper functions
    
    func getLocationsFromLocalStore() async throws -> [PositionInternal] {
        let storedLocations = try await locationStore.getAll()
        try await locationStore.removeAll()
        return storedLocations
    }
    
    func batchSaveLocationsToLocalStore(receivedLocations: [CLLocation], currentTime: Date) {
        Task {
            do {
                let positionsToStore = receivedLocations.map({ PositionInternal(timeStamp: currentTime,
                                                                                latitude: $0.coordinate.latitude,
                                                                                longitude: $0.coordinate.longitude,
                                                                                tracker: options.tracker!) })
                try await self.locationStore.insert(positions: positionsToStore)
            } catch {
              let geoError = Geo.Error.internalPluginError(
                  GeoPluginErrorConstants.errorSavingLocationsToLocalStore.errorDescription,
                  GeoPluginErrorConstants.errorSavingLocationsToLocalStore.recoverySuggestion, error)
              sendHubErrorEvent(error: geoError, locations: receivedLocations)
            }
        }
    }

    func mapReceivedLocationsToPositions(receivedLocations: [CLLocation],
                                         currentTime: Date,
                                         deviceID: String) -> [Position] {
        return receivedLocations.map( {
            Position(timeStamp: currentTime,
                     location: Geo.Location(clLocation: $0.coordinate),
                     tracker: options.tracker!,
                     deviceID: deviceID)
        })
    }
    
    func mapStoredLocationsToPositions(deviceID: String) async -> [Position] {
        do {
            let storedLocations = try await getLocationsFromLocalStore()
            return storedLocations.map( {
                Position(timeStamp: $0.timeStamp,
                         location: Geo.Location(latitude: $0.latitude,
                                                longitude: $0.longitude),
                         tracker: $0.tracker,
                         deviceID: deviceID)
            } )
        } catch {
            Amplify.log.error("Unable to convert stored locations to positions.")
            let geoError = Geo.Error.internalPluginError(
                GeoPluginErrorConstants.errorFetchingLocationsFromLocalStore.errorDescription,
                GeoPluginErrorConstants.errorFetchingLocationsFromLocalStore.recoverySuggestion,
                error)
            sendHubErrorEvent(error: geoError, locations: [Position]())
        }
        return []
    }
    
    func batchSendStoredLocationsToProxyDelegate(with receivedPositions: [Position],
                                                 deviceID: String,
                                                 didUpdatePositions: @escaping (([Position]) -> Void)) {
        Task {
            var allPositions = await mapStoredLocationsToPositions(deviceID: deviceID)
            allPositions.append(contentsOf: receivedPositions)
            if allPositions.count > 0  {
                didUpdatePositions(allPositions)
            }
        }
    }
    
    func batchSendStoredLocationsToService(with receivedPositions: [Position], deviceID: String) {
        Task {
            var allPositions = await self.mapStoredLocationsToPositions(deviceID: deviceID)
            allPositions.append(contentsOf: receivedPositions)
            if allPositions.count == 0 {
                return
            }
            // send all locations to service
            let positionChunks = allPositions.chunked(into: AWSDeviceTracker.Constants.batchSizeForLocationInput)
            for chunk in positionChunks {
                // start a new task for each chunk
                Task {
                    do {
                        let locationUpdates = chunk.map ( {
                            LocationClientTypes.DevicePositionUpdate(
                                accuracy: nil,
                                deviceId: $0.deviceID,
                                position: [$0.location.longitude, $0.location.latitude],
                                positionProperties: nil,
                                sampleTime: Date())
                        } )
                        let input = BatchUpdateDevicePositionInput(trackerName: self.options.tracker!,
                                                                   updates: locationUpdates)
                        let response = try await locationService.updateLocation(forUpdateDevicePosition: input)
                        if let error = response.errors?.first as? Error {
                            Amplify.log.error("Unable to send locations to service.")
                            let geoError = Geo.Error.serviceError(
                                 GeoPluginErrorConstants.errorSaveLocationsFailed.errorDescription,
                                 GeoPluginErrorConstants.errorSaveLocationsFailed.recoverySuggestion,
                                 error)
                            sendHubErrorEvent(error: geoError, locations: chunk)
                            throw GeoErrorHelper.mapAWSLocationError(error)
                        }
                    } catch {
                      Amplify.log.error("Unable to send locations to service.")
                      let geoError = Geo.Error.serviceError(
                          GeoPluginErrorConstants.errorSaveLocationsFailed.errorDescription,
                          GeoPluginErrorConstants.errorSaveLocationsFailed.recoverySuggestion,
                          error)
                      sendHubErrorEvent(error: geoError, locations: chunk)
                    }
                }
            }
        }
    }
    
    func checkPermissionsAndStartTracking() throws {
        let authorizationStatus: CLAuthorizationStatus

        if #available(iOS 14, macOS 11.0, *) {
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
            stopTracking()
            throw Geo.Error.internalPluginError(
                GeoPluginErrorConstants.missingPermissions.errorDescription,
                GeoPluginErrorConstants.missingPermissions.recoverySuggestion
            )
        @unknown default:
            throw Geo.Error.internalPluginError(
                GeoPluginErrorConstants.missingPermissions.errorDescription,
                GeoPluginErrorConstants.missingPermissions.recoverySuggestion
            )
        }
    }
    
    
    // MARK: - Hub
    func sendHubErrorEvent(error: Geo.Error? = nil, locations: [CLLocation]) {
        let geoLocations = locations.map({
            Geo.Location(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude) })
        let data = AWSGeoHubPayloadData(error: error, locations: geoLocations)
        let payload = HubPayload(eventName: HubPayload.EventName.Geo.saveLocationsFailed, data: data)
        Amplify.Hub.dispatch(to: .geo, payload: payload)
    }
    
    func sendHubErrorEvent(error: Geo.Error? = nil, locations: [Position]) {
        let geoLocations = locations.map({
            Geo.Location(latitude: $0.location.latitude, longitude: $0.location.longitude) })
        let data = AWSGeoHubPayloadData(error: error, locations: geoLocations)
        let payload = HubPayload(eventName: HubPayload.EventName.Geo.saveLocationsFailed, data: data)
        Amplify.Hub.dispatch(to: .geo, payload: payload)
    }
}

// MARK: - Extensions

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

extension Geo.BatchingOption {
    enum BatchingOptionType {
        case none
        case distanceTravelledInMetres(value:Int)
        case secondsElapsed(value:Int)
    }
    
    var batchingOptionType: BatchingOptionType {
        if let dist = _metersTravelled {
            return BatchingOptionType.distanceTravelledInMetres(value: dist)
        } else if let sec = _secondsElapsed {
            return BatchingOptionType.secondsElapsed(value:sec)
        } else {
            return BatchingOptionType.none
        }
    }
}

struct LocationUpdate {
    let timeStamp: Date?
    let location: CLLocation?
    
    init(timeStamp: Date?, location: CLLocation?) {
        self.timeStamp = timeStamp
        self.location = location
    }
}

extension AWSDeviceTracker {
    
    struct Constants {
        static let lastLocationUpdateTimeKey = "com.amazonaws.Amplify.AWSLocationGeoPlugin.lastLocationUpdateTime"
        static let lastUpdatedLocationKey = "com.amazonaws.Amplify.AWSLocationGeoPlugin.lastUpdatedLocation"
        static let deviceIDKey = "com.amazonaws.Amplify.AWSLocationGeoPlugin.deviceID"
        static let geoService = "com.amazonaws.Amplify.AWSLocationGeoPlugin"
        static let batchSizeForLocationInput = 10
    }
    
}
