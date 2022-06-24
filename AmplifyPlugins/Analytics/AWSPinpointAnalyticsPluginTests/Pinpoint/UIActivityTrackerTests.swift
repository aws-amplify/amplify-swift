//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if canImport(UIKit)

@testable import AWSPinpointAnalyticsPlugin
import XCTest

class UIActivityTrackerTests: XCTestCase {
    private var tracker: UIActivityTracker!
    private var stateMachine: MockStateMachine!
    private var timeout: TimeInterval = 1

    override func setUp() {
        stateMachine = MockStateMachine(initialState: .initializing) { _, _ in
            return .initializing
        }

        tracker = UIActivityTracker(backgroundTrackingTimeout: timeout,
                                    stateMachine: stateMachine)
    }

    override func tearDown() {
        tracker = nil
        stateMachine = nil
    }

    func testBeginTracking() {
        let expectation = expectation(description: "Initial state")
        tracker.beginActivityTracking { newState in
            XCTAssertEqual(newState, .initializing)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testApplicationStateChanged_shouldReportProperEvent() {
        NotificationCenter.default.post(Notification(name: UIApplication.didEnterBackgroundNotification))
        XCTAssertEqual(stateMachine.processedEvent, .applicationDidMoveToBackground)

        NotificationCenter.default.post(Notification(name: UIApplication.willEnterForegroundNotification))
        XCTAssertEqual(stateMachine.processedEvent, .applicationWillMoveToForeground)

        NotificationCenter.default.post(Notification(name: UIApplication.willTerminateNotification))
        XCTAssertEqual(stateMachine.processedEvent, .applicationWillTerminate)
    }

    func testBackgroundTracking_afterTimeout_shouldReportBackgroundTimeout() {
        NotificationCenter.default.post(Notification(name: UIApplication.didEnterBackgroundNotification))
        XCTAssertEqual(stateMachine.processedEvent, .applicationDidMoveToBackground)
        stateMachine.processExpectation = expectation(description: "Background tracking timeout")
        waitForExpectations(timeout: 1)
        XCTAssertEqual(stateMachine.processedEvent, .backgroundTrackingDidTimeout)
    }
}

class MockStateMachine: StateMachine<ApplicationState, ActivityEvent> {
    var processedEvent: ActivityEvent?
    var processExpectation: XCTestExpectation?

    override func process(_ event: ActivityEvent) {
        processedEvent = event
        processExpectation?.fulfill()
    }
}

#endif
