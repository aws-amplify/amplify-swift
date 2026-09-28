//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import Foundation

extension SessionRecordStore {

    /// Every saved session in this namespace, and the ones that are present but could not be read.
    struct Listing: Equatable, Sendable {

        /// Why a present record produced no row. Only records whose bytes were read and are not a record
        /// this build can use; a record that could not be read at all fails the whole listing.
        enum Unreadable: Equatable, Sendable {
            case unsupportedSchema(version: Int)
            case corrupt
        }

        /// One row per readable record, signed-out rows included, ordered by session ID.
        let sessions: [StoredSession]

        /// Records that exist but produced no row.
        let unreadable: [SessionID: Unreadable]
    }

    /// The saved sessions a picker renders, with no network call and without decoding credentials.
    ///
    /// `includingSignedOut: false` hides rows that were signed out and kept.
    ///
    /// - Throws: `AuthClientError.storageUnavailable` if the saved sessions could not be listed. Never
    ///   `[]` for a failure: an empty list shows sign-in to a user who is signed in.
    ///
    /// With `sweepingChallengesAt`, it also deletes, best effort, this namespace's interrupted sign-in records past
    /// their ceiling at that instant (`sweepExpiredChallenges`). An interrupted sign-in
    /// is never a row: a session whose only record is one is not listed.
    func storedSessions(includingSignedOut: Bool = false, sweepingChallengesAt now: Date? = nil) throws -> [StoredSession] {
        let accounts = try listAccounts()
        let sessions = try listing(accounts: accounts).sessions
        if let now {
            sweepExpiredChallenges(in: accounts, at: now)
        }
        return includingSignedOut ? sessions : sessions.filter { $0.kind != .signedOut }
    }

    /// Lists this namespace's session records in two phases.
    ///
    /// Phase one lists account names only, which reads no item data. Its failure throws, because an empty
    /// list must mean "nothing saved", never "could not look". The names are parsed as v1 session keys and
    /// kept only if they belong to this namespace, so the plugin's record, device metadata, the stored
    /// configuration, interrupted-sign-in records, other pools and other schema versions are all ignored.
    /// Duplicates — the same account seen once per access group by an unscoped listing — collapse to one
    /// session ID.
    ///
    /// Phase two reads each record on its own. A record with a newer schema or corrupt bytes is skipped
    /// and reported in `unreadable`, and is never written or deleted: it is not a transient condition, and
    /// one such record must not blank the list.
    ///
    /// **A record whose read fails throws the whole listing.** Dropping it would return a list that looks
    /// complete but is missing a session — possibly the only signed-in one, leaving just signed-out rows
    /// that the default filter then hides, so the picker would offer sign-in to a signed-in user. A failed
    /// read is usually a locked device, and retrying once it clears returns the full list. A record that
    /// disappears between the phases is simply gone.
    ///
    /// **`.default` is listed from the Auth plugin's record while it has none of its own**, because that is
    /// the record `.default` reads through to: leaving it out would show a migrated app's picker no
    /// sessions and offer sign-in to a signed-in user. Its kind and username are peeked from the plugin's
    /// stored format (`PluginRecordSummary`); it has no label. A plugin record of unrecognised shape is
    /// still listed, conservatively, and logged. Once `$default` exists — readable or not — only it
    /// counts, matching read precedence. A failed read of the plugin's record throws, like any row.
    ///
    /// **A session a restore would carry forward is listed too**, from its record under the namespace its
    /// marker records (`SessionRecordStore+CopyForward.swift`), as it would be carried: a picker shown right
    /// after a configuration change still offers it. Only for a session of this app with no row here, so no
    /// session is ever listed twice. A failed read of its marker or record throws, like any row.
    ///
    /// - Parameter listed: the service's accounts, if the caller has just listed them.
    func listing(accounts listed: [String]? = nil) throws -> Listing {
        let accounts = try listed ?? listAccounts()
        let sessionIds = Set(accounts.compactMap { account -> SessionID? in
            guard let parsed = SessionRecordKey.parse(account),
                  parsed.kind == .session,
                  parsed.namespaceComponent == namespace.pools.keyComponent else {
                return nil
            }
            return parsed.sessionId
        }).sorted { $0.stringValue < $1.stringValue }

        var sessions: [StoredSession] = []
        var unreadable: [SessionID: Listing.Unreadable] = [:]
        var defaultHasOwnRecord = false

        for sessionId in sessionIds {
            guard let data = try fetch(sessionAccount(for: sessionId), operation: "read a saved session") else {
                continue
            }
            if sessionId == .default {
                defaultHasOwnRecord = true
            }
            switch SessionRecordEnvelope.decode(data) {
            case .envelope(let envelope):
                sessions.append(StoredSession(
                    sessionId: sessionId,
                    label: envelope.record.label,
                    username: envelope.record.username,
                    kind: envelope.record.kind
                ))
            case .unsupportedSchema(let version):
                unreadable[sessionId] = .unsupportedSchema(version: version)
            case .corrupt:
                unreadable[sessionId] = .corrupt
            }
        }

        if !defaultHasOwnRecord, let pluginRow = try pluginRecordRow(listedAccounts: accounts) {
            sessions.append(pluginRow)
        }

        let present = Set(sessions.map(\.sessionId)).union(unreadable.keys)
        sessions += try previousConfigurationRows(listedAccounts: accounts, excluding: present)

        return Listing(sessions: sessions.sorted { $0.sessionId.stringValue < $1.sessionId.stringValue }, unreadable: unreadable)
    }

