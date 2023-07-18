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

final class LoggingNetworkMonitorTests: XCTestCase {
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



