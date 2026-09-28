//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// Every test here asserts on call counts and on what each caller received, never on how long
/// anything took. Operations are held in flight by a `Gate` the test opens, so the interleaving is
/// fixed by the test rather than by the scheduler, and a CI retry cannot turn a race into a pass.
final class SingleFlightTests: XCTestCase {

    private struct Failure: Error, Equatable {
        let attempt: Int
    }

    /// Records whether the shared operation observed cancellation after being released.
    private actor CancellationProbe {
        private(set) var sawCancellation = false

        func record(_ cancelled: Bool) {
            sawCancellation = sawCancellation || cancelled
        }
    }

    /// An operation that counts its starts, waits at `gate`, then returns `attempt * 100`.
    private static func gatedOperation(
        starts: Counter,
        gate: Gate,
        probe: CancellationProbe? = nil
    ) -> @Sendable () async throws -> Int {
        return {
            let attempt = await starts.increment()
            await gate.pass()
            await probe?.record(Task.isCancelled)
            return attempt * 100
        }
    }

    private static func assertCancelled(
        _ task: Task<Int, Error>,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            let value = try await task.value
            XCTFail("Expected CancellationError, got \(value)", file: file, line: line)
        } catch {
            XCTAssertTrue(error is CancellationError, "Expected CancellationError, got \(error)", file: file, line: line)
        }
    }

    /// The core invariant: concurrent callers coalesce onto one operation.
    ///
    /// - Given: one caller whose operation is held in flight
    /// - When:
    ///    - nine more callers call `run` while it is held, and the operation is then released
    /// - Then:
    ///    - the operation started exactly once, and all ten callers received its result
    func testConcurrentCallersShareOneOperation() async throws {
        let flight = SingleFlight<Int>()
        let starts = Counter()
        let gate = Gate()
        let operation = Self.gatedOperation(starts: starts, gate: gate)

        let first = Task { try await flight.run(operation) }
        await gate.waitForArrivals(1)
        let joiners = (0 ..< 9).map { _ in Task { try await flight.run(operation) } }
        await waitUntil("all ten callers are waiting") { await flight.waiterCount == 10 }

        let startsWhileHeld = await starts.value
        XCTAssertEqual(startsWhileHeld, 1)

        await gate.open()
        var results = try await [first.value]
        for joiner in joiners {
            try await results.append(joiner.value)
        }

        XCTAssertEqual(results, Array(repeating: 100, count: 10))
        let totalStarts = await starts.value
        XCTAssertEqual(totalStarts, 1)
        let inFlight = await flight.isInFlight
        XCTAssertFalse(inFlight)
    }

    /// - Given: several callers joined onto one operation
    /// - When: that operation throws
    /// - Then:
    ///    - every caller receives the same error, and the operation ran once
    func testJoinedCallersReceiveTheSameError() async {
        let flight = SingleFlight<Int>()
        let starts = Counter()
        let gate = Gate()
        let operation: @Sendable () async throws -> Int = {
            let attempt = await starts.increment()
            await gate.pass()
            throw Failure(attempt: attempt)
        }

        let first = Task { try await flight.run(operation) }
        await gate.waitForArrivals(1)
        let joiners = (0 ..< 4).map { _ in Task { try await flight.run(operation) } }
        await waitUntil("all five callers are waiting") { await flight.waiterCount == 5 }
        await gate.open()

        for task in [first] + joiners {
            do {
                let value = try await task.value
                XCTFail("Expected Failure, got \(value)")
            } catch {
                XCTAssertEqual(error as? Failure, Failure(attempt: 1))
            }
        }
        let totalStarts = await starts.value
        XCTAssertEqual(totalStarts, 1)
    }

    /// - Given: an operation that has completed successfully
    /// - When: `run` is called again
    /// - Then:
    ///    - the slot is empty, and a fresh operation starts and its own result is returned
    func testSlotIsClearedAfterSuccessAndNextCallStartsFresh() async throws {
        let flight = SingleFlight<Int>()
        let starts = Counter()
        let operation: @Sendable () async throws -> Int = { await starts.increment() }

        let first = try await flight.run(operation)
        let inFlightBetween = await flight.isInFlight
        let second = try await flight.run(operation)

        XCTAssertEqual(first, 1)
        XCTAssertFalse(inFlightBetween)
        XCTAssertEqual(second, 2)
        let totalStarts = await starts.value
        XCTAssertEqual(totalStarts, 2)
    }

    /// A failed refresh must not wedge the session's later refreshes.
    ///
    /// - Given: an operation that throws on its first attempt and succeeds on its second
    /// - When: `run` is called, fails, and is called again
    /// - Then:
    ///    - the first call throws, the slot is empty afterwards, and the second call starts a fresh
    ///      operation that succeeds
    func testSlotIsClearedAfterFailureAndNextCallStartsFresh() async throws {
        let flight = SingleFlight<Int>()
        let starts = Counter()
        let operation: @Sendable () async throws -> Int = {
            let attempt = await starts.increment()
            if attempt == 1 {
                throw Failure(attempt: attempt)
            }
            return attempt
        }

        do {
            _ = try await flight.run(operation)
            XCTFail("Expected the first attempt to throw")
        } catch {
            XCTAssertEqual(error as? Failure, Failure(attempt: 1))
        }
        let inFlightBetween = await flight.isInFlight
        let second = try await flight.run(operation)

        XCTAssertFalse(inFlightBetween)
        XCTAssertEqual(second, 2)
    }

    /// Sessions must never wait on each other: per-record exclusion is not a process-wide lock.
    /// Both operations are held in flight at the same moment, which is only possible if neither
    /// instance blocks the other, and B then completes while A is still held.
    ///
    /// - Given: two instances, standing for two sessions, each with its operation held at its own gate
    /// - When:
    ///    - B's gate is opened while A's stays closed
    /// - Then:
    ///    - both operations were in flight at once, B's caller completes while A is still in flight,
    ///      and A completes once its own gate opens
    func testTwoInstancesNeverBlockEachOther() async throws {
        let sessionA = SingleFlight<Int>()
        let sessionB = SingleFlight<Int>()
        let startsA = Counter()
        let startsB = Counter()
        let gateA = Gate()
        let gateB = Gate()

        let operationA = Self.gatedOperation(starts: startsA, gate: gateA)
        let operationB = Self.gatedOperation(starts: startsB, gate: gateB)

        let callerA = Task { try await sessionA.run(operationA) }
        let callerB = Task { try await sessionB.run(operationB) }
        await gateA.waitForArrivals(1)
        await gateB.waitForArrivals(1)

        await gateB.open()
        let resultB = try await callerB.value
        let aStillInFlight = await sessionA.isInFlight
        let aWaiters = await sessionA.waiterCount

        XCTAssertEqual(resultB, 100)
        XCTAssertTrue(aStillInFlight, "B must complete while A is still held")
        XCTAssertEqual(aWaiters, 1)

        await gateA.open()
        let resultA = try await callerA.value
        XCTAssertEqual(resultA, 100)
    }

    /// - Given: an originating caller and a joined caller on one held operation
    /// - When:
    ///    - the joined caller is cancelled, then the operation is released
    /// - Then:
    ///    - the joined caller throws `CancellationError` while the operation is still held, the
    ///      operation is not cancelled, and the originating caller receives its result
    func testCancellingAJoinedCallerDoesNotCancelTheOperation() async throws {
        let flight = SingleFlight<Int>()
        let starts = Counter()
        let gate = Gate()
        let probe = CancellationProbe()
        let operation = Self.gatedOperation(starts: starts, gate: gate, probe: probe)

        let originator = Task { try await flight.run(operation) }
        await gate.waitForArrivals(1)
        let joiner = Task { try await flight.run(operation) }
        await waitUntil("both callers are waiting") { await flight.waiterCount == 2 }

        joiner.cancel()
        await Self.assertCancelled(joiner)
        let waitersAfterCancel = await flight.waiterCount
        XCTAssertEqual(waitersAfterCancel, 1)

        await gate.open()
        let result = try await originator.value
        XCTAssertEqual(result, 100)
        let sawCancellation = await probe.sawCancellation
        XCTAssertFalse(sawCancellation)
        let totalStarts = await starts.value
        XCTAssertEqual(totalStarts, 1)
    }

    /// The caller whose call started the operation gets no special power over it.
    ///
    /// - Given: an originating caller and a joined caller on one held operation
    /// - When:
    ///    - the originating caller is cancelled, then the operation is released
    /// - Then:
    ///    - the originating caller throws `CancellationError` while the operation is still held,
    ///      the operation is not cancelled, and the joined caller receives its result
    func testCancellingTheOriginatingCallerDoesNotCancelTheOperation() async throws {
        let flight = SingleFlight<Int>()
        let starts = Counter()
        let gate = Gate()
        let probe = CancellationProbe()
        let operation = Self.gatedOperation(starts: starts, gate: gate, probe: probe)

        let originator = Task { try await flight.run(operation) }
        await gate.waitForArrivals(1)
        let joiner = Task { try await flight.run(operation) }
        await waitUntil("both callers are waiting") { await flight.waiterCount == 2 }

        originator.cancel()
        await Self.assertCancelled(originator)

        await gate.open()
        let result = try await joiner.value
        XCTAssertEqual(result, 100)
        let sawCancellation = await probe.sawCancellation
        XCTAssertFalse(sawCancellation)
        let totalStarts = await starts.value
        XCTAssertEqual(totalStarts, 1)
    }

    /// With every caller gone, the operation still runs to completion rather than being abandoned
    /// mid-refresh, a caller arriving meanwhile joins it rather than starting a second, and the
    /// slot is cleared once it finishes.
    ///
    /// - Given: a single caller on a held operation
    /// - When:
    ///    - that caller is cancelled, a new caller arrives, and the operation is then released
    /// - Then:
    ///    - the operation stays in flight after the cancellation, the new caller receives the first
    ///      operation's result, and a later call starts a fresh operation
    func testOperationOutlivesCancelledCallersThenClearsTheSlot() async throws {
        let flight = SingleFlight<Int>()
        let starts = Counter()
        let gate = Gate()
        let operation = Self.gatedOperation(starts: starts, gate: gate)

        let abandoned = Task { try await flight.run(operation) }
        await gate.waitForArrivals(1)
        abandoned.cancel()
        await Self.assertCancelled(abandoned)

        let stillInFlight = await flight.isInFlight
        XCTAssertTrue(stillInFlight)

        let latecomer = Task { try await flight.run(operation) }
        await waitUntil("the latecomer is waiting") { await flight.waiterCount == 1 }
        await gate.open()
        let latecomerResult = try await latecomer.value
        XCTAssertEqual(latecomerResult, 100)

        let next = try await flight.run(operation)
        XCTAssertEqual(next, 200)
        let totalStarts = await starts.value
        XCTAssertEqual(totalStarts, 2)
    }

    /// - Given: a caller that is already cancelled
    /// - When: it calls `run`
    /// - Then:
    ///    - it throws `CancellationError`, and no operation is started
    func testAlreadyCancelledCallerStartsNothing() async {
        let flight = SingleFlight<Int>()
        let starts = Counter()
        let operation = Self.gatedOperation(starts: starts, gate: Gate(isOpen: true))

        let caller = Task { () async throws -> Int in
            withUnsafeCurrentTask { $0?.cancel() }
            return try await flight.run(operation)
        }
        await Self.assertCancelled(caller)

        let totalStarts = await starts.value
        XCTAssertEqual(totalStarts, 0)
        let inFlight = await flight.isInFlight
        XCTAssertFalse(inFlight)
    }
}
