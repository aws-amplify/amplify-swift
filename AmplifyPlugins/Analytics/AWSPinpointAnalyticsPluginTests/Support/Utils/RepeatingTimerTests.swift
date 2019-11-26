//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSPinpointAnalyticsPlugin

class RepeatingTimerTests: XCTestCase {

    func testRepeatingTimer() {
        let timerFired = expectation(description: "timer fired")
        var timerFiredCount = 0
        timerFired.expectedFulfillmentCount = 10

        let timer = RepeatingTimer.createRepeatingTimer(timeInterval: TimeInterval(1)) {
            timerFired.fulfill()
            timerFiredCount += 1
        }
        timer.resume()
        wait(for: [timerFired], timeout: 10)
        XCTAssertEqual(timerFiredCount, 10)
    }
}
