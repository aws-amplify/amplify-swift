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
        timerFired.expectedFulfillmentCount = 4
        timerFired.assertForOverFulfill = true
        let timer = RepeatingTimer.createRepeatingTimer(timeInterval: TimeInterval(0.25)) {
            timerFired.fulfill()
        }
        timer.resume()
        await waitForExpectations(timeout: 5)

        timer.setEventHandler {}
        timer.cancel()
        XCTAssertTrue(timer.isCancelled)
    }
}
