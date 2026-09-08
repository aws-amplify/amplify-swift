//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@testable import InternalAWSPinpoint

// `@unchecked Sendable`: the protocol it conforms to now requires `Sendable`. Test double driven
// by a single test at a time.
class MockActivityTracker: ActivityTrackerBehaviour, @unchecked Sendable {
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
