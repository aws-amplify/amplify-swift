//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import Foundation
import InternalAmplifyKeychain
import InternalAWSCognitoAuth

// `.default` uses the Auth plugin's saved login.
//
// **The items.** In the plugin's keychain service (`com.amplify.awsCognitoAuthPlugin`, or `…Shared` with an access
// group):
//
// | Item | Account | Payload |
// |---|---|---|
// | The shared record | `amplify.<ns>.session` | the plugin's `AmplifyCredentials` JSON, as the plugin writes it |
// | The sidecar | `amplify.1.<ns>.$default.meta` | `DefaultSessionMeta`: the label and the last user |
// | The interrupted sign-in | `amplify.1.<ns>.$default.challenge` | unchanged |
//
// No `$default` **session** record is written. An `amplify.1.<ns>.$default.session` item, or a `$default` namespace
// marker, is a leftover of development builds: never read, listed, written or deleted.
//
// **The commit guard compares bytes.** A write expects the bytes it read (`RecordVersion.storedBytes`), or no item
// (`nil`, add-if-absent); there is no generation. The plugin writes unguarded, so the guard protects client-over-client
// and client-over-plugin writes, not plugin-over-client: in-memory side by side over `.default` stays unsupported.
//
// **The sidecar is bound to a user** (`DefaultSessionMeta.applies`). It is the only place `.default`'s label
// lives: a write of the shared record keeps the stored sidecar's label only while it applies to the record's new
// principal, and rewrites it for that principal otherwise, with no label; only with no readable sidecar is the
// record's own label used. It is cosmetic, so a failure to write it is logged and never fails the write of the record.
//
// **What a read derives.** The kind, the username and the user ID come from the record's stored format
// (`PluginRecordSummary`). `identityPending` is a `userPoolOnly` record under a configuration with an identity
// pool: the identity is fetched on first use, as for a named session carried without one. Under a configuration
// without an identity pool, a `userPoolAndIdentityPool` record reads as `userPoolOnly`, and a guest or federated one as
// a signed-out row: what the plugin's rule copied as it was, read as a named session there is. Bytes that are not the
// plugin's format read as `.corrupt`.
//
// **The configuration-change rule is the plugin's** (`SessionRecordStore+PluginConfiguration.swift`). `.default` keeps
// no namespace marker: nothing is carried forward or swept for it by the named sessions' rule.
//
// **Sign-out and purge clear the AWSMobileClient logins**, as the plugin's sign-out does (`clearLegacyLogins()`): the
// plugin migrates them into this record at configure whenever it holds no session, or only a guest, so they must not
// outlive a sign-out. They are cleared before the signed-out write or the purge's delete, so a failure there leaves
// none. A signed-out record (`{"noCredentials":{}}`) stops that migration too, and the migration then clears them, but
// only until a guest replaces it: the migration reads a guest as no session. So a guest the client fetches over a
// signed-out record (`acquireGuestOnce`) clears them again first, best effort; over no record it leaves them, as a
// client-only app that never signed in keeps them for a plugin build to migrate. A sidecar alone (a label set before
// anyone signed in) is no record. The signed-out record may be the plugin's: under an access group, the plugin's own
// sign-out of a login saves the same bytes (plugin releases after 2.63.0; earlier ones delete the record), so a guest
// the client fetches after one clears them too. Without an access group the plugin's sign-out deletes the record, and
// the client's guest then leaves them, as over no record. A guest the plugin, or an app extension on it, saves over the
// signed-out record clears nothing, so after it only an earlier clear protects the user. A purge leaves no record. The
// client never migrates them.
extension SessionRecordStore {

    /// Whether a store re-reads an absent shared record by default: on macOS only, where the keychain's `set`
    /// deletes the item and adds it again.
    static let rereadsAbsentSharedRecordByDefault: Bool = {
        #if os(macOS)
        return true
        #else
        return false
        #endif
    }()

    /// The account of `.default`'s shared record: the Auth plugin's own.
    var sharedRecordAccount: String {
        SessionRecordKey.pluginSessionAccount(in: namespace.pools)
    }

    /// The account of `.default`'s sidecar.
    var sidecarAccount: String {
        SessionRecordKey.metaAccount(in: namespace.pools)
    }

    // MARK: Reading

