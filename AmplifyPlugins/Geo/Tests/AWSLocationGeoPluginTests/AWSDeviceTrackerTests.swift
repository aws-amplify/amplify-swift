//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
@testable import AWSLocationGeoPlugin

class AWSDeviceTrackerTests : AWSLocationGeoPluginTestBase {
    
    /// Test if custom proxydelegate is called when `AWSDeviceTracker`
    /// is configured with `Geo.TrackingSession` with a proxy delegate
    /// and startTracking() is called with batching options set to `.none`
    ///
    /// - Given: `AWSDeviceTracker` is configured with a valid `Geo.TrackingSession` and `MockLocationManager`
    /// - When: Location update from OS is received
    /// - Then: Custom proxydelegate is called
    func testProxyDelegateCalled() async {
        var count = 0
        let didUpdatePositions: ([Position]) -> Void  = { locations in
            count += 1
        }
        let locationProxyDelegate = LocationProxyDelegate(didUpdatePositions: didUpdatePositions)
        let trackingSessionOptions = Geo.LocationManager.TrackingSessionOptions().withProxyDelegate(locationProxyDelegate)
        do {
            try await geoPlugin.startTracking(for: .tiedToDevice(), with: trackingSessionOptions)
        } catch {
            XCTFail("Failed with error: \(error)")
        }
        XCTAssertEqual(count, 1)
    }

}
