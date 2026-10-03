//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import CryptoKit
import Foundation

// Carrying a named session forward across a pool configuration change (decided 2026-09-26: copy forward
// like the plugin). `.default` is the plugin's own record and takes no part in this (see the end of this comment).
//
// A record's key embeds the pool namespace (`SessionRecordKey`): the user pool ID, the identity pool ID, or
// both. Adding a pool, or changing one, is a new namespace, which starts with no record.
//
// **The recorded previous configuration.** The plugin keeps the configuration it last ran with
// (`authConfigurationKey`) and, on start, compares it with the current one
// (`AWSCognitoAuthCredentialStore.restoreCredentialsOnConfigurationChanges`). The client keeps the same fact per
// session: a **namespace marker**, `amplify.1.<sessionId>.<app>.configuration`, recording the namespace this app
// last kept the session's record under. It is written when a record with credentials is first created here, or
// written over a signed-out row (a sign-in, a guest, a carry), and when a restore finds a record here,
// not signed out, that the marker does not name. A session that never held a record writes none, so reading one writes nothing. `<app>` is
// a digest of the bundle identifier, so an app and an extension sharing the access group and a session ID, with
// different configurations, never act on each other's marker. The account ends in `configuration`, which is not a
// record kind, so `SessionRecordKey.parse`, and every listing of this build and of earlier ones, ignores it. A
// marker this build cannot read (corrupt, or a newer schema) is never overwritten, and carries nothing.
//
// A session is carried **only from the namespace its marker names**, only when that differs from the current
// one, only when the current namespace holds no record for it, and only on the changes the plugin accepts:
//
// | Plugin branch | Recorded namespace | Current namespace | The client carries |
// |---|---|---|---|
// | no old user pool, same identity pool (`:127`) | `<ip>` | `<up>.<ip>` | the record as it is (a guest, or a federated identity) |
// | same user pool (`:138-140`) | `<up>` | `<up>.<ip>` | the user pool tokens; the identity is fetched lazily (`identityPending`) |
// | same user pool (`:138-140`) | `<up>.<ip2>` | `<up>.<ip>` | the user pool tokens only: **not** the identity from `<ip2>` (below); fetched lazily |
// | same user pool (`:138-140`) | `<up>.<ip>` | `<up>` | the user pool tokens only |
// | anything else (`:148-153`) | — | — | nothing; the record there is **kept** (the plugin clears it: below) |
//
// So the latest recorded state wins. A signed-out or absent record under the recorded namespace carries nothing,
// even if an older namespace still holds the user (a tombstone). A signed-out row under the *current* namespace is
// the session's own answer too, so a rollback to a configuration whose row was signed out does not carry the
// session back (the safe direction); a sign-in over that row makes the marker name this namespace again. Records
// under the namespace the marker names are read, never others. A session with no marker (none was ever written: a
// record from an earlier build, or another app's) carries nothing.
//
// **A change the client does not carry keeps the old record** (a deliberate difference for named sessions: the
// plugin's `:148-153` branch deletes it). An app can switch its pool configuration at runtime under one session ID (an organisation picker),
// which the plugin cannot; deleting there would delete the other configuration's live session, unrevoked, on every
// switch. The first record started under the new namespace remembers the old one as a copy, with its digest and its
// own user, whoever starts (`recordStartedHere`), so its user's sign-out or purge there sweeps it while it is
// untouched. Switching, or rolling, back reads the old session as it was, unless it was signed out there.
//
// **Copy and keep, as the plugin does.** The record is re-wrapped, never copied byte for byte: written through the
// commit guard as a new record (generation 1) with the same label, username and user ID. The old record is **kept**:
// a rollback reads it again, as the plugin's does. The marker names the new namespace and remembers the copy it came
// from, with a SHA-256 of the bytes that were carried. Sign-out and purge delete a remembered copy **only while its
// bytes still have that digest, it provably holds the same user, and it is not a guest's** (`removePreviousCopies`). The
// digest detects a write after the carry (an app extension on the old configuration that refreshed the record, or
// signed another user in): that record is another writer's, and is left and logged. It does not detect that the
// copy is still read without being written: an extension that only reads the old record loses it at sign-out. A guest's
// copy is never swept, since an extension on the old configuration may use its identity ID, which a new guest there
// would not get back. The marker is per app, but records are shared by every app and extension in the access group.
// A swept copy's refresh token is revoked first when it differs from the one the sign-out revoked (it was rotated
// under the old configuration since the carry) and the copy's user pool is this configuration's; otherwise a deleted
// copy's refresh token is not revoked, and stays valid until it expires.
//
// **What a rollback reads.** Back under a namespace whose record is still the untouched copy the marker remembers,
// with the session signed out or purged under the namespace the marker names (by another app or extension, which
// does not know this app's copies, or by a sign-out whose sweep failed), the copy reads as swept and is deleted
// (`readKept`); not a guest's. Otherwise the session is kept here from then on, and the record under the namespace
// the marker named is remembered as a copy, with its own user, whoever holds the record here.
//
// **Whose each copy is.** The marker records each copy's user (`userKey`: `user:<userId>`, else
// `identity:<identityId>`) and the user of the record under the namespace it names, as additive keys (schema 1 still;
// earlier builds ignore them). Copies are kept whoever starts a session afterwards, and each is taken only by its own
// user: a sweep, and a revoke, only when the copy's user is the session's (the record signed out or purged, else the
// marker's user for this namespace); a rollback's "read as swept" only when the copy's user is the user whose session
// ended under the namespace the marker names (the marker's user, else the signed-out row's). A copy with no recorded
// user (an earlier build's marker) is never swept. No record while the marker names this namespace (another writer
// purged it) sweeps nothing: the marker keeps its copies for their users.
//
// If the old record **vanished or was signed out** between the carry's read and its re-read after the commit (a purge
// or sign-out of the session under the old configuration raced the carry), the carry is undone: the new record is
// deleted while it still holds exactly the committed record (its generation and contents), and the session reads as
// absent. No re-read-then-delete here is atomic (the keychain has no compare-and-delete): a writer that lands between
// the two calls loses its write.
//
// **A deliberate difference from the plugin's `:138` branch.** The plugin copies its record's bytes, so a changed
// identity pool inherits an identity ID and AWS credentials from the old one. The client never carries an
// identity across a changed identity pool: only the tokens, and the new pool issues its own identity on first
// use. **Another:** a record whose kind the change does not carry (a guest under a user-pool-only namespace, as
// the plugin's own row-146 test data stores) is not carried, and not cleared; the plugin copies any bytes.
//
// A keychain failure reading the marker or the recorded record is a failure, never "nothing to carry": the
// restore fails with `storageUnavailable`, and nothing is carried or recorded. A record this build cannot read (a
// newer schema, corrupt bytes, a payload the engine cannot reduce) is not carried and is left alone.
//
// **Limits.** The marker remembers one copy per namespace, with no other bound: as many as the configurations the
// app has kept the session under. On macOS the keychain's `set` is delete-then-add, so the marker's read-modify-write
// can lose a concurrent writer's marker update (another process of the same app): the marker then names one of the
// two namespaces, and the next carry or sweep acts on that.
//
// Device metadata and the ASF device ID are not carried, as the plugin does not carry them.
//
// **Named sessions only.** `.default`'s record is the Auth plugin's own (`SessionRecordStore+DefaultSession.swift`):
// it keeps no marker, so none is read, written or deleted for it, nothing is carried and nothing is swept here. It
// follows the plugin's own rule instead (`SessionRecordStore+PluginConfiguration.swift`). A `$default` marker left by a
// development build is never touched.
extension SessionRecordStore {

