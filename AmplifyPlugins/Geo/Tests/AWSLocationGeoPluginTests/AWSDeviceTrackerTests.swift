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
import AmplifyAsyncTesting

class AWSDeviceTrackerTests : AWSLocationGeoPluginTestBase {
    
    var callStopTracking = true
    
    override func tearDown() async throws {
        if callStopTracking {
            geoPlugin.stopTracking()
        }
        mockKeychainStore.resetCounters()
        try await super.tearDown()
    }
    
    override func setUp() async throws {
        callStopTracking = true
        try await super.setUp()
    }
    
    // MARK: Start Tracking Tests
    
    /// Test if startTracking() is successful when called multiple times with same device
    ///
    /// - Given: `AWSDeviceTracker` is configured with a valid `Geo.TrackingSession` and `MockLocationManager`
    /// - When: startTracking() is called twice with same device
    /// - Then: Operation should be successful
    func testStartTrackingCalledTwiceWithSameDeviceSuccess() async {
        let device1: Geo.Device = .tiedToDevice()
        
        let firstExpectation = asyncExpectation(description: "First call to startTracking() is successful")
        do {
            try await geoPlugin.startTracking(for: device1, with: .init())
            await firstExpectation.fulfill()
        } catch {
            XCTFail("Failed with error: \(error)")
        }

        await waitForExpectations([firstExpectation])
        
        let secondExpectation = asyncExpectation(description: "Second call to startTracking() is successful")
        do {
            try await geoPlugin.startTracking(for: device1, with: .init())
            await secondExpectation.fulfill()
        } catch {
            XCTFail("Failed with error: \(error)")
        }

        await waitForExpectations([secondExpectation])
    }
    
    
    /// Test if error is thrown if startTracking() is called multiple times with different
    /// device ids without calling stopTracking()
    ///
    /// - Given: `AWSDeviceTracker` is configured with a valid `Geo.TrackingSession` and `MockLocationManager`
    /// - When: startTracking() is called twice with different devices
    /// - Then: Error should be thrown
    func testStartTrackingCalledTwiceWithDifferentDevicesShouldThrowError() async {
        let device1: Geo.Device = .tiedToUser()
        let device2: Geo.Device = .tiedToDevice()
        
        let firstExpectation = asyncExpectation(description: "First call to startTracking() is successful")
        do {
            try await geoPlugin.startTracking(for: device1, with: .init())
            await firstExpectation.fulfill()
        } catch {
            XCTFail("Failed with error: \(error)")
        }

        await waitForExpectations([firstExpectation])
        
        let secondExpectation = asyncExpectation(description: "Second call to startTracking() is successful", isInverted: true)
        do {
            try await geoPlugin.startTracking(for: device2, with: .init())
            await secondExpectation.fulfill()
        } catch {
            guard let geoErrorOptional = error as? Geo.Error else {
                XCTFail("Should be of type Geo.Error: \(error)")
                return
            }
            
            guard case .internalPluginError(let errorDesc, _, _) = geoErrorOptional else {
                XCTFail("Should be of type internal plugin Geo.Error: \(error)")
                return
            }
            
            XCTAssertEqual(errorDesc, GeoPluginErrorConstants.errorStartTrackingCalledBeforeStopTracking.errorDescription)
        }

        await waitForExpectations([secondExpectation])
    }
    
