//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import XCTest

@testable import AWSCloudWatchLoggingPlugin
@testable import InternalCloudWatchLogging

final class AWSCloudWatchLoggingMonitorTests: XCTestCase {

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

    /// Given: the the logging monitor is configured with a 2 second interval
    /// When: the monitor is enabled
    /// Then: the delegate is autoamtically invoked
    /// TODO: Disabled: Flaky test, failing in CI/CD.
    func testDelegateIsInvokedOnInterval() async {
        monitor.setAutomaticFlushIntervals()
        await fulfillment(of: [invokedExpectation], timeout: 10)
    }
}

extension AWSCloudWatchLoggingMonitorTests: CloudWatchLoggingMonitorDelegate {
    package func handleAutomaticFlushIntervalEvent() {
        invokedExpectation.fulfill()
    }
}
