//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import Foundation
import InternalAWSCognitoAuth

extension SessionRecordStore {

    /// Every saved session in this namespace, and the ones that are present but could not be read.
    struct Listing: Equatable, Sendable {

        /// Why a present record is a `.failed` row. Only records whose bytes were read and are not a record
        /// this build can use; a record that could not be read at all fails the whole listing.
        enum Unreadable: Equatable, Sendable {
            case unsupportedSchema(version: Int)
            case corrupt
        }

        /// One row per saved session, signed-out rows included, ordered by session ID.
        let sessions: [StoredSession]

        /// The named sessions whose record this build cannot read. Each is a `.failed` row.
        let unreadable: [SessionID: Unreadable]
    }

    /// The saved sessions a picker renders, with no network call.
    ///
    /// `includingSignedOut: false` hides the rows whose state is `.signedOut`: rows that were signed out and kept.
    /// One with an interrupted sign-in is `.awaitingChallenge`, and is not hidden.
    ///
    /// - Throws: `AuthClientError.storageUnavailable` if the saved sessions could not be listed. Never
    ///   `[]` for a failure: an empty list shows sign-in to a user who is signed in.
    ///
    /// With `sweepingChallengesAt`, an interrupted sign-in past its ceiling at that instant is not listed, as a
    /// restore would not resume it, and the listing also deletes, best effort, this namespace's interrupted sign-in
    /// records past their ceiling (`sweepExpiredChallenges`). Without it there is no clock, and none is treated as
    /// expired.
    ///
    /// With `pluginConfiguration`, the `.default` row is the one a restore under it would read after the plugin's
    /// configuration-change rule (`pendingPluginCarry(current:)`).
    func storedSessions(
        includingSignedOut: Bool = false,
        sweepingChallengesAt now: Date? = nil,
        pluginConfiguration: AuthConfiguration? = nil
    ) throws -> [StoredSession] {
        let accounts = try listAccounts()
        let sessions = try listing(accounts: accounts, pluginConfiguration: pluginConfiguration, challengesAt: now).sessions
        if let now {
            sweepExpiredChallenges(in: accounts, at: now)
        }
        return includingSignedOut ? sessions : sessions.filter { $0.state != .signedOut }
    }

