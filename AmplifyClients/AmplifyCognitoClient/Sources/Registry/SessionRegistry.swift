//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// The process-wide table that makes two handles with the same `SessionID` share one session.
///
/// It is what makes "one state machine per session ID" true, and therefore what makes two
/// handles diverging over one stored record structurally impossible within a process.
///
/// Keyed by session ID alone. Keying by configuration instead would turn "same ID, different user
/// pool" into a miss that silently installs a second session — the exact case the design requires
/// to throw — and would let a cosmetic configuration change address a different session over the
/// same stored record. So the configuration is recorded beside each entry and checked:
///
/// | Same session ID, and… | Outcome |
/// |---|---|
/// | same namespace, same fingerprint | the existing session is returned |
/// | same namespace, different fingerprint | throws — same record, contradictory settings |
/// | different namespace | throws — never attach to a session on another pool |
///
/// Entries hold the session weakly, so a session is released when its last handle goes and a later
/// construction builds a fresh one. Correctness never depends on `deinit` running at a particular
/// time: a dead entry is simply replaced on the next lookup.
///
/// A lock-guarded class rather than an actor, because the client's initializer is synchronous and
/// throwing, and so cannot `await`.
///
/// **A session's `deinit` must never call into the registry synchronously.** Every weak load under the
/// lock promotes the reference to strong for a moment. If another thread drops the last handle in that
/// window, the registry's own temporary is the last reference, and the session is released — and its
/// `deinit` runs — while the lock is held. A `deinit` that took this non-recursive lock would then
/// deadlock on its own thread. The throwing path of `session(for:…)` shows it most plainly: the live
/// reference dies at the `throw`, inside the lock. So a session schedules its prune instead, which is
/// safe because `pruneIfReleased` compares before it clears.
final class SessionRegistry<Namespace: Equatable & Sendable, Fingerprint: Equatable & Sendable, Session: AnyObject & Sendable>: @unchecked Sendable {

    private struct Entry {
        weak var session: Session?
        let namespace: Namespace
        let fingerprint: Fingerprint
    }

    private let lock = NSLock()
    private var entries: [SessionID: Entry] = [:]

    /// Test seam: runs under the lock, right after a lookup has promoted a live entry to a strong
    /// reference. Lets a test drop the last handle at exactly that moment.
    private let didLoadLiveEntry: (@Sendable (SessionID) -> Void)?

    init(didLoadLiveEntry: (@Sendable (SessionID) -> Void)? = nil) {
        self.didLoadLiveEntry = didLoadLiveEntry
    }

    /// Returns the live session for `sessionId`, or builds one with `make` if none is live.
    ///
    /// `make` runs while the lock is held, so two concurrent constructions of the same session ID
    /// cannot both build a session. It must therefore be cheap and must not call back into the
    /// registry, which would deadlock.
    ///
    /// - Throws: `AuthClientError.sessionConfigurationMismatch` if the session is already live under
    ///   a different namespace or fingerprint, or whatever `make` throws.
    func session(
        for sessionId: SessionID,
        namespace: Namespace,
        fingerprint: Fingerprint,
        make: () throws -> Session
    ) throws -> Session {
        lock.lock()
        defer { lock.unlock() }

        if let entry = entries[sessionId], let live = entry.session {
            didLoadLiveEntry?(sessionId)
            guard entry.namespace == namespace else {
                throw AuthClientError.sessionConfigurationMismatch(
                    sessionId,
                    "Session \"\(sessionId)\" is already in use with a different user pool, identity pool or keychain access group.",
                    "Use a different session ID for each configuration, or construct every client for this session with the same pools and access group."
                )
            }
            guard entry.fingerprint == fingerprint else {
                throw AuthClientError.sessionConfigurationMismatch(
                    sessionId,
                    "Session \"\(sessionId)\" is already in use with different settings.",
                    "Construct every client for one session with the same configuration."
                )
            }
            return live
        }

        let session = try make()
        entries[sessionId] = Entry(session: session, namespace: namespace, fingerprint: fingerprint)
        return session
    }

    /// The live session for `sessionId` and the namespace it was built with, or `nil` if none is live.
    /// Never builds one.
    ///
    /// The strong reference is moved out of the locked region before it is returned, so if the caller
    /// ends up holding the last reference, the session is released outside the lock.
    func liveSession(for sessionId: SessionID) -> (session: Session, namespace: Namespace)? {
        let found: (session: Session, namespace: Namespace)?
        lock.lock()
        if let entry = entries[sessionId], let live = entry.session {
            found = (live, entry.namespace)
        } else {
            found = nil
        }
        lock.unlock()
        return found
    }

    /// The number of entries, live or not yet pruned. For tests that check the table returns to its
    /// baseline.
    var entryCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return entries.count
    }

    /// Removes the entry for `sessionId` if its session has been released. Safe to call at any
    /// time; a live entry is left alone, so a racing construction that has just replaced it is not
    /// disturbed.
    func pruneIfReleased(_ sessionId: SessionID) {
        lock.lock()
        defer { lock.unlock() }
        if let entry = entries[sessionId], entry.session == nil {
            entries[sessionId] = nil
        }
    }

    /// The session IDs whose sessions are currently alive in this process.
    var liveSessionIDs: Set<SessionID> {
        lock.lock()
        defer { lock.unlock() }
        return Set(entries.compactMap { $0.value.session == nil ? nil : $0.key })
    }
}