    /// Test if startTracking() is successful when called with one device, then stopTracking()
    /// is called and startTracking() is called again with different device
    ///
    /// - Given: `AWSDeviceTracker` is configured with a valid `Geo.TrackingSession` and `MockLocationManager`
    /// - When: startTracking() and stopTracking() is called with one device, then startTracking() called with
    ///         different device
    /// - Then: Operation should be successful
    func testStartTrackingCalledWithDifferentDevicesSuccess() async {
        let device1: Geo.Device = .tiedToUser()
        let device2: Geo.Device = .tiedToDevice()
        
        let firstExpectation = asyncExpectation(description: "First call to startTracking() is successful")
        do {
            try await geoPlugin.startTracking(for: device1, with: .init())
            await firstExpectation.fulfill()
        } catch {
            XCTFail("Failed with error: \(error)")
        }

        await waitForExpectations([firstExpectation])
        
        // stop tracking is called
        geoPlugin.stopTracking()
        
        let secondExpectation = asyncExpectation(description: "Second call to startTracking() is successful")
        do {
            try await geoPlugin.startTracking(for: device2, with: .init())
            await secondExpectation.fulfill()
        } catch {
            XCTFail("Failed with error :\(error)")
        }

        await waitForExpectations([secondExpectation])
    }
    
    // MARK: Keychain Tests
    
    /// Test if device id is successfully stored in keychain after startTracking() is called for first time
    ///
    /// - Given: `AWSDeviceTracker` is configured with a valid `Geo.TrackingSession` and `MockLocationManager`
    /// - When: startTracking() is called
    /// - Then: Device ID is stored successfully in keychain
    func testDeviceIDStoredInKeychainSuccess() async {
        let device: Geo.Device = .tiedToDevice()
        
        let expectation = asyncExpectation(description: "Device ID is stored successfully in keychain")
        do {
            try await geoPlugin.startTracking(for: device, with: .init())
            await expectation.fulfill()
        } catch {
            XCTFail("Failed with error: \(error)")
        }

        await waitForExpectations([expectation])
        
        if let savedDeviceId = try? mockKeychainStore._getString(AWSDeviceTracker.Constants.deviceIDKey) {
            XCTAssertEqual(device.id, savedDeviceId)
        } else {
            XCTFail("Device ID not stored in keychain")
        }
    }
    
    /// Test if device id is successfully cleared from keychain after stopTracking() is called
    ///
    /// - Given: `AWSDeviceTracker` is configured with a valid `Geo.TrackingSession` and `MockLocationManager`
    /// - When: startTracking() is called, then stopTracking() is called
    /// - Then: Device ID is cleared successfully from keychain
    func testDeviceIDClearedFromKeychainSuccess() async {
        let device: Geo.Device = .tiedToDevice()
        
        let saveExpectation = asyncExpectation(description: "Device ID is stored successfully in keychain")
        do {
            try await geoPlugin.startTracking(for: device, with: .init())
            await saveExpectation.fulfill()
        } catch {
            XCTFail("Failed with error: \(error)")
        }

        await waitForExpectations([saveExpectation])
        geoPlugin.stopTracking()
        
        let clearExpectation = asyncExpectation(description: "Device ID is cleared successfully from keychain")
        if let _ = try? mockKeychainStore._getString(AWSDeviceTracker.Constants.deviceIDKey) {
            XCTFail("Device ID not cleared from keychain")
        } else {
            await clearExpectation.fulfill()
        }
        
        await waitForExpectations([clearExpectation])
    }
    