    /// Lists this namespace's session records in two phases.
    ///
    /// Phase one lists account names only, which reads no item data. Its failure throws, because an empty
    /// list must mean "nothing saved", never "could not look". The names are parsed as v1 session keys and
    /// kept only if they belong to this namespace, so the plugin's record, device metadata, the stored
    /// configuration, other pools and other schema versions are all ignored.
    /// Duplicates — the same account seen once per access group by an unscoped listing — collapse to one
    /// session ID.
    ///
    /// Phase two reads each record on its own. A record with a newer schema or corrupt bytes is a `.failed` row,
    /// reported in `unreadable` too, and is never written or deleted: it is not a transient condition, and
    /// one such record must not blank the list.
    ///
    /// **Each row's state is the one a restore would report** (`SessionSnapshot.state`), from what is saved for
    /// the session as a restore's snapshot holds it, and never from a session live in the process. Where a record
    /// does not itself name its principal (a federated record, or one saved with no user ID), `.default`'s included,
    /// its credentials are decoded as its engine decodes them (`describeCredentials`); no other row's are read. A
    /// restore differs in the two cases `StoredSession.state` names: a copy a rollback's restore would sweep, and a
    /// `.default` login the plugin's rule would carry that this build cannot read. **An interrupted sign-in is listed
    /// as a restore would resume it** (`SessionCore.pendingOrResumedChallenge`): over a signed-out or guest row, and
    /// as a row of its own for a session with nothing else saved. Its record is read only for those; a failed read
    /// throws, like any row's.
    ///
    /// **A record whose read fails throws the whole listing.** Dropping it would return a list that looks
    /// complete but is missing a session — possibly the only signed-in one, leaving just signed-out rows
    /// that the default filter then hides, so the picker would offer sign-in to a signed-in user. A failed
    /// read is usually a locked device, and retrying once it clears returns the full list. A record that
    /// disappears between the phases is simply gone.
    ///
    /// **`.default` is listed from the Auth plugin's record, its session record, and its sidecar**: its kind and
    /// user are peeked from the plugin's stored format (`PluginRecordSummary`), its label is the sidecar's while
    /// the sidecar applies, and a signed-out or absent record beside a sidecar is a signed-out row with the sidecar's
    /// label and last user. A plugin record of unrecognised shape is still listed, conservatively, and logged.
    /// An `amplify.1.<ns>.$default.session` item, left by development builds, is never read or listed. A failed read
    /// of the plugin's record or the sidecar throws, like any row.
    ///
    /// **A session a restore would carry forward is listed too**, from its record under the namespace its
    /// marker records (`SessionRecordStore+CopyForward.swift`), as it would be carried: a picker shown right
    /// after a configuration change still offers it. Only for a named session of this app with no row here, so no
    /// session is ever listed twice. A failed read of its marker or record throws, like any row.
    ///
    /// - Parameters:
    ///   - listed: the service's accounts, if the caller has just listed them.
    ///   - pluginConfiguration: the engine configuration `.default` runs with, for its pending carry; `nil` lists this
    ///     namespace's own record only.
    ///   - now: the instant an interrupted sign-in's ceiling is judged at; `nil` treats none as expired.
    func listing(
        accounts listed: [String]? = nil,
        pluginConfiguration: AuthConfiguration? = nil,
        challengesAt now: Date? = nil
    ) throws -> Listing {
        let accounts = try listed ?? listAccounts()
        let sessionIds = Set(accounts.compactMap { account -> SessionID? in
            guard let parsed = SessionRecordKey.parse(account),
                  parsed.kind == .session,
                  // A `$default` session record is a development build's leftover, never a row.
                  parsed.sessionId != .default,
                  parsed.namespaceComponent == namespace.pools.keyComponent else {
                return nil
            }
            return parsed.sessionId
        }).sorted { $0.stringValue < $1.stringValue }
        // The sessions with an interrupted sign-in saved, `.default` included.
        let challenged = Set(accounts.compactMap { account -> SessionID? in
            guard let parsed = SessionRecordKey.parse(account),
                  parsed.kind == .challenge,
                  parsed.namespaceComponent == namespace.pools.keyComponent else {
                return nil
            }
            return parsed.sessionId
        })

        // What is saved for each session, as a restore's snapshot holds it.
        var saved: [SessionID: SessionSnapshot.Source] = [:]
        var unreadable: [SessionID: Listing.Unreadable] = [:]

        for sessionId in sessionIds {
            guard let data = try fetch(sessionAccount(for: sessionId), operation: "read a saved session") else {
                continue
            }
            switch SessionRecordEnvelope.decode(data) {
            case .envelope(let envelope):
                saved[sessionId] = .own(envelope.record)
            case .unsupportedSchema(let version):
                saved[sessionId] = .unreadable(.unsupportedSchema(version: version))
                unreadable[sessionId] = .unsupportedSchema(version: version)
            case .corrupt:
                saved[sessionId] = .unreadable(.corrupt)
                unreadable[sessionId] = .corrupt
            }
        }

        if let pending = try pluginConfiguration.flatMap({ try pendingPluginCarry(current: $0) }) {
            saved[.default] = .own(pending)
        } else if let source = try defaultSource(listedAccounts: accounts) {
            saved[.default] = source
        }

        // A session of this app with no record here but one a restore would carry forward, from the namespace its
        // marker records.
        let pending = pendingMarkerSessions(in: accounts).subtracting(saved.keys)
        for sessionId in pending.sorted(by: { $0.stringValue < $1.stringValue }) {
            saved[sessionId] = try pendingCarriedRecord(for: sessionId).map { .own($0) }
        }
        // A session with nothing saved but an interrupted sign-in.
        for sessionId in challenged.subtracting(saved.keys) {
            saved[sessionId] = .absent
        }

        let sessions = try saved.sorted { $0.key.stringValue < $1.key.stringValue }.compactMap { sessionId, source in
            try row(sessionId, source, challenged: challenged.contains(sessionId), at: now)
        }
        return Listing(sessions: sessions, unreadable: unreadable)
    }

