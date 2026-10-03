//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import InternalAmplifyKeychain

/// Reads and writes the saved records of every session in one storage namespace.
///
/// One namespace is one set of pools under one keychain service and access group. When an access group is
/// configured, every read, write, delete and listing is scoped to it: the same account can exist once per
/// entitled access group, and an unscoped operation reaches all of the copies.
///
/// **A keychain failure is never "absent".** Every read distinguishes "nothing is stored" from "storage
/// could not be read", and the second always throws `AuthClientError.storageUnavailable`. A failed read
/// must never be answered with sign-in, and must never be answered by writing over the record.
///
/// This type does not serialize callers. Exclusion is per session record and belongs to the session that
/// owns it; the commit guard on `write` is what bounds a writer the process cannot exclude.
///
/// **`.default` uses the Auth plugin's saved login** (`SessionRecordStore+DefaultSession.swift`):
/// its session record is the plugin's own item, `amplify.<poolNamespace>.session`, holding the plugin's
/// `AmplifyCredentials` JSON, guarded on its stored bytes; a sidecar beside it holds what that format cannot (the label,
/// and the last user for a signed-out row). Named sessions keep their own envelopes under
/// `amplify.1.<poolNamespace>.<sessionId>.session`.
struct SessionRecordStore: Sendable {

    /// The service the Auth plugin stores its records under with no access group. Session records are
    /// siblings of the plugin's under the same service, and `.default`'s is the plugin's own.
    static let unsharedService = "com.amplify.awsCognitoAuthPlugin"

    /// The service the Auth plugin uses when an access group is configured.
    static let sharedService = "com.amplify.awsCognitoAuthPluginShared"

    static func service(forAccessGroup accessGroup: String?) -> String {
        accessGroup == nil ? unsharedService : sharedService
    }

    /// Guarded sign-out attempts before sign-out replaces a record whose credentials have not changed but
    /// whose metadata keeps moving. See `signOut(_:)`.
    static let maximumGuardedSignOutAttempts = 3

    let namespace: SessionStorageNamespace
    // Internal, not private, for the copy-forward extension (`SessionRecordStore+CopyForward.swift`).
    let keychain: any KeychainItemStoreBehavior
    let now: @Sendable () -> Date
    /// A credentials payload reduced to its user pool tokens, or `nil` if it holds none: how a record from a
    /// user pool namespace is carried forward (`readCarryingForward(_:)`). The engine's format; injectable so
    /// tests can use their own payloads.
    let userPoolTokensOnly: @Sendable (Data) throws -> Data?
    /// A credentials payload's identity pool identity ID, or `nil`: how two guests or federated identities are told
    /// apart when deciding whether a record under another namespace is the same user's
    /// (`SessionRecordStore+CopyForward.swift`). The engine's format; injectable for tests' payloads.
    let identityIdOf: @Sendable (Data) -> String?
    /// A credentials payload's user pool refresh token, or `nil`: whether a copy a sign-out sweeps holds a token the
    /// sign-out has not revoked (`copiesToRevoke`). The engine's format; injectable for tests' payloads.
    let refreshTokenOf: @Sendable (Data) -> String?
    /// Which app's namespace markers this store reads and writes (`SessionRecordStore+CopyForward.swift`): a
    /// digest of the bundle identifier, so an app and an extension sharing the access group keep their own.
    let markerScope: String
    /// What `.default`'s shared record holds, read from its stored format without decoding the credentials
    /// (`PluginRecordSummary.peek`). Injectable so tests can use their own payloads.
    let summarizeSharedRecord: @Sendable (Data) -> PluginRecordSummary
    /// Whether a read that finds `.default`'s shared record absent reads it once more before answering "absent".
    /// On by default on macOS only, where the keychain's `set` deletes the item and adds it again, so a reader
    /// in another process can find it missing in between; a property so tests can drive it on every platform.
    let rereadsAbsentSharedRecord: Bool
    /// Whether two payloads hold the same credentials, however they are encoded (`CredentialSlot.sameCredentials`):
    /// what a sign-out compares, so the Auth plugin saving `.default`'s credentials again in other bytes is not
    /// another writer's sign-in. The engine's format; injectable for tests' payloads.
    let sameCredentials: @Sendable (Data, Data) -> Bool

