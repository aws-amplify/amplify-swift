//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import AWSPinpointAnalyticsPlugin

class AWSPinpointAnalyticsPluginResetTests: AWSPinpointAnalyticsPluginTestBase {
  func testReset() {
    let completedInvoked = expectation(description: "onComplete is invoked")
    analyticsPlugin.reset {
      completedInvoked.fulfill()
    }

    waitForExpectations(timeout: 1)
    XCTAssertNil(analyticsPlugin.pinpoint)
    XCTAssertNil(analyticsPlugin.authService)
    XCTAssertNil(analyticsPlugin.autoFlushEventsTimer)
    XCTAssertNil(analyticsPlugin.appSessionTracker)
    XCTAssertNil(analyticsPlugin.globalProperties)
    XCTAssertNil(analyticsPlugin.isEnabled)
  }
}
