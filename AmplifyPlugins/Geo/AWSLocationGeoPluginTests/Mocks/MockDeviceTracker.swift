//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
import Amplify
@testable import AWSLocationGeoPlugin

public class MockAWSDeviceTracker: AWSDeviceTrackingBehavior {
    
    // MARK: - Method call counts for MockAWSDeviceTracker
    var configureCalled = 0
    var startDeviceTrackingCalled = 0
    var stopDeviceTrackingCalled = 0
    
    public func configure(with options: Geo.LocationManager.TrackingSessionOptions) {
        configureCalled += 1
    }
    
    public func startTracking() {
        startDeviceTrackingCalled += 1
    }
    
    public func stopTracking() {
        stopDeviceTrackingCalled += 1
    }
   
}