    init(
        namespace: SessionStorageNamespace,
        keychain: any KeychainItemStoreBehavior,
        now: @escaping @Sendable () -> Date = Date.init,
        userPoolTokensOnly: @escaping @Sendable (Data) throws -> Data? = CredentialSlot.userPoolTokensOnly,
        identityIdOf: @escaping @Sendable (Data) -> String? = CredentialSlot.identityId,
        refreshTokenOf: @escaping @Sendable (Data) -> String? = CredentialSlot.refreshToken,
        markerScope: String = SessionRecordStore.appMarkerScope,
        summarizeSharedRecord: @escaping @Sendable (Data) -> PluginRecordSummary = PluginRecordSummary.peek,
        rereadsAbsentSharedRecord: Bool = SessionRecordStore.rereadsAbsentSharedRecordByDefault,
        sameCredentials: @escaping @Sendable (Data, Data) -> Bool = CredentialSlot.sameCredentials
    ) {
        self.namespace = namespace
        self.keychain = keychain
        self.now = now
        self.userPoolTokensOnly = userPoolTokensOnly
        self.identityIdOf = identityIdOf
        self.refreshTokenOf = refreshTokenOf
        self.markerScope = markerScope
        self.summarizeSharedRecord = summarizeSharedRecord
        self.rereadsAbsentSharedRecord = rereadsAbsentSharedRecord
        self.sameCredentials = sameCredentials
    }

    /// A store over the real keychain.
    init(namespace: SessionStorageNamespace) {
        self.init(
            namespace: namespace,
            keychain: KeychainItemStore(
                service: Self.service(forAccessGroup: namespace.accessGroup),
                accessGroup: namespace.accessGroup,
                logger: ClientLog.logger(ClientLog.keychainItemStore)
            )
        )
    }

    // MARK: Accounts

    /// The account of a session's record: for `.default` the Auth plugin's own (`pluginSessionAccount(for:)`), for a
    /// named session its envelope's.
    func sessionAccount(for sessionId: SessionID) -> String {
        pluginSessionAccount(for: sessionId) ?? SessionRecordKey.account(for: sessionId, in: namespace.pools, kind: .session)
    }

    func challengeAccount(for sessionId: SessionID) -> String {
        SessionRecordKey.account(for: sessionId, in: namespace.pools, kind: .challenge)
    }

    /// The Auth plugin's own record, `amplify.<poolNamespace>.session`: `.default`'s session record, and no other
    /// session's. `nil` for named sessions, which never read, write or delete it.
    func pluginSessionAccount(for sessionId: SessionID) -> String? {
        sessionId == .default ? SessionRecordKey.pluginSessionAccount(in: namespace.pools) : nil
    }

    // MARK: Read

    /// What is stored for a session.
    enum ReadResult: Equatable, Sendable {
        /// Nothing is stored. The only result that means "no session".
        case absent
        /// A record this build reads, with the version a write over it must expect.
        case record(VersionedSessionRecord)
        /// A record written by a newer schema. Present, so not "no session", and not corrupt: it is
        /// never overwritten by `write` or deleted except by an explicit sign-out or purge.
        case unsupportedSchema(version: Int)
        /// Bytes under the session's key that are not a record. Present, so not "no session".
        case corrupt
    }

    /// Reads a session's record: for `.default`, the shared record and its sidecar (`readDefault()`).
    ///
    /// - Throws: `AuthClientError.storageUnavailable` if the record (or `.default`'s sidecar) could not be read.
    func read(_ sessionId: SessionID) throws -> ReadResult {
        if sessionId == .default {
            return try readDefault()
        }
        if let data = try fetch(sessionAccount(for: sessionId), operation: "read the session record") {
            switch SessionRecordEnvelope.decode(data) {
            case .envelope(let envelope):
                return .record(VersionedSessionRecord(envelope))
            case .unsupportedSchema(let version):
                return .unsupportedSchema(version: version)
            case .corrupt:
                return .corrupt
            }
        }
        return .absent
    }

    // MARK: Write

    /// Whether a guarded write landed.
    enum CommitOutcome: Equatable, Sendable {
        /// Written: the record as a read would now return it, with the version a write over it must expect.
        case committed(VersionedSessionRecord)
        /// Not written, because the record is no longer what the caller read. Not an error.
        case discarded

