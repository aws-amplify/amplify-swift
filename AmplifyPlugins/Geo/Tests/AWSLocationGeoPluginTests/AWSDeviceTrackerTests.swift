//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
import CoreLocation
@testable import Amplify
@testable import AWSLocationGeoPlugin

class AWSDeviceTrackerTests : AWSLocationGeoPluginTestBase {
    
    // MARK: Proxy Delegate Tests
    
    /// Test if custom proxydelegate is called when `AWSDeviceTracker`
    /// is configured with `Geo.TrackingSession` with a proxy delegate
    /// and startTracking() is called with batching options set to `.none`
    ///
    /// - Given: `AWSDeviceTracker` is configured with a valid `Geo.TrackingSession` and `MockLocationManager`
    /// - When: startTracking() is called and first location update from OS is received
    /// - Then: Custom proxydelegate is called
    func testProxyDelegateCalled() async {
        let currentLocation = CLLocation(latitude: 20, longitude: 30)
        mockLocationManager.locations = [currentLocation]
        let successExpectation = expectation(description: "proxydelegate is called")
        let didUpdatePositions: ([Position]) -> Void  = { locations in
            XCTAssertEqual(locations.count, 1)
            XCTAssertEqual(locations[0].location.latitude, currentLocation.coordinate.latitude)
            XCTAssertEqual(locations[0].location.longitude, currentLocation.coordinate.longitude)
            successExpectation.fulfill()
        }
        
        let locationProxyDelegate = LocationProxyDelegate(didUpdatePositions: didUpdatePositions)
        let trackingSessionOptions = Geo.TrackingSessionOptions().withProxyDelegate(locationProxyDelegate)
        do {
            try await geoPlugin.startTracking(for: .tiedToDevice(), with: trackingSessionOptions)
        } catch {
            XCTFail("Failed with error: \(error)")
        }

        await waitForExpectations(timeout: 5)
    }
    
    /// Test if custom proxydelegate is not called when `AWSDeviceTracker`
    /// is configured with `Geo.TrackingSession` with a proxy delegate
    /// and startTracking() is called with batching options set to `.distanceTravelled`
    ///
    /// - Given: `AWSDeviceTracker` is configured with a valid `Geo.TrackingSession` with batching options set to
    ///          `.distanceTravelled` and `MockLocationManager`
    /// - When: startTracking() is called and first location update from OS is received
    /// - Then: Custom proxydelegate is not called and local store successfully saves the location
    func testFirstLocationUpdateWithDistanceBatchingOptionAndProxyDelegate() async {
        let currentLocation = CLLocation(latitude: 20, longitude: 30)
        mockLocationManager.locations = [currentLocation]
        let successExpectation = expectation(description: "proxydelegate is called")
        successExpectation.isInverted = true
        let didUpdatePositions: ([Position]) -> Void  = { locations in
            successExpectation.fulfill()
        }
        
        let locationProxyDelegate = LocationProxyDelegate(didUpdatePositions: didUpdatePositions)
        let trackingSessionOptions = Geo.TrackingSessionOptions(batchingOption: .distanceTravelled(meters: 100)).withProxyDelegate(locationProxyDelegate)
        do {
            let device = Geo.Device.tiedToDevice()
            try await geoPlugin.startTracking(for: device, with: trackingSessionOptions)
            let savedLocations = try await mockLocationStore.getAll()
            XCTAssertEqual(savedLocations.count, 1)
            XCTAssertEqual(savedLocations[0].latitude, currentLocation.coordinate.latitude)
            XCTAssertEqual(savedLocations[0].longitude, currentLocation.coordinate.longitude)
            XCTAssertEqual(savedLocations[0].deviceID, device.id)
            XCTAssertEqual(savedLocations[0].tracker, GeoPluginTestConfig.defaultTracker)
        } catch {
            XCTFail("Failed with error: \(error)")
        }

        await waitForExpectations(timeout: 5)
    }
    
