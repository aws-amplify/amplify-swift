//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(macOS) || os(visionOS)
import Foundation
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// Every test here asserts on who holds the lock, who was served, and what each caller received,
/// never on how long anything took. Flows are held in flight by a `Gate` the test opens, timeouts
/// fire when the test opens a gate standing in for the clock, and state that changes on another
/// task is awaited with the bounded `waitUntil`. Each test builds its own lock, so none of them
/// touches `SystemSheetLock.shared`.
final class SystemSheetLockTests: XCTestCase {

    private struct Failure: Error, Equatable {}

    private static let alice = try! SessionID.named("alice")
    private static let bob = try! SessionID.named("bob")
    private static let carol = try! SessionID.named("carol")
    private static let dave = try! SessionID.named("dave")

    /// Records the order in which flows ran their bodies.
    private actor Journal {
        private(set) var entries: [SessionID] = []

        func record(_ session: SessionID) {
            entries.append(session)
        }
    }

    /// Records whether a body saw its task cancelled.
    private actor CancellationProbe {
        private(set) var sawCancellation = false

        func record(_ cancelled: Bool) {
            sawCancellation = sawCancellation || cancelled
        }
    }

    /// Counts how many bodies are inside the lock at once, from any thread, under an `NSLock`.
    private final class OccupancyTally: @unchecked Sendable {
        private let lock = NSLock()
        private var current = 0
        private var peak = 0
        private var entries = 0

        func enter() {
            lock.lock()
            current += 1
            entries += 1
            peak = max(peak, current)
            lock.unlock()
        }

        func leave() {
            lock.lock()
            current -= 1
            lock.unlock()
        }

        var snapshot: (current: Int, peak: Int, entries: Int) {
            lock.lock()
            defer { lock.unlock() }
            return (current, peak, entries)
        }
    }

    /// A body that waits at `gate`, ignoring cancellation, then returns its holder.
    private static func heldBody(_ gate: Gate) -> @Sendable (BrowserLease) async throws -> SessionID {
        return { lease in
            await gate.pass()
            return lease.holder
        }
    }

    /// A body that waits at `gate` until the gate opens or the task is cancelled, then throws
    /// `CancellationError` if it was cancelled. The shape a real presenter has: cancelling it
    /// dismisses the browser.
    private static func cancellableBody(_ gate: Gate, probe: CancellationProbe) -> @Sendable (BrowserLease) async throws -> SessionID {
        return { lease in
            await withTaskCancellationHandler {
                await gate.pass()
            } onCancel: {
                Task { await gate.open() }
            }
            await probe.record(Task.isCancelled)
            try Task.checkCancellation()
            return lease.holder
        }
    }

    /// Starts `body` under the lock in a new task, after passing `gate` if one is given.
    ///
    /// A static helper rather than an inline `Task { }`, because Swift 6.3.2's region-based isolation
    /// checker rejects the inline form in these test methods ("pattern that the region-based
    /// isolation checker does not understand how to check").
    private static func start<T: Sendable>(
        _ lock: SystemSheetLock,
        _ session: SessionID,
        _ policy: WebUIOptions.BrowserBusyPolicy,
        after gate: Gate? = nil,
        waitsOnlyForItself: Bool = false,
        _ body: @escaping @Sendable (BrowserLease) async throws -> T
    ) -> Task<T, Error> {
        Task {
            await gate?.pass()
            return try await lock.withLease(for: session, policy: policy, waitsOnlyForItself: waitsOnlyForItself, body)
        }
    }

