//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

final class SessionRecordGateTests: XCTestCase {

    /// Records the order bodies ran in.
    private actor Order {
        private(set) var values: [Int] = []

        func append(_ value: Int) {
            values.append(value)
        }
    }

    /// Takes `gate` and keeps it until `latch` opens, reporting once it holds it.
    private func hold(_ gate: SessionRecordGate, until latch: Gate) -> Task<Void, Error> {
        Task {
            try await gate.withLock {
                await latch.pass()
            }
        }
    }

    /// - Given: a gate held by one caller, and five waiters queued one after another
    /// - When: the holder releases
    /// - Then:
    ///    - the waiters run one at a time, in the order they queued
    func testWaitersRunInFIFOOrder() async throws {
        let gate = SessionRecordGate()
        let latch = Gate()
        let holder = hold(gate, until: latch)
        await latch.waitForArrivals(1)

        let order = Order()
        var waiters: [Task<Void, Error>] = []
        for index in 1 ... 5 {
            waiters.append(Task {
                try await gate.withLock { await order.append(index) }
            })
            await waitUntil("waiter \(index) queues") { await gate.waiterCount == index }
        }

        await latch.open()
        try await holder.value
        for waiter in waiters {
            try await waiter.value
        }

        let ran = await order.values
        XCTAssertEqual(ran, [1, 2, 3, 4, 5])
        let isLocked = await gate.isLocked
        XCTAssertFalse(isLocked)
    }

    /// - Given: a gate held by one caller, and a waiter queued behind it
    /// - When: the waiter is cancelled
    /// - Then:
    ///    - it throws `CancellationError` without running its body, and leaves the queue
    ///    - the holder's release is not handed to it, so the gate is free afterwards
    func testCancelledWaiterIsRemovedFromTheQueue() async throws {
        let gate = SessionRecordGate()
        let latch = Gate()
        let holder = hold(gate, until: latch)
        await latch.waitForArrivals(1)

        let ran = Flag()
        let waiter = Task {
            try await gate.withLock { ran.raise() }
        }
        await waitUntil("the waiter queues") { await gate.waiterCount == 1 }

        waiter.cancel()
        await assertThrowsAsync({ try await waiter.value }) { error in
            XCTAssertTrue(error is CancellationError, "\(error)")
        }
        await waitUntil("the cancelled waiter leaves the queue") { await gate.waiterCount == 0 }

        await latch.open()
        try await holder.value
        XCTAssertFalse(ran.isRaised)
        let isLocked = await gate.isLocked
        XCTAssertFalse(isLocked)
        try await gate.withLock {}
    }

    /// The cancellation and the grant race: whichever lands first, the outcome must be the same.
    ///
    /// - Given: a gate held by one caller, and a waiter queued behind it
    /// - When: the holder cancels the waiter from inside its body, then releases at once
    /// - Then:
    ///    - the waiter throws `CancellationError` without running its body, whether it was still queued
    ///      or had just been granted the lock
    ///    - the gate ends free, so a later caller takes it
    func testWaiterGrantedWhileCancelledReleasesImmediately() async throws {
        let gate = SessionRecordGate()
        let latch = Gate()
        let ran = Flag()
        let queued = Gate()
        let waiterBox = TaskBox()

        let holder = Task {
            try await gate.withLock {
                await latch.pass()
                waiterBox.cancel()
            }
        }
        await latch.waitForArrivals(1)
        let waiter = Task {
            await queued.pass()
            try await gate.withLock { ran.raise() }
        }
        waiterBox.set(waiter)
        await queued.open()
        await waitUntil("the waiter queues") { await gate.waiterCount == 1 }

        await latch.open()
        try await holder.value

        await assertThrowsAsync({ try await waiter.value }) { error in
            XCTAssertTrue(error is CancellationError, "\(error)")
        }
        XCTAssertFalse(ran.isRaised)
        await waitUntil("the gate is released") { await !gate.isLocked }
        try await gate.withLock {}
    }