    /// Test if custom proxydelegate is not called when `AWSDeviceTracker`
    /// is configured with `Geo.TrackingSession` with a proxy delegate
    /// and startTracking() is called with batching options set to `.timeElapsed`
    ///
    /// - Given: `AWSDeviceTracker` is configured with a valid `Geo.TrackingSession` with batching options set to
    ///          `.distanceTravelled` and `MockLocationManager`
    /// - When: startTracking() is called and first location update from OS is received
    /// - Then: Custom proxydelegate is not called and local store successfully saves the location
    func testFirstLocationUpdateWithTimeBatchingOptionAndProxyDelegate() async {
        let currentLocation = CLLocation(latitude: 20, longitude: 30)
        mockLocationManager.locations = [currentLocation]
        let successExpectation = expectation(description: "proxydelegate is called")
        successExpectation.isInverted = true
        let didUpdatePositions: ([Position]) -> Void  = { locations in
            successExpectation.fulfill()
        }
        
        let locationProxyDelegate = LocationProxyDelegate(didUpdatePositions: didUpdatePositions)
        let trackingSessionOptions = Geo.TrackingSessionOptions(batchingOption: .timeElapsed(seconds: 60)).withProxyDelegate(locationProxyDelegate)
        do {
            let device = Geo.Device.tiedToDevice()
            try await geoPlugin.startTracking(for: device, with: trackingSessionOptions)
            let savedLocations = try await mockLocationStore.getAll()
            XCTAssertEqual(savedLocations.count, 1)
            XCTAssertEqual(savedLocations[0].latitude, currentLocation.coordinate.latitude)
            XCTAssertEqual(savedLocations[0].longitude, currentLocation.coordinate.longitude)
            XCTAssertEqual(savedLocations[0].deviceID, device.id)
            XCTAssertEqual(savedLocations[0].tracker, GeoPluginTestConfig.defaultTracker)
        } catch {
            XCTFail("Failed with error: \(error)")
        }

        await waitForExpectations(timeout: 5)
    }
    
    /// Test if custom proxydelegate is called when `AWSDeviceTracker`
    /// is configured with `Geo.TrackingSession` with a proxy delegate
    /// and stopTracking() is called after startTracking() with batching options set to `.timeElapsed`
    ///
    /// - Given: `AWSDeviceTracker` is configured with a valid `Geo.TrackingSession` with batching options set to
    ///          `.distanceTravelled` and `MockLocationManager`
    /// - When: startTracking() is called and first location update from OS is received and then stopTracking() is called
    /// - Then: Firstly local store successfully saves the location and secondly proxydelegate is called
    func testProxyDelegateCalledWhenStopTrackingAfterFirstLocationUpdate1() async {
        let currentLocation = CLLocation(latitude: 20, longitude: 30)
        mockLocationManager.locations = [currentLocation]
        let successExpectation = expectation(description: "proxydelegate is called")
        let didUpdatePositions: ([Position]) -> Void  = { locations in
            XCTAssertEqual(locations.count, 1)
            XCTAssertEqual(locations[0].location.latitude, currentLocation.coordinate.latitude)
            XCTAssertEqual(locations[0].location.longitude, currentLocation.coordinate.longitude)
            successExpectation.fulfill()
        }
        
        let locationProxyDelegate = LocationProxyDelegate(didUpdatePositions: didUpdatePositions)
        let trackingSessionOptions = Geo.TrackingSessionOptions(batchingOption: .timeElapsed(seconds: 60)).withProxyDelegate(locationProxyDelegate)
        do {
            let device = Geo.Device.tiedToDevice()
            try await geoPlugin.startTracking(for: device, with: trackingSessionOptions)
            let savedLocations = try await mockLocationStore.getAll()
            XCTAssertEqual(savedLocations.count, 1)
            XCTAssertEqual(savedLocations[0].latitude, currentLocation.coordinate.latitude)
            XCTAssertEqual(savedLocations[0].longitude, currentLocation.coordinate.longitude)
            XCTAssertEqual(savedLocations[0].deviceID, device.id)
            XCTAssertEqual(savedLocations[0].tracker, GeoPluginTestConfig.defaultTracker)
            geoPlugin.stopTracking()
        } catch {
            XCTFail("Failed with error: \(error)")
        }

        await waitForExpectations(timeout: 5)
    }
    