    private static func assertBrowserBusy(
        _ task: Task<SessionID, Error>,
        holder expected: SessionID,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            let value = try await task.value
            XCTFail("Expected browserBusy, got \(value)", file: file, line: line)
        } catch AuthClientError.browserBusy(let holder, _, _, _) {
            XCTAssertEqual(holder, expected, file: file, line: line)
        } catch {
            XCTFail("Expected browserBusy, got \(error)", file: file, line: line)
        }
    }

    private static func assertCancelled(
        _ task: Task<SessionID, Error>,
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

    // MARK: - Fail policy

    /// The default policy fails fast and names the session that holds the browser.
    ///
    /// - Given: alice holding the lock, her flow held in flight
    /// - When:
    ///    - bob asks for it with `.fail`
    /// - Then:
    ///    - bob throws `browserBusy(holder: alice)`, his body never runs, and alice still holds it
    ///    - once alice's flow finishes, the lock is free
    func testFailPolicyThrowsBrowserBusyNamingTheHolder() async throws {
        let lock = SystemSheetLock()
        let gate = Gate()
        let body = Self.heldBody(gate)
        let journal = Journal()

        let alice = Self.start(lock, Self.alice, .fail, body)
        await gate.waitForArrivals(1)

        let bob = Self.start(lock, Self.bob, .fail) { lease in
            await journal.record(lease.holder)
            return lease.holder
        }
        await Self.assertBrowserBusy(bob, holder: Self.alice)

        let holderWhileHeld = await lock.currentHolder
        XCTAssertEqual(holderWhileHeld, Self.alice)
        let journalEntries = await journal.entries
        XCTAssertEqual(journalEntries, [])

        await gate.open()
        let aliceResult = try await alice.value
        XCTAssertEqual(aliceResult, Self.alice)
        let holderAfter = await lock.currentHolder
        XCTAssertNil(holderAfter)
    }

    /// The error's text distinguishes a clash between sessions from a repeat call by one session.
    ///
    /// - Given: the `browserBusy` factory
    /// - When:
    ///    - it is built once for another session and once for the holder itself
    /// - Then:
    ///    - both carry the holder, and their descriptions differ
    func testBrowserBusyNamesTheHolderAndDistinguishesARepeatCall() {
        let clash = AuthClientError.browserBusy(heldBy: Self.alice, requestedBy: Self.bob)
        let repeated = AuthClientError.browserBusy(heldBy: Self.alice, requestedBy: Self.alice)

        guard case .browserBusy(let clashHolder, _, _, _) = clash,
              case .browserBusy(let repeatHolder, _, _, _) = repeated else {
            return XCTFail("Expected browserBusy, got \(clash) and \(repeated)")
        }
        XCTAssertEqual(clashHolder, Self.alice)
        XCTAssertEqual(repeatHolder, Self.alice)
        XCTAssertTrue(clash.errorDescription.contains("alice"))
        XCTAssertNotEqual(clash.errorDescription, repeated.errorDescription)
    }

    /// A session waiting on itself could only time out, so it is refused whatever the policy.
    ///
    /// - Given: alice holding the lock
    /// - When:
    ///    - alice asks again with `.waitWithoutBound`
    /// - Then:
    ///    - the second call throws `browserBusy(holder: alice)` without queueing
    func testSameSessionIsRefusedEvenWithTheWaitPolicy() async throws {
        let lock = SystemSheetLock()
        let gate = Gate()

        let first = Self.start(lock, Self.alice, .fail, Self.heldBody(gate))
        await gate.waitForArrivals(1)

        let second = Self.start(lock, Self.alice, .waitWithoutBound, Self.heldBody(gate))
        await Self.assertBrowserBusy(second, holder: Self.alice)
        let queued = await lock.waiterCount
        XCTAssertEqual(queued, 0)

        await gate.open()
        _ = try await first.value
    }

    /// A session queues at most once, so a double tap cannot line up a second browser.
    ///
    /// - Given: alice holding the lock, and bob queued behind her with `.wait`
    /// - When:
    ///    - bob asks again, once with `.wait` and once with `.fail`, and alice's flow then finishes
    /// - Then:
    ///    - both repeat calls throw `browserBusy(holder: alice)`, and only one bob is ever queued
    ///    - bob's first call is served, and his body runs exactly once
    func testSessionAlreadyQueuedIsRefused() async throws {
        let lock = SystemSheetLock()
        let gate = Gate()
        let journal = Journal()
        let recordingBody: @Sendable (BrowserLease) async throws -> SessionID = { lease in
            await journal.record(lease.holder)
            return lease.holder
        }

        let alice = Self.start(lock, Self.alice, .fail, Self.heldBody(gate))
        await gate.waitForArrivals(1)
        let bob = Self.start(lock, Self.bob, .wait(timeout: 3_600), recordingBody)
        await waitUntil("bob is queued") { await lock.waiterCount == 1 }

        let bobAgainWaiting = Self.start(lock, Self.bob, .wait(timeout: 3_600), recordingBody)
        await Self.assertBrowserBusy(bobAgainWaiting, holder: Self.alice)
        let bobAgainFailing = Self.start(lock, Self.bob, .fail, recordingBody)
        await Self.assertBrowserBusy(bobAgainFailing, holder: Self.alice)
        let queued = await lock.waiterCount
        XCTAssertEqual(queued, 1)

        await gate.open()
        _ = try await alice.value
        let bobResult = try await bob.value
        XCTAssertEqual(bobResult, Self.bob)
        let journalEntries = await journal.entries
        XCTAssertEqual(journalEntries, [Self.bob])
    }

    /// The repeat-call message names the queued session, and every reason reads differently.
    ///
    /// - Given: the five `browserBusy` reasons
    /// - When:
    ///    - each is built for holder alice and requester bob
    /// - Then:
    ///    - all carry alice as the holder, the queued and timed-out ones name bob, the five messages differ,
    ///      and none names a browser sign-in, since the sheet may be a passkey sheet or a sign-out page
    func testAlreadyQueuedMessageNamesTheQueuedSession() {
        let reasons: [BrowserBusyReason] = [.heldByAnotherSession, .alreadyInFlight, .alreadyQueued, .stillClosing, .timedOut]
        let errors = reasons.map { AuthClientError.browserBusy(heldBy: Self.alice, requestedBy: Self.bob, reason: $0) }

        for error in errors {
            guard case .browserBusy(let holder, _, _, _) = error else {
                return XCTFail("Expected browserBusy, got \(error)")
            }
            XCTAssertEqual(holder, Self.alice)
        }
        XCTAssertTrue(errors[2].errorDescription.contains("bob"))
        XCTAssertTrue(errors[4].errorDescription.contains("bob"))
        XCTAssertEqual(Set(errors.map(\.errorDescription)).count, 5)
        for error in errors {
            XCTAssertFalse(error.errorDescription.contains("sign-in"), error.errorDescription)
            XCTAssertFalse(error.errorDescription.contains("browser"), error.errorDescription)
        }
    }

    /// A non-positive timeout does not queue.
    ///
    /// - Given: alice holding the lock
    /// - When:
    ///    - bob asks with `.wait(timeout: 0)`
    /// - Then:
    ///    - bob throws `browserBusy(holder: alice)` and nothing is queued
    func testZeroTimeoutBehavesAsFail() async throws {
        let lock = SystemSheetLock()
        let gate = Gate()

        let alice = Self.start(lock, Self.alice, .fail, Self.heldBody(gate))
        await gate.waitForArrivals(1)

        let bob = Self.start(lock, Self.bob, .wait(timeout: 0), Self.heldBody(gate))
        await Self.assertBrowserBusy(bob, holder: Self.alice)
        let queued = await lock.waiterCount
        XCTAssertEqual(queued, 0)

        await gate.open()
        _ = try await alice.value
    }

    // MARK: - Wait policy

    /// Waiters are served first come first served.
    ///
    /// - Given: alice holding the lock
    /// - When:
    ///    - bob, carol and dave queue with `.wait`, one after another, and alice's flow then finishes
    /// - Then:
    ///    - their bodies run in the order bob, carol, dave, and the lock ends free
    func testWaitPolicyServesWaitersFirstInFirstOut() async throws {
        let lock = SystemSheetLock()
        let gate = Gate()
        let journal = Journal()
        let recordingBody: @Sendable (BrowserLease) async throws -> SessionID = { lease in
            await journal.record(lease.holder)
            return lease.holder
        }

        let alice = Self.start(lock, Self.alice, .fail, Self.heldBody(gate))
        await gate.waitForArrivals(1)

        var waiters: [Task<SessionID, Error>] = []
        for (index, session) in [Self.bob, Self.carol, Self.dave].enumerated() {
            waiters.append(Self.start(lock, session, .wait(timeout: 3_600), recordingBody))
            // Each joins the queue before the next is started, so the arrival order is fixed.
            await waitUntil("\(session) is queued") { await lock.waiterCount == index + 1 }
        }

        await gate.open()
        _ = try await alice.value
        for waiter in waiters {
            _ = try await waiter.value
        }

        // The journal is written from inside each body, so its order is the order the lock granted.
        let journalEntries = await journal.entries
        XCTAssertEqual(journalEntries, [Self.bob, Self.carol, Self.dave])
        let holderAfter = await lock.currentHolder
        XCTAssertNil(holderAfter)
    }

    /// A waiter whose timeout expires fails with the holder's name and leaves the queue.
    ///
    /// - Given: a lock whose timeouts fire when the test opens `clock`, and alice holding it
    /// - When:
    ///    - bob queues with `.wait(timeout: 60)`, and his timeout then fires
    /// - Then:
    ///    - bob throws `browserBusy(holder: alice)` with the timed-out text, which says he waited until his
    ///      timeout; the queue is empty, and alice still holds the lock
    func testWaitTimeoutThrowsBrowserBusyAndLeavesTheQueue() async throws {
        let clock = Gate()
        let lock = SystemSheetLock(sleep: { _ in await clock.pass() })
        let gate = Gate()

        let alice = Self.start(lock, Self.alice, .fail, Self.heldBody(gate))
        await gate.waitForArrivals(1)

        let bob = Self.start(lock, Self.bob, .wait(timeout: 60), Self.heldBody(gate))
        await clock.waitForArrivals(1)
        await clock.open()

        await Self.assertBrowserBusy(bob, holder: Self.alice)
        do {
            _ = try await bob.value
            XCTFail("Expected browserBusy")
        } catch let error as AuthClientError {
            let timedOut = AuthClientError.browserBusy(heldBy: Self.alice, requestedBy: Self.bob, reason: .timedOut)
            XCTAssertEqual(error.errorDescription, timedOut.errorDescription)
            XCTAssertTrue(error.errorDescription.contains("until its timeout"), error.errorDescription)
        } catch {
            XCTFail("Expected browserBusy, got \(error)")
        }
        let queued = await lock.waiterCount
        XCTAssertEqual(queued, 0)
        let holder = await lock.currentHolder
        XCTAssertEqual(holder, Self.alice)

        await gate.open()
        _ = try await alice.value
    }

    // MARK: - Cancellation

    /// A cancelled waiter leaves the queue without ever taking the lock, and does not hold up the
    /// waiter behind it.
    ///
    /// - Given: alice holding the lock, with bob and then carol queued behind her
    /// - When:
    ///    - bob's task is cancelled, and alice's flow then finishes
    /// - Then:
    ///    - bob throws `CancellationError` while alice still holds the lock, and his body never runs
    ///    - carol is served next, and the lock ends free
    func testCancellingAWaiterLeavesTheQueueWithoutTakingTheLock() async throws {
        let lock = SystemSheetLock()
        let gate = Gate()
        let journal = Journal()
        let recordingBody: @Sendable (BrowserLease) async throws -> SessionID = { lease in
            await journal.record(lease.holder)
            return lease.holder
        }

        let alice = Self.start(lock, Self.alice, .fail, Self.heldBody(gate))
        await gate.waitForArrivals(1)
        let bob = Self.start(lock, Self.bob, .waitWithoutBound, recordingBody)
        await waitUntil("bob is queued") { await lock.waiterCount == 1 }
        let carol = Self.start(lock, Self.carol, .waitWithoutBound, recordingBody)
        await waitUntil("carol is queued") { await lock.waiterCount == 2 }

        bob.cancel()
        await Self.assertCancelled(bob)
        await waitUntil("bob has left the queue") { await lock.waiterCount == 1 }
        let holderAfterCancel = await lock.currentHolder
        XCTAssertEqual(holderAfterCancel, Self.alice)

        await gate.open()
        _ = try await alice.value
        let carolResult = try await carol.value
        XCTAssertEqual(carolResult, Self.carol)

        let journalEntries = await journal.entries
        XCTAssertEqual(journalEntries, [Self.carol])
        let holderAfter = await lock.currentHolder
        XCTAssertNil(holderAfter)
    }

    /// A caller that is already cancelled takes nothing.
    ///
    /// - Given: a free lock and a task that is cancelled before it asks
    /// - When:
    ///    - the task calls `withLease`
    /// - Then:
    ///    - it throws `CancellationError`, its body never runs, and the lock stays free
    func testAlreadyCancelledCallerTakesNothing() async throws {
        let lock = SystemSheetLock()
        let journal = Journal()
        let start = Gate()

        let task = Self.start(lock, Self.alice, .fail, after: start) { lease in
            await journal.record(lease.holder)
            return lease.holder
        }
        await start.waitForArrivals(1)
        task.cancel()
        await start.open()

        await Self.assertCancelled(task)
        let journalEntries = await journal.entries
        XCTAssertEqual(journalEntries, [])
        let holder = await lock.currentHolder
        XCTAssertNil(holder)
    }

    /// Cancelling the holder answers its caller at once, cancels its flow, and releases the lock once
    /// the flow has unwound.
    ///
    /// - Given: alice holding the lock with a flow that stops when cancelled, and bob queued
    /// - When:
    ///    - alice's task is cancelled
    /// - Then:
    ///    - alice throws `CancellationError` and her flow saw the cancellation
    ///    - bob is then served
    func testCancellingTheHolderCancelsItsFlowAndPassesTheLockOn() async throws {
        let lock = SystemSheetLock()
        let gate = Gate()
        let probe = CancellationProbe()

        let alice = Self.start(lock, Self.alice, .fail, Self.cancellableBody(gate, probe: probe))
        await gate.waitForArrivals(1)
        let bob = Self.start(lock, Self.bob, .waitWithoutBound) { $0.holder }
        await waitUntil("bob is queued") { await lock.waiterCount == 1 }

        alice.cancel()
        await Self.assertCancelled(alice)

        let bobResult = try await bob.value
        XCTAssertEqual(bobResult, Self.bob)
        let sawCancellation = await probe.sawCancellation
        XCTAssertTrue(sawCancellation)
        let holder = await lock.currentHolder
        XCTAssertNil(holder)
    }

    /// A cancelled holder's caller returns straight away, but the lock stays held until the flow has
    /// actually finished, so the next browser never presents over one still being dismissed.
    ///
    /// - Given: alice holding the lock with a flow that ignores cancellation, held at a gate
    /// - When:
    ///    - alice's task is cancelled, and the gate is later opened
    /// - Then:
    ///    - alice throws `CancellationError` while the gate is still closed, and alice still holds the lock
    ///    - once the flow finishes, the lock is free
    func testCancelledHolderKeepsTheLockUntilItsFlowUnwinds() async throws {
        let lock = SystemSheetLock()
        let gate = Gate()

        let alice = Self.start(lock, Self.alice, .fail, Self.heldBody(gate))
        await gate.waitForArrivals(1)

        alice.cancel()
        await Self.assertCancelled(alice)
        let holderWhileUnwinding = await lock.currentHolder
        XCTAssertEqual(holderWhileUnwinding, Self.alice)

        await gate.open()
        await waitUntil("the lock is released once the flow finishes") { await lock.currentHolder == nil }
    }

    /// "Cancel, then Sign in again": the same session may queue behind its own closing browser.
    ///
    /// - Given: alice holding the lock with a flow that ignores cancellation, held at a gate
    /// - When:
    ///    - `cancel(for: alice)` is called, then alice retries with `.fail`, then with `.wait`, and
    ///      the old flow is then allowed to finish
    /// - Then:
    ///    - the first call throws `CancellationError` at once
    ///    - the `.fail` retry throws `browserBusy(holder: alice)` with the "still closing" message
    ///    - the `.wait` retry queues, and runs its body once the old flow has unwound
    func testCancelledHolderCanQueueItsOwnRetryWhileClosing() async throws {
        let lock = SystemSheetLock()
        let closing = Gate()
        let journal = Journal()

        let first = Self.start(lock, Self.alice, .fail, Self.heldBody(closing))
        await closing.waitForArrivals(1)
        await lock.cancel(for: Self.alice)
        await Self.assertCancelled(first)

        let failingRetry = Self.start(lock, Self.alice, .fail) { $0.holder }
        do {
            let value = try await failingRetry.value
            XCTFail("Expected browserBusy, got \(value)")
        } catch let error as AuthClientError {
            let closingError = AuthClientError.browserBusy(heldBy: Self.alice, requestedBy: Self.alice, reason: .stillClosing)
            XCTAssertEqual(error.errorDescription, closingError.errorDescription)
        }

        let waitingRetry = Self.start(lock, Self.alice, .wait(timeout: 3_600)) { lease in
            await journal.record(lease.holder)
            return lease.holder
        }
        await waitUntil("the retry is queued behind the closing flow") { await lock.waiterCount == 1 }
        let journalWhileClosing = await journal.entries
        XCTAssertEqual(journalWhileClosing, [])

        await closing.open()
        let retryResult = try await waitingRetry.value
        XCTAssertEqual(retryResult, Self.alice)
        let journalEntries = await journal.entries
        XCTAssertEqual(journalEntries, [Self.alice])
        let holder = await lock.currentHolder
        XCTAssertNil(holder)
    }

    /// A holder whose own caller was cancelled is closing too, so its retry may queue.
    ///
    /// - Given: alice holding the lock with a flow that ignores cancellation, held at a gate
    /// - When:
    ///    - alice's task is cancelled, and she retries at once with `.wait`
    /// - Then:
    ///    - the retry queues rather than throwing, and is served once the old flow finishes
    func testCallerCancellationAlsoLetsTheRetryQueue() async throws {
        let lock = SystemSheetLock()
        let closing = Gate()

        let first = Self.start(lock, Self.alice, .fail, Self.heldBody(closing))
        await closing.waitForArrivals(1)
        first.cancel()
        await Self.assertCancelled(first)

        let retry = Self.start(lock, Self.alice, .wait(timeout: 3_600)) { $0.holder }
        await waitUntil("the retry is queued") { await lock.waiterCount == 1 }

        await closing.open()
        let retryResult = try await retry.value
        XCTAssertEqual(retryResult, Self.alice)
    }

    /// `waitsOnlyForItself` queues behind the session's own closing sheet, as a plain `.wait` does.
    ///
    /// - Given: alice holding the lock with a flow held at a gate, then cancelled, so it is closing
    /// - When:
    ///    - alice asks again with `.wait` and `waitsOnlyForItself`, and the old flow then unwinds
    /// - Then:
    ///    - the retry queues while the old flow closes, and is served once it has unwound
    func testWaitingOnlyForItselfQueuesBehindItsOwnClosingSheet() async throws {
        let lock = SystemSheetLock()
        let closing = Gate()

        let first = Self.start(lock, Self.alice, .fail, Self.heldBody(closing))
        await closing.waitForArrivals(1)
        await lock.cancel(for: Self.alice)
        await Self.assertCancelled(first)

        let retry = Self.start(lock, Self.alice, .wait(timeout: 3_600), waitsOnlyForItself: true) { $0.holder }
        await waitUntil("the retry is queued behind the closing flow") { await lock.waiterCount == 1 }

        await closing.open()
        let retryResult = try await retry.value
        XCTAssertEqual(retryResult, Self.alice)
        let holder = await lock.currentHolder
        XCTAssertNil(holder)
    }

    /// `waitsOnlyForItself` never queues behind another session's sheet.
    ///
    /// - Given: alice holding the lock, and a lock whose waits would fail the test if they started a timer
    /// - When:
    ///    - bob asks for it with `.wait` and `waitsOnlyForItself`
    /// - Then:
    ///    - bob throws `browserBusy(holder: alice)` at once, saying another session holds it; nothing is queued
    func testWaitingOnlyForItselfIsRefusedAtOnceByAnotherSession() async throws {
        let lock = SystemSheetLock(sleep: { _ in XCTFail("bob queued behind another session") })
        let gate = Gate()

        let alice = Self.start(lock, Self.alice, .fail, Self.heldBody(gate))
        await gate.waitForArrivals(1)

        let bob = Self.start(lock, Self.bob, .wait(timeout: 3_600), waitsOnlyForItself: true) { $0.holder }
        do {
            let value = try await bob.value
            XCTFail("Expected browserBusy, got \(value)")
        } catch let error as AuthClientError {
            let expected = AuthClientError.browserBusy(heldBy: Self.alice, requestedBy: Self.bob, reason: .heldByAnotherSession)
            XCTAssertEqual(error.kind, .browserBusy(holder: Self.alice))
            XCTAssertEqual(error.errorDescription, expected.errorDescription)
        }
        let waiters = await lock.waiterCount
        XCTAssertEqual(waiters, 0)

        await gate.open()
        _ = try await alice.value
    }

    /// A waiter that waits only for its own closing sheet is refused once the lock passes to another session
    /// queued ahead of it; plain waiters are left queued.
    ///
    /// - Given: alice holding the lock with a flow held at a gate, bob queued behind her with a plain `.wait`,
    ///   alice cancelled and queued again with `waitsOnlyForItself`, then carol queued with a plain `.wait`, and a
    ///   lock whose waits time out only when the test is long over
    /// - When:
    ///    - alice's old flow unwinds, so the lock passes to bob
    /// - Then:
    ///    - alice's retry throws `browserBusy(holder: bob)` at once, saying another session holds it
    ///    - carol stays queued, and is served once bob has finished
    func testWaitingOnlyForItselfIsRefusedWhenTheLockPassesToAnotherSession() async throws {
        let lock = SystemSheetLock(sleep: { _ in try await Task.sleep(nanoseconds: 3_600_000_000_000) })
        let closing = Gate()
        let bobGate = Gate()

        let first = Self.start(lock, Self.alice, .fail, Self.heldBody(closing))
        await closing.waitForArrivals(1)
        let bob = Self.start(lock, Self.bob, .wait(timeout: 3_600), Self.heldBody(bobGate))
        await waitUntil("bob is queued") { await lock.waiterCount == 1 }
        await lock.cancel(for: Self.alice)
        await Self.assertCancelled(first)
        let retry = Self.start(lock, Self.alice, .wait(timeout: 3_600), waitsOnlyForItself: true) { $0.holder }
        await waitUntil("alice's retry is queued") { await lock.waiterCount == 2 }
        let carol = Self.start(lock, Self.carol, .wait(timeout: 3_600)) { $0.holder }
        await waitUntil("carol is queued") { await lock.waiterCount == 3 }

        await closing.open()
        do {
            let value = try await retry.value(within: 10)
            XCTFail("Expected browserBusy, got \(value)")
        } catch let error as AuthClientError {
            let expected = AuthClientError.browserBusy(heldBy: Self.bob, requestedBy: Self.alice, reason: .heldByAnotherSession)
            XCTAssertEqual(error.kind, .browserBusy(holder: Self.bob))
            XCTAssertEqual(error.errorDescription, expected.errorDescription)
        }
        await bobGate.waitForArrivals(1)
        let holder = await lock.currentHolder
        XCTAssertEqual(holder, Self.bob)
        let waiters = await lock.waiterCount
        XCTAssertEqual(waiters, 1)

        await bobGate.open()
        let bobResult = try await bob.value
        XCTAssertEqual(bobResult, Self.bob)
        let carolResult = try await carol.value
        XCTAssertEqual(carolResult, Self.carol)
    }

    /// A result that arrives after an interrupt is discarded, so a caller that commits only what
    /// `withLease` returns never commits a cancelled sign-in.
    ///
    /// - Given: alice's caller, which commits what `withLease` returns, and a flow that ignores
    ///   cancellation and then succeeds
    /// - When:
    ///    - `cancel(for: alice)` is called, and the flow is then allowed to finish successfully
    /// - Then:
    ///    - the caller throws `CancellationError` and commits nothing
    ///    - the flow did finish, and the lock is released
    func testLateSuccessAfterInterruptIsNeverReturned() async throws {
        let lock = SystemSheetLock()
        let gate = Gate()
        let finished = Journal()
        let committed = Journal()

        let caller = Self.start(lock, Self.alice, .fail) { lease -> SessionID in
            await gate.pass()
            await finished.record(lease.holder)
            return lease.holder
        }
        let committer = Task {
            let tokens = try await caller.value
            await committed.record(tokens)
        }
        await gate.waitForArrivals(1)

        await lock.cancel(for: Self.alice)
        do {
            try await committer.value
            XCTFail("Expected CancellationError")
        } catch {
            XCTAssertTrue(error is CancellationError, "Expected CancellationError, got \(error)")
        }

        await gate.open()
        await waitUntil("the flow finishes and releases") { await lock.currentHolder == nil }
        let finishedEntries = await finished.entries
        XCTAssertEqual(finishedEntries, [Self.alice])
        let committedEntries = await committed.entries
        XCTAssertEqual(committedEntries, [])
    }

    /// `cancel(for:)` stops a session's flow if it holds the lock, and removes it if it is queued.
    ///
    /// - Given: alice holding the lock with a flow that stops when cancelled, and bob then carol queued
    /// - When:
    ///    - `cancel(for: bob)` is called, then `cancel(for: alice)`, then `cancel(for: dave)`, who has
    ///      no sign-in
    /// - Then:
    ///    - bob throws `CancellationError` and leaves the queue while alice still holds the lock
    ///    - alice throws `CancellationError`, her flow saw the cancellation, and carol is then served
    ///    - cancelling dave changes nothing
    func testCancelForSessionStopsItsFlowOrItsWait() async throws {
        let lock = SystemSheetLock()
        let gate = Gate()
        let probe = CancellationProbe()

        let alice = Self.start(lock, Self.alice, .fail, Self.cancellableBody(gate, probe: probe))
        await gate.waitForArrivals(1)
        let bob = Self.start(lock, Self.bob, .waitWithoutBound) { $0.holder }
        await waitUntil("bob is queued") { await lock.waiterCount == 1 }
        let carol = Self.start(lock, Self.carol, .waitWithoutBound) { $0.holder }
        await waitUntil("carol is queued") { await lock.waiterCount == 2 }

        await lock.cancel(for: Self.bob)
        await Self.assertCancelled(bob)
        let queuedAfterBob = await lock.waiterCount
        XCTAssertEqual(queuedAfterBob, 1)
        let holderAfterBob = await lock.currentHolder
        XCTAssertEqual(holderAfterBob, Self.alice)

        await lock.cancel(for: Self.alice)
        await Self.assertCancelled(alice)
        let carolResult = try await carol.value
        XCTAssertEqual(carolResult, Self.carol)
        let sawCancellation = await probe.sawCancellation
        XCTAssertTrue(sawCancellation)

        await lock.cancel(for: Self.dave)
        let holder = await lock.currentHolder
        XCTAssertNil(holder)
        let queued = await lock.waiterCount
        XCTAssertEqual(queued, 0)
    }

    // MARK: - Release

    /// A throwing flow releases the lock, and its error reaches the caller unchanged.
    ///
    /// - Given: a free lock
    /// - When:
    ///    - alice's flow throws, and bob then asks with `.fail`
    /// - Then:
    ///    - alice receives the flow's error, the lock is free, and bob acquires it
    func testLockIsReleasedWhenTheFlowThrows() async throws {
        let lock = SystemSheetLock()

        do {
            _ = try await lock.withLease(for: Self.alice, policy: .fail) { _ -> SessionID in
                throw Failure()
            }
            XCTFail("Expected the flow's error")
        } catch {
            XCTAssertEqual(error as? Failure, Failure())
        }
        let holderAfterThrow = await lock.currentHolder
        XCTAssertNil(holderAfterThrow)

        let bob = try await lock.withLease(for: Self.bob, policy: .fail) { $0.holder }
        XCTAssertEqual(bob, Self.bob)
    }

    /// A succeeding flow returns its value and releases the lock, and the holder is visible meanwhile.
    ///
    /// - Given: a free lock
    /// - When:
    ///    - alice runs a flow that reads the lock's holder
    /// - Then:
    ///    - the flow saw alice as the holder, alice receives its value, and the lock is free afterwards
    func testLockIsReleasedWhenTheFlowSucceeds() async throws {
        let lock = SystemSheetLock()

        let seen = try await lock.withLease(for: Self.alice, policy: .fail) { _ in
            await lock.currentHolder
        }

        XCTAssertEqual(seen, Self.alice)
        let holder = await lock.currentHolder
        XCTAssertNil(holder)
    }

    // MARK: - Reset

    /// `reset()` frees a lock whose flow never finishes, answers that flow's caller, and hands the
    /// lock to the first waiter. The stale flow finishing later does not release the new holder.
    ///
    /// - Given: alice holding the lock with a flow that ignores cancellation and never returns until
    ///   the test lets it, and bob queued behind her holding his own flow
    /// - When:
    ///    - `reset()` is called, and later alice's stale flow is allowed to finish
    /// - Then:
    ///    - `reset()` returns alice, alice throws `CancellationError`, and bob holds the lock at once
    ///    - after alice's flow finishes, bob still holds the lock
    func testResetFreesAWedgedHolderAndPassesTheLockOn() async throws {
        let lock = SystemSheetLock()
        let wedged = Gate()
        let bobGate = Gate()

        let alice = Self.start(lock, Self.alice, .fail, Self.heldBody(wedged))
        await wedged.waitForArrivals(1)
        let bob = Self.start(lock, Self.bob, .waitWithoutBound, Self.heldBody(bobGate))
        await waitUntil("bob is queued") { await lock.waiterCount == 1 }

        let previous = await lock.reset()
        XCTAssertEqual(previous, Self.alice)
        await Self.assertCancelled(alice)
        let holderAfterReset = await lock.currentHolder
        XCTAssertEqual(holderAfterReset, Self.bob)
        await bobGate.waitForArrivals(1)

        await wedged.open()
        await waitUntil("alice's stale flow has finished and released") { await lock.ignoredReleaseCount == 1 }
        let holderAfterStaleFinish = await lock.currentHolder
        XCTAssertEqual(holderAfterStaleFinish, Self.bob)

        await bobGate.open()
        let bobResult = try await bob.value
        XCTAssertEqual(bobResult, Self.bob)
        let holder = await lock.currentHolder
        XCTAssertNil(holder)
    }

    /// `reset()` with nobody queued leaves the lock free, and a later sign-in succeeds.
    ///
    /// - Given: alice holding the lock with a flow that never finishes until the test lets it
    /// - When:
    ///    - `reset()` is called, then bob asks with `.fail`, then `reset()` is called on the free lock
    /// - Then:
    ///    - the first reset returns alice and bob acquires the lock; the second returns `nil`
    func testResetLeavesTheLockFreeAndIsANoOpWhenFree() async throws {
        let lock = SystemSheetLock()
        let wedged = Gate()

        let alice = Self.start(lock, Self.alice, .fail, Self.heldBody(wedged))
        await wedged.waitForArrivals(1)

        let previous = await lock.reset()
        XCTAssertEqual(previous, Self.alice)
        await Self.assertCancelled(alice)

        let bob = try await lock.withLease(for: Self.bob, policy: .fail) { $0.holder }
        XCTAssertEqual(bob, Self.bob)

        let resetWhenFree = await lock.reset()
        XCTAssertNil(resetWhenFree)
        await wedged.open()
    }

    // MARK: - Race windows

    /// A seam that holds only `session`'s caller at `gate`, and lets every other caller through.
    private static func holding(_ session: SessionID, at gate: Gate) -> SystemSheetLock.Seam {
        return { lease in
            if lease.holder == session {
                await gate.pass()
            }
        }
    }

    /// `cancel(for:)` between grant and registration is not lost: the flow stops when it registers.
    ///
    /// - Given: alice granted the lock and held between grant and registration
    /// - When:
    ///    - `cancel(for: alice)` is called, and alice is then let through
    /// - Then:
    ///    - alice throws `CancellationError`, her body never runs, and the lock is free
    func testCancelBetweenGrantAndRegistrationStopsTheFlow() async throws {
        let seam = Gate()
        let lock = SystemSheetLock(afterAcquire: Self.holding(Self.alice, at: seam))
        let journal = Journal()

        let alice = Self.start(lock, Self.alice, .fail) { lease in
            await journal.record(lease.holder)
            return lease.holder
        }
        await seam.waitForArrivals(1)
        await lock.cancel(for: Self.alice)
        await seam.open()

        await Self.assertCancelled(alice)
        let journalEntries = await journal.entries
        XCTAssertEqual(journalEntries, [])
        let holder = await lock.currentHolder
        XCTAssertNil(holder)
    }

    /// `reset()` between grant and registration hands the lock on, and the reset caller stops.
    ///
    /// - Given: alice granted the lock and held between grant and registration, and bob queued
    /// - When:
    ///    - `reset()` is called, and alice is then let through
    /// - Then:
    ///    - `reset()` returns alice and bob holds the lock at once
    ///    - alice throws `CancellationError` without running her body, and her release is ignored
    ///    - bob is served
    func testResetBetweenGrantAndRegistrationHandsTheLockOn() async throws {
        let seam = Gate()
        let lock = SystemSheetLock(afterAcquire: Self.holding(Self.alice, at: seam))
        let journal = Journal()
        let recordingBody: @Sendable (BrowserLease) async throws -> SessionID = { lease in
            await journal.record(lease.holder)
            return lease.holder
        }
        let bobGate = Gate()

        let alice = Self.start(lock, Self.alice, .fail, recordingBody)
        await seam.waitForArrivals(1)
        let bob = Self.start(lock, Self.bob, .waitWithoutBound, Self.heldBody(bobGate))
        await waitUntil("bob is queued") { await lock.waiterCount == 1 }

        let previous = await lock.reset()
        XCTAssertEqual(previous, Self.alice)
        let holderAfterReset = await lock.currentHolder
        XCTAssertEqual(holderAfterReset, Self.bob)

        await seam.open()
        await Self.assertCancelled(alice)
        let journalEntries = await journal.entries
        XCTAssertEqual(journalEntries, [])
        let ignoredReleases = await lock.ignoredReleaseCount
        XCTAssertEqual(ignoredReleases, 1)
        let holderAfterStaleRelease = await lock.currentHolder
        XCTAssertEqual(holderAfterStaleRelease, Self.bob)

        await bobGate.open()
        let bobResult = try await bob.value
        XCTAssertEqual(bobResult, Self.bob)
    }

    /// An interrupt that lands after registration but before the body starts skips the body.
    ///
    /// - Given: alice registered with the lock and held before her body starts
    /// - When:
    ///    - `cancel(for: alice)` is called, and alice is then let through
    /// - Then:
    ///    - alice throws `CancellationError`, her body never runs, and the lock is released
    func testInterruptBeforeTheBodyStartsSkipsTheBody() async throws {
        let seam = Gate()
        let lock = SystemSheetLock(afterAttach: Self.holding(Self.alice, at: seam))
        let journal = Journal()

        let alice = Self.start(lock, Self.alice, .fail) { lease in
            await journal.record(lease.holder)
            return lease.holder
        }
        await seam.waitForArrivals(1)
        await lock.cancel(for: Self.alice)
        await seam.open()

        await Self.assertCancelled(alice)
        await waitUntil("the skipped flow releases") { await lock.currentHolder == nil }
        let journalEntries = await journal.entries
        XCTAssertEqual(journalEntries, [])
    }

    /// The `beforeAcquire` seam holds a caller before it asks for the lock, so a test can hand the lock to someone
    /// else at that moment.
    ///
    /// - Given: alice held at `beforeAcquire`, as she calls `withLease` with `.fail`
    /// - When:
    ///    - bob takes the lock meanwhile, and alice is then let through
    /// - Then:
    ///    - the lock was free while alice was held: she had not asked for it yet
    ///    - alice throws `browserBusy(holder: bob)` and her body never runs; bob's flow is untouched
    func testBeforeAcquireHoldsTheCallerBeforeItAsks() async throws {
        let seam = Gate()
        let lock = SystemSheetLock(beforeAcquire: { session in
            if session == Self.alice {
                await seam.pass()
            }
        })
        let journal = Journal()

        let alice = Self.start(lock, Self.alice, .fail) { lease in
            await journal.record(lease.holder)
            return lease.holder
        }
        await seam.waitForArrivals(1)
        let holderWhileHeld = await lock.currentHolder
        XCTAssertNil(holderWhileHeld)
        let bobGate = Gate()
        let bob = Self.start(lock, Self.bob, .fail, Self.heldBody(bobGate))
        await bobGate.waitForArrivals(1)
        await seam.open()

        await Self.assertBrowserBusy(alice, holder: Self.bob)
        let journalEntries = await journal.entries
        XCTAssertEqual(journalEntries, [])
        await bobGate.open()
        let bobResult = try await bob.value
        XCTAssertEqual(bobResult, Self.bob)
    }

    /// A waiter granted the lock just as its task is cancelled gives it up without running its body.
    ///
    /// - Given: alice holding the lock, with bob then carol queued, and bob to be held right after
    ///   his grant
    /// - When:
    ///    - alice's flow finishes, so bob is granted; bob's task is cancelled; bob is let through
    /// - Then:
    ///    - bob throws `CancellationError` and his body never runs
    ///    - carol is served next
    func testWaiterGrantedAsItIsCancelledGivesTheLockUp() async throws {
        let seam = Gate()
        let lock = SystemSheetLock(afterAcquire: Self.holding(Self.bob, at: seam))
        let gate = Gate()
        let journal = Journal()
        let recordingBody: @Sendable (BrowserLease) async throws -> SessionID = { lease in
            await journal.record(lease.holder)
            return lease.holder
        }

        let alice = Self.start(lock, Self.alice, .fail, Self.heldBody(gate))
        await gate.waitForArrivals(1)
        let bob = Self.start(lock, Self.bob, .waitWithoutBound, recordingBody)
        await waitUntil("bob is queued") { await lock.waiterCount == 1 }
        let carol = Self.start(lock, Self.carol, .waitWithoutBound, recordingBody)
        await waitUntil("carol is queued") { await lock.waiterCount == 2 }

        await gate.open()
        _ = try await alice.value
        await seam.waitForArrivals(1)
        let holderAtGrant = await lock.currentHolder
        XCTAssertEqual(holderAtGrant, Self.bob)
        bob.cancel()
        await seam.open()

        await Self.assertCancelled(bob)
        let carolResult = try await carol.value
        XCTAssertEqual(carolResult, Self.carol)
        let journalEntries = await journal.entries
        XCTAssertEqual(journalEntries, [Self.carol])
    }

    /// Release first, then the timeout: the waiter is served and the late timeout is ignored.
    ///
    /// - Given: a lock whose timeouts fire when the test opens `clock`, alice holding it, and bob
    ///   queued with a timeout whose timer has started
    /// - When:
    ///    - alice's flow finishes, and only then the clock fires
    /// - Then:
    ///    - bob is served, the late timeout is counted as ignored, and the lock ends free
    func testReleaseBeforeTimeoutServesTheWaiterAndIgnoresTheTimeout() async throws {
        let clock = Gate()
        let lock = SystemSheetLock(sleep: { _ in await clock.pass() })
        let gate = Gate()

        let alice = Self.start(lock, Self.alice, .fail, Self.heldBody(gate))
        await gate.waitForArrivals(1)
        let bob = Self.start(lock, Self.bob, .wait(timeout: 60)) { $0.holder }
        await clock.waitForArrivals(1)

        await gate.open()
        _ = try await alice.value
        let bobResult = try await bob.value
        XCTAssertEqual(bobResult, Self.bob)

        await clock.open()
        await waitUntil("the late timeout has run") { await lock.ignoredExpiryCount == 1 }
        let holder = await lock.currentHolder
        XCTAssertNil(holder)
        let queued = await lock.waiterCount
        XCTAssertEqual(queued, 0)
    }

    /// Timeout first, then the release: the waiter fails and the next waiter is served.
    ///
    /// - Given: a lock whose timeouts fire when the test opens `clock`, alice holding it, bob queued
    ///   with a timeout, and carol queued behind him with no timeout
    /// - When:
    ///    - the clock fires, and alice's flow then finishes
    /// - Then:
    ///    - bob throws `browserBusy(holder: alice)`, and carol is served after alice
    func testTimeoutBeforeReleaseFailsTheWaiterAndServesTheNext() async throws {
        let clock = Gate()
        let lock = SystemSheetLock(sleep: { _ in await clock.pass() })
        let gate = Gate()

        let alice = Self.start(lock, Self.alice, .fail, Self.heldBody(gate))
        await gate.waitForArrivals(1)
        let bob = Self.start(lock, Self.bob, .wait(timeout: 60)) { $0.holder }
        await clock.waitForArrivals(1)
        let carol = Self.start(lock, Self.carol, .waitWithoutBound) { $0.holder }
        await waitUntil("carol is queued") { await lock.waiterCount == 2 }

        await clock.open()
        await Self.assertBrowserBusy(bob, holder: Self.alice)
        let queued = await lock.waiterCount
        XCTAssertEqual(queued, 1)

        await gate.open()
        _ = try await alice.value
        let carolResult = try await carol.value
        XCTAssertEqual(carolResult, Self.carol)
        let holder = await lock.currentHolder
        XCTAssertNil(holder)
    }

    // MARK: - Contention

    /// Under 64-way contention the lock has exactly one holder at a time, and serves everyone.
    ///
    /// - Given: 64 sessions all asking at once with `.waitWithoutBound`
    /// - When:
    ///    - each flow counts itself in, yields, checks the lock names it, and counts itself out
    /// - Then:
    ///    - no more than one flow was ever inside at once, all 64 ran, each saw itself as the holder,
    ///      and the lock ends free with nobody queued
    func testSixtyFourWayContentionHasExactlyOneHolderAtATime() async throws {
        let lock = SystemSheetLock()
        let tally = OccupancyTally()
        let sessions = try (0 ..< 64).map { try SessionID.named("session-\($0)") }

        // Handles are kept for the whole test, so every caller stays alive until it has been served.
        let body: @Sendable (BrowserLease) async throws -> Bool = { lease in
            tally.enter()
            for _ in 0 ..< 10 {
                await Task.yield()
            }
            let named = await lock.currentHolder == lease.holder
            tally.leave()
            return named
        }
        let tasks = sessions.map { Self.start(lock, $0, .waitWithoutBound, body) }
        var sawThemselves = 0
        for task in tasks where try await task.value {
            sawThemselves += 1
        }

        let snapshot = tally.snapshot
        XCTAssertEqual(snapshot.peak, 1)
        XCTAssertEqual(snapshot.entries, 64)
        XCTAssertEqual(snapshot.current, 0)
        XCTAssertEqual(sawThemselves, 64)
        let holder = await lock.currentHolder
        XCTAssertNil(holder)
        let queued = await lock.waiterCount
        XCTAssertEqual(queued, 0)
    }
}
#endif
