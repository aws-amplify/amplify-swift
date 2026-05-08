//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Network
import XCTest

@testable import AmplifyCloudWatchLoggingClient
@testable import InternalCloudWatchLogging

final class LoggingNetworkMonitorTests: XCTestCase {

    /// Given: a LoggingNetworkMonitor backed by NWPathMonitor
    /// When: monitoring starts
    /// Then: the monitor detects the device is online
    func testNetworkMonitorEvent() {
        let onlineExpectation = expectation(description: "Device is online")
        let loggingMonitor: LoggingNetworkMonitor = NWPathMonitor()
        (loggingMonitor as? NWPathMonitor)?.pathUpdateHandler = { newPath in
            if newPath.status == .satisfied {
                onlineExpectation.fulfill()
            }
        }

        loggingMonitor.startMonitoring(using: DispatchQueue(label: "AmplifyCloudWatchLogging.NetworkMonitor"))

        wait(for: [onlineExpectation], timeout: 10)
        XCTAssertTrue(loggingMonitor.isOnline)
        loggingMonitor.stopMonitoring()
    }
}