    /// - Given: a caller whose task is already cancelled
    /// - When: it asks for the gate
    /// - Then:
    ///    - it throws `CancellationError` without queueing or running its body
    func testAlreadyCancelledCallerNeverRunsItsBody() async throws {
        let gate = SessionRecordGate()
        let ran = Flag()
        let start = Gate()
        let caller = Task {
            await start.pass()
            try await gate.withLock { ran.raise() }
        }
        caller.cancel()
        await start.open()

        await assertThrowsAsync({ try await caller.value }) { error in
            XCTAssertTrue(error is CancellationError, "\(error)")
        }
        XCTAssertFalse(ran.isRaised)
        let isLocked = await gate.isLocked
        XCTAssertFalse(isLocked)
    }

    /// - Given: a body that throws
    /// - When: it runs under the gate
    /// - Then:
    ///    - the error reaches the caller and the gate is released
    func testThrowingBodyReleasesTheGate() async throws {
        let gate = SessionRecordGate()

        await assertThrowsAsync({ try await gate.withLock { throw FixtureError(description: "body failed") } }) { error in
            XCTAssertEqual((error as? FixtureError)?.description, "body failed")
        }

        let isLocked = await gate.isLocked
        XCTAssertFalse(isLocked)
    }

    /// Different sessions never wait on each other. Asserted by completion, not by timing: B finishes
    /// while A is still held, and A is only released afterwards.
    ///
    /// - Given: the gate table, and session A's gate held indefinitely
    /// - When: session B's gate is taken
    /// - Then:
    ///    - B's body runs to completion while A is still held
    func testHoldingOneRecordDoesNotDelayAnother() async throws {
        let gates = SessionRecordGates()
        let gateA = gates.gate(for: StorageFixtures.namespace, sessionId: try SessionID.named("a"))
        let gateB = gates.gate(for: StorageFixtures.namespace, sessionId: try SessionID.named("b"))
        let latch = Gate()
        let holder = hold(gateA, until: latch)
        await latch.waitForArrivals(1)

        let ranB = Flag()
        try await gateB.withLock { ranB.raise() }

        XCTAssertTrue(ranB.isRaised)
        let aStillHeld = await gateA.isLocked
        XCTAssertTrue(aStillHeld, "A was still held when B finished")
        await latch.open()
        try await holder.value
    }

    /// - Given: the gate table
    /// - When: a gate is requested twice for one record, once for another namespace and once for another
    ///   session, and then every gate is dropped
    /// - Then:
    ///    - the same record gets the same gate; the others get their own
    ///    - the table holds gates weakly and returns to empty once nobody holds them
    func testGateTableSharesPerRecordAndReturnsToBaseline() throws {
        let gates = SessionRecordGates()
        let work = try SessionID.named("work")
        let shared = SessionStorageNamespace(pools: StorageFixtures.pools, accessGroup: "group.shared")
        var first: SessionRecordGate? = gates.gate(for: StorageFixtures.namespace, sessionId: work)
        var second: SessionRecordGate? = gates.gate(for: StorageFixtures.namespace, sessionId: work)
        var otherNamespace: SessionRecordGate? = gates.gate(for: shared, sessionId: work)
        var otherSession: SessionRecordGate? = gates.gate(for: StorageFixtures.namespace, sessionId: .default)

        XCTAssertTrue(first === second)
        XCTAssertFalse(first === otherNamespace)
        XCTAssertFalse(first === otherSession)
        XCTAssertEqual(gates.liveGateCount, 3)

        first = nil
        second = nil
        otherNamespace = nil
        otherSession = nil
        XCTAssertEqual(gates.liveGateCount, 0)
        _ = (first, second, otherNamespace, otherSession)
    }

    // MARK: Several gates