    /// Test if custom proxydelegate is called when `AWSDeviceTracker`
    /// is configured with `Geo.TrackingSession` with a proxy delegate
    /// and stopTracking() is called after startTracking() with batching options set to `.distanceTravelled`
    ///
    /// - Given: `AWSDeviceTracker` is configured with a valid `Geo.TrackingSession` with batching options set to
    ///          `.distanceTravelled` and `MockLocationManager`
    /// - When: startTracking() is called and first location update from OS is received and then stopTracking() is called
    /// - Then: Firstly local store successfully saves the location and secondly proxydelegate is called
    func testProxyDelegateCalledWhenStopTrackingAfterFirstLocationUpdate2() async {
        let currentLocation = CLLocation(latitude: 20, longitude: 30)
        mockLocationManager.locations = [currentLocation]
        let successExpectation = expectation(description: "proxydelegate is called")
        let didUpdatePositions: ([Position]) -> Void  = { locations in
            XCTAssertEqual(locations.count, 1)
            XCTAssertEqual(locations[0].location.latitude, currentLocation.coordinate.latitude)
            XCTAssertEqual(locations[0].location.longitude, currentLocation.coordinate.longitude)
            successExpectation.fulfill()
        }
        
        let locationProxyDelegate = LocationProxyDelegate(didUpdatePositions: didUpdatePositions)
        let trackingSessionOptions = Geo.TrackingSessionOptions(batchingOption: .distanceTravelled(meters: 100)).withProxyDelegate(locationProxyDelegate)
        do {
            let device = Geo.Device.tiedToDevice()
            try await geoPlugin.startTracking(for: device, with: trackingSessionOptions)
            let savedLocations = try await mockLocationStore.getAll()
            XCTAssertEqual(savedLocations.count, 1)
            XCTAssertEqual(savedLocations[0].latitude, currentLocation.coordinate.latitude)
            XCTAssertEqual(savedLocations[0].longitude, currentLocation.coordinate.longitude)
            XCTAssertEqual(savedLocations[0].deviceID, device.id)
            XCTAssertEqual(savedLocations[0].tracker, GeoPluginTestConfig.defaultTracker)
            geoPlugin.stopTracking()
        } catch {
            XCTFail("Failed with error: \(error)")
        }

        await waitForExpectations(timeout: 5)
    }
    
    /// Test if custom proxydelegate is called when `AWSDeviceTracker`
    /// is configured with `Geo.TrackingSession` with a proxy delegate
    /// and location update is received after trackUntil time has elapsed
    ///
    /// - Given: `AWSDeviceTracker` is configured with a valid `Geo.TrackingSession` with batching options set to
    ///          `.none`
    /// - When: startTracking() is called and first location update from OS is received after trackUntil time has elapsed
    /// - Then: Proxy delegate should be called with received locations
    func testProxyDelegateCalledWhenTrackUntilTimeElapsed() async {
        let currentLocation = CLLocation(latitude: 20, longitude: 30)
        mockLocationManager.locations = [currentLocation]
        let successExpectation = expectation(description: "proxydelegate is called")
        let didUpdatePositions: ([Position]) -> Void  = { locations in
            XCTAssertEqual(locations.count, 1)
            XCTAssertEqual(locations[0].location.latitude, currentLocation.coordinate.latitude)
            XCTAssertEqual(locations[0].location.longitude, currentLocation.coordinate.longitude)
            successExpectation.fulfill()
        }
        
        let dateBeforeOneHour = Calendar.current.date(byAdding: .hour, value: -1, to: Date())!
        let locationProxyDelegate = LocationProxyDelegate(didUpdatePositions: didUpdatePositions)
        let trackingSessionOptions = Geo.TrackingSessionOptions(trackUntil: dateBeforeOneHour).withProxyDelegate(locationProxyDelegate)
        do {
            let device = Geo.Device.tiedToDevice()
            try await geoPlugin.startTracking(for: device, with: trackingSessionOptions)
        } catch {
            XCTFail("Failed with error: \(error)")
        }

        await waitForExpectations(timeout: 5)
    }
    
    // MARK: Without Proxy Delegate Tests
    
