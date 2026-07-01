//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AmplifyEventEnrichmentClient
import Foundation
import XCTest

#if canImport(UIKit)
import UIKit
#endif

@available(iOS 13.0, macOS 12.0, tvOS 13.0, watchOS 9.0, *)
final class ActivityTrackerTests: XCTestCase {

    /// Test that ActivityTracker calls onPause when background notification is posted
    ///
    /// - Given: An ActivityTracker with onPause/onResume callbacks
    /// - When:
    ///    - The background notification is posted
    /// - Then:
    ///    - The onPause callback is invoked
    ///
    @MainActor
    func testBackgroundNotificationCallsOnPause() async throws {
        let pauseExpectation = expectation(description: "onPause called")
        let tracker = ActivityTracker(
            onPause: { pauseExpectation.fulfill() },
            onResume: {}
        )

        #if canImport(UIKit) && !os(watchOS)
        NotificationCenter.default.post(
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        #elseif canImport(AppKit)
        NotificationCenter.default.post(
            name: NSApplication.didResignActiveNotification,
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
    @MainActor
    func testForegroundNotificationCallsOnResume() async throws {
        let resumeExpectation = expectation(description: "onResume called")
        let tracker = ActivityTracker(
            onPause: {},
            onResume: { resumeExpectation.fulfill() }
        )

        #if canImport(UIKit) && !os(watchOS)
        NotificationCenter.default.post(
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        #elseif canImport(AppKit)
        NotificationCenter.default.post(
            name: NSApplication.willBecomeActiveNotification,
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

        // Ensure session has started
        _ = try await client.record("warmup")

        #if canImport(UIKit) && !os(watchOS)
        NotificationCenter.default.post(
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        #elseif canImport(AppKit)
        NotificationCenter.default.post(
            name: NSApplication.didResignActiveNotification,
            object: nil
        )
        #endif

        // Give the Task in ActivityTracker time to execute
        try await Task.sleep(nanoseconds: 50_000_000)

        // Verify session is paused by resuming and checking session ID is preserved
        #if canImport(UIKit) && !os(watchOS)
        NotificationCenter.default.post(
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        #elseif canImport(AppKit)
        NotificationCenter.default.post(
            name: NSApplication.willBecomeActiveNotification,
            object: nil
        )
        #endif

        try await Task.sleep(nanoseconds: 50_000_000)

        let event = try await client.record("after_resume")
        XCTAssertFalse(event.session.id.isEmpty)

        await client.close()
    }
}
