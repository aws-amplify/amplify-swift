//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import AWSPinpointAnalyticsPlugin

class RepeatingTimerTests: XCTestCase {
  func testRepeatingTimer() {
    let timerFired = expectation(description: "timer fired")
    timerFired.expectedFulfillmentCount = 4
    timerFired.assertForOverFulfill = true
    let timer = RepeatingTimer.createRepeatingTimer(timeInterval: TimeInterval(0.25)) {
      timerFired.fulfill()
    }
    timer.resume()
    wait(for: [timerFired], timeout: 2)

    timer.setEventHandler {}
    timer.cancel()
    XCTAssertTrue(timer.isCancelled)
  }
}
