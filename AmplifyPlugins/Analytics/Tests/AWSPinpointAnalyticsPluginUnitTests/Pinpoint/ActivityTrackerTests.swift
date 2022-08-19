//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSPinpointAnalyticsPlugin
import XCTest

class ActivityTrackerTests: XCTestCase {
    private var tracker: ActivityTracker!
    private var stateMachine: MockStateMachine!
    private var timeout: TimeInterval = 1

    private static let applicationDidMoveToBackgroundNotification: Notification.Name = {
    #if canImport(UIKit)
        UIApplication.didEnterBackgroundNotification
    #else
        NSApplication.didResignActiveNotification
    #endif
    }()

    private static  let applicationWillMoveToForegoundNotification: Notification.Name = {
    #if canImport(UIKit)
        UIApplication.willEnterForegroundNotification
    #else
        NSApplication.willBecomeActiveNotification
    #endif
    }()

    private static  var applicationWillTerminateNotification: Notification.Name = {
    #if canImport(UIKit)
        UIApplication.willTerminateNotification
    #else
        NSApplication.willTerminateNotification
    #endif
    }()

    override func setUp() {
        stateMachine = MockStateMachine(initialState: .initializing) { _, _ in
            return .initializing
        }

        tracker = ActivityTracker(backgroundTrackingTimeout: timeout,
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
        NotificationCenter.default.post(Notification(name: Self.applicationDidMoveToBackgroundNotification))
        XCTAssertEqual(stateMachine.processedEvent, .applicationDidMoveToBackground)

        NotificationCenter.default.post(Notification(name: Self.applicationWillMoveToForegoundNotification))
        XCTAssertEqual(stateMachine.processedEvent, .applicationWillMoveToForeground)

        NotificationCenter.default.post(Notification(name: Self.applicationWillTerminateNotification))
        XCTAssertEqual(stateMachine.processedEvent, .applicationWillTerminate)
    }

    func testBackgroundTracking_afterTimeout_shouldReportBackgroundTimeout() {
        NotificationCenter.default.post(Notification(name: Self.applicationDidMoveToBackgroundNotification))
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
