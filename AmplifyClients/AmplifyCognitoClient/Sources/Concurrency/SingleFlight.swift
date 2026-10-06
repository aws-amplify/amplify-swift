//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Coalesces concurrent calls into one in-flight operation.
///
/// This is the per-session single-flight refresh the design requires to be an explicit invariant
/// rather than an emergent one. The plugin coalesces only by accident: there is one global state
/// machine, so a second concurrent fetch waits on the first because it has nothing else to watch.
/// Split that machine per session and the property silently disappears, so it is built here on
/// purpose.
///
/// - While an operation is in flight, every further `run(_:)` joins it instead of starting another,
///   and every joined caller receives the same result, including the same thrown error.
/// - The in-flight slot is cleared when the operation finishes, whether it returned or threw, so a
///   failure never wedges later calls. The next call after that starts a fresh operation.
/// - There is one instance per session and no shared state between instances, so two sessions never
///   wait on each other. Nothing here is `static`: a process-wide lock would re-create exactly the
///   serialization the multi-session design exists to remove.
///
/// **Cancellation.** The shared operation is never cancelled by a caller, including the one whose
/// call started it. It runs in its own unstructured task, so it does not inherit any caller's
/// cancellation. A cancelled caller stops waiting and throws `CancellationError` straight away,
/// while the operation carries on for everyone else. This is deliberate: under refresh-token
/// rotation, abandoning a refresh after Cognito has rotated the token but before the new one is
/// stored leaves the session holding a refresh token that can never be used again. One caller
/// losing interest is not a reason to put every other handle on the session at that risk.
///
/// A caller that is already cancelled when it calls `run(_:)` throws `CancellationError` without
/// joining or starting anything.
///
/// Because the operation outlives its callers, it must be bounded on its own (a refresh is bounded
/// by its network timeouts). If every caller is cancelled, the operation still completes and clears
/// the slot, and its result is discarded.
actor SingleFlight<Value: Sendable> {

    private typealias Waiter = CheckedContinuation<Value, Error>

    /// The waiters of the operation currently in flight, or `nil` when idle. Waiters live here
    /// rather than awaiting the task's `value` directly because `Task.value` cannot be abandoned
    /// early: a cancelled caller would otherwise be stuck until the operation finished.
    private var waiters: [UInt64: Waiter]?
    private var nextWaiterID: UInt64 = 0

    init() {}

    /// Whether an operation is currently in flight.
    var isInFlight: Bool {
        waiters != nil
    }

    /// The number of callers currently waiting on the in-flight operation.
    var waiterCount: Int {
        waiters?.count ?? 0
    }

    /// Runs `operation`, or joins the one already in flight.
    ///
    /// When a call joins, its own `operation` is not run: the in-flight one's result is returned.
    /// Every caller of one instance must pass an equivalent operation, so keep one instance per kind of
    /// operation: a caller that needs something the in-flight operation may not do must not join it.
    ///
    /// - Throws: whatever the shared operation throws, or `CancellationError` if this caller is
    ///   cancelled before the operation finishes.
    func run(_ operation: @escaping @Sendable () async throws -> Value) async throws -> Value {
        let id = nextWaiterID
        nextWaiterID &+= 1

        return try await withTaskCancellationHandler {
            // The body runs synchronously on this actor, so registering the waiter and starting
            // the operation cannot interleave with another caller, with the operation finishing,
            // or with this caller's cancellation, which has to hop onto the actor to take effect.
            try await withCheckedThrowingContinuation { (continuation: Waiter) in
                guard !Task.isCancelled else {
                    continuation.resume(throwing: CancellationError())
                    return
                }
                if waiters == nil {
                    waiters = [id: continuation]
                    start(operation)
                } else {
                    waiters?[id] = continuation
                }
            }
        } onCancel: {
            Task { await self.cancelWaiter(id) }
        }
    }

    private func start(_ operation: @escaping @Sendable () async throws -> Value) {
        // Unstructured rather than a child task, so no caller's cancellation reaches it. It holds
        // `self` until it finishes, which it must: the waiters can only be resumed from here.
        Task {
            let result: Result<Value, Error>
            do {
                result = try await .success(operation())
            } catch {
                result = .failure(error)
            }
            finish(with: result)
        }
    }

    private func finish(with result: Result<Value, Error>) {
        let resumed = waiters ?? [:]
        waiters = nil
        for waiter in resumed.values {
            waiter.resume(with: result)
        }
    }

    private func cancelWaiter(_ id: UInt64) {
        // Absent when the operation has already finished and resumed this caller, or when the
        // caller was cancelled before it registered. Either way it has been answered already.
        guard let waiter = waiters?.removeValue(forKey: id) else {
            return
        }
        waiter.resume(throwing: CancellationError())
    }
}