    /// The row for what is saved under `sessionId`: the session's record, a record this build cannot read, or
    /// nothing (`.absent`) beside an interrupted sign-in, which is a row only while a restore would resume it.
    ///
    /// - Throws: `AuthClientError.storageUnavailable` if the interrupted sign-in's record could not be read.
    private func row(
        _ sessionId: SessionID,
        _ source: SessionSnapshot.Source,
        challenged: Bool,
        at now: Date?
    ) throws -> StoredSession? {
        var state = SessionSnapshot.state(of: source, challenge: nil, describe: describeCredentials)
        // Resumed only over a session that can be signing in, as a restore resumes it.
        if challenged, state == .signedOut || state == .guest, let step = try resumableChallenge(sessionId, at: now) {
            state = SessionSnapshot.state(of: source, challenge: step, describe: describeCredentials)
        }
        switch source {
        case .absent:
            // No credentials are saved, as for a signed-out row: the closest kind.
            return state == .signedOut ? nil : StoredSession(sessionId: sessionId, label: nil, user: nil, kind: .signedOut, state: state)
        case .unreadable:
            // As `.default`'s unrecognised record is listed: a record is there, and nothing says what it holds.
            return StoredSession(sessionId: sessionId, label: nil, user: nil, kind: PluginRecordSummary.unrecognisedKind, state: state)
        case .own(let record):
            // The signed-in user, else the last one a signed-out row kept. A guest or federated row names none,
            // whatever its record holds.
            var user: AuthClientUser?
            if case .signedIn(let signedIn) = state {
                user = signedIn
            } else if Self.isSignedIn(record.kind) || record.kind == .signedOut {
                user = CredentialSummary(kind: record.kind, username: record.username, userId: record.userId).user
            }
            return StoredSession(sessionId: sessionId, label: record.label, user: user, kind: record.kind, state: state)
        }
    }

    /// The step of the session's interrupted sign-in, if a restore at `now` would resume it: `nil` with no record,
    /// one past its ceiling, a newer schema's, corrupt bytes, or one this build cannot resume. Nothing is deleted
    /// here: a restore deletes most of those, and a listing sweeps the expired (`sweepExpiredChallenges`).
    private func resumableChallenge(_ sessionId: SessionID, at now: Date?) throws -> AuthClientSignInStep? {
        guard case .record(let record) = try readChallenge(sessionId), now.map(record.isPastCeiling(at:)) != true else {
            return nil
        }
        return record.state.resumedState(logger: ClientEngineLogger())?.1
    }