    /// Test if first received location is sent to service when
    /// startTracking() is called with batching options set to `.none`
    ///
    /// - Given: `AWSDeviceTracker` is configured with a valid `Geo.TrackingSession` with batching options set to
    ///          .none`
    /// - When: startTracking() is called and first location update from OS is received
    /// - Then: Received location is sent to service
    func testLocationSentToService() async {
        let currentLocation = CLLocation(latitude: 20, longitude: 30)
        mockLocationManager.locations = [currentLocation]
        
        let trackingSessionOptions = Geo.TrackingSessionOptions()
        do {
            let device = Geo.Device.tiedToDevice()
            try await geoPlugin.startTracking(for: device, with: trackingSessionOptions)
            XCTAssertEqual(mockDeviceTracker.batchSendStoredLocationsToServiceCalled, 1)
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }
    
    
    /// Test if first received location is stored in local store when
    /// startTracking() is called with batching options set to `.distanceTravelled`
    ///
    /// - Given: `AWSDeviceTracker` is configured with a valid `Geo.TrackingSession` with batching options set to
    ///          .distanceTravelled`
    /// - When: startTracking() is called and first location update from OS is received
    /// - Then: Local store successfully saves the location
    func testFirstLocationUpdateWithDistanceBatchingOption() async {
        let currentLocation = CLLocation(latitude: 20, longitude: 30)
        mockLocationManager.locations = [currentLocation]
        
        let trackingSessionOptions = Geo.TrackingSessionOptions(batchingOption: .distanceTravelled(meters: 100))
        do {
            let device = Geo.Device.tiedToDevice()
            try await geoPlugin.startTracking(for: device, with: trackingSessionOptions)
            let savedLocations = try await mockLocationStore.getAll()
            XCTAssertEqual(savedLocations.count, 1)
            XCTAssertEqual(savedLocations[0].latitude, currentLocation.coordinate.latitude)
            XCTAssertEqual(savedLocations[0].longitude, currentLocation.coordinate.longitude)
            XCTAssertEqual(savedLocations[0].deviceID, device.id)
            XCTAssertEqual(savedLocations[0].tracker, GeoPluginTestConfig.defaultTracker)
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }
    
    /// Test if first received location is stored in local store when
    /// startTracking() is called with batching options set to `.timeElapsed`
    ///
    /// - Given: `AWSDeviceTracker` is configured with a valid `Geo.TrackingSession` with batching options set to
    ///          `.timeElapsed`
    /// - When: startTracking() is called and first location update from OS is received
    /// - Then: Local store successfully saves the location
    func testFirstLocationUpdateWithTimeBatchingOption() async {
        let currentLocation = CLLocation(latitude: 20, longitude: 30)
        mockLocationManager.locations = [currentLocation]

        let trackingSessionOptions = Geo.TrackingSessionOptions(batchingOption: .timeElapsed(seconds: 60))
        do {
            let device = Geo.Device.tiedToDevice()
            try await geoPlugin.startTracking(for: device, with: trackingSessionOptions)
            let savedLocations = try await mockLocationStore.getAll()
            XCTAssertEqual(savedLocations.count, 1)
            XCTAssertEqual(savedLocations[0].latitude, currentLocation.coordinate.latitude)
            XCTAssertEqual(savedLocations[0].longitude, currentLocation.coordinate.longitude)
            XCTAssertEqual(savedLocations[0].deviceID, device.id)
            XCTAssertEqual(savedLocations[0].tracker, GeoPluginTestConfig.defaultTracker)
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }
    
    /// Test if first received location is stored in local store when
    /// startTracking() is called with batching options set to `.none` and when network is disconnected
    ///
    /// - Given: `AWSDeviceTracker` is configured with a valid `Geo.TrackingSession` with batching options set to
    ///          `.none` and when network is disconnected
    /// - When: startTracking() is called and first location update from OS is received
    /// - Then: Local store successfully saves the location
    func testFirstLocationUpdateWhenNetworkDisconnected() async {
        let currentLocation = CLLocation(latitude: 20, longitude: 30)
        mockLocationManager.locations = [currentLocation]
        mockNetworkMonitor.isNetworkConnected = false
        let trackingSessionOptions = Geo.TrackingSessionOptions()
        do {
            let device = Geo.Device.tiedToDevice()
            try await geoPlugin.startTracking(for: device, with: trackingSessionOptions)
            let savedLocations = try await mockLocationStore.getAll()
            XCTAssertEqual(savedLocations.count, 1)
            XCTAssertEqual(savedLocations[0].latitude, currentLocation.coordinate.latitude)
            XCTAssertEqual(savedLocations[0].longitude, currentLocation.coordinate.longitude)
            XCTAssertEqual(savedLocations[0].deviceID, device.id)
            XCTAssertEqual(savedLocations[0].tracker, GeoPluginTestConfig.defaultTracker)
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }
    
    /// Test if first received location is not stored in local store when
    /// startTracking() is called with batching options set to `.none`, `disregardLocationUpdatesWhenOffline` set to `true`
    /// and when network is disconnected
    ///
    /// - Given: `AWSDeviceTracker` is configured with a valid `Geo.TrackingSession` with batching options set to
    ///          `.none`, `disregardLocationUpdatesWhenOffline` set to `true` and when network is disconnected
    /// - When: startTracking() is called and first location update from OS is received
    /// - Then: Local store successfully saves the location
    func testFirstLocationUpdateWhenNetworkDisconnectedAndDisregardOfflineUpdate() async {
        let currentLocation = CLLocation(latitude: 20, longitude: 30)
        mockLocationManager.locations = [currentLocation]
        mockNetworkMonitor.isNetworkConnected = false
        let trackingSessionOptions = Geo.TrackingSessionOptions(disregardLocationUpdatesWhenOffline: true)
        do {
            let device = Geo.Device.tiedToDevice()
            try await geoPlugin.startTracking(for: device, with: trackingSessionOptions)
            let savedLocations = try await mockLocationStore.getAll()
            XCTAssertEqual(savedLocations.count, 0)
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }
    
    /// Test if received locations are sent to service when `AWSDeviceTracker`
    /// is configured with `Geo.TrackingSession` and trackUntil time has elapsed and
    /// location update is received
    ///
    /// - Given: `AWSDeviceTracker` is configured with a valid `Geo.TrackingSession` with batching options set to
    ///          `.none`
    /// - When: startTracking() is called, network is connected and first location update from OS is received after trackUntil time has elapsed
    /// - Then: Received location should be sent to service
    func testLocationIsSentToServiceWhenTrackUntilTimeElapsed() async {
        let currentLocation = CLLocation(latitude: 20, longitude: 30)
        mockLocationManager.locations = [currentLocation]
        
        let dateBeforeOneHour = Calendar.current.date(byAdding: .hour, value: -1, to: Date())!
        let trackingSessionOptions = Geo.TrackingSessionOptions(trackUntil: dateBeforeOneHour)
        do {
            let device = Geo.Device.tiedToDevice()
            try await geoPlugin.startTracking(for: device, with: trackingSessionOptions)
            // one call from startTracking(), one from stopTracking()
            XCTAssertEqual(mockDeviceTracker.batchSendStoredLocationsToServiceCalled, 2)
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }
    
    /// Test if local store has stored the received location when `AWSDeviceTracker`
    /// is configured with `Geo.TrackingSession` when network is disconnected and
    /// trackUntil time has elapsed
    ///
    /// - Given: `AWSDeviceTracker` is configured with a valid `Geo.TrackingSession` with batching options set to
    ///          `.none`
    /// - When: startTracking() is called and first location update from OS is received after trackUntil time has elapsed
    /// - Then: Proxy delegate should be called with received locations
    func testLocationIsSavedInLocalStoreWhenTrackUntilTimeElapsedAndNetworkDisconnected() async {
        let currentLocation = CLLocation(latitude: 20, longitude: 30)
        mockLocationManager.locations = [currentLocation]
        mockNetworkMonitor.isNetworkConnected = false
        
        let dateBeforeOneHour = Calendar.current.date(byAdding: .hour, value: -1, to: Date())!
        let trackingSessionOptions = Geo.TrackingSessionOptions(trackUntil: dateBeforeOneHour)
        do {
            let device = Geo.Device.tiedToDevice()
            try await geoPlugin.startTracking(for: device, with: trackingSessionOptions)
            let savedLocations = try await mockLocationStore.getAll()
            XCTAssertEqual(savedLocations.count, 1)
            XCTAssertEqual(savedLocations[0].latitude, currentLocation.coordinate.latitude)
            XCTAssertEqual(savedLocations[0].longitude, currentLocation.coordinate.longitude)
            XCTAssertEqual(savedLocations[0].deviceID, device.id)
            XCTAssertEqual(savedLocations[0].tracker, GeoPluginTestConfig.defaultTracker)
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }
    
    // MARK: Permission Tests
    
    /// Test if startTracking() is successful when location app permission is authorizedAlways
    ///
    /// - Given: `AWSDeviceTracker` is configured with a valid `Geo.TrackingSession` and `MockLocationManager`
    /// - When: startTracking() is called and location permission is granted
    /// - Then: startTracking() should be successful
    func testStartTrackingSuccessWhenLocationPermissionAuthorizedAlways() async {
        mockLocationManager.mockAuthorizationStatus = .authorizedAlways
        let successExpectation = expectation(description: "operation is successful")
        do {
            try await geoPlugin.startTracking(for: .tiedToDevice(), with: .init())
            successExpectation.fulfill()
        } catch {
            XCTFail("Failed with error: \(error)")
        }
        wait(for: [successExpectation], timeout: 1)
    }
    
    /// Test if startTracking() is successful when location app permission is authorizedWhenInUse
    ///
    /// - Given: `AWSDeviceTracker` is configured with a valid `Geo.TrackingSession` and `MockLocationManager`
    /// - When: startTracking() is called and location permission is granted
    /// - Then: startTracking() should be successful
    #if !os(macOS)
    func testStartTrackingSuccessWhenLocationPermissionAuthorizedWhenInUse() async {
        mockLocationManager.mockAuthorizationStatus = .authorizedWhenInUse
        let successExpectation = expectation(description: "operation is successful")
        do {
            try await geoPlugin.startTracking(for: .tiedToDevice(), with: .init())
            successExpectation.fulfill()
        } catch {
            XCTFail("Failed with error: \(error)")
        }
        wait(for: [successExpectation], timeout: 1)
    }
    #endif
    
    /// Test if startTracking() is successful when location app permission is authorized
    ///
    /// - Given: `AWSDeviceTracker` is configured with a valid `Geo.TrackingSession` and `MockLocationManager`
    /// - When: startTracking() is called and location permission is granted
    /// - Then: startTracking() should be successful
    #if os(macOS)
    func testStartTrackingSuccessWhenLocationPermissionAuthorized() async {
        mockLocationManager.mockAuthorizationStatus = .authorized
        let successExpectation = expectation(description: "operation is successful")
        do {
            try await geoPlugin.startTracking(for: .tiedToDevice(), with: .init())
            successExpectation.fulfill()
        } catch {
            XCTFail("Failed with error: \(error)")
        }
        wait(for: [successExpectation], timeout: 1)
    }
    #endif
    
    /// Test if error is thrown when startTracking() is called and location app
    /// permission is denied
    ///
    /// - Given: `AWSDeviceTracker` is configured with a valid `Geo.TrackingSession` and `MockLocationManager`
    /// - When: startTracking() is called and location app permission is denied
    /// - Then: Error should be thrown and stopTracking() should be called
    func testStartTrackingThrowErrorWhenLocationPermissionDenied() async {
        mockLocationManager.mockAuthorizationStatus = .denied
        let successExpectation = expectation(description: "operation is successful")
        successExpectation.isInverted = true
        do {
            try await geoPlugin.startTracking(for: .tiedToDevice(), with: .init())
            successExpectation.fulfill()
        } catch {
            guard let geoErrorOptional = error as? Geo.Error else {
                XCTFail("Should be of type Geo.Error: \(error)")
                return
            }
            
            guard case .internalPluginError(let errorDesc, _, _) = geoErrorOptional else {
                XCTFail("Should be of type internal plugin Geo.Error: \(error)")
                return
            }
            
            XCTAssertEqual(errorDesc, GeoPluginErrorConstants.missingPermissions.errorDescription)
        }
        wait(for: [successExpectation], timeout: 1)
    }
    
    /// Test if error is thrown when startTracking() is called and location app
    /// permission is restricted
    ///
    /// - Given: `AWSDeviceTracker` is configured with a valid `Geo.TrackingSession` and `MockLocationManager`
    /// - When: startTracking() is called and location app permission is restricted
    /// - Then: Error should be thrown and stopTracking() should be called
    func testStartTrackingThrowErrorWhenLocationPermissionRestricted() async {
        mockLocationManager.mockAuthorizationStatus = .restricted
        let successExpectation = expectation(description: "operation is successful")
        successExpectation.isInverted = true
        do {
            try await geoPlugin.startTracking(for: .tiedToDevice(), with: .init())
            successExpectation.fulfill()
        } catch {
            guard let geoErrorOptional = error as? Geo.Error else {
                XCTFail("Should be of type Geo.Error: \(error)")
                return
            }
            
            guard case .internalPluginError(let errorDesc, _, _) = geoErrorOptional else {
                XCTFail("Should be of type internal plugin Geo.Error: \(error)")
                return
            }
            
            XCTAssertEqual(errorDesc, GeoPluginErrorConstants.missingPermissions.errorDescription)
        }
        wait(for: [successExpectation], timeout: 1)
    }
    
    // MARK: Device Tracker Helper Tests
    
    func testTimeElapsedBatchingOptionThresholdReached() {
        let currentTime = Date()
        let previousTime = Calendar.current.date(byAdding: .minute, value: -15, to: currentTime)!
        let locationUpdateOld = LocationUpdate(timeStamp: previousTime, location: nil)
        let locationUpdateNew = LocationUpdate(timeStamp: currentTime, location: nil)
        let batchingOption : Geo.BatchingOption = .timeElapsed(seconds: 600) // 10 minutes
        XCTAssertTrue(DeviceTrackingHelper.batchingThresholdReached(old: locationUpdateOld,
                                                                    new: locationUpdateNew,
                                                                    batchingOption: batchingOption))
    }
    
    func testTimeElapsedBatchingOptionThresholdNotReached() {
        let currentTime = Date()
        let previousTime = Calendar.current.date(byAdding: .minute, value: -5, to: currentTime)!
        let locationUpdateOld = LocationUpdate(timeStamp: previousTime, location: nil)
        let locationUpdateNew = LocationUpdate(timeStamp: currentTime, location: nil)
        let batchingOption : Geo.BatchingOption = .timeElapsed(seconds: 600) // 10 minutes
        XCTAssertFalse(DeviceTrackingHelper.batchingThresholdReached(old: locationUpdateOld,
                                                                    new: locationUpdateNew,
                                                                    batchingOption: batchingOption))
    }
    
    func testDistanceTravelledBatchingOptionThresholdReached() {
        let previousLocation = CLLocation(latitude: 47.610075, longitude: -122.3422)
        let newLocation = CLLocation(latitude: 47.635402, longitude: -122.294952)
        let locationUpdateOld = LocationUpdate(timeStamp: nil, location: previousLocation)
        let locationUpdateNew = LocationUpdate(timeStamp: nil, location: newLocation)
        let batchingOption : Geo.BatchingOption = .distanceTravelled(meters: 1000) // 1km
        XCTAssertTrue(DeviceTrackingHelper.batchingThresholdReached(old: locationUpdateOld,
                                                                    new: locationUpdateNew,
                                                                    batchingOption: batchingOption))
    }
    
    func testDistanceTravelledBatchingOptionThresholdNotReached() {
        let previousLocation = CLLocation(latitude: 47.610075, longitude: -122.3422)
        let newLocation = CLLocation(latitude: 47.610589, longitude: -122.340949)
        let locationUpdateOld = LocationUpdate(timeStamp: nil, location: previousLocation)
        let locationUpdateNew = LocationUpdate(timeStamp: nil, location: newLocation)
        let batchingOption : Geo.BatchingOption = .distanceTravelled(meters: 1000) // 1km
        XCTAssertFalse(DeviceTrackingHelper.batchingThresholdReached(old: locationUpdateOld,
                                                                    new: locationUpdateNew,
                                                                    batchingOption: batchingOption))
    }
}