        var didCommit: Bool {
            if case .committed = self { return true }
            return false
        }
    }

    /// Writes `record` only if the stored record is still the one the caller read — the commit guard.
    ///
    /// Re-reads the session's key and compares its generation with `expected` (`nil` means "I read no
    /// record"; a `.storedBytes` version never matches a generation). If they match, writes the record one
    /// generation later, conditioned on the stored bytes being unchanged; the first write goes through
    /// add-if-absent. Otherwise writes nothing and returns `.discarded`. A record this build cannot read
    /// (newer schema, corrupt) is never overwritten here, so it discards too.
    ///
    /// **This is not atomic, and cannot be.** The keychain has no compare-and-swap, so a window remains
    /// between the re-read and the write in which another process sharing the access group can land.
    /// The guard bounds the lost update; it is not a lock.
    ///
    /// **`.discarded` means "your view is stale": re-read, and act on what is there now.** Never answer it
    /// with a forcing retry — re-reading only to take the new generation and writing the same payload, or
    /// looping until it commits. The record that moved is newer than the caller's: typically a
    /// concurrent refresh that already rotated the refresh token. Forcing the write restores the older
    /// token, which the server has already invalidated, and the session can never refresh again.
    ///
    /// **`.default`** writes the Auth plugin's record instead, guarded on its stored bytes, and then its sidecar
    /// (`writeDefault`, `SessionRecordStore+DefaultSession.swift`). No namespace marker is written for it.
    ///
    /// - Throws: `AuthClientError.storageUnavailable` if the record could not be read or written.
    ///
    /// Creating a record with credentials, or writing one over a signed-out row, also records, in the session's
    /// namespace marker, that the session is kept here (`SessionRecordStore+CopyForward.swift`);
    /// `recordingMarker: false` leaves that to the caller.
    @discardableResult
    func write(
        _ record: SessionRecord,
        for sessionId: SessionID,
        expecting expected: RecordVersion?,
        recordingMarker: Bool = true
    ) throws -> CommitOutcome {
        if sessionId == .default {
            return try writeDefault(record, expecting: expected)
        }
        let account = sessionAccount(for: sessionId)
        let current = try fetch(account, operation: "read the session record before writing it")

        let nextGeneration: UInt64
        // Whether this write starts the session's record here: over nothing, or over a signed-out row.
        var starts = true
        if let current {
            guard case .envelope(let stored) = SessionRecordEnvelope.decode(current),
                  expected == .generation(stored.generation) else {
                return .discarded
            }
            starts = stored.record.isSignedOut
            let (next, overflow) = stored.generation.addingReportingOverflow(1)
            guard !overflow else {
                return .discarded
            }
            nextGeneration = next
        } else {
            guard expected == nil else {
                return .discarded
            }
            nextGeneration = 1
        }

        let envelope = SessionRecordEnvelope(generation: nextGeneration, lastWriteTimestamp: now(), record: record)
        let committed = try perform("write the session record") {
            try keychain.setIfUnchanged(envelope.encoded(), key: account, expecting: current)
        }
        if committed, recordingMarker, starts, record.credentials != nil {
            // A record with credentials created here, or written over a signed-out row (a sign-in after a
            // sign-out, perhaps after a rollback): the session's marker names this namespace from now on
            // (`SessionRecordStore+CopyForward.swift`). Best effort.
            recordStartedHere(sessionId, record: record)
        }
        return committed ? .committed(VersionedSessionRecord(envelope)) : .discarded
    }

    // MARK: Sign-out and purge

    /// What a sign-out did.
    enum SignOutOutcome: Equatable, Sendable {
        /// The record now holds no credentials: this call wrote it signed out, or it already was.
        case signedOut
        /// There is no record — nothing was stored, or it was purged concurrently — and none was created.
        case noRecord
        /// Another writer replaced the credentials this sign-out set out to remove — a sign-in, or a
        /// refresh in another process — so its record was left alone. The caller re-reads and decides.
        case superseded
    }