    /// What `.default`'s sidecar holds.
    enum SidecarRead: Equatable, Sendable {
        case absent
        /// A sidecar this build reads, with its stored bytes for a guarded write over it.
        case meta(DefaultSessionMeta, stored: Data)
        /// A newer schema's sidecar: shown as absent, and never overwritten.
        case unsupportedSchema(stored: Data)
        /// Bytes that are not a sidecar: shown as absent, and replaced by the next write.
        case corrupt(stored: Data)

        var meta: DefaultSessionMeta? {
            guard case .meta(let meta, _) = self else {
                return nil
            }
            return meta
        }

        var stored: Data? {
            switch self {
            case .absent:
                return nil
            case .meta(_, let stored), .unsupportedSchema(let stored), .corrupt(let stored):
                return stored
            }
        }
    }

    /// The shared record's bytes, `nil` if there is no item. With `rereadsAbsentSharedRecord`, an absent item is
    /// read once more before answering `nil`, so another process's delete-then-add is not taken for a sign-out.
    ///
    /// - Throws: `AuthClientError.storageUnavailable` if it could not be read.
    func fetchSharedRecord(operation: String) throws -> Data? {
        try fetchRereadingAbsent(sharedRecordAccount, operation: operation)
    }

    /// An Auth plugin record's bytes, `nil` if there is no item: with `rereadsAbsentSharedRecord`, an absent item is
    /// read once more first. For `.default`'s shared record, and the previous configuration's record that the
    /// plugin's configuration-change rule copies or deletes.
    ///
    /// - Throws: `AuthClientError.storageUnavailable` if it could not be read.
    func fetchRereadingAbsent(_ account: String, operation: String) throws -> Data? {
        if let data = try fetch(account, operation: operation) {
            return data
        }
        guard rereadsAbsentSharedRecord else {
            return nil
        }
        return try fetch(account, operation: operation)
    }

    /// `.default`'s sidecar.
    ///
    /// - Throws: `AuthClientError.storageUnavailable` if it could not be read.
    func readSidecar() throws -> SidecarRead {
        try readSidecar(at: sidecarAccount)
    }

    /// The sidecar at `account`: this namespace's, or another's (`SessionRecordStore+PluginConfiguration.swift`).
    ///
    /// - Throws: `AuthClientError.storageUnavailable` if it could not be read.
    func readSidecar(at account: String) throws -> SidecarRead {
        guard let data = try fetch(account, operation: "read the default session's sidecar") else {
            return .absent
        }
        switch DefaultSessionMeta.decode(data) {
        case .meta(let meta):
            return .meta(meta, stored: data)
        case .unsupportedSchema:
            return .unsupportedSchema(stored: data)
        case .corrupt:
            return .corrupt(stored: data)
        }
    }

    /// `.default`'s record: the shared record, with the sidecar's label while the sidecar applies to it.
    ///
    /// - No shared record and no sidecar: `.absent`.
    /// - `{"noCredentials":{}}`, or no shared record beside a sidecar: a signed-out row with the sidecar's label and
    ///   last user, versioned by the bytes read (or `nil`, none).
    /// - A signed-in, guest or federated record: that record, versioned by its bytes. A guest or federated record under
    ///   a configuration without an identity pool, copied there by the plugin's rule: a signed-out row, versioned by
    ///   its bytes, which stay as they are.
    /// - Bytes that are not the plugin's format: `.corrupt`.
    ///
    /// - Throws: `AuthClientError.storageUnavailable` if the record or the sidecar could not be read.
    func readDefault() throws -> ReadResult {
        let bytes = try fetchSharedRecord(operation: "read the default session's saved login")
        let sidecar = try readSidecar().meta
        guard let bytes else {
            guard let sidecar else {
                return .absent
            }
            return .record(VersionedSessionRecord(record: Self.signedOutRow(sidecar), version: nil))
        }
        guard let record = defaultRecord(holding: bytes, sidecar: sidecar) else {
            return .corrupt
        }
        return .record(VersionedSessionRecord(record: record, version: .storedBytes(bytes)))
    }

