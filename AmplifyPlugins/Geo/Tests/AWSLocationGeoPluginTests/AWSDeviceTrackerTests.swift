//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AWSLocationGeoPlugin

class AWSDeviceTrackerTests : AWSLocationGeoPluginTestBase {
    
    /// Test if custom proxydelegate is called when `AWSDeviceTracker`
    /// is configured with `Geo.TrackingSession` with a proxy delegate
    /// and startTracking() is called with batching options set to `.none`
    ///
    /// - Given: `AWSDeviceTracker` is configured with a valid `Geo.TrackingSession` and `MockLocationManager`
    /// - When: startTracking() is called and location update from OS is received
    /// - Then: Custom proxydelegate is called
    func testProxyDelegateCalled() async {
        var count = 0
        let didUpdatePositions: ([Position]) -> Void  = { locations in
            count += 1
        }
        let locationProxyDelegate = LocationProxyDelegate(didUpdatePositions: didUpdatePositions)
        let trackingSessionOptions = Geo.TrackingSessionOptions().withProxyDelegate(locationProxyDelegate)
        do {
            try await geoPlugin.startTracking(for: .tiedToDevice(), with: trackingSessionOptions)
        } catch {
            XCTFail("Failed with error: \(error)")
        }
        XCTAssertEqual(mockDeviceTracker.startDeviceTrackingCalled, 1)
        XCTAssertEqual(mockDeviceTracker.configureCalled, 1)
        XCTAssertEqual(count, 1)
    }

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
        XCTAssertEqual(mockDeviceTracker.startDeviceTrackingCalled, 1)
        XCTAssertEqual(mockDeviceTracker.configureCalled, 1)
        wait(for: [successExpectation], timeout: 1)
    }
    
    /// Test if startTracking() is successful when location app permission is authorizedWhenInUse
    ///
    /// - Given: `AWSDeviceTracker` is configured with a valid `Geo.TrackingSession` and `MockLocationManager`
    /// - When: startTracking() is called and location permission is granted
    /// - Then: startTracking() should be successful
    func testStartTrackingSuccessWhenLocationPermissionAuthorizedWhenInUse() async {
        mockLocationManager.mockAuthorizationStatus = .authorizedWhenInUse
        let successExpectation = expectation(description: "operation is successful")
        do {
            try await geoPlugin.startTracking(for: .tiedToDevice(), with: .init())
            successExpectation.fulfill()
        } catch {
            XCTFail("Failed with error: \(error)")
        }
        XCTAssertEqual(mockDeviceTracker.startDeviceTrackingCalled, 1)
        XCTAssertEqual(mockDeviceTracker.configureCalled, 1)
        wait(for: [successExpectation], timeout: 1)
    }
    
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
        XCTAssertEqual(mockDeviceTracker.startDeviceTrackingCalled, 1)
        XCTAssertEqual(mockDeviceTracker.configureCalled, 1)
        XCTAssertEqual(mockDeviceTracker.stopDeviceTrackingCalled, 1)
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
        XCTAssertEqual(mockDeviceTracker.startDeviceTrackingCalled, 1)
        XCTAssertEqual(mockDeviceTracker.configureCalled, 1)
        XCTAssertEqual(mockDeviceTracker.stopDeviceTrackingCalled, 1)
        wait(for: [successExpectation], timeout: 1)
    }
}
