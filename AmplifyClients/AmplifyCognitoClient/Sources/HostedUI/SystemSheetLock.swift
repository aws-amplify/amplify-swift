//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(macOS) || os(visionOS)
import Foundation

/// One hold on the browser, by one session.
struct BrowserLease: Sendable, Equatable {

    /// Distinguishes this hold from every other, including later holds by the same session, so a
    /// flow that finishes after a reset cannot release a lease it no longer has.
    let id: UInt64

    /// The session holding the browser.
    let holder: SessionID
}

/// The one place that enforces the rule that only one system sheet is up per process: the hosted UI's browser
/// (its sign-in, and a sign-out that shows the logout page) and the passkey sheet of a WebAuthn ceremony.
///
/// Today the plugin is serialized only by accident: one global state machine behind one task queue.
/// Splitting auth into sessions removes that, so the rule is built here on purpose, rather than
/// inherited from nothing.
///
/// - **Process-wide.** `shared` is the one production instance, used by every session of every
///   client. The justification is UI presentation (a flow needs a foreground-active anchor, and a
///   device cannot offer two), and the foreground belongs to the process, not to a user pool.
/// - **In memory only, never persisted.** Process death releases it. A persisted lock would survive
///   a crash and block sign-in until something cleared it.
/// - **Scoped.** The only way to hold it is `withLease(for:policy:_:)`, which releases it when the
///   flow finishes: on success, on a throw, and after cancellation once the flow has unwound. There
///   is no public release to forget.
/// - **Recoverable.** `cancel(for:)` stops one session's flow; `reset()` frees the lock whoever
///   holds it, for a flow that has stopped responding.
///
/// Acquiring, per policy:
///
/// | Lock is | `.fail` | `.wait(timeout:)` |
/// |---|---|---|
/// | free | acquire | acquire |
/// | held by another session | throw `browserBusy(holder:)` | queue, first come first served |
/// | held by the calling session | throw `browserBusy(holder:)` | throw `browserBusy(holder:)` |
/// | held by the calling session, whose flow was cancelled and is closing | throw `browserBusy(holder:)`, "still closing" | queue, first come first served |
/// | the calling session is already queued | throw `browserBusy(holder:)` | throw `browserBusy(holder:)` |
///
/// A session waiting on itself could only time out, so that is refused whatever the policy. The
/// exception is a holder that has been cancelled and is only unwinding: that wait does end, so the
/// same session may queue behind its own closing browser ("Cancel, then Sign in again"). A
/// session queues at most once, so a double tap cannot line up a second browser behind the first. A
/// waiter whose timeout expires throws `browserBusy(holder:)` naming the holder at that moment; a
/// waiter whose task is cancelled throws `CancellationError`. Either way it leaves the queue and
/// never takes the lock.
///
/// Compiled on iOS, macOS and visionOS only, the platforms with a hosted UI.
///
/// Not built here: a bound on how long a holder may keep the lock. That is a watchdog that cancels
/// a live flow, so it needs a product decision on the number first.
actor SystemSheetLock {

    /// The process-wide instance every session uses.
    static let shared = SystemSheetLock()

    /// Suspends for a number of nanoseconds. Injected so a test can decide when a timeout fires.
    typealias Sleep = @Sendable (_ nanoseconds: UInt64) async throws -> Void

    /// A test seam: a point inside `withLease` where a test can hold a caller. Does nothing in
    /// production.
    typealias Seam = @Sendable (BrowserLease) async -> Void

    private struct Holder {
        let lease: BrowserLease
        /// The running flow, which can be interrupted: its task cancelled and its caller answered at
        /// once. `nil` until the flow has registered, just after acquiring.
        var flow: (any InterruptibleFlow)?
        /// Set by `cancel(for:)` before `flow` exists, so the flow stops as soon as it registers.
        var cancelRequested = false

        /// Whether the flow has been told to stop and is only unwinding. Its caller has already been
        /// answered, so the same session may queue behind it.
        var isDraining: Bool {
            cancelRequested || flow?.isInterrupted == true
        }
    }

    private struct Waiter {
        let id: UInt64
        let session: SessionID
        let continuation: CheckedContinuation<BrowserLease, Error>
        var timeout: Task<Void, Never>?
    }

    private var holder: Holder?
    /// First come first served. Non-empty only while `holder` is set: a release hands the lock to
    /// the first waiter in the same step.
    private var waiters: [Waiter] = []
    private var nextID: UInt64 = 0
    private let sleep: Sleep
    private let afterAcquire: Seam
    private let afterAttach: Seam
    private let beforeRelease: Seam
    private let beforeBody: Seam

    /// - Parameters:
    ///   - sleep: how a waiter's timeout waits.
    ///   - afterAcquire: runs once the lock is granted, before the flow registers with it. A test
    ///     holds a caller here to cancel or reset in the window between grant and registration.
    ///   - afterAttach: runs once the flow has registered, before its body starts. A test holds a
    ///     caller here to interrupt a flow whose body has not started.
    ///   - beforeRelease: runs once the body has finished, before the lease is released and the caller
    ///     answered. A test holds a flow here to interrupt it after its body produced a result.
    ///   - beforeBody: runs in the flow's task once it has started, just before the body is called. A test holds
    ///     a flow here to interrupt it after it started but before its body's first step.
    init(
        sleep: @escaping Sleep = { try await Task.sleep(nanoseconds: $0) },
        afterAcquire: @escaping Seam = { _ in },
        afterAttach: @escaping Seam = { _ in },
        beforeRelease: @escaping Seam = { _ in },
        beforeBody: @escaping Seam = { _ in }
    ) {
        self.beforeBody = beforeBody
        self.sleep = sleep
        self.afterAcquire = afterAcquire
        self.afterAttach = afterAttach
        self.beforeRelease = beforeRelease
    }

    /// The session whose browser sign-in is in flight, or `nil` when the lock is free.
    var currentHolder: SessionID? {
        holder?.lease.holder
    }

    /// How many callers are queued behind the holder.
    var waiterCount: Int {
        waiters.count
    }

    /// How many releases arrived for a lease that was no longer current, from flows that finished
    /// after a reset. Each was ignored. For diagnostics and tests.
    private(set) var ignoredReleaseCount = 0

    /// How many waiter timeouts fired for a waiter that had already been answered: granted,
    /// cancelled or reset. Each was ignored. For diagnostics and tests.
    private(set) var ignoredExpiryCount = 0

    // MARK: - Holding the lock

    /// Runs `body` while holding the lock for `session`, acquiring it per `policy` first.
    ///
    /// `body` is the whole browser round trip, including the code-for-token exchange, since the
    /// token endpoint and the browser's cookie jar are what the lock protects. It runs in its own
    /// task, so the lock can stop it from outside.
    ///
    /// - The lock is released when `body` finishes, whether it returned or threw.
    /// - If the calling task is cancelled, or `cancel(for:)` names this session, `body`'s task is
    ///   cancelled and this call throws `CancellationError` at once. The lock stays held until `body`
    ///   has actually unwound, so a following sign-in never presents over a browser that is still
    ///   being dismissed.
    /// - If `reset()` is called, this call throws `CancellationError` at once and the lock is freed
    ///   at once, even if `body` never finishes. When it does finish, its release is ignored.
    ///
    /// **Cancellation handlers must not block.** An interrupt from `cancel(for:)` or `reset()`
    /// cancels `body`'s task synchronously on this actor, so every cancellation handler inside
    /// `body` (the presenter's, which dismisses the browser) runs on the actor too. It must return
    /// promptly: hop to the main actor with `Task { @MainActor in … }`, never
    /// `DispatchQueue.main.sync` or a wait on a lock another task holds.
    ///
    /// **`body` returns what the flow produced and commits nothing.** After an interrupt `body` keeps
    /// running until it unwinds, and a result it produces then is discarded: it is never returned to
    /// anyone, even one `body` had already returned when the interrupt landed. A caller whose result holds
    /// something to clean up (tokens to revoke) must hand it over outside the lock, as the hosted-UI sign-in's
    /// `LateSignInClaim` does. So `body` must not store tokens, update session state or emit events. It returns the
    /// tokens, and the caller commits them after `withLease` returns. That way a sign-in the caller
    /// saw as cancelled can never sign the session in behind its back.
    ///
    /// - Throws: `AuthClientError.browserBusy(holder:)` if the lock could not be acquired under
    ///   `policy`; `CancellationError` as above; otherwise whatever `body` throws.
    nonisolated func withLease<T: Sendable>(
        for session: SessionID,
        policy: WebUIOptions.BrowserBusyPolicy,
        _ body: @escaping @Sendable (BrowserLease) async throws -> T
    ) async throws -> T {
        let lease = try await acquire(for: session, policy: policy)
        await afterAcquire(lease)
        let flow = LeasedFlow<T>()
        let attached = await attach(flow, to: lease)
        // A waiter can be granted the lock just as its task is cancelled. It must not run `body`.
        guard attached, !Task.isCancelled else {
            await release(lease)
            throw CancellationError()
        }
        await afterAttach(lease)
        flow.start { [self] skipBody in
            let result: Result<T, Error>
            if skipBody {
                result = .failure(CancellationError())
            } else {
                await beforeBody(lease)
                do {
                    result = try await .success(body(lease))
                } catch {
                    result = .failure(error)
                }
            }
            await beforeRelease(lease)
            // Released before the caller is answered, so a caller that returns normally always
            // finds the lock free.
            await release(lease)
            return result
        }
        return try await withTaskCancellationHandler {
            try await flow.value()
        } onCancel: {
            flow.interrupt()
        }
    }

    // MARK: - Recovery

    /// Stops `session`'s browser sign-in, whether it holds the lock or is queued for it.
    ///
    /// A holder's flow is cancelled and its caller throws `CancellationError`; the lock is released
    /// once the flow has unwound. A queued caller throws `CancellationError` and leaves the queue.
    /// Idempotent, and a no-op for a session with no sign-in.
    func cancel(for session: SessionID) {
        if holder?.lease.holder == session {
            if let flow = holder?.flow {
                flow.interrupt()
            } else {
                holder?.cancelRequested = true
            }
        }
        let cancelled = waiters.filter { $0.session == session }
        waiters.removeAll { $0.session == session }
        for waiter in cancelled {
            waiter.timeout?.cancel()
            waiter.continuation.resume(throwing: CancellationError())
        }
    }

    /// Frees the lock whoever holds it, for a flow that has stopped responding, such as one the OS
    /// tore down without a callback.
    ///
    /// The holder's flow is cancelled and its caller throws `CancellationError`. Unlike
    /// `cancel(for:)`, the lock does not wait for the flow to unwind: it passes straight to the first
    /// queued caller, or becomes free. A recovery tool; the normal way to stop a sign-in is
    /// `cancel(for:)`.
    ///
    /// - Returns: the session that was holding the lock, or `nil` if it was already free.
    @discardableResult
    func reset() -> SessionID? {
        guard let current = holder else {
            return nil
        }
        holder = nil
        // With no flow registered yet, the flow finds its lease gone when it tries to register, and
        // stops there.
        current.flow?.interrupt()
        grantNext()
        return current.lease.holder
    }

    // MARK: - Internals

    private func acquire(
        for session: SessionID,
        policy: WebUIOptions.BrowserBusyPolicy
    ) async throws -> BrowserLease {
        let id = mintID()
        return try await withTaskCancellationHandler {
            // The body runs synchronously on this actor, so checking the holder and joining the
            // queue cannot interleave with a release, a reset or this caller's cancellation, which
            // has to hop onto the actor to take effect.
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<BrowserLease, Error>) in
                guard !Task.isCancelled else {
                    continuation.resume(throwing: CancellationError())
                    return
                }
                guard let current = holder else {
                    let lease = BrowserLease(id: id, holder: session)
                    holder = Holder(lease: lease)
                    continuation.resume(returning: lease)
                    return
                }
                let holding = current.lease.holder
                // A second call from a session that is already queued, such as a double tap, would
                // otherwise be served straight after the first: a second browser nobody asked for.
                guard !waiters.contains(where: { $0.session == session }) else {
                    continuation.resume(throwing: AuthClientError.browserBusy(
                        heldBy: holding,
                        requestedBy: session,
                        reason: .alreadyQueued
                    ))
                    return
                }
                // The holder asking again is refused, since waiting on itself could only time out.
                // Unless its flow has been interrupted and is only closing: that wait ends, so
                // "Cancel, then Sign in again" can queue behind the closing browser.
                let isClosing = current.isDraining
                if holding == session, !isClosing {
                    continuation.resume(throwing: AuthClientError.browserBusy(
                        heldBy: holding,
                        requestedBy: session,
                        reason: .alreadyInFlight
                    ))
                    return
                }
                guard let timeout = policy.timeoutNanoseconds, timeout > 0 else {
                    continuation.resume(throwing: AuthClientError.browserBusy(
                        heldBy: holding,
                        requestedBy: session,
                        reason: holding == session ? .stillClosing : .heldByAnotherSession
                    ))
                    return
                }
                var waiter = Waiter(id: id, session: session, continuation: continuation)
                // `UInt64.max` nanoseconds is 584 years: no timer, rather than one that never fires.
                if timeout < .max {
                    // Isolated to this actor like its surroundings; only the sleep runs off it.
                    waiter.timeout = Task { [sleep] in
                        do {
                            try await sleep(timeout)
                        } catch {
                            return
                        }
                        self.expireWaiter(id)
                    }
                }
                waiters.append(waiter)
            }
        } onCancel: {
            Task { await self.cancelWaiter(id) }
        }
    }

    private func mintID() -> UInt64 {
        let id = nextID
        nextID &+= 1
        return id
    }

    private func attach(_ flow: any InterruptibleFlow, to lease: BrowserLease) -> Bool {
        guard holder?.lease.id == lease.id, holder?.cancelRequested == false else {
            return false
        }
        holder?.flow = flow
        return true
    }

    private func release(_ lease: BrowserLease) {
        // A lease that is no longer current was reset away, and the lock may already belong to
        // someone else.
        guard holder?.lease.id == lease.id else {
            ignoredReleaseCount += 1
            return
        }
        holder = nil
        grantNext()
    }

    private func grantNext() {
        guard !waiters.isEmpty else {
            return
        }
        let next = waiters.removeFirst()
        next.timeout?.cancel()
        let lease = BrowserLease(id: mintID(), holder: next.session)
        holder = Holder(lease: lease)
        next.continuation.resume(returning: lease)
    }

    private func expireWaiter(_ id: UInt64) {
        // Absent when the waiter was granted, cancelled or reset before its timer ran out.
        guard let index = waiters.firstIndex(where: { $0.id == id }) else {
            ignoredExpiryCount += 1
            return
        }
        let waiter = waiters.remove(at: index)
        guard let holding = holder?.lease.holder else {
            // Unreachable while waiters are only queued behind a holder. Loud in debug builds; in
            // release the waiter is owed the free lock rather than an error.
            assertionFailure("A waiter was queued while the browser lock was free")
            let lease = BrowserLease(id: mintID(), holder: waiter.session)
            holder = Holder(lease: lease)
            waiter.continuation.resume(returning: lease)
            return
        }
        waiter.continuation.resume(throwing: AuthClientError.browserBusy(
            heldBy: holding,
            requestedBy: waiter.session,
            reason: .timedOut
        ))
    }

    private func cancelWaiter(_ id: UInt64) {
        // Absent when the waiter was already answered: granted, timed out, or never queued.
        guard let index = waiters.firstIndex(where: { $0.id == id }) else {
            return
        }
        let waiter = waiters.remove(at: index)
        waiter.timeout?.cancel()
        waiter.continuation.resume(throwing: CancellationError())
    }
}