    /// The record the shared record's `bytes` and the sidecar describe, or `nil` if the bytes are not the plugin's
    /// format.
    func defaultRecord(holding bytes: Data, sidecar: DefaultSessionMeta?) -> SessionRecord? {
        let summary = summarizeSharedRecord(bytes)
        guard summary.isRecognised else {
            return nil
        }
        // Derived, as `identityPending` is: a guest or federated identity the plugin's rule copied as it was from a
        // configuration with an identity pool is nobody's under one without, so it reads as a signed-out row, as a named
        // session's is, which is not carried there. The bytes are unchanged: the row keeps them as its version.
        let identityWithoutItsPool = (summary.kind == .guest || summary.kind == .federated) && !namespace.pools.hasIdentityPool
        if summary.kind == .signedOut || identityWithoutItsPool {
            return sidecar.map(Self.signedOutRow) ?? .signedOut(label: nil, username: nil)
        }
        let user = Self.user(of: summary)
        let applies = sidecar?.applies(toRecordUser: user, recordIsSignedOut: false) == true
        // Derived, as `identityPending` is: a login the plugin's rule copied as it was from a configuration with an
        // identity pool still holds that pool's identity, which a configuration without one never uses. The bytes are
        // unchanged.
        let kind = summary.kind == .userPoolAndIdentityPool && !namespace.pools.hasIdentityPool ? .userPoolOnly : summary.kind
        return SessionRecord(
            label: applies ? sidecar?.label : nil,
            username: summary.username,
            userId: summary.userId,
            kind: kind,
            credentials: bytes,
            // Derived: `.default` has no envelope to hold the flag.
            identityPending: summary.kind == .userPoolOnly && namespace.pools.hasIdentityPool
        )
    }

    // MARK: Writing

    /// `write(_:for:expecting:)` for `.default`: the shared record through the byte guard, then the sidecar.
    ///
    /// The payload is the record's credentials, or `{"noCredentials":{}}` for a signed-out row. The sidecar is written
    /// only once the record has committed, a signed-out row's too: a commit another writer beat
    /// leaves that writer's sidecar, never one naming the user who was signing out. A process stopped between the two
    /// writes leaves the sidecar the record had, which for a sign-out is the same user's: the signed-out row keeps the
    /// label and last user it had, if any. No namespace marker is written.
    func writeDefault(_ record: SessionRecord, expecting expected: RecordVersion?) throws -> CommitOutcome {
        let account = sharedRecordAccount
        let current = try fetch(account, operation: "read the default session's saved login before writing it")
        switch expected {
        case nil:
            guard current == nil else {
                return .discarded
            }
        case .storedBytes(let bytes)?:
            guard current == bytes else {
                return .discarded
            }
        case .generation?:
            // A named session's version never matches the shared record.
            return .discarded
        }

        let signingOut = record.isSignedOut || record.credentials == nil
        let payload = record.credentials.flatMap { signingOut ? nil : $0 } ?? PluginRecordSummary.signedOutPayload
        let committed = try perform("write the default session's saved login") {
            try keychain.setIfUnchanged(payload, key: account, expecting: current)
        }
        guard committed else {
            return .discarded
        }
        let sidecar = updateSidecar(for: record)
        let written = defaultRecord(holding: payload, sidecar: sidecar) ?? record
        return .committed(VersionedSessionRecord(record: written, version: .storedBytes(payload)))
    }

    /// Rewrites the sidecar for `record`, the record just committed.
    ///
    /// - A signed-out row: its last user and its label.
    /// - A user: that user, keeping the stored sidecar's label while it applies (the same user, or a sidecar with no
    ///   user yet); otherwise no label. With no readable sidecar, the record's own label.
    /// - A guest or federated identity: no user, keeping the label only of a sidecar with no user.
    ///
    /// Nothing is written when nothing changes. Guarded on the sidecar's own bytes; a lost race re-reads and tries
    /// once more. A newer schema's sidecar is never overwritten. Best effort: a failure is logged.
    ///
    /// - Returns: The sidecar that now describes `record`, as written, or as it would have been.
    @discardableResult
    func updateSidecar(for record: SessionRecord) -> DefaultSessionMeta? {
        var next: DefaultSessionMeta?
        for _ in 1 ... 2 {
            let stored: SidecarRead
            do {
                stored = try readSidecar()
            } catch {
                break
            }
            if case .unsupportedSchema = stored {
                return nil
            }
            next = sidecar(after: record, replacing: stored.meta)
            guard let wanted = next, !Self.describesTheSame(wanted, stored.meta) else {
                return next ?? stored.meta
            }
            do {
                let data = try wanted.encoded()
                if try keychain.setIfUnchanged(data, key: sidecarAccount, expecting: stored.stored) {
                    return wanted
                }
            } catch {
                break
            }
        }
        ClientLog.logger(ClientLog.sessionRecordStore).warn(
            "The default session's sidecar could not be written. Its label or signed-out row may be out of date."
        )
        return next
    }

