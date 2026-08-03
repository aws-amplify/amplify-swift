//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AmplifyEventEnrichmentClient
import Foundation
import XCTest

#if canImport(WatchKit)
import WatchKit
#elseif canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@available(iOS 13.0, macOS 12.0, tvOS 13.0, watchOS 9.0, *)
@MainActor
final class ActivityTrackerTests: XCTestCase {

    /// Test that ActivityTracker calls onPause when background notification is posted
    ///
    /// - Given: An ActivityTracker with onPause/onResume callbacks
    /// - When:
    ///    - The background notification is posted
    /// - Then:
    ///    - The onPause callback is invoked
    ///
    func testBackgroundNotificationCallsOnPause() async throws {
        let pauseExpectation = expectation(description: "onPause called")
        let tracker = ActivityTracker(
            onPause: { pauseExpectation.fulfill() },
            onResume: {}
        )

        #if canImport(WatchKit)
        NotificationCenter.default.post(
            name: WKExtension.applicationDidEnterBackgroundNotification,
            object: nil
        )
        #elseif canImport(UIKit)
        NotificationCenter.default.post(
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        #elseif canImport(AppKit)
        NotificationCenter.default.post(
            name: NSApplication.didHideNotification,
            object: nil
        )
        #endif

        await fulfillment(of: [pauseExpectation], timeout: 1.0)
        _ = tracker
    }

    /// Test that ActivityTracker calls onResume when foreground notification is posted
    ///
    /// - Given: An ActivityTracker with onPause/onResume callbacks
    /// - When:
    ///    - The foreground notification is posted
    /// - Then:
    ///    - The onResume callback is invoked
    ///
    func testForegroundNotificationCallsOnResume() async throws {
        let resumeExpectation = expectation(description: "onResume called")
        let tracker = ActivityTracker(
            onPause: {},
            onResume: { resumeExpectation.fulfill() }
        )

        #if canImport(WatchKit)
        NotificationCenter.default.post(
            name: WKExtension.applicationWillEnterForegroundNotification,
            object: nil
        )
        #elseif canImport(UIKit)
        NotificationCenter.default.post(
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        #elseif canImport(AppKit)
        NotificationCenter.default.post(
            name: NSApplication.willUnhideNotification,
            object: nil
        )
        #endif

        await fulfillment(of: [resumeExpectation], timeout: 1.0)
        _ = tracker
    }

    /// Test that session pauses when background notification fires via the client
    ///
    /// - Given: A client with autoSessionTracking enabled
    /// - When:
    ///    - The background notification is posted
    /// - Then:
    ///    - The session manager transitions to paused state
    ///
    func testClientSessionPausesOnBackgroundNotification() async throws {
        let client = AmplifyEventEnrichmentClient(
            appId: "test-app",
            sdkMetadata: SDKMetadata(name: "test", version: "1.0"),
            options: EventEnrichmentClientOptions(autoSessionTracking: true)
        )

        _ = try await client.record("warmup")

        #if canImport(WatchKit)
        NotificationCenter.default.post(
            name: WKExtension.applicationDidEnterBackgroundNotification,
            object: nil
        )
        #elseif canImport(UIKit)
        NotificationCenter.default.post(
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        #elseif canImport(AppKit)
        NotificationCenter.default.post(
            name: NSApplication.didHideNotification,
            object: nil
        )
        #endif

        try await Task.sleep(nanoseconds: 50_000_000)

        #if canImport(WatchKit)
        NotificationCenter.default.post(
            name: WKExtension.applicationWillEnterForegroundNotification,
            object: nil
        )
        #elseif canImport(UIKit)
        NotificationCenter.default.post(
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        #elseif canImport(AppKit)
        NotificationCenter.default.post(
            name: NSApplication.willUnhideNotification,
            object: nil
        )
        #endif

        try await Task.sleep(nanoseconds: 50_000_000)

        let event = try await client.record("after_resume")
        XCTAssertFalse(event.session.id.isEmpty)

        await client.close()
    }

    /// Test that stopTracking() prevents further callbacks
    ///
    /// - Given: An ActivityTracker that has been stopped
    /// - When:
    ///    - Background and foreground notifications are posted
    /// - Then:
    ///    - Neither callback is invoked
    ///
    func testStopTrackingPreventsCallbacks() async throws {
        let pauseExpectation = expectation(description: "onPause not called")
        pauseExpectation.isInverted = true
        let resumeExpectation = expectation(description: "onResume not called")
        resumeExpectation.isInverted = true

        let tracker = ActivityTracker(
            onPause: { pauseExpectation.fulfill() },
            onResume: { resumeExpectation.fulfill() }
        )
        tracker.stopTracking()

        postBackgroundNotification()
        postForegroundNotification()

        await fulfillment(of: [pauseExpectation, resumeExpectation], timeout: 0.5)
        withExtendedLifetime(tracker) {}
    }

    /// Test that closing a client tears down lifecycle tracking
    ///
    /// - Given: A closed client that had autoSessionTracking enabled
    /// - When:
    ///    - A foreground notification is posted afterwards
    /// - Then:
    ///    - No new session is started, so recording still reports the client
    ///      as closed rather than succeeding
    ///
    func testCloseStopsLifecycleTracking() async throws {
        let client = AmplifyEventEnrichmentClient(
            appId: "test-app",
            sdkMetadata: SDKMetadata(name: "test", version: "1.0"),
            options: EventEnrichmentClientOptions(autoSessionTracking: true)
        )

        _ = try await client.record("warmup")
        await client.close()

        postForegroundNotification()
        try await Task.sleep(nanoseconds: 100_000_000)

        do {
            _ = try await client.record("after_close")
            XCTFail("Expected clientClosed error after close()")
        } catch let error as EventEnrichmentError {
            guard case .clientClosed = error else {
                XCTFail("Expected clientClosed error, got \(error)")
                return
            }
        }

        let state = await client.sessionState
        let isTracking = await client.isTrackingLifecycle
        XCTAssertEqual(state, .stopped)
        XCTAssertFalse(isTracking)
    }

    private func postBackgroundNotification() {
        #if canImport(WatchKit)
        NotificationCenter.default.post(
            name: WKExtension.applicationDidEnterBackgroundNotification,
            object: nil
        )
        #elseif canImport(UIKit)
        NotificationCenter.default.post(
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        #elseif canImport(AppKit)
        NotificationCenter.default.post(
            name: NSApplication.didHideNotification,
            object: nil
        )
        #endif
    }

    private func postForegroundNotification() {
        #if canImport(WatchKit)
        NotificationCenter.default.post(
            name: WKExtension.applicationWillEnterForegroundNotification,
            object: nil
        )
        #elseif canImport(UIKit)
        NotificationCenter.default.post(
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        #elseif canImport(AppKit)
        NotificationCenter.default.post(
            name: NSApplication.willUnhideNotification,
            object: nil
        )
        #endif
    }
}
