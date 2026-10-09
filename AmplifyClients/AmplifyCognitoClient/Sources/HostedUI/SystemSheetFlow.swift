//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(macOS) || os(visionOS)
import Foundation
import InternalAWSCognitoAuth

/// One call's flow on the system sheet: a hosted-UI sign-in, or a passkey ceremony. It is what lets
/// that call be stopped from outside, and says afterwards who stopped it.
///
/// The work that holds the sheet runs in a task of its own (`run`), because the task it would otherwise run
/// in is out of reach: a sign-in step runs in `withSignInLock`'s own task, and a sign-in's passkey ceremony
/// in an engine effect task. `cancel(_:)` cancels that task, which interrupts the sheet lease (the
/// browser or the passkey sheet closes, and `withLease` throws `CancellationError` at once).
///
/// **Sticky.** A flow serves one call. Once cancelled, work that has not started yet is cancelled as it
/// starts, so a caller that gave up before the lease never sees a sheet.
///
/// **Who stopped it**, for the call's error:
///
/// | Stopped by | How it is recorded | What the call reports |
/// |---|---|---|
/// | the caller cancelling its own task | `cancel(.caller)` | `CancellationError` |
/// | a sign-out, purge or deletion of the session | `cancel(.sessionEnded)` | the operation's ended-by-the-session `invalidState` |
/// | `cancelWebUISignIn()` or `resetSystemSheet()` (the lock interrupts the lease) | `wasInterruptedByTheLock` | `.userCancelled` |
final class SystemSheetFlow: @unchecked Sendable {

    /// Who stopped a flow.
    enum Stop: Sendable, Equatable {
        /// The caller cancelled its own task.
        case caller
        /// A sign-out, purge or deletion ended the session.
        case sessionEnded
    }

    // `@unchecked Sendable`: every property below is only touched while holding `lock`.
    private let lock = NSLock()
    private var stop: Stop?
    private var stopReached = false
    private var interruptedByTheLock = false
    /// The work `run` is waiting on, and which `run` it belongs to; cleared when that `run` returns, so a stop
    /// after the work has finished reaches nothing.
    private var task: (any CancellableTask)?
    private var taskId: UInt64 = 0
    private var holders: [String: SessionID] = [:]

    /// Whether the flow has been stopped, by anyone.
    var isCancelled: Bool {
        lock.withLock { stop != nil }
    }

    /// Who stopped the flow first, or `nil`.
    var stoppedBy: Stop? {
        lock.withLock { stop }
    }

    /// Whether the stop reached work: it cancelled work in flight, or work that tried to start after it. Work
    /// that had already finished is not reached.
    var stopReachedWork: Bool {
        lock.withLock { stopReached }
    }

    /// Whether the sheet lock interrupted the work with nobody having stopped the flow: the app's
    /// `cancelWebUISignIn()` or `resetSystemSheet()`.
    var wasInterruptedByTheLock: Bool {
        lock.withLock { interruptedByTheLock }
    }

    /// Stops the flow, now and for good, and cancels the work `run` is waiting on, if any. Idempotent; the
    /// first stop names who stopped it.
    func cancel(_ by: Stop = .caller) {
        let running: (any CancellableTask)? = lock.withLock {
            if stop == nil {
                stop = by
            }
            if task != nil {
                stopReached = true
            }
            return task
        }
        running?.cancel()
    }

    /// Runs `body` in a task `cancel(_:)` cancels, cancelled at once if the flow has already been stopped.
    func run<T: Sendable>(_ body: @escaping @Sendable () async throws -> T) async throws -> T {
        let running = Task { try await body() }
        let (id, stopped) = attach(running)
        if stopped {
            running.cancel()
        }
        defer {
            lock.withLock {
                if taskId == id {
                    task = nil
                }
            }
        }
        do {
            return try await withTaskCancellationHandler {
                try await running.value
            } onCancel: {
                running.cancel()
            }
        } catch is CancellationError {
            lock.withLock {
                if stop == nil, !Task.isCancelled {
                    interruptedByTheLock = true
                }
            }
            throw CancellationError()
        }
    }

    /// Registers the task `cancel(_:)` cancels: its id, and whether the flow has already been stopped.
    private func attach(_ running: any CancellableTask) -> (UInt64, Bool) {
        lock.withLock {
            taskId &+= 1
            task = running
            if stop != nil {
                stopReached = true
                return (taskId, true)
            }
            return (taskId, false)
        }
    }

    // MARK: Hosted UI

    /// The other sessions' users a hosted-UI sign-in step read, for its error's description.
    var subjects: [String: SessionID] {
        lock.withLock { holders }
    }

    func record(_ subjects: [String: SessionID]) {
        lock.withLock { holders = subjects }
    }

    // MARK: WebAuthn

    /// The engine's ceremony context for this call: a runner that runs one
    /// ceremony under `sheetLock`'s lease for `session`, with the `.fail` policy, in this flow; and the stop the
    /// engine's `cancelPendingSignIn` calls, which is a session ending.
    func ceremonyContext(anchor: EnginePresentationAnchorBox?, sheetLock: SystemSheetLock, session: SessionID) -> EngineCeremonyContext {
        EngineCeremonyContext(
            anchor: anchor,
            ceremony: { [self] body in
                try await run {
                    try await sheetLock.withLease(for: session, policy: .fail) { _ in
                        try await body()
                    }
                }
            },
            cancel: { [weak self] in self?.cancel(.sessionEnded) }
        )
    }
}

/// A task `SystemSheetFlow` can cancel, whatever its result type.
private protocol CancellableTask: Sendable {
    func cancel()
}

extension Task: CancellableTask {}
#endif