    /// Test if stopTracking() is called when signedOut Hub event is fired
    ///
    /// - Given: `AWSDeviceTracker` is configured with a valid `Geo.TrackingSession` and `MockLocationManager`
    /// - When: startTracking() is called, then signedOut Hub event is fired
    /// - Then: stopTracking() should be called
    func testStopTrackingCalledAfterSignOut() async {
        let device: Geo.Device = .tiedToDevice()
        
        let saveExpectation = asyncExpectation(description: "Device ID is stored successfully in keychain")
        do {
            try await geoPlugin.startTracking(for: device, with: .init())
            await saveExpectation.fulfill()
        } catch {
            XCTFail("Failed with error: \(error)")
        }

        await waitForExpectations([saveExpectation])
        
        Amplify.Hub.dispatch(to: .auth, payload: HubPayload(eventName: HubPayload.EventName.Auth.signedOut))
        let stopTrackingExpectation = asyncExpectation(description: "Stop tracking is called")
        Task {
            try await Task.sleep(seconds: 2)
            XCTAssertEqual(mockDeviceTracker.stopDeviceTrackingCalled, 1)
            await stopTrackingExpectation.fulfill()
        }
        await waitForExpectations([stopTrackingExpectation], timeout: 5)
        callStopTracking = false
    }
    
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
        let device: Geo.Device = .tiedToDevice()
        let successExpectation = expectation(description: "proxydelegate is called")
        let didUpdatePositions: ([Position]) -> Void  = { locations in
            XCTAssertEqual(locations.count, 1)
            XCTAssertEqual(locations[0].location.latitude, currentLocation.coordinate.latitude)
            XCTAssertEqual(locations[0].location.longitude, currentLocation.coordinate.longitude)
            XCTAssertEqual(locations[0].tracker, GeoPluginTestConfig.defaultTracker)
            XCTAssertEqual(locations[0].deviceID, device.id)
            successExpectation.fulfill()
        }
        