    /// The sidecar that describes `record`, given the stored one; `nil` when there is nothing to keep.
    private func sidecar(after record: SessionRecord, replacing previous: DefaultSessionMeta?) -> DefaultSessionMeta? {
        let label: String?
        let username: String?
        let userId: String?
        if record.isSignedOut || record.credentials == nil {
            (label, username, userId) = (record.label, record.username, record.userId)
        } else {
            let user = Self.isUserKind(record.kind) ? record.userId : nil
            if let previous {
                label = previous.applies(toRecordUser: user, recordIsSignedOut: false) ? previous.label : nil
            } else {
                // No sidecar to bind to: the caller's label, which the core keeps only for the same principal.
                label = record.label
            }
            (username, userId) = Self.isUserKind(record.kind) ? (record.username, record.userId) : (nil, nil)
        }
        guard previous != nil || label != nil || username != nil || userId != nil else {
            return nil
        }
        return DefaultSessionMeta(lastWriteTimestamp: now(), label: label, username: username, userId: userId)
    }

    // MARK: Label

    /// What setting `.default`'s label did.
    enum DefaultLabelOutcome: Equatable, Sendable {
        /// Written (or nothing to write); the record as a read now returns it.
        case written(ReadResult)
        /// The sidecar changed since it was read: re-read and try again.
        case discarded
        /// The shared record is not the plugin's format: never overwritten.
        case unreadableRecord
        /// The sidecar, which holds the label, is a newer schema's: never overwritten.
        case unreadableSidecar
    }

    /// Sets, or with `nil` clears, `.default`'s label: the sidecar only, guarded on its bytes, bound to the user the
    /// shared record holds (or, signed out or absent, to the last user the sidecar names). The shared record is never
    /// rewritten for a label.
    ///
    /// - Throws: `AuthClientError.storageUnavailable` if storage could not be read or written.
    func setDefaultLabel(_ label: String?) throws -> DefaultLabelOutcome {
        let bytes = try fetchSharedRecord(operation: "read the default session's saved login")
        let stored = try readSidecar()
        if case .unsupportedSchema = stored {
            return .unreadableSidecar
        }
        var record: SessionRecord?
        if let bytes {
            guard let held = defaultRecord(holding: bytes, sidecar: stored.meta) else {
                return .unreadableRecord
            }
            record = held
        }
        let username: String?
        let userId: String?
        if let record, !record.isSignedOut {
            (username, userId) = Self.isUserKind(record.kind) ? (record.username, record.userId) : (nil, nil)
        } else {
            (username, userId) = (stored.meta?.username, stored.meta?.userId)
        }
        let next = DefaultSessionMeta(lastWriteTimestamp: now(), label: label, username: username, userId: userId)
        if stored.meta.map({ Self.describesTheSame(next, $0) }) ?? (label == nil && username == nil && userId == nil) {
            return try .written(readDefault())
        }
        let committed = try perform("write the default session's sidecar") {
            try keychain.setIfUnchanged(next.encoded(), key: sidecarAccount, expecting: stored.stored)
        }
        guard committed else {
            return .discarded
        }
        return try .written(readDefault())
    }

    // MARK: Sign-out and purge

    /// `purge(_:)` for `.default`: first, best effort, the AWSMobileClient logins (`clearLegacyLogins()`), then the
    /// shared record, the sidecar and the interrupted-sign-in record. The logins go first: once the shared record is
    /// gone, a plugin build migrates whatever logins are left, so a failed delete, or a process stopped after it, must
    /// find none.
    func purgeDefault() throws {
        clearLegacyLogins()
        try perform("delete the default session's saved login") { try keychain.remove(sharedRecordAccount) }
        try perform("delete the default session's sidecar") { try keychain.remove(sidecarAccount) }
        try perform("delete the interrupted sign-in record") { try keychain.remove(challengeAccount(for: .default)) }
    }

    // MARK: AWSMobileClient logins

    /// What a failed clear of an AWSMobileClient login logs: no identifiers.
    static let legacyLoginClearFailedWarning =
        "An AWSMobileClient login could not be cleared after the default session was signed out. An Auth plugin build may migrate it back."

