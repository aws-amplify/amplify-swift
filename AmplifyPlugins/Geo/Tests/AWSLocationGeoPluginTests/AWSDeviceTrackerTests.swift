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
    
    // MARK: Without Proxy Delegate Tests
    
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
}