        let locationProxyDelegate = LocationProxyDelegate(didUpdatePositions: didUpdatePositions)
        let trackingSessionOptions = Geo.TrackingSessionOptions().withProxyDelegate(locationProxyDelegate)
        do {
            try await geoPlugin.startTracking(for: device, with: trackingSessionOptions)
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
        let proxyDelegateSuccessExpectation = expectation(description: "proxydelegate is called")
        proxyDelegateSuccessExpectation.isInverted = true
        let didUpdatePositions: ([Position]) -> Void  = { locations in
            proxyDelegateSuccessExpectation.fulfill()
        }
        
        let locationProxyDelegate = LocationProxyDelegate(didUpdatePositions: didUpdatePositions)
        let trackingSessionOptions = Geo.TrackingSessionOptions(batchingOption: .distanceTravelled(meters: 100)).withProxyDelegate(locationProxyDelegate)
        let device = Geo.Device.tiedToDevice()
        
        let startTrackingSuccessExpectation = asyncExpectation(description: "Operation was successful")
        Task {
            do {
                try await geoPlugin.startTracking(for: device, with: trackingSessionOptions)
                await startTrackingSuccessExpectation.fulfill()
            } catch {
                XCTFail("Failed with error: \(error)")
            }
        }
        
        await waitForExpectations([startTrackingSuccessExpectation])
        
        let locationSaveExpectation = asyncExpectation(description: "Save was successful")
        Task {
            do {
                let savedLocations = try await self.mockLocationStore.getAll()
                XCTAssertEqual(savedLocations.count, 1)
                XCTAssertEqual(savedLocations[0].latitude, currentLocation.coordinate.latitude)
                XCTAssertEqual(savedLocations[0].longitude, currentLocation.coordinate.longitude)
                XCTAssertEqual(savedLocations[0].tracker, GeoPluginTestConfig.defaultTracker)
                await locationSaveExpectation.fulfill()
            } catch {
                XCTFail("Failed with error: \(error)")
            }
        }
        
        await waitForExpectations([locationSaveExpectation], timeout: 5)
        wait(for: [proxyDelegateSuccessExpectation], timeout: 5)
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
        let proxyDelegateSuccessExpectation = expectation(description: "proxydelegate is called")
        proxyDelegateSuccessExpectation.isInverted = true
        let didUpdatePositions: ([Position]) -> Void  = { locations in
            proxyDelegateSuccessExpectation.fulfill()
        }
        
        let locationProxyDelegate = LocationProxyDelegate(didUpdatePositions: didUpdatePositions)
        let trackingSessionOptions = Geo.TrackingSessionOptions(batchingOption: .timeElapsed(seconds: 60)).withProxyDelegate(locationProxyDelegate)
        let device = Geo.Device.tiedToDevice()
        
        let startTrackingSuccessExpectation = asyncExpectation(description: "Operation was successful")
        Task {
            do {
                try await geoPlugin.startTracking(for: device, with: trackingSessionOptions)
                await startTrackingSuccessExpectation.fulfill()
            } catch {
                XCTFail("Failed with error: \(error)")
            }
        }
        
        await waitForExpectations([startTrackingSuccessExpectation])
        
        let locationSaveExpectation = asyncExpectation(description: "Save was successful")
        Task {
            do {
                let savedLocations = try await self.mockLocationStore.getAll()
                XCTAssertEqual(savedLocations.count, 1)
                XCTAssertEqual(savedLocations[0].latitude, currentLocation.coordinate.latitude)
                XCTAssertEqual(savedLocations[0].longitude, currentLocation.coordinate.longitude)
                XCTAssertEqual(savedLocations[0].tracker, GeoPluginTestConfig.defaultTracker)
                await locationSaveExpectation.fulfill()
            } catch {
                XCTFail("Failed with error: \(error)")
            }
        }
        
        await waitForExpectations([locationSaveExpectation], timeout: 5)
        wait(for: [proxyDelegateSuccessExpectation], timeout: 1)
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
        let proxyDelegateSuccessExpectation = expectation(description: "proxydelegate is called")
        let device = Geo.Device.tiedToDevice()
        let didUpdatePositions: ([Position]) -> Void  = { locations in
            XCTAssertEqual(locations.count, 1)
            XCTAssertEqual(locations[0].location.latitude, currentLocation.coordinate.latitude)
            XCTAssertEqual(locations[0].location.longitude, currentLocation.coordinate.longitude)
            XCTAssertEqual(locations[0].tracker, GeoPluginTestConfig.defaultTracker)
            XCTAssertEqual(locations[0].deviceID, device.id)
            proxyDelegateSuccessExpectation.fulfill()
        }
        
        let locationProxyDelegate = LocationProxyDelegate(didUpdatePositions: didUpdatePositions)
        let trackingSessionOptions = Geo.TrackingSessionOptions(batchingOption: .timeElapsed(seconds: 60)).withProxyDelegate(locationProxyDelegate)
        
        let startTrackingSuccessExpectation = asyncExpectation(description: "Operation was successful")
        Task {
            do {
                try await geoPlugin.startTracking(for: device, with: trackingSessionOptions)
                await startTrackingSuccessExpectation.fulfill()
            } catch {
                XCTFail("Failed with error: \(error)")
            }
        }
        
        await waitForExpectations([startTrackingSuccessExpectation])
        
        let locationSaveExpectation = asyncExpectation(description: "Save was successful")
        Task {
            do {
                let savedLocations = try await mockLocationStore.getAll()
                XCTAssertEqual(savedLocations.count, 1)
                XCTAssertEqual(savedLocations[0].latitude, currentLocation.coordinate.latitude)
                XCTAssertEqual(savedLocations[0].longitude, currentLocation.coordinate.longitude)
                XCTAssertEqual(savedLocations[0].tracker, GeoPluginTestConfig.defaultTracker)
                await locationSaveExpectation.fulfill()
            } catch {
                XCTFail("Failed with error: \(error)")
            }
        }
        
        await waitForExpectations([locationSaveExpectation], timeout: 5)
        
        geoPlugin.stopTracking()
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
        let proxyDelegateSuccessExpectation = expectation(description: "proxydelegate is called")
        let device = Geo.Device.tiedToDevice()
        let didUpdatePositions: ([Position]) -> Void  = { locations in
            XCTAssertEqual(locations.count, 1)
            XCTAssertEqual(locations[0].location.latitude, currentLocation.coordinate.latitude)
            XCTAssertEqual(locations[0].location.longitude, currentLocation.coordinate.longitude)
            XCTAssertEqual(locations[0].tracker, GeoPluginTestConfig.defaultTracker)
            XCTAssertEqual(locations[0].deviceID, device.id)
            proxyDelegateSuccessExpectation.fulfill()
        }
        
        let locationProxyDelegate = LocationProxyDelegate(didUpdatePositions: didUpdatePositions)
        let trackingSessionOptions = Geo.TrackingSessionOptions(batchingOption: .distanceTravelled(meters: 100)).withProxyDelegate(locationProxyDelegate)
        
        
        let startTrackingSuccessExpectation = asyncExpectation(description: "Operation was successful")
        Task {
            do {
                try await geoPlugin.startTracking(for: device, with: trackingSessionOptions)
                await startTrackingSuccessExpectation.fulfill()
            } catch {
                XCTFail("Failed with error: \(error)")
            }
        }
        
        await waitForExpectations([startTrackingSuccessExpectation])
        
        let locationSaveExpectation = asyncExpectation(description: "Save was successful")
        Task {
            do {
                let savedLocations = try await mockLocationStore.getAll()
                XCTAssertEqual(savedLocations.count, 1)
                XCTAssertEqual(savedLocations[0].latitude, currentLocation.coordinate.latitude)
                XCTAssertEqual(savedLocations[0].longitude, currentLocation.coordinate.longitude)
                XCTAssertEqual(savedLocations[0].tracker, GeoPluginTestConfig.defaultTracker)
                await locationSaveExpectation.fulfill()
            } catch {
                XCTFail("Failed with error: \(error)")
            }
        }
        
        await waitForExpectations([locationSaveExpectation], timeout: 5)
        
        geoPlugin.stopTracking()
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
        let device = Geo.Device.tiedToDevice()
        let didUpdatePositions: ([Position]) -> Void  = { locations in
            XCTAssertEqual(locations.count, 1)
            XCTAssertEqual(locations[0].location.latitude, currentLocation.coordinate.latitude)
            XCTAssertEqual(locations[0].location.longitude, currentLocation.coordinate.longitude)
            XCTAssertEqual(locations[0].tracker, GeoPluginTestConfig.defaultTracker)
            XCTAssertEqual(locations[0].deviceID, device.id)
            successExpectation.fulfill()
        }
        
        let dateBeforeOneHour = Calendar.current.date(byAdding: .hour, value: -1, to: Date())!
        let locationProxyDelegate = LocationProxyDelegate(didUpdatePositions: didUpdatePositions)
        let trackingSessionOptions = Geo.TrackingSessionOptions(trackUntil: dateBeforeOneHour).withProxyDelegate(locationProxyDelegate)
        do {
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
        let device = Geo.Device.tiedToDevice()
        
        let successExpectation = asyncExpectation(description: "Operation was successful")
        Task {
            do {
                try await geoPlugin.startTracking(for: device, with: trackingSessionOptions)
                await successExpectation.fulfill()
            } catch {
                XCTFail("Failed with error: \(error)")
            }
        }
        
        await waitForExpectations([successExpectation])
        
        let locationSaveExpectation = asyncExpectation(description: "Save was successful")
        Task {
            do {
                let savedLocations = try await self.mockLocationStore.getAll()
                XCTAssertEqual(savedLocations.count, 1)
                XCTAssertEqual(savedLocations[0].latitude, currentLocation.coordinate.latitude)
                XCTAssertEqual(savedLocations[0].longitude, currentLocation.coordinate.longitude)
                XCTAssertEqual(savedLocations[0].tracker, GeoPluginTestConfig.defaultTracker)
                await locationSaveExpectation.fulfill()
            } catch {
                XCTFail("Failed with error: \(error)")
            }
        }
        
        await waitForExpectations([locationSaveExpectation], timeout: 5)
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
        let device = Geo.Device.tiedToDevice()
        
        let successExpectation = asyncExpectation(description: "Operation was successful")
        Task {
            do {
                try await geoPlugin.startTracking(for: device, with: trackingSessionOptions)
                await successExpectation.fulfill()
            } catch {
                XCTFail("Failed with error: \(error)")
            }
        }
        
        await waitForExpectations([successExpectation])
        
        let locationSaveExpectation = asyncExpectation(description: "Save was successful")
        Task {
            do {
                let savedLocations = try await self.mockLocationStore.getAll()
                XCTAssertEqual(savedLocations.count, 1)
                XCTAssertEqual(savedLocations[0].latitude, currentLocation.coordinate.latitude)
                XCTAssertEqual(savedLocations[0].longitude, currentLocation.coordinate.longitude)
                XCTAssertEqual(savedLocations[0].tracker, GeoPluginTestConfig.defaultTracker)
                await locationSaveExpectation.fulfill()
            } catch {
                XCTFail("Failed with error: \(error)")
            }
        }
        
        await waitForExpectations([locationSaveExpectation], timeout: 5)
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
        let device = Geo.Device.tiedToDevice()
        
        let successExpectation = asyncExpectation(description: "Operation was successful")
        Task {
            do {
                try await geoPlugin.startTracking(for: device, with: trackingSessionOptions)
                await successExpectation.fulfill()
            } catch {
                XCTFail("Failed with error: \(error)")
            }
        }
        
        await waitForExpectations([successExpectation])
        
        let locationSaveExpectation = asyncExpectation(description: "Save was successful")
        Task {
            do {
                let savedLocations = try await self.mockLocationStore.getAll()
                XCTAssertEqual(savedLocations.count, 1)
                XCTAssertEqual(savedLocations[0].latitude, currentLocation.coordinate.latitude)
                XCTAssertEqual(savedLocations[0].longitude, currentLocation.coordinate.longitude)
                XCTAssertEqual(savedLocations[0].tracker, GeoPluginTestConfig.defaultTracker)
                await locationSaveExpectation.fulfill()
            } catch {
                XCTFail("Failed with error: \(error)")
            }
        }
        
        await waitForExpectations([locationSaveExpectation], timeout: 5)
        
    }
    
    /// Test if first received location is not stored in local store when
    /// startTracking() is called with batching options set to `.none`, `disregardLocationUpdatesWhenOffline` set to `true`
    /// and when network is disconnected
    ///
    /// - Given: `AWSDeviceTracker` is configured with a valid `Geo.TrackingSession` with batching options set to
    ///          `.none`, `disregardLocationUpdatesWhenOffline` set to `true` and when network is disconnected
    /// - When: startTracking() is called and first location update from OS is received
    /// - Then: Local store shouldn't save the location
    func testFirstLocationUpdateWhenNetworkDisconnectedAndDisregardOfflineUpdate() async {
        let currentLocation = CLLocation(latitude: 20, longitude: 30)
        mockLocationManager.locations = [currentLocation]
        mockNetworkMonitor.isNetworkConnected = false
        let trackingSessionOptions = Geo.TrackingSessionOptions(disregardLocationUpdatesWhenOffline: true)
        let device = Geo.Device.tiedToDevice()
        
        let successExpectation = asyncExpectation(description: "Operation was successful")
        Task {
            do {
                try await geoPlugin.startTracking(for: device, with: trackingSessionOptions)
                await successExpectation.fulfill()
            } catch {
                XCTFail("Failed with error: \(error)")
            }
        }
        
        await waitForExpectations([successExpectation])
        
        let locationSaveExpectation = asyncExpectation(description: "Local save was not done.")
        Task {
            do {
                let savedLocations = try await mockLocationStore.getAll()
                XCTAssertEqual(savedLocations.count, 0)
                await locationSaveExpectation.fulfill()
            } catch {
                XCTFail("Failed with error: \(error)")
            }
        }
        
        await waitForExpectations([locationSaveExpectation], timeout: 5)
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
            XCTAssertEqual(mockDeviceTracker.batchSendStoredLocationsToServiceCalled, 1)
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
