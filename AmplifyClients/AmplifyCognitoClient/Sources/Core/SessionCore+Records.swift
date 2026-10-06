//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyFoundation
import Foundation

extension SessionCore {

    /// Attempts a metadata write makes against concurrent writers before giving up.
    static let maximumRecordWriteAttempts = 3

    // MARK: Label

    /// Sets, or with `nil` clears, the session's display label. No event, and the state does not change.
    ///
    /// A lost race is rebased, not forced: the label is re-applied to the fresh record, carrying its
    /// fresh credentials forward, so an older credentials payload is never written back.
    ///
    /// `.default`'s label is its sidecar's (`SessionRecordStore.setDefaultLabel`): only the sidecar is written,
    /// bound to the user the shared record holds as re-read, and the shared record is never rewritten for a label.
    ///
    /// - Throws: `storageUnavailable` if storage failed, or if every attempt lost its race; `.unknown` if
    ///   the record is one this build cannot read, which is never overwritten.
    nonisolated func setSessionLabel(_ label: String?) async throws {
        _ = try await restoredSnapshot()
        try await withRecord { [self] store in
            for _ in 1 ... Self.maximumRecordWriteAttempts {
                if sessionId == .default {
                    switch try await store.setDefaultLabel(label) {
                    case .written(let result):
                        await apply(SessionSnapshot(result), event: nil)
                        return
                    case .discarded:
                        continue
                    case .unreadableRecord:
                        throw Self.unlabellable(sessionId)
                    case .unreadableSidecar:
                        throw Self.labelUnreadable(sessionId)
                    }
                }
                let record: SessionRecord
                let expected: RecordVersion?
                switch try await store.read(sessionId) {
                case .absent:
                    guard label != nil else {
                        return
                    }
                    // A labelled signed-out row, listed with `includingSignedOut: true`.
                    record = .signedOut(label: label, username: nil)
                    expected = nil
                case .record(let stored):
                    var labelled = stored.record
                    labelled.label = label
                    record = labelled
                    expected = stored.version
                case .unsupportedSchema, .corrupt:
                    throw Self.unlabellable(sessionId)
                }
                if case .committed(let committed) = try await store.write(record, for: sessionId, expecting: expected) {
                    await apply(SessionSnapshot(committed), event: nil)
                    return
                }
            }
            throw Self.contended("label")
        }
    }

    /// `.default`'s label is kept in a sidecar written by a newer version, which this one never overwrites.
    private static func labelUnreadable(_ sessionId: SessionID) -> AuthClientError {
        .unknown(
            "Session \"\(sessionId)\" cannot be labelled: its saved label was written by a newer version of the app, which this version cannot read.",
            "Update the app. A purge would reset the label, but for this session it also deletes the Auth plugin's saved login, which signs the user out."
        )
    }

    private static func unlabellable(_ sessionId: SessionID) -> AuthClientError {
        .unknown(
            "Session \"\(sessionId)\" cannot be labelled: its saved record is one this version cannot read.",
            "Sign the session out to reset it, or update the app."
        )
    }

    /// Forgets what the process remembers about this record (`SessionRecordGates.memory`): its identity-step failures
    /// and its last reused refresh token. For a signed-out or purged session, whose next user starts clean.
    nonisolated func forgetRecordMemory() {
        identityRetry.reset()
        refreshTokenReuse.reset()
    }

    // MARK: Purge and sign-out, as the static calls route them to a live session

    /// Deletes the session's saved records, locally only, and leaves the session usable in
    /// `.signedOut`. Sends `.signedOut` if it held credentials.
    nonisolated func purgeStoredRecord() async throws {
        try await withRecord { [self] store in
            let stored = try? await store.load(sessionId)
            let inMemory = await restoredSnapshotIfAny
            let heldCredentials = stored?.credentials != nil || inMemory?.credentials != nil
            try await store.purge(sessionId)
            forgetRecordMemory()
            await cancelPendingSignIns()
            await apply(.absent, challenge: .set(nil), event: heldCredentials ? .signedOut : nil)
        }
    }

