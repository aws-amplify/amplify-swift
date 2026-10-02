//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if !os(watchOS)
import Foundation
import XCTest
@testable import AWSAPIPlugin

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class AmplifyReachabilityTests: XCTestCase, @unchecked Sendable {

    /// Test that a reachability callback can read state while the flags are being set
    ///
    /// - Given: A reachability with no notification queue, so callbacks run synchronously on its serial queue
    /// - When:
    ///    - The notifier starts and sets the initial flags
    /// - Then:
    ///    - The callback runs, reads `connection` and `allowsCellularConnection`, and `startNotifier()` returns
    ///
    func testStartNotifier_withoutNotificationQueue_notifiesWithoutDeadlock() throws {
        let reachability = try AmplifyReachability(notificationQueue: nil)
        let notified = expectation(description: "reachability callback invoked")
        notified.assertForOverFulfill = false
        let onChange: AmplifyReachability.NetworkReachable = { reachability in
            _ = reachability.connection
            _ = reachability.allowsCellularConnection
            notified.fulfill()
        }
        reachability.whenReachable = onChange
        reachability.whenUnreachable = onChange

        // Started off the test thread so a deadlock fails the wait instead of hanging the test.
        let started = expectation(description: "startNotifier returned")
        DispatchQueue.global().async {
            do {
                try reachability.startNotifier()
            } catch {
                XCTFail("startNotifier failed: \(error)")
            }
            started.fulfill()
        }

        wait(for: [notified, started], timeout: 5)
        reachability.stopNotifier()
    }

    /// Test that settable state stays consistent under concurrent access
    ///
    /// - Given: A reachability whose notifier is running
    /// - When:
    ///    - Many threads write its settable properties and read `connection` at the same time
    /// - Then:
    ///    - Every access completes and the last write wins. Run with `--sanitize=thread` to detect data races.
    ///
    func testConcurrentAccess_fromManyThreads_keepsStateConsistent() throws {
        let reachability = try AmplifyReachability(notificationQueue: nil)
        try reachability.startNotifier()
        defer { reachability.stopNotifier() }

        DispatchQueue.concurrentPerform(iterations: 1_000) { index in
            reachability.allowsCellularConnection = index.isMultiple(of: 2)
            reachability.whenReachable = { _ in }
            reachability.whenUnreachable = { _ in }
            reachability.notificationCenter = NotificationCenter()
            _ = reachability.allowsCellularConnection
            _ = reachability.connection
            _ = reachability.description
            _ = reachability.notifierRunning
        }

        reachability.allowsCellularConnection = false
        XCTAssertFalse(reachability.allowsCellularConnection)
        XCTAssertTrue(reachability.notifierRunning)
    }
}
#endif
