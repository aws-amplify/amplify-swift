//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest

/// `withinTime`, the WebAuthn suites' bound on a wait: it must hold for a wait that ignores cancellation.
final class BoundedWaitTests: XCTestCase {

    /// - Given: a gate that is never passed, whose `waitForArrivals` ignores cancellation
    /// - When: its first arrival is awaited with a bound of 0.5 s
    /// - Then:
    ///    - the wait throws `WaitTimedOut`, within 3 s of starting
    func testANeverArrivingGateFailsWithinTheBound() async {
        let gate = Gate()
        let started = Date()

        do {
            try await gate.arrivals(1, within: 0.5)
            XCTFail("a gate nobody passed reported an arrival")
        } catch {
            XCTAssertTrue(error is WaitTimedOut, "\(error)")
        }

        XCTAssertLessThan(Date().timeIntervalSince(started), 3)
    }

    /// - Given: bodies returning `nil`, a value, and throwing
    /// - When: each runs within a bound it easily meets
    /// - Then:
    ///    - `nil` comes back as `nil` (not as a timeout), a value as itself, and the error as itself
    func testTheBodysOutcomeComesBackAsItIs() async throws {
        let none: Int? = try await withinTime(1, "nil") { nil }
        let some: Int? = try await withinTime(1, "a value") { 7 }
        XCTAssertNil(none)
        XCTAssertEqual(some, 7)
        do {
            _ = try await withinTime(1, "a throw") { () -> Int in throw FixtureError(description: "thrown") }
            XCTFail("the body's error was lost")
        } catch {
            XCTAssertEqual((error as? FixtureError)?.description, "thrown")
        }
    }

    /// - Given: a body that sleeps for a minute and honours cancellation, bounded at 30 s
    /// - When: the task awaiting it is cancelled
    /// - Then:
    ///    - the cancellation reaches the body: the wait ends with its `CancellationError`, well before the bound
    func testTheCallersCancellationReachesTheBody() async {
        let started = Date()
        let caller = Task {
            try await withinTime(30, "a minute's sleep") { try await Task.sleep(nanoseconds: 60_000_000_000) }
        }
        try? await Task.sleep(nanoseconds: 100_000_000)
        caller.cancel()

        let result = await caller.result
        XCTAssertThrowsError(try result.get()) { XCTAssertTrue($0 is CancellationError, "\($0)") }
        XCTAssertLessThan(Date().timeIntervalSince(started), 10)
    }
}