    /// The marker scope of this process: the first 16 hex digits of the SHA-256 of its bundle identifier.
    static let appMarkerScope: String = {
        // A process with no bundle identifier (a command-line tool) shares the scope of `"unknown-bundle"` with every
        // other such process on the device.
        let identifier = Bundle.main.bundleIdentifier ?? "unknown-bundle"
        return SHA256.hash(data: Data(identifier.utf8)).prefix(8).map { String(format: "%02x", $0) }.joined()
    }()

    /// The SHA-256 of a record's stored bytes, hex: what a marker remembers of a copy.
    static func digest(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    /// What a session's namespace marker records.
    struct NamespaceMarker: Codable, Equatable, Sendable {
        static let currentSchemaVersion = 1

        /// A record of the session this app left under an earlier namespace: the namespace, the digest of its bytes
        /// then, and whose it is (`userKey`). Sign-out and purge delete it only while it still has that digest, and
        /// only for that user.
        struct Copy: Codable, Equatable, Sendable {
            var poolNamespace: String
            var sha256: String
            /// The copy's user (`SessionRecordStore.userKey`): an additive key, absent in markers of earlier builds,
            /// whose copies are then never swept (their user cannot be proved).
            var user: String?
        }

        var schemaVersion = NamespaceMarker.currentSchemaVersion
        /// The rendered namespace this app last kept the session's record under.
        var poolNamespace: String
        /// Copies left under earlier namespaces, oldest first: at most one per namespace, so no more than the
        /// configurations this app has kept the session under. Kept whoever starts a session afterwards: each names
        /// its user, and only that user's sign-out, purge or rollback check takes it.
        var copies: [Copy] = []
        /// The user of the record kept under `poolNamespace` when the marker was last written there: whose session
        /// ended if that record is later signed out without a user, or purged. An additive key, like `Copy.user`.
        var user: String?

        /// This marker with the session kept under `own` by `user`, and `copy` (if any) remembered.
        func keptHere(_ own: String, user: String?, remembering copy: Copy? = nil) -> NamespaceMarker {
            var kept = copies.filter { $0.poolNamespace != own && $0.poolNamespace != copy?.poolNamespace }
            if let copy, copy.poolNamespace != own {
                kept.append(copy)
            }
            return NamespaceMarker(poolNamespace: own, copies: kept, user: user)
        }
    }

    /// Who a record's user is, as the marker records it: `user:<userId>` for a user pool user, else
    /// `identity:<identityId>` for a guest or federated identity, else `nil` (a signed-out row of a guest, say). Two
    /// records with the same key are the same user; a user pool user and a guest never share one, even with the same
    /// identity ID (a guest, and the user it later signed in as).
    func userKey(_ record: SessionRecord) -> String? {
        if let userId = record.userId {
            return "user:" + userId
        }
        return record.credentials.flatMap(identityIdOf).map { "identity:" + $0 }
    }

    /// What is stored as a session's marker.
    enum MarkerRead: Equatable, Sendable {
        case absent
        case marker(NamespaceMarker)
        /// Present, but corrupt or of a newer schema: never overwritten, and it carries nothing.
        case unreadable
    }

    /// How a record under the recorded namespace is carried into this one.
    enum Carry: Equatable, Sendable {
        /// As it is: a guest or federated record from the identity-pool-only namespace.
        case asIs
        /// Its user pool tokens only (`userPoolOnly`), dropping any identity ID and AWS credentials.
        /// `identityPending` when this configuration has an identity pool: the identity is fetched lazily.
        case userPoolTokensOnly(identityPending: Bool)

        /// The kinds of record this carry takes.
        func accepts(_ kind: SessionKind) -> Bool {
            switch self {
            case .asIs:
                return kind == .guest || kind == .federated
            case .userPoolTokensOnly:
                return kind == .userPoolOnly || kind == .userPoolAndIdentityPool
            }
        }
    }

    /// How a session recorded under `previous` is carried into `current`, or `nil` if the change is not one
    /// the plugin carries (the table above).
    static func carry(from previous: PoolNamespace, into current: PoolNamespace) -> Carry? {
        switch (previous, current) {
        case let (.identityPool(old), .userPoolAndIdentityPool(_, new)) where old == new:
            return .asIs
        case let (.userPool(old), .userPoolAndIdentityPool(new, _)) where old == new:
            return .userPoolTokensOnly(identityPending: true)
        case let (.userPoolAndIdentityPool(oldUserPool, oldIdentityPool), .userPoolAndIdentityPool(newUserPool, newIdentityPool))
            where oldUserPool == newUserPool && oldIdentityPool != newIdentityPool:
            return .userPoolTokensOnly(identityPending: true)
        case let (.userPoolAndIdentityPool(old, _), .userPool(new)) where old == new:
            return .userPoolTokensOnly(identityPending: false)
        default:
            return nil
        }
    }

    // MARK: Markers

    func markerAccount(for sessionId: SessionID) -> String {
        SessionRecordKey.markerAccount(for: sessionId, scope: markerScope)
    }

    private struct SchemaProbe: Decodable {
        let schemaVersion: Int
    }

    /// The session's namespace marker for this app.
    ///
    /// - Throws: `AuthClientError.storageUnavailable` if it could not be read.
    func readMarker(for sessionId: SessionID) throws -> MarkerRead {
        // `.default` keeps no marker; a `$default` one is a development build's leftover, never read.
        guard sessionId != .default else {
            return .absent
        }
        guard let data = try fetch(markerAccount(for: sessionId), operation: "read the session's namespace marker") else {
            return .absent
        }
        guard let probe = try? JSONDecoder().decode(SchemaProbe.self, from: data),
              probe.schemaVersion == NamespaceMarker.currentSchemaVersion,
              let marker = try? JSONDecoder().decode(NamespaceMarker.self, from: data) else {
            return .unreadable
        }
        return .marker(marker)
    }

    /// The session's readable marker, or `nil` if it is absent or unreadable.
    ///
    /// - Throws: `AuthClientError.storageUnavailable` if it could not be read.
    func marker(for sessionId: SessionID) throws -> NamespaceMarker? {
        guard case .marker(let marker) = try readMarker(for: sessionId) else {
            return nil
        }
        return marker
    }

    /// Writes the session's namespace marker for this app.
    ///
    /// - Throws: `AuthClientError.storageUnavailable` if it could not be written.
    func writeMarker(_ marker: NamespaceMarker, for sessionId: SessionID) throws {
        guard sessionId != .default else {
            return
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(marker)
        try performStorage("write the session's namespace marker") {
            try keychain.set(data, key: markerAccount(for: sessionId))
        }
    }

    /// Rewrites the session's marker as `change` returns it, if it changed; never an unreadable one. Best effort: a
    /// failure is logged and leaves the marker as it was. A stale marker only matters after a later configuration
    /// change, and then carries at most the record it names, under the checks of every carry.
    func updateMarker(_ sessionId: SessionID, _ change: (NamespaceMarker?) -> NamespaceMarker) {
        guard sessionId != .default else {
            return
        }
        do {
            let current: NamespaceMarker?
            switch try readMarker(for: sessionId) {
            case .absent: current = nil
            case .marker(let marker): current = marker
            case .unreadable: return
            }
            let next = change(current)
            if next != current {
                try writeMarker(next, for: sessionId)
            }
        } catch {
            ClientLog.logger(ClientLog.sessionRecordStore).warn(
                "The session's namespace marker could not be written. A later configuration change may not carry the session forward."
            )
        }
    }

    /// Records that the session's record, `record`, is kept under this namespace, remembering `copy`.
    func recordRunningHere(_ sessionId: SessionID, record: SessionRecord, remembering copy: NamespaceMarker.Copy? = nil) {
        let own = namespace.pools.keyComponent
        let user = userKey(record)
        updateMarker(sessionId) { ($0 ?? NamespaceMarker(poolNamespace: own)).keptHere(own, user: user, remembering: copy) }
    }

    /// Records that `record` started the session here (a sign-in, a guest, over nothing or a signed-out
    /// row). If the marker named another namespace whose record is not signed out (a change the client does not
    /// carry, such as an app switching its pool configuration under one session ID), that record is remembered as a
    /// copy with its digest and **its own** user, whoever starts here: only that user's sign-out or purge sweeps it,
    /// while it is untouched, and only that user's ended session reads it as swept on a rollback. It is never deleted
    /// here: switching back reads it as it was, unless it was signed out there. The marker's other copies are kept
    /// whoever starts here: each names its user, and only that user's sign-out, purge or rollback check takes it.
    /// Best effort: a failed read remembers nothing.
    func recordStartedHere(_ sessionId: SessionID, record: SessionRecord) {
        let own = namespace.pools.keyComponent
        let user = userKey(record)
        updateMarker(sessionId) { current in
            guard let current, current.poolNamespace != own else {
                return (current ?? NamespaceMarker(poolNamespace: own)).keptHere(own, user: user)
            }
            let account = SessionRecordKey.account(for: sessionId, namespaceComponent: current.poolNamespace, kind: .session)
            guard let data = try? fetch(account, operation: "read the session record of the configuration the marker names"),
                  case .envelope(let stored) = SessionRecordEnvelope.decode(data),
                  !stored.record.isSignedOut else {
                return current.keptHere(own, user: user)
            }
            let copy = NamespaceMarker.Copy(
                poolNamespace: current.poolNamespace,
                sha256: Self.digest(data),
                user: userKey(stored.record)
            )
            return current.keptHere(own, user: user, remembering: copy)
        }
    }

    // MARK: Carrying

    /// The record under the recorded namespace as it would be carried here, if the change carries it.
    func carried(_ old: SessionRecord, by carry: Carry) -> SessionRecord? {
        guard !old.isSignedOut, let credentials = old.credentials, carry.accepts(old.kind) else {
            return nil
        }
        switch carry {
        case .asIs:
            return SessionRecord(label: old.label, username: old.username, userId: old.userId, kind: old.kind, credentials: credentials)
        case .userPoolTokensOnly(let identityPending):
            // A payload the engine cannot read is not carried, and is left where it is.
            guard let tokens = try? userPoolTokensOnly(credentials) else {
                return nil
            }
            return SessionRecord(
                label: old.label,
                username: old.username,
                userId: old.userId,
                kind: .userPoolOnly,
                credentials: tokens,
                identityPending: identityPending
            )
        }
    }

    /// Where the session's marker says it was kept last, if it is carried from there into this namespace.
    func recordedPrevious(_ marker: NamespaceMarker?) -> (component: String, carry: Carry)? {
        guard let marker, marker.poolNamespace != namespace.pools.keyComponent,
              let previous = PoolNamespace(keyComponent: marker.poolNamespace),
              let carry = Self.carry(from: previous, into: namespace.pools) else {
            return nil
        }
        return (marker.poolNamespace, carry)
    }

    /// The namespace the marker names, if it is not this one: where a carry, a rollback's check, or the clearing of
    /// a change the plugin does not carry reads, so the gate a restore also takes.
    func markerSource(_ marker: NamespaceMarker?) -> PoolNamespace? {
        guard let marker, marker.poolNamespace != namespace.pools.keyComponent else {
            return nil
        }
        return PoolNamespace(keyComponent: marker.poolNamespace)
    }

    /// The namespace other than this one that the session's marker names, if any: the gate a restore also takes.
    ///
    /// - Throws: `AuthClientError.storageUnavailable` if the marker could not be read.
    func carrySource(for sessionId: SessionID) throws -> PoolNamespace? {
        markerSource(try marker(for: sessionId))
    }

    /// The record under the recorded namespace, as it would be carried here, with its account and stored bytes.
    private func pendingCarry(for sessionId: SessionID, marker: NamespaceMarker?) throws -> (account: String, data: Data, record: SessionRecord)? {
        guard let previous = recordedPrevious(marker) else {
            return nil
        }
        let account = SessionRecordKey.account(for: sessionId, namespaceComponent: previous.component, kind: .session)
        guard let data = try fetch(account, operation: "read the session record of the previous configuration"),
              case .envelope(let source) = SessionRecordEnvelope.decode(data),
              let record = carried(source.record, by: previous.carry) else {
            // The latest recorded state holds nothing to carry: signed out, gone, or unreadable.
            return nil
        }
        return (account, data, record)
    }

    /// A carry's source is not the namespace whose gate the caller holds: the marker changed since the caller read
    /// it. The caller takes the gates again.
    struct CarrySourceChanged: Error {}

    /// Reads the session's record, first carrying it forward from the namespace its marker records if this
    /// namespace holds none. Returns what is stored for the session afterwards.
    ///
    /// Also, so that no ended session comes back: a record here that is the untouched copy of a session since signed
    /// out or purged under the namespace the marker names, of that session's user, reads as swept, and is deleted
    /// (`readKept`); a signed-out row here sweeps the copies the marker remembers that provably hold its user. A
    /// change the client does not carry leaves the record there as it is.
    ///
    /// - Parameter heldSource: For a caller that holds the gate of the namespace the marker names (a restore): the
    ///   namespace it expects. A marker naming another throws `CarrySourceChanged` instead. `nil` does not check.
    /// `.default` keeps no marker: this is its plain `read`.
    ///
    /// - Throws: `AuthClientError.storageUnavailable` if the marker or a record could not be read or written;
    ///   nothing is carried then.
    func readCarryingForward(_ sessionId: SessionID, heldSource: PoolNamespace?? = nil) throws -> ReadResult {
        guard sessionId != .default else {
            return try read(sessionId)
        }
        let current = try read(sessionId)
        let markerRead = try readMarker(for: sessionId)
        let own = namespace.pools.keyComponent
        switch current {
        case .record(let stored):
            return try readKept(stored, of: sessionId, markerRead: markerRead, heldSource: heldSource)
        case .absent:
            break
        case .unsupportedSchema, .corrupt:
            return current
        }
        guard case .marker(let marker) = markerRead else {
            return current
        }
        if marker.poolNamespace == own {
            // No record here, though the marker names this namespace: another writer purged the session here, or
            // this app did, leaving the marker it rewrites to name this namespace with no user and only other users'
            // copies (`purge`). With no record to tell whose the copies are, none is swept. The marker keeps them for
            // their own users: a rollback reads one as swept only when its user's session ended here, which a marker
            // with no user (this app's purge) never records.
            return current
        }
        if let heldSource, markerSource(marker) != heldSource {
            throw CarrySourceChanged()
        }
        guard let previous = PoolNamespace(keyComponent: marker.poolNamespace) else {
            return current
        }
        guard Self.carry(from: previous, into: namespace.pools) != nil else {
            // A change the client does not carry: the record there is kept, as it was. The first record started
            // here remembers it as a copy with its own user, whoever starts (`recordStartedHere`).
            return current
        }
        guard let source = try pendingCarry(for: sessionId, marker: marker) else {
            return current
        }
        switch try write(source.record, for: sessionId, expecting: nil, recordingMarker: false) {
        case .committed(let committed):
            let copy = NamespaceMarker.Copy(
                poolNamespace: marker.poolNamespace,
                sha256: Self.digest(source.data),
                user: userKey(source.record)
            )
            let user = userKey(source.record)
            updateMarker(sessionId) { ($0 ?? marker).keptHere(own, user: user, remembering: copy) }
            return undoIfTheSourceEnded(sessionId, source: source.account, committed: committed)
        case .discarded:
            // Another writer stored a record meanwhile: that one is the session's.
            return try read(sessionId)
        }
    }

    /// A record here, as a restore reads it.
    ///
    /// - A signed-out row sweeps the copies the marker remembers: another writer, which does not know this app's
    ///   copies, signed the session out here.
    /// - With the marker naming another namespace (this app is back here: a rollback): if the session was signed out
    ///   or purged there, and this record is still the untouched copy the marker remembers, it reads as swept and is
    ///   deleted, as that sign-out or purge would have deleted it. A guest's copy is never swept: an app extension
    ///   still on this configuration keeps its identity. Otherwise the session is kept here from now on, and the
    ///   record there, if not signed out, is remembered as a copy with its own user.
    private func readKept(
        _ stored: VersionedSessionRecord,
        of sessionId: SessionID,
        markerRead: MarkerRead,
        heldSource: PoolNamespace??
    ) throws -> ReadResult {
        let own = namespace.pools.keyComponent
        guard case .marker(let marker) = markerRead else {
            if case .absent = markerRead, !stored.record.isSignedOut, stored.record.credentials != nil {
                recordRunningHere(sessionId, record: stored.record)
            }
            return .record(stored)
        }
        if stored.record.isSignedOut {
            sweepQuietly(sessionId, marker: marker, reference: stored.record)
            return .record(stored)
        }
        guard marker.poolNamespace != own else {
            return .record(stored)
        }
        if let heldSource, markerSource(marker) != heldSource {
            throw CarrySourceChanged()
        }
        let otherAccount = SessionRecordKey.account(for: sessionId, namespaceComponent: marker.poolNamespace, kind: .session)
        let otherData = try fetch(otherAccount, operation: "read the session record of the configuration the marker names")
        var other: SessionRecord?
        if let otherData, case .envelope(let decoded) = SessionRecordEnvelope.decode(otherData) {
            other = decoded.record
        }
        let ended = otherData == nil || other?.isSignedOut == true
        // Whose session ended there: the user the marker recorded for it, else the signed-out row's.
        let endedUser = marker.user ?? other.flatMap(userKey)
        if ended, stored.record.kind != .guest,
           let kept = marker.copies.first(where: { $0.poolNamespace == own }),
           let keptUser = kept.user, keptUser == endedUser {
            let account = sessionAccount(for: sessionId)
            // Not atomic: re-read, then delete. A writer that lands in between loses its write.
            if let data = try fetch(account, operation: "re-read the session record kept here"), Self.digest(data) == kept.sha256 {
                try performStorage("delete the copy of a session signed out under a later configuration") {
                    try keychain.remove(account)
                }
                updateMarker(sessionId) { current in
                    var next = current ?? marker
                    next.copies.removeAll { $0.poolNamespace == own }
                    return next
                }
                return .absent
            }
        }
        var copy: NamespaceMarker.Copy?
        if let otherData, let other, !other.isSignedOut {
            copy = NamespaceMarker.Copy(poolNamespace: marker.poolNamespace, sha256: Self.digest(otherData), user: userKey(other))
        }
        recordRunningHere(sessionId, record: stored.record, remembering: copy)
        return .record(stored)
    }

    /// After the carried record committed: if the old record vanished, or was signed out, since it was read (a
    /// purge or sign-out under the old configuration raced the carry), undoes the carry, deleting the new record
    /// while it still holds exactly the committed record (its generation and contents). Best effort: a failure is
    /// logged, and the carried record kept.
    private func undoIfTheSourceEnded(_ sessionId: SessionID, source: String, committed: VersionedSessionRecord) -> ReadResult {
        do {
            if let data = try fetch(source, operation: "re-read the carried session record") {
                guard case .envelope(let stored) = SessionRecordEnvelope.decode(data), stored.record.isSignedOut else {
                    return .record(committed)
                }
            }
            let account = sessionAccount(for: sessionId)
            // Not atomic: re-read, then delete. A writer that lands in between loses its write.
            guard let current = try fetch(account, operation: "re-read the session record carried here"),
                  case .envelope(let stored) = SessionRecordEnvelope.decode(current),
                  VersionedSessionRecord(stored) == committed else {
                return try read(sessionId)
            }
            try performStorage("undo the carry of a session ended meanwhile") { try keychain.remove(account) }
            return .absent
        } catch {
            ClientLog.logger(ClientLog.sessionRecordStore).warn(
                "Could not check whether a session carried forward was signed out or purged under its previous configuration meanwhile."
            )
            return .record(committed)
        }
    }

    // MARK: Sweeping

    /// `removePreviousCopies`, logging a failure instead of throwing: for a restore, whose answer does not depend on
    /// it.
    private func sweepQuietly(_ sessionId: SessionID, marker: NamespaceMarker, reference: SessionRecord?) {
        guard !marker.copies.isEmpty else {
            return
        }
        try? removePreviousCopies(of: sessionId, marker: marker, reference: reference, throwing: false)
    }

    /// Deletes the copies of the session the marker remembers, each only while its bytes still have the digest the
    /// marker recorded, and only if the user the marker recorded for it is the session's: `reference`'s (the
    /// session's record here, read if not given), else the user the marker recorded for this namespace. A copy that
    /// changed belongs to another writer (an app extension still on that configuration), and is left, and logged; so
    /// is a guest's copy, whose identity such an extension may still use, and a copy of another user or with no
    /// recorded user. The marker then remembers the copies whose deletion failed and those of another user or none
    /// (each for its own user's sign-out, purge or rollback check), and forgets the rest.
    ///
    /// - Parameters:
    ///   - marker: the marker, if the caller has just read it.
    ///   - reference: the session's record, if the caller has just read it (a sign-out: the record it signed out).
    ///   - throwing: whether a failure throws (purge), or is logged (sign-out, which has already signed the session
    ///     out here and must not fail on this).
    /// - Throws: `AuthClientError.storageUnavailable`, when `throwing`, if the marker, the session's record or a copy
    ///   could not be read, or a copy or the marker could not be written.
    func removePreviousCopies(
        of sessionId: SessionID,
        marker knownMarker: NamespaceMarker? = nil,
        reference knownReference: SessionRecord? = nil,
        throwing: Bool = true
    ) throws {
        let logger = ClientLog.logger(ClientLog.sessionRecordStore)
        let marker: NamespaceMarker
        let reference: SessionRecord?
        let referenceUser: String?
        do {
            if let knownMarker {
                marker = knownMarker
            } else {
                guard case .marker(let read) = try readMarker(for: sessionId) else {
                    return
                }
                marker = read
            }
            guard !marker.copies.isEmpty else {
                return
            }
            if let knownReference {
                reference = knownReference
            } else if case .record(let own) = try read(sessionId) {
                reference = own.record
            } else {
                reference = nil
            }
            referenceUser = reference.flatMap(userKey)
                ?? (marker.poolNamespace == namespace.pools.keyComponent ? marker.user : nil)
        } catch {
            if throwing { throw error }
            logger.warn("A session's copies under a previous configuration could not be read. They are deleted by its next sign-out or purge.")
            return
        }
        var left: [NamespaceMarker.Copy] = []
        for copy in marker.copies where copy.poolNamespace != namespace.pools.keyComponent {
            let account = SessionRecordKey.account(for: sessionId, namespaceComponent: copy.poolNamespace, kind: .session)
            do {
                guard let data = try fetch(account, operation: "read a session record of a previous configuration") else {
                    continue
                }
                guard Self.digest(data) == copy.sha256, case .envelope(let stored) = SessionRecordEnvelope.decode(data) else {
                    logger.info("A session's copy under a previous configuration changed since it was carried, so another writer holds it. It is left.")
                    continue
                }
                guard stored.record.kind != .guest else {
                    logger.info("A guest's copy under a previous configuration is left: an app extension on that configuration may still use its identity.")
                    continue
                }
                guard let copyUser = copy.user, copyUser == referenceUser else {
                    // Kept in the marker: a rollback to it still reads it as swept if its user's session ended here.
                    logger.info("A session's copy under a previous configuration is not provably the same user's. It is left.")
                    left.append(copy)
                    continue
                }
                try performStorage("delete a session record of a previous configuration") { try keychain.remove(account) }
            } catch {
                if throwing { throw error }
                logger.warn("A session's copy under a previous configuration could not be deleted. It is deleted by its next sign-out or purge.")
                left.append(copy)
            }
        }
        var next = marker
        next.copies = left
        if next != marker {
            do {
                try writeMarker(next, for: sessionId)
            } catch {
                if throwing { throw error }
                logger.warn("The session's namespace marker could not be written after its copies were swept.")
            }
        }
    }

    /// The credentials of the copies a sign-out's sweep would delete (`removePreviousCopies`) that hold a refresh
    /// token other than `revoking`'s, under this configuration's user pool, whose token the sign-out's revoke does
    /// not reach: this side rotated after the carry, or the other side rotated before the copy was remembered. The
    /// sign-out revokes them first, with this configuration's engine; a carry needs the same user pool, so the pool's
    /// revoke accepts them. A copy under another user pool is swept without a revoke, and its refresh token stays
    /// valid until it expires.
    ///
    /// - Throws: `AuthClientError.storageUnavailable` if the marker, the session's record or a copy could not be read.
    func copiesToRevoke(of sessionId: SessionID, revoking payload: Data) throws -> [Data] {
        guard sessionId != .default, case .marker(let marker) = try readMarker(for: sessionId), !marker.copies.isEmpty,
              let userPool = namespace.pools.userPoolId else {
            return []
        }
        var referenceUser: String?
        if case .record(let own) = try read(sessionId) {
            referenceUser = userKey(own.record)
        }
        referenceUser = referenceUser ?? (marker.poolNamespace == namespace.pools.keyComponent ? marker.user : nil)
        let revoked = refreshTokenOf(payload)
        var copies: [Data] = []
        for copy in marker.copies where copy.poolNamespace != namespace.pools.keyComponent {
            guard PoolNamespace(keyComponent: copy.poolNamespace)?.userPoolId == userPool else {
                continue
            }
            let account = SessionRecordKey.account(for: sessionId, namespaceComponent: copy.poolNamespace, kind: .session)
            guard let data = try fetch(account, operation: "read a session record of a previous configuration"),
                  Self.digest(data) == copy.sha256,
                  case .envelope(let stored) = SessionRecordEnvelope.decode(data),
                  stored.record.kind != .guest,
                  let credentials = stored.record.credentials,
                  let copyUser = copy.user, copyUser == referenceUser,
                  let token = refreshTokenOf(credentials),
                  token != revoked else {
                continue
            }
            copies.append(credentials)
        }
        return copies
    }

    // MARK: Listing

    /// The record a session with no record here would carry from the recorded namespace, as it would be carried:
    /// what a picker shows before the session is restored.
    ///
    /// - Throws: `AuthClientError.storageUnavailable` if the marker or the record could not be read.
    func pendingCarriedRecord(for sessionId: SessionID) throws -> SessionRecord? {
        try pendingCarry(for: sessionId, marker: marker(for: sessionId))?.record
    }

    /// `pendingCarriedRecord` as a listing row.
    func pendingCarryRow(for sessionId: SessionID) throws -> StoredSession? {
        try pendingCarriedRecord(for: sessionId).map {
            StoredSession(sessionId: sessionId, label: $0.label, username: $0.username, kind: $0.kind)
        }
    }

    private func performStorage<Value>(_ operation: String, _ body: () throws -> Value) throws -> Value {
        do {
            return try body()
        } catch {
            throw AuthClientError.storageUnavailable(from: error, operation: operation)
        }
    }
}
