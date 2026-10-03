//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import InternalAWSCognitoAuth

// `.default` follows the Auth plugin's configuration-change rule.
//
// The plugin records the configuration it last ran with in one `authConfiguration` item of its keychain service, and
// on start compares it with the current one (`AWSCognitoAuthCredentialStore.configurationChange(from:to:)`). `.default`
// uses the plugin's record, so it runs the same decision, from the engine's own code, before its restore reads:
//
// | Change | The plugin, and `.default` |
// |---|---|
// | a user pool added to an identity-pool-only configuration (same identity pool) | the record is copied as it is; the old one is kept |
// | an identity pool added, changed or removed under the same user pool, app client and region | the same: the old identity ID goes along |
// | only the app client changed, with the same pools | nothing: the key has no client ID, so the record stays, and its next refresh gives `sessionExpired` |
// | any other change of the key | the old record is deleted |
//
// Then it writes `authConfiguration` = the current configuration, as the plugin does, so a plugin build started next
// compares with this configuration, and never copies an older login over a newer one.
//
// **Unlike the plugin, a failed read is never "no previous configuration".** The plugin reads with `try?`, so a locked
// keychain at launch overwrites `authConfiguration` and loses a pending carry. Here a failed read of the item, or of a
// record the rule copies or deletes, throws `storageUnavailable`, and nothing is written: the next restore applies the
// rule again. `authConfiguration` is written last, only after the carry or delete succeeded. Bytes that are not a
// configuration are "no previous configuration", as in the plugin.
//
// **Two writes the plugin makes are skipped**, since neither changes what is stored: a carry onto the same account (an
// identity-pool-only configuration started again, or a change outside the key), and `authConfiguration` rewritten with
// the configuration it already holds.
//
// **The sidecar goes with a carried record**, while the new namespace has none: it holds the record's label and last
// user, which the plugin's format cannot, and the carried record is the same user's. **It goes with a deleted record**
// too, so no signed-out row is left for a login the user never signed out of. Both are best effort.
//
// **The static `signOutStoredSession` and `purgeStoredSession` apply the rule only when it carries**: they can
// be called with a configuration other than the app's, which must never delete the app's login (`onlyIfCarrying`).
//
// A record the rule reads is read again once if found absent where the keychain's `set` deletes and re-adds (macOS),
// as the shared record is.
//
// **A deleted login is revoked**, best effort, when the user pool is the same: `revocablePayload(after:current:)`.
// With the same user pool the key changes only through the identity pool, and the record is then deleted only if the
// app client (or region) changed too, so the revoke must use the previous configuration's app client ID, which
// `authConfiguration` records. Another user pool's login is not revoked, and stays valid until it expires.
//
// Named sessions keep their own rule (`SessionRecordStore+CopyForward.swift`): never cleared, user pool tokens only.
extension SessionRecordStore {

    /// What the plugin's configuration-change rule did for `.default`.
    enum PluginConfigurationOutcome: Equatable, Sendable {
        /// Nothing was carried or deleted.
        case unchanged
        /// The previous configuration's record was copied to this one's, as its bytes are.
        case carried
        /// The previous configuration's record was deleted. `previousPayload` is what it held (`nil`: nothing), for the
        /// revoke.
        case cleared(previousPayload: Data?, previous: AuthConfiguration)
    }

    /// The account of the item the plugin records its last configuration in.
    static var pluginConfigurationAccount: String {
        AWSCognitoAuthCredentialStore.authConfigurationAccount
    }

    /// The configuration the plugin, or `.default`, last ran with: `nil` if none is recorded, or if the bytes are not a
    /// configuration (as the plugin reads them).
    ///
    /// - Throws: `AuthClientError.storageUnavailable` if the item could not be read.
    func previousPluginConfiguration() throws -> AuthConfiguration? {
        guard let data = try fetch(Self.pluginConfigurationAccount, operation: "read the Auth plugin's last configuration") else {
            return nil
        }
        return try? AWSCognitoAuthCredentialStore.decodeAuthConfiguration(data)
    }

    /// The namespace other than this one that the recorded previous configuration names: the gate a `.default` restore
    /// also takes, as a named session's takes the namespace its marker names.
    ///
    /// - Throws: `AuthClientError.storageUnavailable` if the item could not be read.
    func pluginConfigurationSource() throws -> PoolNamespace? {
        Self.otherNamespace(of: try previousPluginConfiguration(), than: namespace.pools)
    }