/// A running flow the lock can stop without knowing its result type.
private protocol InterruptibleFlow: AnyObject, Sendable {

    /// Cancels the flow's task and answers its caller with `CancellationError`. Idempotent.
    func interrupt()

    /// Whether `interrupt()` has been called. Set before the caller is answered.
    var isInterrupted: Bool { get }
}

/// The running body of one lease, and the one place its caller is answered.
///
/// The caller is answered exactly once, by whichever comes first: the body finishing, or an
/// interrupt (the caller's cancellation, `cancel(for:)` or `reset()`). Later answers are ignored, so
/// no path can resume the caller twice or leave it unresumed.
private final class LeasedFlow<T: Sendable>: InterruptibleFlow, @unchecked Sendable {

    private let lock = NSLock()
    private var result: Result<T, Error>?
    private var continuation: CheckedContinuation<T, Error>?
    private var task: Task<Void, Never>?
    private var interrupted = false

    var isInterrupted: Bool {
        lock.lock()
        defer { lock.unlock() }
        return interrupted
    }

    /// Starts the body. `operation` is told to skip the body if an interrupt arrived first; it is
    /// still run, because it is what releases the lease.
    func start(_ operation: @escaping @Sendable (_ skipBody: Bool) async -> Result<T, Error>) {
        lock.lock()
        defer { lock.unlock() }
        // Read and stored under the one lock `interrupt()` takes, so an interrupt either lands
        // before (and the body is skipped) or after (and finds the task to cancel).
        let skipBody = interrupted
        task = Task {
            let result = await operation(skipBody)
            self.answer(with: result)
        }
    }

    /// Cancels the body's task and answers the caller with `CancellationError`. Idempotent.
    func interrupt() {
        lock.lock()
        interrupted = true
        let task = task
        lock.unlock()
        task?.cancel()
        answer(with: .failure(CancellationError()))
    }

    /// Suspends until the caller is answered. Called once, by the lease's caller.
    func value() async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            lock.lock()
            if let result {
                lock.unlock()
                continuation.resume(with: result)
                return
            }
            self.continuation = continuation
            lock.unlock()
        }
    }

    private func answer(with result: Result<T, Error>) {
        lock.lock()
        guard self.result == nil else {
            lock.unlock()
            return
        }
        self.result = result
        let continuation = continuation
        self.continuation = nil
        lock.unlock()
        continuation?.resume(with: result)
    }
}
#endif