    /// Clears the AWSMobileClient logins once `.default` has been signed out or purged, as the Auth plugin's own
    /// sign-out does (`ClearCredentialStore`): `.default` is the plugin's saved login, and every plugin configure first
    /// migrates those logins into it when it holds no session, or only a guest, so a login kept for a later migration
    /// would otherwise sign its user in again under the next plugin build. Like the plugin's, it runs on a sign-out that
    /// had nothing to sign out too, or that another writer's sign-out beat: `SessionSignOut.run()` calls it when this
    /// store's own sign-out did not run. Best effort, as the plugin's: each service that fails to clear logs one
    /// warning, and none fails the sign-out or purge. It runs before the signed-out write or the purge's delete, so a
    /// failed write or delete leaves no login behind. A login that fails to clear is left for the next sign-out or
    /// purge, or for the clear that a guest the client fetches over the signed-out record runs first
    /// (`acquireGuestOnce`). After a sign-out, the signed-out record also stops a plugin build from migrating it, but
    /// only until a guest replaces that record; from then on only a clear does.
    ///
    /// The services are the plugin's for this store's own pools (`namespace.pools`), plus every other identity pool's
    /// credentials service found in the app's keychain (`legacyLoginStores(for:listServices:makeStore:)`), which the
    /// plugin doesn't clear: a login an AWSMobileClient app kept for another identity pool than the client's
    /// configuration names would otherwise be migrated by a plugin build as a guest holding that user's identity and AWS
    /// credentials. Those services are the AWS SDK for iOS's `AWSCognitoCredentialsProvider` caches, whatever code
    /// wrote them, so an app still using that provider loses its cached identity ID and AWS credentials, and a guest
    /// its identity. The user pool service is cleared whole, as the plugin's `ClearCredentialStore` clears it, only
    /// with a user pool configured: `<bundle>.AWSCognitoIdentityUserPool` holds every app client's logins
    /// (`<clientId>.*`).
    /// The AWSMobileClient service is cleared whole on any `.default` sign-out or purge, a static one under another
    /// configuration than the app's included.
    func clearLegacyLogins() {
        for store in legacyLoginStores() {
            do {
                try store.removeAll()
            } catch {
                ClientLog.logger(ClientLog.sessionRecordStore).warn(Self.legacyLoginClearFailedWarning)
            }
        }
    }

    /// What a failed listing of the app's keychain services logs, when the other identity pools' AWSMobileClient
    /// logins could not be looked for.
    static let legacyLoginListingFailedWarning =
        "The keychain could not be listed, so AWSMobileClient logins of other identity pools were not cleared after the default session was signed out."

    /// Item stores for the AWSMobileClient logins a `.default` sign-out or purge clears: the plugin's services for
    /// `pools` (`legacyLoginServices(for:)`), then every other `<bundle>.AWSCognitoCredentialsProvider.<identity pool>`
    /// service `listServices` finds, sorted. Over the real keychain by default, with no access group, as the plugin
    /// builds them (`AWSCognitoAuthPlugin.makeLegacyKeychainStore(service:)`): the listing reads attributes only, and a
    /// failed one logs one warning and leaves only the plugin's services.
    static func legacyLoginStores(
        for pools: PoolNamespace,
        bundleIdentifier: String? = Bundle.main.bundleIdentifier,
        listServices: () throws -> [String] = {
            try KeychainItemStore.allServices(logger: ClientLog.logger(ClientLog.keychainItemStore))
        },
        makeStore: (String) -> any KeychainItemStoreBehavior = {
            KeychainItemStore(service: $0, logger: ClientLog.logger(ClientLog.keychainItemStore))
        }
    ) -> [any KeychainItemStoreBehavior] {
        var services = legacyLoginServices(for: pools)
        if let bundleIdentifier {
            let prefix = "\(bundleIdentifier).\(legacyCredentialsProviderService)."
            do {
                for service in try listServices().sorted() where service.hasPrefix(prefix) && !services.contains(service) {
                    services.append(service)
                }
            } catch {
                ClientLog.logger(ClientLog.sessionRecordStore).warn(Self.legacyLoginListingFailedWarning)
            }
        }
        return services.map(makeStore)
    }

