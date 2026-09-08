//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import InternalAWSPinpoint
#if canImport(WatchKit)
import WatchKit
#elseif canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class ActivityTrackerTests: XCTestCase, @unchecked Sendable {
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
    private static let applicationWillMoveToForegoundNotification: Notification.Name = {
#if canImport(WatchKit)
    WKExtension.applicationWillEnterForegroundNotification
#elseif canImport(UIKit)
    UIApplication.willEnterForegroundNotification
#elseif canImport(AppKit)
    NSApplication.willBecomeActiveNotification
#endif
    }()

    @MainActor
    private static let applicationWillTerminateNotification: Notification.Name = {
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

        tracker = ActivityTracker(
            backgroundTrackingTimeout: timeout,
            stateMachine: stateMachine
        )
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

    // `@MainActor` to match how these notifications actually arrive. `NotificationCenter` delivers
    // synchronously on the posting thread, and the handler is main-actor-isolated because the platform
    // posts the real notifications on the main thread. Posting from a background executor — as this test
    // did before — trapped the main-actor check in the `@objc` thunk under the Swift 6 language mode.
    @MainActor
    func testApplicationStateChanged_shouldReportProperEvent() async {
        stateMachine.processExpectation = expectation(description: "Application state changed")
        stateMachine.processExpectation?.expectedFulfillmentCount = 3

        NotificationCenter.default.post(Notification(name: Self.applicationDidMoveToBackgroundNotification))
        NotificationCenter.default.post(Notification(name: Self.applicationWillMoveToForegoundNotification))
        NotificationCenter.default.post(Notification(name: Self.applicationWillTerminateNotification))

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

extension [ActivityEvent] {
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
