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
    /// - Throws: `storageUnavailable` if storage failed, or if every attempt lost its race; `.unknown` if
    ///   the record is one this build cannot read, which is never overwritten.
    nonisolated func setSessionLabel(_ label: String?) async throws {
        _ = try await restoredSnapshot()
        try await withRecord { [self] store in
            for _ in 1 ... Self.maximumRecordWriteAttempts {
                let record: SessionRecord
                let expected: UInt64?
                switch try await store.read(sessionId) {
                case .pluginRecord(let payload) where PluginRecordSummary.isSignedOutMarker(payload):
                    // The plugin's signed-out marker holds no session, so it is labelled like nothing stored.
                    fallthrough
                case .absent:
                    guard label != nil else {
                        return
                    }
                    // A labelled signed-out row, listed with `includingSignedOut: true`.
                    record = .signedOut(label: label, username: nil)
                    expected = nil
                case .record(let envelope):
                    var labelled = envelope.record
                    labelled.label = label
                    record = labelled
                    expected = envelope.generation
                case .pluginRecord(let payload):
                    // The storage layer's first write after read-through: it lands on `.default`'s own
                    // key and leaves the plugin's record as it was.
                    record = try Self.record(adopting: payload, label: label, engine: engine)
                    expected = nil
                case .unsupportedSchema, .corrupt:
                    throw AuthClientError.unknown(
                        "Session \"\(sessionId)\" cannot be labelled: its saved record is one this version cannot read.",
                        "Sign the session out to reset it, or update the app."
                    )
                }
                if case .committed(let envelope) = try await store.write(record, for: sessionId, expecting: expected) {
                    await apply(SessionSnapshot(envelope), event: nil)
                    return
                }
            }
            throw Self.contended("label")
        }
    }

    // MARK: Adoption

    /// Completes the migration of the Auth plugin's session into `.default`: copies the plugin's record
    /// into `.default`'s own, then deletes the plugin's.
    ///
    /// The own write always lands before the plugin delete, so there is never a moment with neither
    /// record. Idempotent, and a no-op for any session other than `.default`, which is the only one
    /// that reads through.
    ///
    /// **It deletes only what it adopted.** The plugin's record is deleted if it is byte-equal to the
    /// credentials `.default` now holds, is the plugin's signed-out marker, or — when `.default` already
    /// had its own record — holds the same user (the plugin's older copy of a session the client has
    /// since refreshed). A plugin record for a different user, or one the plugin rewrote while this call
    /// was copying it, belongs to a session this call never adopted, and is kept.
    ///
    /// - Throws: `storageUnavailable` if storage failed; `.unknown` if the own record is unreadable, the
    ///   plugin's credentials cannot be read, or the plugin's record holds a session that was not
    ///   adopted. In every such case the plugin's record is kept.
    nonisolated func completeAdoption() async throws {
        guard sessionId == .default else {
            return
        }
        _ = try await restoredSnapshot()
        try await withRecord { [self] store in
            for _ in 1 ... Self.maximumRecordWriteAttempts {
                switch try await store.read(sessionId) {
                case .pluginRecord(let payload) where PluginRecordSummary.isSignedOutMarker(payload):
                    // The plugin's signed-out marker holds no session: nothing to adopt.
                    return
                case .pluginRecord(let payload):
                    let record = try Self.record(adopting: payload, label: nil, engine: engine)
                    guard case .committed(let envelope) = try await store.write(record, for: sessionId, expecting: nil) else {
                        // Another writer created the own record first: re-read, and decide from that.
                        continue
                    }
                    // The copy is committed. Delete the plugin's record only if it is still what was copied.
                    let current = try await store.pluginRecord(for: sessionId)
                    guard current == nil || current == payload || current.map(PluginRecordSummary.isSignedOutMarker) == true else {
                        throw Self.pluginRecordNotAdopted()
                    }
                    // Memory follows storage first: the own record is committed whether or not the delete
                    // below succeeds.
                    await apply(SessionSnapshot(envelope), event: nil)
                    try await store.removePluginRecord(for: sessionId)
                    return
                case .record(let envelope):
                    // Already has its own record: an earlier first write, or a lost race.
                    let plugin = try await store.pluginRecord(for: sessionId)
                    guard pluginRecordIsAdopted(plugin, by: envelope.record) else {
                        throw Self.pluginRecordNotAdopted()
                    }
                    // Memory follows storage first: the own record is committed whether or not the delete
                    // below succeeds.
                    await apply(SessionSnapshot(envelope), event: nil)
                    try await store.removePluginRecord(for: sessionId)
                    return
                case .absent:
                    return
                case .unsupportedSchema, .corrupt:
                    throw AuthClientError.unknown(
                        "The default session cannot complete adoption: its saved record is one this version cannot read.",
                        "Sign the session out to reset it, or update the app. The Auth plugin's record was kept."
                    )
                }
            }
            throw Self.contended("adoption")
        }
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
    /// Never signs out a different user who signed in to this session ID meanwhile: that is reported as
    /// `.superseded` and they stay signed in (see `SessionSignOut`).
    ///
    /// - Throws: `storageUnavailable` if storage failed. When only the purge failed, the session is
    ///   already signed out and its row is kept; the error's underlying error is then the sign-out's
    ///   revoke or global sign-out failure, if it had one, so the partial result is not lost.
    ///
    /// **The hosted UI's sign-out.** After a hosted-UI sign-in that shared the
    /// browser's cookies, the first attempt shows the hosted UI's logout page in `window`, holding the system
    /// sheet (`firstSignOutAttempt`); retries never do. The user closing it throws `.userCancelled` and leaves
    /// the session signed in. Without a window, a hosted UI or the sheet, the sign-out goes ahead without it and
    /// reports `hostedUIError` in `.partial`: the browser keeps its sign-in.
    nonisolated func signOut(
        global: Bool = false,
        purge: Bool = false,
        window: SignOutWindow = .none
    ) async throws -> AuthClientSignOutResult {
        _ = try await restoredSnapshot()
        return try await withRecord { [self] store in
            let engine = engine
            let outcome = try await SessionSignOut(
                sessionId: sessionId,
                store: store,
                describe: { try? engine.describe($0) },
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
            if outcome.endedSession {
                forgetRecordMemory()
                await cancelPendingSignIns()
                // The store deletes the challenge record when it signs a record out; a session with none to sign
                // out (a first sign-in waiting on its challenge) still ends that sign-in, so its record goes too.
                await deleteChallengeRecord(in: store)
            }
            let after: SessionSnapshot?
            do {
                after = try await store.load(sessionId)
            } catch {
                after = outcome.removedCredentials ? .absent : nil
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
                    let reason = (error as? AuthClientError).flatMap(\.storageUnavailableReason) ?? .interrupted
                    throw AuthClientError.storageUnavailable(
                        reason,
                        "Session \"\(sessionId)\" was signed out, but its saved row could not be removed.",
                        "Purge the session to remove the row.",
                        outcome.server.firstError ?? error
                    )
                }
                await apply(.absent, event: nil)
            }
            return try outcome.result()
        }
    }

    // MARK: Helpers

    /// Whether the plugin's record is one `.default`'s own record already carries, so deleting it loses no
    /// session: absent, the signed-out marker, byte-equal to the own credentials, or the same user.
    private nonisolated func pluginRecordIsAdopted(_ plugin: Data?, by own: SessionRecord) -> Bool {
        guard let plugin else {
            return true
        }
        if PluginRecordSummary.isSignedOutMarker(plugin) || plugin == own.credentials {
            return true
        }
        guard let ownSummary = try? SessionSnapshot(generation: nil, source: .own(own)).summary(engine: engine),
              let pluginSummary = try? engine.describe(plugin) else {
            // A signed-out own row, or credentials that cannot be read: nothing shows this is one session.
            return false
        }
        return pluginSummary.isSamePrincipal(as: ownSummary)
    }

    static func pluginRecordNotAdopted() -> AuthClientError {
        .unknown(
            "The Auth plugin's saved record holds a session the default session did not adopt, so it was kept.",
            "Another copy of the Auth plugin may be signing users in beside this client. Sign one of the two sessions out, then retry."
        )
    }

    /// `.default`'s own record holding the plugin's credentials verbatim, described by the engine.
    static func record(adopting payload: Data, label: String?, engine: any SessionEngine) throws -> SessionRecord {
        let summary = try engine.checkedDescribe(payload)
        return SessionRecord(
            label: label,
            username: summary.username,
            userId: summary.userId,
            kind: summary.kind,
            credentials: payload
        )
    }

    static func contended(_ operation: String) -> AuthClientError {
        .storageUnavailable(
            .interrupted,
            "The session's saved record kept changing, so the \(operation) could not be saved.",
            "Retry the operation."
        )
    }
}