    /// Signs a session's record out, keeping the row.
    ///
    /// Writes a record with no credentials and `kind: .signedOut`, carrying the label and username forward so
    /// a picker can still render the row as signed-out and resumable. A session with no record has no row to keep,
    /// so nothing is written. For `.default` that is the sidecar first (the last user and the label), then the
    /// plugin's `{"noCredentials":{}}` through the guard.
    ///
    /// **It removes only the credentials it read.** The first read fixes which credentials this sign-out
    /// is removing. It writes through the commit guard; on a lost race it re-reads, and:
    /// - if the credentials are still the ones it is removing — only the generation or metadata moved,
    ///   as with a concurrent label write — it tries again, carrying the new label forward, and after
    ///   `maximumGuardedSignOutAttempts` replaces the record unguarded;
    /// - if they changed, another writer has signed in (or refreshed) over it, and erasing that would
    ///   sign out a session this call never saw — possibly a different user, whose tokens nobody revoked.
    ///   It returns `.superseded` and leaves that record alone.
    ///
    /// Unless superseded, it also deletes the session's interrupted-sign-in record; a superseded sign-out leaves it,
    /// since it may belong to the newer sign-in.
    ///
    /// A record this build cannot read is replaced by a signed-out row, since its credentials cannot be
    /// kept past sign-out; its generation cannot be read, so the row starts again at generation 1.
    ///
    /// Idempotent. A failure part-way leaves the call safe to repeat.
    ///
    /// Not `@discardableResult`: a caller that ignored `.superseded` would report "signed out" for a
    /// session that is still signed in. The credentials are opaque here, so a refresh by another process
    /// cannot be told apart from a different user's sign-in. **The caller contract** on `.superseded`:
    /// re-read; if the record still holds the same user, revoke the new tokens and sign out again, a
    /// bounded number of times; otherwise leave the new user signed in and report that another sign-in
    /// replaced the session. `SessionSignOut` is that caller.
    ///
    /// - Throws: `AuthClientError.storageUnavailable` if storage could not be read or written.
    func signOut(_ sessionId: SessionID) throws -> SignOutOutcome {
        try signOut(sessionId, expecting: .firstRead)
    }

    /// Signs a session's record out only if it still holds `credentials` — the payload the caller has just
    /// revoked. Otherwise returns `.superseded` and writes nothing.
    ///
    /// The plain `signOut(_:)` fixes what it removes from its own first read. A caller that revoked tokens
    /// first needs this form: between its last check and the store's first read, another process sharing
    /// the access group can sign a different user in, and the plain form would then erase that user, whose
    /// tokens nobody revoked.
    ///
    /// - Throws: `AuthClientError.storageUnavailable` if storage could not be read or written.
    func signOut(_ sessionId: SessionID, removing credentials: Data) throws -> SignOutOutcome {
        try signOut(sessionId, expecting: .credentials(credentials))
    }

    /// Which credentials a sign-out is removing.
    private enum Removing {
        /// Whatever the first read finds.
        case firstRead
        /// Exactly these; anything else means another writer got there first.
        case credentials(Data)
    }

    private func signOut(_ sessionId: SessionID, expecting removing: Removing) throws -> SignOutOutcome {
        var removed: SessionRecord?
        let outcome = try signOutRecord(sessionId, removing: removing, removed: &removed)
        // A superseded sign-out left the session signed in, so nothing else of it is deleted: not the
        // interrupted sign-in record, which may belong to the newer sign-in.
        guard outcome != .superseded else {
            return outcome
        }
        try perform("delete the interrupted sign-in record") { try keychain.remove(challengeAccount(for: sessionId)) }
        guard sessionId != .default else {
            // `.default` keeps no namespace marker, so it has no remembered copies or challenges to sweep.
            return outcome
        }
        // Its interrupted sign-ins under the namespaces its marker remembers, which no restore resumes: before the
        // copies below, whose sweep rewrites the marker. Best effort, as that sweep is.
        try removeRememberedChallenges(of: sessionId, reference: removed, throwing: false)
        // The copies of the session this app left under earlier namespaces (its namespace marker), which a
        // rollback would otherwise find signed in: each deleted only while untouched since it was carried. Best
        // effort, and last: the session is already signed out here, and a failure must not leave a live session
        // reporting a user whose tokens are revoked. A copy left behind is deleted by the next sign-out or purge.
        // The record signed out tells which user the copies must hold.
        try? removePreviousCopies(of: sessionId, reference: removed, throwing: false)
        return outcome
    }