    /// Revokes the session's tokens through the engine, then clears them locally, keeping the row.
    /// Holds the gate throughout, then publishes. Sends `.signedOut` if it removed credentials.
    ///
    /// With `global`, the engine signs the user out of every device before revoking; a failure of either
    /// is reported in `.partial`. With `purge`, a sign-out that ended the session then removes its row, as
    /// `purgeStoredRecord()` does. A superseded sign-out purges nothing: the row is another user's.
    ///
    /// Any pending sign-in is cancelled whenever the session ends signed out, credentials or not, so a
    /// session waiting on a challenge lands in `.signedOut`. A superseded sign-out ends nothing
    /// and leaves it.
    ///
    /// Never signs out a different user who signed in to this session ID meanwhile: that is
    /// `.failed(.invalidState)` and they stay signed in (see `SessionSignOut`).
    ///
    /// **Never throws**: a sign-out that did not clear the session is `.failed`, and the session is still
    /// signed in. A storage failure, a cancelled or failed restore, the task cancelled before anything was
    /// revoked (`.unknown` with a `CancellationError`), and the user closing the logout page are all
    /// `.failed`. Once a revoke has completed, cancellation never stops the local clear. When only the purge
    /// failed, the session is already signed out and its row is kept: `.partial` with `storageError`.
    ///
    /// **The hosted UI's sign-out.** After a hosted-UI sign-in that shared the
    /// browser's cookies, the first attempt shows the hosted UI's logout page in `window`, holding the system
    /// sheet (`firstSignOutAttempt`); retries never do. The user closing it is `.failed(.userCancelled)`, and the
    /// session stays signed in. With a window, a page that cannot be shown or completed (no hosted UI or sign-out
    /// redirect URI, the sheet busy, the window gone, the browser failing) is `.failed` too, as in the plugin.
    /// Only without a window does the sign-out go ahead without the page, reporting `hostedUIError`
    /// in `.partial`: the browser keeps its sign-in.
    nonisolated func signOut(
        global: Bool = false,
        purge: Bool = false,
        window: SignOutWindow = .none
    ) async -> AuthClientSignOutResult {
        do {
            _ = try await restoredSnapshot()
            return try await withRecord { [self] store in
                let engine = engine
                let outcome = try await SessionSignOut(
                    sessionId: sessionId,
                    store: store,
                    describe: { try? engine.describe($0) },
                    sameCredentials: { engine.sameCredentials($0, $1) },
                    revoke: { [self] payload, firstAttempt in
                        guard firstAttempt else {
                            return try await engine.revoke(payload, global: global)
                        }
                        return try await firstSignOutAttempt(payload, global: global, window: window)
                    },
                    revokeCopy: { payload in
                        try await engine.revoke(payload, global: false)
                    }
                ).run()
                // From here on nothing throws: the record is cleared, or the outcome says why not.
                if outcome.endedSession {
                    forgetRecordMemory()
                    // The sign-out has deleted the interrupted sign-in's record, under the gate this holds, so no step of the
                    // sign-in cancelled here can write it back (each writes under the gate, after checking the epoch).
                    await cancelPendingSignIns()
                }
                let after: SessionSnapshot?
                do {
                    after = try await store.load(sessionId)
                } catch {
                    // The record is signed out, but could not be read back: the signed-out row as this session knew it,
                    // keeping its label and last user, rather than no row at all.
                    after = outcome.removedCredentials ? Self.signedOutRow(keeping: await restoredSnapshotIfAny) : nil
                }
                if let after {
                    await apply(
                        after,
                        challenge: outcome.endedSession ? .set(nil) : .unchanged,
                        event: outcome.removedCredentials ? .signedOut : nil
                    )
                }
                if purge, outcome.endedSession {
                    do {
                        try await store.purge(sessionId)
                    } catch {
                        // Signed out, but the row is kept: `.partial` with the purge's failure.
                        let reason = (error as? AuthClientError).flatMap(\.storageUnavailableReason) ?? .interrupted
                        return outcome.server.signedOutResult(storageError: .storageUnavailable(
                            reason,
                            "Session \"\(sessionId)\" was signed out, but its saved row could not be removed.",
                            "Purge the session to remove the row.",
                            error
                        ))
                    }
                    await apply(.absent, event: nil)
                }
                return outcome.result()
            }
        } catch {
            // Thrown before anything was cleared: the session is still signed in.
            return .failed(SessionSignOut.failure(error))
        }
    }

    // MARK: Helpers

    static func contended(_ operation: String) -> AuthClientError {
        .storageUnavailable(
            .interrupted,
            "The session's saved record kept changing, so the \(operation) could not be saved.",
            "Retry the operation."
        )
    }

    /// The signed-out row a sign-out leaves, as `known` described the session before it: its label and last user. No
    /// version, as `.absent` has none: a write over it is discarded while a record is stored, and re-reads. `.absent`
    /// when this session knew no record of its own.
    static func signedOutRow(keeping known: SessionSnapshot?) -> SessionSnapshot {
        guard let record = known?.ownRecord else {
            return .absent
        }
        return SessionSnapshot(
            version: nil,
            source: .own(.signedOut(label: record.label, username: record.username, userId: record.userId))
        )
    }
}
