//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

import Network
import XCTest

@testable import AmplifyTestCommon
@testable import AWSCloudWatchLoggingPlugin

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
final class LoggingNetworkMonitorTests: XCTestCase, @unchecked Sendable {
    func testNetworkMonitorEvent() {
        let onlineExpectation = expectation(description: "Device is online")
        let loggingMonitor: LoggingNetworkMonitor = NWPathMonitor()
        (loggingMonitor as? NWPathMonitor)?.pathUpdateHandler = { newPath in
            if newPath.status == .satisfied {
                onlineExpectation.fulfill()
            }
        }

        loggingMonitor.startMonitoring(using: DispatchQueue(label: "AWSCloudWatchingLogging.NetworkMonitor"))

        wait(for: [onlineExpectation], timeout: TestCommonConstants.networkTimeout)
        XCTAssertTrue(loggingMonitor.isOnline)
        loggingMonitor.stopMonitoring()
    }
}



