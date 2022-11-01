//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
@testable import AWSLocationGeoPlugin

class AWSDeviceTrackerTests : XCTestCase {
    
    /// Test if custom proxydelegate is called when `AWSDeviceTracker`
    /// is configured with `Geo.TrackingSession` with a proxy delegate
    /// and startTracking() is called
    ///
    /// - Given: `AWSDeviceTracker` is configured with a valid `Geo.TrackingSession`
    /// - When: Location update from OS is received
    /// - Then: Custom proxydelegate is called
    func testProxyDelegateCalled() throws {
        var count = 0
        let didUpdateLocations: ([Position]) -> Void  = { locations in
            count += 1
        }
        let locationProxyDelegate = LocationProxyDelegate(didUpdateLocations: didUpdateLocations)
        let trackingSessionOptions = Geo.LocationManager.TrackingSessionOptions().withProxyDelegate(locationProxyDelegate)
        let deviceTracker = try MockAWSDeviceTracker(options: trackingSessionOptions, locationManager: MockLocationManager())
        deviceTracker.configure(with: trackingSessionOptions)
        deviceTracker.startTracking(for: .tiedToDevice())
        XCTAssertEqual(count, 1)
    }
}