    /// The user ID (`sub`) each signed-in saved session of this namespace holds, by session ID: what a hosted-UI
    /// sign-in that must return a user of no other session checks against.
    ///
    /// Read as `listing()` reads: the same accounts (and, with `rereadsAbsentSharedRecord`, the Auth plugin's record
    /// even when they miss it), `.default` from the Auth plugin's record only, and a named
    /// session waiting to be carried forward counted as the user it would carry. A record's `userId` is used as
    /// stored, and `describe` reads it from the credentials when the record has none, and always for `.default`.
    /// Signed-out, guest and federated rows, unreadable records, and credentials `describe` cannot read contribute
    /// nothing.
    ///
    /// - Throws: `AuthClientError.storageUnavailable` if a record could not be read: a missing session could
    ///   let its user through.
    ///
    /// With `pluginConfiguration`, `.default` counts as the user a restore under it would read after the Auth plugin's
    /// configuration-change rule (`pendingPluginCarry(current:)`): a login the rule would carry here holds its user
    /// before `.default` is restored.
    func signedInUserIds(describe: (Data) -> CredentialSummary?, pluginConfiguration: AuthConfiguration? = nil) throws -> [SessionID: String] {
        let accounts = try listAccounts()
        var userIds: [SessionID: String] = [:]
        for account in accounts {
            guard let parsed = SessionRecordKey.parse(account),
                  parsed.kind == .session,
                  // A `$default` session record is a development build's leftover: `.default` is the plugin's record.
                  parsed.sessionId != .default,
                  parsed.namespaceComponent == namespace.pools.keyComponent,
                  userIds[parsed.sessionId] == nil,
                  let data = try fetch(account, operation: "read a saved session") else {
                continue
            }
            guard case .envelope(let envelope) = SessionRecordEnvelope.decode(data),
                  Self.isSignedIn(envelope.record.kind),
                  let credentials = envelope.record.credentials,
                  let userId = envelope.record.userId ?? describe(credentials)?.userId else {
                continue
            }
            userIds[parsed.sessionId] = userId
        }
        if let pending = try pluginConfiguration.flatMap({ try pendingPluginCarry(current: $0) }) {
            if Self.isSignedIn(pending.kind), let credentials = pending.credentials,
               let userId = describe(credentials)?.userId ?? pending.userId {
                userIds[.default] = userId
            }
        } else if accounts.contains(sharedRecordAccount) || rereadsAbsentSharedRecord,
                  let data = try fetchSharedRecord(operation: "read the default session's saved login") {
            let summary = summarizeSharedRecord(data)
            if summary.isRecognised, Self.isSignedIn(summary.kind), let userId = describe(data)?.userId ?? summary.userId {
                userIds[.default] = userId
            }
        }
        // A named session with no record here that a restore would carry forward holds its user already: it counts,
        // so a sign-in that must return a user of no other session holds before that session is restored.
        let pending = pendingMarkerSessions(in: accounts).subtracting(userIds.keys)
        for sessionId in pending.sorted(by: { $0.stringValue < $1.stringValue }) {
            guard !accounts.contains(sessionAccount(for: sessionId)),
                  let record = try pendingCarriedRecord(for: sessionId),
                  Self.isSignedIn(record.kind),
                  let credentials = record.credentials,
                  let userId = record.userId ?? describe(credentials)?.userId else {
                continue
            }
            userIds[sessionId] = userId
        }
        return userIds
    }

    private static func isSignedIn(_ kind: SessionKind) -> Bool {
        kind == .userPoolOnly || kind == .userPoolAndIdentityPool
    }

    /// The named sessions of this app with a namespace marker among `accounts`. A `$default` marker is a development
    /// build's leftover: `.default` keeps none.
    private func pendingMarkerSessions(in accounts: [String]) -> Set<SessionID> {
        Set(accounts.compactMap { SessionRecordKey.parseMarker($0, scope: markerScope) }).subtracting([.default])
    }

    /// What is saved for `.default`, from the Auth plugin's record and the sidecar, if phase one listed either and
    /// one is still there. With `rereadsAbsentSharedRecord`, the record is read even when phase one did not list it:
    /// on macOS a listing taken inside another writer's delete-then-add misses it, and absent once is not signed out.
    private func defaultSource(listedAccounts: [String]) throws -> SessionSnapshot.Source? {
        let readsRecord = listedAccounts.contains(sharedRecordAccount) || rereadsAbsentSharedRecord
        guard readsRecord || listedAccounts.contains(sidecarAccount) else {
            return nil
        }
        let data = readsRecord ? try fetchSharedRecord(operation: "read the default session's saved login") : nil
        let sidecar = try readSidecar().meta
        guard let data else {
            return sidecar.map { .own(Self.signedOutRow($0)) }
        }
        guard let record = defaultRecord(holding: data, sidecar: sidecar) else {
            ClientLog.logger(ClientLog.sessionRecordStore).warn(
                "The Auth plugin's session record has a shape this version does not recognise. Listing it as "
                    + "the default session with kind \(PluginRecordSummary.unrecognisedKind) and no user."
            )
            return .unreadable(.corrupt)
        }
        return .own(record)
    }
}