    private func signOutRecord(_ sessionId: SessionID, removing expected: Removing, removed: inout SessionRecord?) throws -> SignOutOutcome {
        var removing: Data?
        if case .credentials(let credentials) = expected {
            removing = credentials
        }
        var attempt = 0
        while true {
            attempt += 1
            let credentials: Data?
            let record: SessionRecord
            let version: RecordVersion?
            switch try read(sessionId) {
            case .absent:
                return .noRecord
            case .record(let stored):
                if stored.record.isSignedOut {
                    return .signedOut
                }
                credentials = stored.record.credentials
                removed = stored.record
                record = .signedOut(
                    label: stored.record.label,
                    username: stored.record.username,
                    userId: stored.record.userId
                )
                version = stored.version
            case .unsupportedSchema, .corrupt:
                // Unreadable on the first read: replace it. Unreadable only after a lost race, or when the
                // caller named the credentials it revoked: a newer writer put it there, and this call
                // cannot tell whose it is.
                guard attempt == 1, case .firstRead = expected else {
                    return .superseded
                }
                return try replaceUnreadable(sessionId)
            }

            if attempt == 1, case .firstRead = expected {
                removing = credentials
            } else if !Self.holdSameCredentials(credentials, removing, sameCredentials) {
                return .superseded
            }

            if try write(record, for: sessionId, expecting: version).didCommit {
                return .signedOut
            }
            if attempt >= Self.maximumGuardedSignOutAttempts {
                return try forceSignOut(sessionId, removing: removing)
            }
        }
    }

    /// For `.default`: deletes the Auth plugin's record (the shared saved login), then the sidecar, then the
    /// interrupted-sign-in record (`purgeDefault`). It keeps no namespace marker, so nothing else is deleted.
    ///
    /// For a named session, deletes, in this order: the copies this app left under
    /// earlier namespaces of the purged record's user, each only while untouched since it was carried
    /// (`removePreviousCopies`, `SessionRecordStore+CopyForward.swift`), with that user's interrupted-sign-in records
    /// under the namespaces its marker remembers, deleted before the copies (`SessionRecordStore+Challenge.swift`);
    /// the session's record; its interrupted-sign-in record; and last its namespace marker, so no later restore
    /// carries it forward again. A copy another writer changed is left: it is that writer's.
    ///
    /// **The marker is kept, rewritten, when other users' copies are left** (alice's while bob purges): it is
    /// rewritten to name this namespace, where no record is left, with no user and only those copies, so it carries
    /// nothing, even if it named a later namespace (a purge under an older configuration), and the copies stay for
    /// their own users' sign-out, purge or rollback check. A rollback reads none of them as swept, since no user's
    /// session is recorded as ended here.
    ///
    /// **Purged under an older configuration** (a namespace the marker does not name, such as an app rolled back
    /// before it restored the session): this namespace's record and its user's remembered copies are deleted, but not
    /// the record under the namespace the marker names, which this store does not own: that record is then a session
    /// of its own, restored as signed in under its configuration. Purge under the configuration the session last ran
    /// with to end it everywhere.
    ///
    /// Local only: nothing is revoked, so the refresh token stays valid server-side until it expires.
    /// Idempotent; deleting an absent record succeeds.
    ///
    /// - Throws: `AuthClientError.storageUnavailable` if a record could not be read or deleted, or the namespace
    ///   marker read, rewritten or deleted last.
    func purge(_ sessionId: SessionID) throws {
        if sessionId == .default {
            return try purgeDefault()
        }
        // Before the session's own record, so a failure leaves the session as it was: its interrupted sign-ins
        // under the namespaces its marker remembers (`SessionRecordStore+Challenge.swift`), read from the marker
        // before the copies' sweep rewrites it, then those copies.
        try removeRememberedChallenges(of: sessionId)
        try removePreviousCopies(of: sessionId)
        try perform("delete the session record") { try keychain.remove(sessionAccount(for: sessionId)) }
        try perform("delete the interrupted sign-in record") { try keychain.remove(challengeAccount(for: sessionId)) }
        // Last: until the record is gone, a marker naming this namespace carries nothing. A marker that still
        // remembers other users' copies (the ones the sweep left, each with its recorded user) is rewritten to name
        // this namespace, where no record is left, with no user and only those copies: it carries nothing, even
        // when it named a later namespace (a purge under an older configuration), and its copies stay for their
        // own users' sign-out, purge or rollback check. Any other marker, an unreadable one or one whose copies
        // record no user (inert: nothing ever sweeps them) included, is deleted.
        if case .marker(let marker) = try readMarker(for: sessionId), marker.copies.contains(where: { $0.user != nil }) {
            let own = namespace.pools.keyComponent
            let kept = NamespaceMarker(
                poolNamespace: own,
                copies: marker.copies.filter { $0.user != nil && $0.poolNamespace != own },
                user: nil
            )
            if kept != marker {
                try writeMarker(kept, for: sessionId)
            }
            return
        }
        try perform("delete the namespace marker") { try keychain.remove(markerAccount(for: sessionId)) }
    }

