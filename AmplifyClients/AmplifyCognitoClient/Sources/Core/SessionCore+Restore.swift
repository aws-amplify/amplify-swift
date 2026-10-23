//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyFoundation
import Foundation

extension SessionCore {

    /// Starts the restore early, right after the core is built, so the first operation usually finds
    /// the session already loaded. Correctness never depends on it: every operation restores first.
    nonisolated func warmRestore() async {
        _ = try? await restoredSnapshot()
    }

    /// The session's snapshot, restoring it first if no restore has succeeded yet.
    ///
    /// Concurrent first callers share one read. The wait is bounded: a restore that has not finished
    /// within `bounds.restoreNanoseconds` surfaces `storageUnavailable(.interrupted)` rather than
    /// hanging. What is raced is a `SingleFlight` waiter, which is abandoned promptly, so the bound holds
    /// even while the keychain call itself is stuck; the read carries on, and adopts its result when it
    /// finishes, so a late success is not lost.
    ///
    /// A failure is not cached. The next operation attempts one fresh restore, so a second attempt after
    /// storage recovers succeeds. No single call retries.
    ///
    /// A storage failure is never reported as signed out: it throws `storageUnavailable`, and the state
    /// becomes `.unavailable(reason)`.
    nonisolated func restoredSnapshot() async throws -> SessionSnapshot {
        if let current = await restoredSnapshotIfAny {
            return current
        }
        let timeout = AuthClientError.storageUnavailable(
            .interrupted,
            "Secure storage did not respond within \(bounds.restoreNanoseconds / 1_000_000) ms while restoring session \"\(sessionId)\".",
            "Retry the operation. Do not treat this as signed out."
        )
        do {
            return try await withBound(nanoseconds: bounds.restoreNanoseconds, timeout: timeout) { [self] in
                try await restoreFlight.run { [self] in
                    try await restoreOnce()
                }
            }
        } catch let error as AuthClientError {
            if case .storageUnavailable(let reason, _, _, _) = error {
                await restoreFailed(reason)
            }
            throw error
        }
    }

    /// One restore: under the record's gate, so it never observes the middle of a purge or sign-out.
    /// Reads the record once, and the session's challenge record, which resumes a sign-in interrupted by the
    /// app closing (`pendingOrResumedChallenge`), then adopts the result before the flight ends, so a caller
    /// that arrives afterwards finds it and reads nothing.
    ///
    /// A restore that may carry the session forward (`SessionRecordStore+CopyForward.swift`) also holds the gate of
    /// the namespace its marker names, taken with its own in the one global order: the marker is read, both gates
    /// taken, and the marker read again; if it now names another namespace, the gates are taken again, at most
    /// `SessionRecordGates.maximumGateAttempts` times, and then the restore fails with
    /// `storageUnavailable(.interrupted)`, so a later call restores, and carries, again.
    ///
    /// `.default` keeps no marker. It runs the Auth plugin's configuration-change rule instead, first, in the same way:
    /// the gate it also holds is the namespace of the plugin's last configuration (`authConfiguration`), and the rule
    /// carries or deletes before the read (`SessionRecordStore+PluginConfiguration.swift`). A failed read of that item
    /// fails the restore, and nothing is written.
    private nonisolated func restoreOnce() async throws -> SessionSnapshot {
        let reader = SessionRecordIO(store: store, queue: SessionRecordIO.listingQueue)
        let sessionId = sessionId
        for _ in 1 ... SessionRecordGates.maximumGateAttempts {
            // A failed read here is not the restore's answer: the read under the gates reports it, in order.
            let source = try? await reader.perform { store in
                // `.default` keeps no marker: the namespace the plugin's last configuration names.
                try sessionId == .default ? store.pluginConfigurationSource() : store.carrySource(for: sessionId)
            }
            let held = [namespace] + [source].compactMap { $0 }.map {
                SessionStorageNamespace(pools: $0, accessGroup: namespace.accessGroup)
            }
            let restored: SessionSnapshot? = try await gates.holding(held, sessionId: sessionId) { [self] in
                let store = SessionRecordIO(store: store, queue: gate.ioQueue)
                if let current = await restoredSnapshotIfAny {
                    return current
                }
                let loaded: SessionSnapshot
                do {
                    if sessionId == .default {
                        try await Self.applyPluginConfigurationRule(
                            through: store,
                            current: pluginConfiguration,
                            heldSource: .some(source ?? nil),
                            makeRevoker: makePreviousConfigurationRevoker
                        )
                    }
                    loaded = try await store.loadCarryingForward(sessionId, heldSource: .some(source ?? nil))
                } catch is SessionRecordStore.CarrySourceChanged {
                    return nil
                }
                let generation = await challengeGeneration
                let pending = try await pendingOrResumedChallenge(loaded, store: store)
                return await adoptRestored(loaded, challenge: pending, readAtChallengeGeneration: generation)
            }
            if let restored {
                return restored
            }
        }
        // The marker kept changing: this restore fails as interrupted, which is not cached, so the next operation
        // on this core restores again, and carries if it can. Reading without carrying would adopt "absent" for
        // the rest of this core's life.
        throw AuthClientError.storageUnavailable(
            .interrupted,
            "Session \"\(sessionId)\"'s saved configuration changed while it was being restored.",
            "Retry the operation. Do not treat this as signed out."
        )
    }

    /// The session's state. Never throws: a storage failure is `.unavailable(reason)`, anything else
    /// unrecoverable is `.failed`. Answers from memory after the restore, without re-reading storage.
    nonisolated func sessionState() async -> AuthSessionState {
        do {
            _ = try await restoredSnapshot()
        } catch let error as AuthClientError {
            if case .storageUnavailable(let reason, _, _, _) = error {
                return .unavailable(reason)
            }
            return .failed(error)
        } catch is CancellationError {
            // The caller stopped waiting; nothing was learned about storage.
            return .unavailable(.interrupted)
        } catch {
            return .failed(.unknown("The session could not be restored.", "Retry the operation.", error))
        }
        return await currentState ?? .unavailable(.interrupted)
    }
}