    /// The middle part of the per-identity-pool credentials services of the AWS SDK for iOS's
    /// `AWSCognitoCredentialsProvider`, which AWSMobileClient uses:
    /// `<bundle>.AWSCognitoCredentialsProvider.<identity pool ID>`.
    static let legacyCredentialsProviderService = "AWSCognitoCredentialsProvider"

    /// The keychain services of the AWSMobileClient logins the Auth plugin migrates and clears for `pools`: the
    /// engine's own list (`MigrateLegacyCredentialStore.legacyServiceKeys(for:)`). It names a service from which pools
    /// are configured and the identity pool's ID only, so the configuration it is given holds nothing else.
    static func legacyLoginServices(for pools: PoolNamespace) -> [String] {
        func userPool(_ poolId: String) -> UserPoolConfigurationData {
            UserPoolConfigurationData(poolId: poolId, clientId: "", region: "")
        }
        func identityPool(_ poolId: String) -> IdentityPoolConfigurationData {
            IdentityPoolConfigurationData(poolId: poolId, region: "")
        }
        let configuration: AuthConfiguration
        switch pools {
        case .userPool(let userPoolId):
            configuration = .userPools(userPool(userPoolId))
        case .identityPool(let identityPoolId):
            configuration = .identityPools(identityPool(identityPoolId))
        case .userPoolAndIdentityPool(let userPoolId, let identityPoolId):
            configuration = .userPoolsAndIdentityPools(userPool(userPoolId), identityPool(identityPoolId))
        }
        return MigrateLegacyCredentialStore.legacyServiceKeys(for: configuration)
    }

    /// Sign-out's last resort for `.default`: replaces the shared record with `{"noCredentials":{}}`, unguarded,
    /// but only if it still holds `credentials`; then, once replaced, the sidecar for the signed-out row (a record
    /// purged meanwhile gets no sidecar back).
    func forceSignOutDefault(removing credentials: Data?) throws -> SignOutOutcome {
        guard let data = try fetchSharedRecord(operation: "read the default session's saved login before signing it out") else {
            return .noRecord
        }
        guard let stored = defaultRecord(holding: data, sidecar: try readSidecar().meta) else {
            return .superseded
        }
        if stored.isSignedOut {
            return .signedOut
        }
        guard Self.holdSameCredentials(stored.credentials, credentials, sameCredentials) else {
            return .superseded
        }
        guard try replaceSharedRecordSignedOut() else {
            return .noRecord
        }
        updateSidecar(for: .signedOut(label: stored.label, username: stored.username, userId: stored.userId))
        return .signedOut
    }

    /// Replaces a shared record that is not the plugin's format with `{"noCredentials":{}}`, unless it has meanwhile
    /// become one this build reads: another writer's, which is left alone.
    func replaceUnreadableDefault() throws -> SignOutOutcome {
        guard let data = try fetchSharedRecord(operation: "read the default session's saved login before signing it out") else {
            return .noRecord
        }
        if summarizeSharedRecord(data).isRecognised {
            return .superseded
        }
        return try replaceSharedRecordSignedOut() ? .signedOut : .noRecord
    }

    /// Replaces an existing shared record, never creating one: a concurrent purge is not undone.
    private func replaceSharedRecordSignedOut() throws -> Bool {
        try perform("write the default session's saved login") {
            try keychain.replaceIfPresent(PluginRecordSummary.signedOutPayload, key: sharedRecordAccount)
        }
    }

    // MARK: Helpers

    /// The signed-out row a sidecar describes.
    static func signedOutRow(_ sidecar: DefaultSessionMeta) -> SessionRecord {
        .signedOut(label: sidecar.label, username: sidecar.username, userId: sidecar.userId)
    }

    /// The record's user, the user pool `sub`; `nil` for a guest or federated identity.
    static func user(of summary: PluginRecordSummary) -> String? {
        isUserKind(summary.kind) ? summary.userId : nil
    }

    static func isUserKind(_ kind: SessionKind) -> Bool {
        kind == .userPoolOnly || kind == .userPoolAndIdentityPool
    }

    /// Whether two sidecars say the same thing, whenever they were written.
    private static func describesTheSame(_ lhs: DefaultSessionMeta, _ rhs: DefaultSessionMeta?) -> Bool {
        guard let rhs else {
            return false
        }
        return lhs.label == rhs.label && lhs.username == rhs.username && lhs.userId == rhs.userId
    }
}
