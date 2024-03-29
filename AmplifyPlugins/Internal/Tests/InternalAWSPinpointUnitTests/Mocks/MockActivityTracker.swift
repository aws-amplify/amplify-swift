//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import InternalAWSPinpoint
import Foundation

class MockActivityTracker: ActivityTrackerBehaviour {
    var backgroundTrackingTimeout: TimeInterval = 0
    
    var beginActivityTrackingCount = 0
    var callback: ((ApplicationState) -> Void)?

    func beginActivityTracking(_ listener: @escaping (ApplicationState) -> Void) {
        beginActivityTrackingCount += 1
        callback = listener
    }

    func resetCounters() {
        beginActivityTrackingCount = 0
    }
}
