//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import AmplifyCloudWatchClient

final class CloudWatchLoggingMonitorTests: XCTestCase {

    var monitor: CloudWatchLoggingMonitor!
    var invokedExpectation: XCTestExpectation!

    override func setUp() async throws {
        monitor = CloudWatchLoggingMonitor(
            flushIntervalInSeconds: 1,
            eventDelegate: self,
            queue: DispatchQueue(label: "com.amplify.cloudwatchlogging.monitor.tests", qos: .userInitiated)
        )
        invokedExpectation = expectation(description: "Delegate is invoked")
    }

    override func tearDown() async throws {
        monitor = nil
        invokedExpectation = nil
    }

    /// Given: the logging monitor is configured with a 1 second interval
    /// When: the monitor is enabled
    /// Then: the delegate is automatically invoked
    func testDelegateIsInvokedOnInterval() async {
        monitor.setAutomaticFlushIntervals()
        await fulfillment(of: [invokedExpectation], timeout: 10)
    }
}

extension CloudWatchLoggingMonitorTests: CloudWatchLoggingMonitorDelegate {
    func handleAutomaticFlushIntervalEvent() {
        invokedExpectation.fulfill()
    }
}
