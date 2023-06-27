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

final class AWSCloudWatchLoggingMonitorTests: XCTestCase {
    
    var monitor: AWSCLoudWatchLoggingMonitor!
    var invokedExpectation: XCTestExpectation!
    
    override func setUp() async throws {
        monitor = AWSCLoudWatchLoggingMonitor(flushIntervalInSeconds: 2, eventDelegate: self)
        invokedExpectation = expectation(description: "Delegate is invoked")
    }
    
    override func tearDown() async throws {
        monitor = nil
        invokedExpectation = nil
    }
    
    func testDelegateIsInvokedOnInterval() {
        monitor.setAutomaticSubmitEventsInterval()
        wait(for: [invokedExpectation], timeout: 3)
    }
}

extension AWSCloudWatchLoggingMonitorTests: AWSCloudWatchLoggingMonitorDelegate {
    func handleAutomaticFlushIntervalEvent() {
        invokedExpectation.fulfill()
    }
}
