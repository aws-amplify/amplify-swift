//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSPinpointAnalyticsPlugin
import XCTest

class RepeatingTimerTests: XCTestCase {
    func testRepeatingTimer() async {
        let timerFired = expectation(description: "timer fired")
        timerFired.expectedFulfillmentCount = 2
        timerFired.assertForOverFulfill = true
        let timer = RepeatingTimer.createRepeatingTimer(timeInterval: TimeInterval(0.2)) {
            timerFired.fulfill()
        }
        timer.activate()
        await waitForExpectations(timeout: 10)

        timer.setEventHandler {}
        timer.cancel()
        XCTAssertTrue(timer.isCancelled)
    }
}