    // MARK: Keychain access

    /// Reads an item, `nil` if none is stored. Every failure throws `storageUnavailable`.
    func fetch(_ account: String, operation: String) throws -> Data? {
        try perform(operation) { try keychain.dataIfPresent(account) }
    }

    func listAccounts() throws -> [String] {
        try perform("list the saved sessions") { try keychain.allAccounts() }
    }

    /// Sign-out's last resort after repeated lost races: replaces the record unguarded, but only if it
    /// still holds the credentials being removed, carrying forward its current label and username.
    private func forceSignOut(_ sessionId: SessionID, removing credentials: Data?) throws -> SignOutOutcome {
        if sessionId == .default {
            return try forceSignOutDefault(removing: credentials)
        }
        let account = sessionAccount(for: sessionId)
        guard let data = try fetch(account, operation: "read the session record before signing it out") else {
            return .noRecord
        }
        guard case .envelope(let stored) = SessionRecordEnvelope.decode(data) else {
            return .superseded
        }
        if stored.record.isSignedOut {
            return .signedOut
        }
        guard stored.record.credentials == credentials else {
            return .superseded
        }
        let record = SessionRecord.signedOut(
            label: stored.record.label,
            username: stored.record.username,
            userId: stored.record.userId
        )
        return try replace(account, with: record, after: stored.generation) ? .signedOut : .noRecord
    }

    /// Replaces a record this build cannot read with a signed-out row, unless it has meanwhile become
    /// one it can read — another writer's, which is left alone.
    private func replaceUnreadable(_ sessionId: SessionID) throws -> SignOutOutcome {
        if sessionId == .default {
            return try replaceUnreadableDefault()
        }
        let account = sessionAccount(for: sessionId)
        guard let data = try fetch(account, operation: "read the session record before signing it out") else {
            return .noRecord
        }
        if case .envelope = SessionRecordEnvelope.decode(data) {
            return .superseded
        }
        return try replace(account, with: .signedOut(label: nil, username: nil), after: nil) ? .signedOut : .noRecord
    }

    /// An unguarded replace, for sign-out only, one generation past `generation`.
    ///
    /// Replaces an existing item and never creates one: `set` is delete-then-add on macOS, which opens a
    /// window in which the record reads as absent, loses the row if the add fails, and would recreate a
    /// record that a concurrent purge removed.
    ///
    /// - Returns: `false` if the record no longer exists — it was purged — and so was not recreated.
    private func replace(_ account: String, with record: SessionRecord, after generation: UInt64?) throws -> Bool {
        let next = generation.map { $0 == .max ? $0 : $0 + 1 } ?? 1
        let envelope = SessionRecordEnvelope(generation: next, lastWriteTimestamp: now(), record: record)
        return try perform("write the session record") {
            try keychain.replaceIfPresent(envelope.encoded(), key: account)
        }
    }

    /// Whether two optional payloads hold the same credentials: both absent, or both present and the same decoded.
    static func holdSameCredentials(_ lhs: Data?, _ rhs: Data?, _ same: (Data, Data) -> Bool) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil):
            return true
        case (let lhs?, let rhs?):
            return same(lhs, rhs)
        default:
            return false
        }
    }

    func perform<Value>(_ operation: String, _ body: () throws -> Value) throws -> Value {
        do {
            return try body()
        } catch {
            throw AuthClientError.storageUnavailable(from: error, operation: operation)
        }
    }
}