    /// Runs the plugin's configuration-change rule for `.default`, from the recorded previous configuration to
    /// `current`, then records `current`. The caller holds the gates of this namespace and of the one the previous
    /// configuration names (`pluginConfigurationSource()`).
    ///
    /// - Parameters:
    ///   - current: The engine configuration `.default` runs with now, `AuthConfiguration(client:)`.
    ///   - heldSource: For a caller holding the gate of the namespace the previous configuration names: the namespace
    ///     it expects. Another throws `CarrySourceChanged`, and nothing is changed. `nil` does not check.
    ///   - onlyIfCarrying: For the static `signOutStoredSession` and `purgeStoredSession`: apply the rule only
    ///     when it carries. They may be called with a configuration other than the app's, which must never delete the
    ///     app's login, so any other decision changes nothing at all, `authConfiguration` included; the next restore
    ///     under the new configuration applies the rule in full.
    /// - Throws: `AuthClientError.storageUnavailable` if an item could not be read, written or deleted. Nothing after
    ///   the failure is done, and `authConfiguration` is written only once the rest succeeded.
    func applyPluginConfigurationRule(
        current: AuthConfiguration,
        heldSource: PoolNamespace?? = nil,
        onlyIfCarrying: Bool = false
    ) throws -> PluginConfigurationOutcome {
        let previous = try previousPluginConfiguration()
        if let heldSource, Self.otherNamespace(of: previous, than: namespace.pools) != heldSource {
            throw CarrySourceChanged()
        }
        let change = AWSCognitoAuthCredentialStore.configurationChange(from: previous, to: current)
        if onlyIfCarrying, !Self.carries(change) {
            return .unchanged
        }
        let outcome: PluginConfigurationOutcome
        switch change {
        case .unchanged:
            outcome = .unchanged
        case .carry(let fromAccount, let toAccount):
            outcome = try carryPluginRecord(from: fromAccount, to: toAccount, previous: previous)
        case .clear(let account, let previous):
            let payload = try fetchRereadingAbsent(account, operation: "read the saved login of the previous configuration")
            try perform("delete the saved login of the previous configuration") { try keychain.remove(account) }
            // The old namespace's sidecar goes with its record, so no signed-out row is left for a login the user
            // never signed out of. Cosmetic, so best effort.
            try? keychain.remove(SessionRecordKey.metaAccount(in: PoolNamespace(previous)))
            outcome = .cleared(previousPayload: payload, previous: previous)
        }
        if previous != current {
            try perform("record the configuration for the Auth plugin") {
                try keychain.set(AWSCognitoAuthCredentialStore.encodeAuthConfiguration(current), key: Self.pluginConfigurationAccount)
            }
        }
        return outcome
    }

    /// The payload a deleted login's revoke sends, if it is revoked at all: the deleted record's, when it
    /// holds user pool tokens and its user pool is `current`'s.
    func revocablePayload(after outcome: PluginConfigurationOutcome, current: AuthConfiguration) -> Data? {
        guard case .cleared(let payload?, let previous) = outcome,
              let userPoolId = current.getUserPoolConfiguration()?.poolId,
              previous.getUserPoolConfiguration()?.poolId == userPoolId,
              Self.isUserKind(summarizeSharedRecord(payload).kind) else {
            return nil
        }
        return payload
    }

    /// `.default`'s record as a restore would read it after the rule, without changing anything: the previous
    /// configuration's record when the rule would carry it here, else `nil` (read this namespace's own). What a
    /// picker shown before the first restore after a change lists. A deleting change lists no row of the old record.
    ///
    /// - Throws: `AuthClientError.storageUnavailable` if an item could not be read.
    func pendingPluginCarry(current: AuthConfiguration) throws -> SessionRecord? {
        let previous = try previousPluginConfiguration()
        guard case .carry(let fromAccount, let toAccount) = AWSCognitoAuthCredentialStore.configurationChange(from: previous, to: current),
              fromAccount != toAccount,
              let bytes = try fetchRereadingAbsent(fromAccount, operation: "read the saved login of the previous configuration") else {
            return nil
        }
        var sidecar = try readSidecar()
        if case .absent = sidecar, let previousPools = previous.map(PoolNamespace.init) {
            sidecar = try readSidecar(at: SessionRecordKey.metaAccount(in: previousPools))
        }
        return defaultRecord(holding: bytes, sidecar: sidecar.meta)
    }

    // MARK: Helpers

    /// The carry: the previous record's bytes, as they are, with a plain `set`, as the plugin copies them; then its
    /// sidecar, if this namespace has none.
    private func carryPluginRecord(from fromAccount: String, to toAccount: String, previous: AuthConfiguration?) throws -> PluginConfigurationOutcome {
        guard fromAccount != toAccount else {
            // The plugin writes the record over itself: nothing changes.
            return .unchanged
        }
        guard let bytes = try fetchRereadingAbsent(fromAccount, operation: "read the saved login of the previous configuration") else {
            return .unchanged
        }
        try perform("copy the saved login of the previous configuration") { try keychain.set(bytes, key: toAccount) }
        if let previousPools = previous.map(PoolNamespace.init) {
            carrySidecar(from: SessionRecordKey.metaAccount(in: previousPools))
        }
        return .carried
    }

    /// Copies the previous namespace's sidecar here if this namespace has none. Cosmetic, so best effort: a failure
    /// leaves the carried record with no label.
    private func carrySidecar(from account: String) {
        guard let data = try? fetch(account, operation: "read the default session's sidecar") else {
            return
        }
        _ = try? keychain.addIfAbsent(data, key: sidecarAccount)
    }

    private static func carries(_ change: AWSCognitoAuthCredentialStore.ConfigurationChange) -> Bool {
        if case .carry = change {
            return true
        }
        return false
    }

    /// `configuration`'s namespace if it is not `pools`.
    private static func otherNamespace(of configuration: AuthConfiguration?, than pools: PoolNamespace) -> PoolNamespace? {
        guard let configuration else {
            return nil
        }
        let other = PoolNamespace(configuration)
        return other == pools ? nil : other
    }
}