    /// The user ID (`sub`) each signed-in saved session of this namespace holds, by session ID: what a hosted-UI
    /// sign-in that must return a user of no other session checks against.
    ///
    /// Read as `listing()` reads: the same accounts, the same precedence for `.default` (its own record, else
    /// the Auth plugin's), and a session waiting to be carried forward counted as the user it would carry. A
    /// record's `userId` is used as stored, and `describe` reads it from the credentials
    /// when the record has none, as for a `.default` read through from the plugin's record. Signed-out, guest
    /// and federated rows, unreadable records, and credentials `describe` cannot read contribute nothing.
    ///
    /// - Throws: `AuthClientError.storageUnavailable` if a record could not be read: a missing session could
    ///   let its user through.
    func signedInUserIds(describe: (Data) -> CredentialSummary?) throws -> [SessionID: String] {
        let accounts = try listAccounts()
        var userIds: [SessionID: String] = [:]
        var defaultHasOwnRecord = false
        for account in accounts {
            guard let parsed = SessionRecordKey.parse(account),
                  parsed.kind == .session,
                  parsed.namespaceComponent == namespace.pools.keyComponent,
                  userIds[parsed.sessionId] == nil,
                  let data = try fetch(account, operation: "read a saved session") else {
                continue
            }
            if parsed.sessionId == .default {
                defaultHasOwnRecord = true
            }
            guard case .envelope(let envelope) = SessionRecordEnvelope.decode(data),
                  Self.isSignedIn(envelope.record.kind),
                  let credentials = envelope.record.credentials,
                  let userId = envelope.record.userId ?? describe(credentials)?.userId else {
                continue
            }
            userIds[parsed.sessionId] = userId
        }
        if !defaultHasOwnRecord,
           let legacyAccount = legacyAccount(for: .default),
           accounts.contains(legacyAccount),
           let data = try fetch(legacyAccount, operation: "read the Auth plugin's session record"),
           Self.isSignedIn(PluginRecordSummary.peek(data).kind),
           let userId = describe(data)?.userId ?? PluginRecordSummary.peek(data).userId {
            userIds[.default] = userId
        }
        // A session with no record here that a restore would carry forward holds its user already: it counts,
        // so a sign-in that must return a user of no other session holds before that session is restored.
        let pending = Set(accounts.compactMap { SessionRecordKey.parseMarker($0, scope: markerScope) })
            .subtracting(userIds.keys)
        for sessionId in pending.sorted(by: { $0.stringValue < $1.stringValue }) {
            if sessionId == .default, defaultHasOwnRecord || legacyAccount(for: .default).map(accounts.contains) == true {
                continue
            }
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

    /// One row per session of this app that has no record here but one a restore would carry forward, from
    /// the namespace its marker records.
    private func previousConfigurationRows(listedAccounts accounts: [String], excluding present: Set<SessionID>) throws -> [StoredSession] {
        let pending = Set(accounts.compactMap { SessionRecordKey.parseMarker($0, scope: markerScope) })
            .subtracting(present)
        return try pending.sorted { $0.stringValue < $1.stringValue }.compactMap { try pendingCarryRow(for: $0) }
    }

    /// The `.default` row read from the Auth plugin's record, if phase one listed it and it is still there.
    private func pluginRecordRow(listedAccounts: [String]) throws -> StoredSession? {
        guard let legacyAccount = legacyAccount(for: .default),
              listedAccounts.contains(legacyAccount),
              let data = try fetch(legacyAccount, operation: "read the Auth plugin's session record") else {
            return nil
        }
        let summary = PluginRecordSummary.peek(data)
        if !summary.isRecognised {
            AmplifyLogging.logger(for: SessionRecordStore.self).warn(
                "The Auth plugin's session record has a shape this version does not recognise. Listing it as "
                    + "the default session with kind \(PluginRecordSummary.unrecognisedKind) and no username."
            )
        }
        return StoredSession(sessionId: .default, label: nil, username: summary.username, kind: summary.kind)
    }
}
