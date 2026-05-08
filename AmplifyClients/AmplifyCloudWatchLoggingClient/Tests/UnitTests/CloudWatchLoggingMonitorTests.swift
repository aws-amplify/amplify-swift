//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import AmplifyCloudWatchLoggingClient
@testable import InternalCloudWatchLogging

final class CloudWatchLoggingMonitorTests: XCTestCase {

    var monitor: CloudWatchLoggingMonitor!
    var invokedExpectation: XCTestExpectation!

    override func setUp() async throws {
        monitor = CloudWatchLoggingMonitor(flushIntervalInSeconds: 2, eventDelegate: self)
        invokedExpectation = expectation(description: "Delegate is invoked")
    }

    override func tearDown() async throws {
        monitor = nil
        invokedExpectation = nil
    }

    /// Given: the logging monitor is configured with a 2 second interval
    /// When: the monitor is enabled
    /// Then: the delegate is automatically invoked
    /// TODO: Disabled: Flaky test, failing in CI/CD.
    func testDelegateIsInvokedOnInterval() async {
        monitor.setAutomaticFlushIntervals()
        await fulfillment(of: [invokedExpectation], timeout: 10)
    }
}

extension CloudWatchLoggingMonitorTests: CloudWatchLoggingMonitorDelegate {
    package func handleAutomaticFlushIntervalEvent() {
        invokedExpectation.fulfill()
    }
}
