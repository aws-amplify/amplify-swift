//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@testable import AWSPinpointAnalyticsPlugin

class MockNetworkMonitor: NetworkMonitor {
    var isOnline = true
    func startMonitoring(using queue: DispatchQueue) {}
    func stopMonitoring() {}
}