    /// The one global order: by pool namespace, then by access group, no group first.
    ///
    /// - Given: namespaces over two user pools, each with no access group and two access groups, listed out of order
    /// - When: they are sorted by `order(_:)`
    /// - Then:
    ///    - the first pool's three come first, then the second's, each with no group, then the groups in order
    func testGateOrderIsByPoolNamespaceThenAccessGroup() {
        func namespace(_ poolId: String, _ accessGroup: String?) -> SessionStorageNamespace {
            SessionStorageNamespace(pools: .userPool(poolId), accessGroup: accessGroup)
        }
        let expected = [
            namespace("us-east-1_A", nil),
            namespace("us-east-1_A", "group.a"),
            namespace("us-east-1_A", "group.b"),
            namespace("us-east-1_B", nil),
            namespace("us-east-1_B", "group.a"),
            namespace("us-east-1_B", "group.b")
        ]
        let shuffled = [expected[4], expected[2], expected[3], expected[0], expected[5], expected[1]]

        let sorted = shuffled.sorted { SessionRecordGates.order($0) < SessionRecordGates.order($1) }

        XCTAssertEqual(sorted, expected)
    }

    /// Callers that hold several gates (a restore whose marker names another namespace, a static purge or sign-out)
    /// never deadlock only because every one takes them in the same order, whatever order it lists them in.
    ///
    /// - Given: five namespaces' gates for one session, and the third in the global order held from outside
    /// - When: `holding` is asked for all five, listed in reverse
    /// - Then:
    ///    - it waits on the third with exactly the first two taken and the last two free
    ///    - once the third is released, the body runs holding all five, and afterwards none is held
    func testHoldingTakesSeveralGatesInTheGlobalOrder() async throws {
        let gates = SessionRecordGates()
        let work = try SessionID.named("work")
        let namespaces = (1 ... 5).map {
            SessionStorageNamespace(pools: .userPool("us-east-1_Pool\($0)"), accessGroup: nil)
        }
        XCTAssertEqual(namespaces, namespaces.sorted { SessionRecordGates.order($0) < SessionRecordGates.order($1) })
        // Held for the whole test, so `holding` finds these same gates in the weak table.
        let held = namespaces.map { gates.gate(for: $0, sessionId: work) }
        let latch = Gate()
        let outside = hold(held[2], until: latch)
        await latch.waitForArrivals(1)

        let lockedInBody = Box<[Bool]>()
        let caller = Task {
            try await gates.holding(Array(namespaces.reversed()), sessionId: work) {
                var locked: [Bool] = []
                for gate in held {
                    await locked.append(gate.isLocked)
                }
                lockedInBody.set(locked)
            }
        }
        await waitUntil("the caller waits on the third gate") { await held[2].waiterCount == 1 }

        var locked: [Bool] = []
        for gate in held {
            await locked.append(gate.isLocked)
        }
        XCTAssertEqual(locked, [true, true, true, false, false], "only the gates before the held one are taken")

        await latch.open()
        try await outside.value
        try await caller.value
        XCTAssertEqual(lockedInBody.value, [true, true, true, true, true])
        for gate in held {
            let isLocked = await gate.isLocked
            XCTAssertFalse(isLocked)
        }
    }
}

/// A value set from a `@Sendable` closure and read afterwards.
private final class Box<Value: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var stored: Value?

    var value: Value? {
        lock.lock()
        defer { lock.unlock() }
        return stored
    }

    func set(_ value: Value) {
        lock.lock()
        stored = value
        lock.unlock()
    }
}

/// Lets a task be cancelled by code that runs before the task value exists.
private final class TaskBox: @unchecked Sendable {
    private let lock = NSLock()
    private var task: Task<Void, Error>?

    func set(_ task: Task<Void, Error>) {
        lock.lock()
        self.task = task
        lock.unlock()
    }

    func cancel() {
        lock.lock()
        let task = task
        lock.unlock()
        task?.cancel()
    }
}
