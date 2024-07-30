//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import InternalAWSPinpoint
import XCTest
#if canImport(WatchKit)
import WatchKit
#elseif canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

class ActivityTrackerTests: XCTestCase {
    private var tracker: ActivityTracker!
    private var stateMachine: MockStateMachine!
    private var timeout: TimeInterval = 1

    @MainActor
    private static let applicationDidMoveToBackgroundNotification: Notification.Name = {
#if canImport(WatchKit)
    WKExtension.applicationDidEnterBackgroundNotification
#elseif canImport(UIKit)
    UIApplication.didEnterBackgroundNotification
#elseif canImport(AppKit)
    NSApplication.didResignActiveNotification
#endif
    }()

    @MainActor
    private static  let applicationWillMoveToForegoundNotification: Notification.Name = {
#if canImport(WatchKit)
    WKExtension.applicationWillEnterForegroundNotification
#elseif canImport(UIKit)
    UIApplication.willEnterForegroundNotification
#elseif canImport(AppKit)
    NSApplication.willBecomeActiveNotification
#endif
    }()

    @MainActor
    private static  var applicationWillTerminateNotification: Notification.Name = {
#if canImport(WatchKit)
    WKExtension.applicationWillResignActiveNotification
#elseif canImport(UIKit)
    UIApplication.willTerminateNotification
#elseif canImport(AppKit)
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

    func testBeginTracking() async {
        let expectation = expectation(description: "Initial state")
        tracker.beginActivityTracking { newState in
            XCTAssertEqual(newState, .initializing)
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 1)
    }

    func testApplicationStateChanged_shouldReportProperEvent() async {
        stateMachine.processExpectation = expectation(description: "Application state changed")
        stateMachine.processExpectation?.expectedFulfillmentCount = 3
        
        NotificationCenter.default.post(Notification(name: Self.applicationDidMoveToBackgroundNotification))
        NotificationCenter.default.post(Notification(name: Self.applicationWillMoveToForegoundNotification))
        await NotificationCenter.default.post(Notification(name: Self.applicationWillTerminateNotification))
        
        await fulfillment(of: [stateMachine.processExpectation!], timeout: 1)
        XCTAssertTrue(stateMachine.processedEvents.contains(.applicationDidMoveToBackground))
        XCTAssertTrue(stateMachine.processedEvents.contains(.applicationWillMoveToForeground))
        XCTAssertTrue(stateMachine.processedEvents.contains(.applicationWillTerminate))
    }

    @MainActor
    func testBackgroundTracking_afterTimeout_shouldReportBackgroundTimeout() async {
        stateMachine.processExpectation = expectation(description: "Background tracking timeout")
        stateMachine.processExpectation?.expectedFulfillmentCount = 2
        
        NotificationCenter.default.post(Notification(name: Self.applicationDidMoveToBackgroundNotification))

        await fulfillment(of: [stateMachine.processExpectation!], timeout: 5)
        XCTAssertTrue(stateMachine.processedEvents.contains(.applicationDidMoveToBackground))
        XCTAssertTrue(stateMachine.processedEvents.contains(.backgroundTrackingDidTimeout))

    }
}

extension Array where Element == ActivityEvent {
    func contains(_ element: Element) -> Bool {
        return contains(where: { $0 == element })
    }
}

class MockStateMachine: StateMachine<ApplicationState, ActivityEvent> {
    var processedEvents: [ActivityEvent] = []
    var processExpectation: XCTestExpectation?

    override func process(_ event: ActivityEvent) {
        processedEvents.append(event)
        processExpectation?.fulfill()
    }
}
