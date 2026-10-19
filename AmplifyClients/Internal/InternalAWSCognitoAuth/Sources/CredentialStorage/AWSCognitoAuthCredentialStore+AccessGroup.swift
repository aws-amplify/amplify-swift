//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import InternalAmplifyKeychain

/// The access-group handling of `AWSCognitoAuthCredentialStore.init`: the access group recorded in
/// `UserDefaults`, the migration of the plugin's keychain items when the access group changes, and the
/// `UserDefaults` mark that lets an interrupted migration resume.
extension AWSCognitoAuthCredentialStore {

    func retrieveStoredAccessGroup() -> String? {
        return userDefaults.string(forKey: accessGroupKey)
    }

    func saveStoredAccessGroup() {
        if let accessGroup {
            userDefaults.set(accessGroup, forKey: accessGroupKey)
        } else {
            userDefaults.removeObject(forKey: accessGroupKey)
        }
    }

    /// The value `migrationInProgressKey` holds while migrating to `accessGroup`.
    private var migrationInProgressValue: String {
        accessGroup ?? ""
    }

    /// Whether this process's `UserDefaults` show a migration to this access group that started and never
    /// recorded the group: the app was terminated part-way through the move.
    func isResumingInterruptedMigration() -> Bool {
        userDefaults.string(forKey: migrationInProgressKey) == migrationInProgressValue
    }

    /// Removes `migrationInProgressKey`, if set. Called once the access group is recorded.
    func clearMigrationInProgress() {
        if userDefaults.object(forKey: migrationInProgressKey) != nil {
            userDefaults.removeObject(forKey: migrationInProgressKey)
        }
    }

    func migrateKeychainItemsToAccessGroup() throws {
        let oldAccessGroup = retrieveStoredAccessGroup()

        if oldAccessGroup == accessGroup {
            log.info("[AWSCognitoAuthCredentialStore] Stored access group is the same as current access group, aborting migration")
            return
        }

        // The move is one `SecItemUpdate` per item, so an app terminated part-way leaves some items moved
        // and the rest in the old service, and no access group recorded. The check below would then see the
        // moved items and abort, stranding the rest. So a migration found in progress resumes instead: it
        // moves what is left, without clearing the destination, which holds the items already moved.
        let resuming = isResumingInterruptedMigration()
        if resuming {
            log.info("[AWSCognitoAuthCredentialStore] A previous migration was interrupted, resuming it")
        }

        let oldService = oldAccessGroup != nil ? sharedService : service
        let newService = accessGroup != nil ? sharedService : service

        // The stores the checks below read through: their failures have always been silent.
        let quietStore = { [makeKeychainStore, logger] (service: String, accessGroup: String?) in
            EngineKeychainStore.quiet(makeKeychainStore(service, accessGroup), logger: logger)
        }

        // If the shared keychain already has items, migration has already occurred
        // (likely by the main app). Skip migration to prevent data loss.
        // This check is necessary because UserDefaults is not shared between app and extensions,
        // so the extension may not know that migration already happened. A guest's session record
        // doesn't stop the migration of a login (`sharedKeychainHasMigratedItems`).
        if !resuming, sharedKeychainHasMigratedItems(
            accessGroup: accessGroup,
            source: { quietStore(oldService, oldAccessGroup) }
        ) {
            log.info("[AWSCognitoAuthCredentialStore] Shared keychain already has items, migration already completed, aborting")
            return
        }

        // What `KeychainStoreMigrator.migrate()` does, over this store's own factory. Keep the two in step.
        let newAccessGroup = accessGroup
        let migrator = KeychainItemMigrator(
            source: KeychainItemAttributes(service: oldService, accessGroup: oldAccessGroup),
            destination: KeychainItemAttributes(service: newService, accessGroup: newAccessGroup),
            sourceStore: makeKeychainStore(oldService, oldAccessGroup),
            // Only asked whether it holds items, which has always been silent on failure.
            destinationStore: EngineKeychainStore.quiet(makeKeychainStore(newService, newAccessGroup), logger: logger),
            logger: migratorLog
        )
        // Recorded once the destination clear has finished, just before the first move, and removed by `init`
        // once the access group is recorded. Not before the clear: an app terminated during the clear would
        // then resume without it, and a stale item the clear hadn't reached yet would be kept over the one
        // the migration moves. Without the record, that launch runs the migration from the start, clear
        // included.
        let markInProgress = { [userDefaults, migrationInProgressValue, migrationInProgressKey] in
            userDefaults.set(migrationInProgressValue, forKey: migrationInProgressKey)
        }
        do {
            try EngineCredentialStoreError.mapping {
                if resuming {
                    // The destination holds the items moved before the interruption: keep them. An item
                    // already there is skipped, as any collision is, except a guest's session record that
                    // the source's login replaces: another process saved it after the interruption.
                    try migrator.migrate(clearingDestinationWith: { [self] in
                        removeGuestSessionsReplacedByALogin(
                            destination: quietStore(newService, newAccessGroup),
                            source: quietStore(oldService, oldAccessGroup)
                        )
                    }, willMove: markInProgress)
                    return
                }
                // Clears a non-empty destination first, sparing the standalone clients' session records but
                // not the Cognito client's default-session sidecar and challenge items, which belong to the
                // plugin's session and are moved with it. If it cannot be listed, nothing is removed.
                try migrator.migrate(clearingDestinationWith: { [makeKeychainStore, logger] in
                    try? Self.keychainStore(newService, newAccessGroup, makeKeychainStore, logger: logger)
                        .removeAllExceptSessionRecords(sparingDefaultSessionItems: false)
                }, willMove: markInProgress)
            }
        } catch {
            log.error("[AWSCognitoAuthCredentialStore] Migration has failed")
            return
        }

        log.verbose("[AWSCognitoAuthCredentialStore] Migration of keychain items from old access group to new access group successful")
    }

    /// Checks if the shared keychain (with the given access group) already contains items.
    /// This is used to determine if migration has already occurred, which helps prevent
    /// data loss when app extensions initialize with their own UserDefaults that don't
    /// reflect the migration state recorded by the main app.
    ///
    /// Only the plugin's own items count: a standalone client's session record in the shared service
    /// says nothing about whether the plugin has migrated. A failed check counts as "no items", as it
    /// always has.
    ///
    /// The Cognito client's default-session sidecar and challenge items (`$default.meta` and
    /// `$default.challenge`) do not count either, although the migration moves them and the destination
    /// clear removes them. The client can write them in the shared service before the plugin has
    /// migrated, so counting them would let a shared service holding only those items abort the
    /// migration, and strand the plugin's signed-in record in the old service.
    ///
    /// Nor does the plugin's configuration record (`authConfiguration`): it says which configuration the
    /// shared service's login belongs to, not that a login was migrated. Any process that starts a store
    /// over the shared service writes it first: the Cognito client's default session at a restore, or an app
    /// extension's plugin configured with the access group before the app. Counting it aborted the app's
    /// migration and left its login in the old service. The destination clear removes it, and the store
    /// writes it again after the migration. Session and device records still count, so an extension never
    /// clears the shared service over a login the app has already migrated. This is the check of the transition
    /// without migration; the migration's own, `sharedKeychainHasMigratedItems(accessGroup:source:)`, also
    /// weighs a guest's session record against the login it would move.
    func sharedKeychainHasItems(accessGroup: String?) -> Bool {
        sharedKeychainPluginAccounts(accessGroup: accessGroup).isEmpty == false
    }

    /// The migration's form of `sharedKeychainHasItems(accessGroup:)`: whether the shared service holds a
    /// login another process has already migrated or saved there, so the migration must not clear it.
    ///
    /// A guest's session record does not count when `source` holds a login. An app extension, or the
    /// Cognito client's default session, that fetches a session before the app's first launch after the
    /// update finds the shared service empty, gets a guest identity and saves it there. Counting that
    /// record aborted the migration, and left the app's login in the old service. The destination clear
    /// removes it, and the login moves. A guest's record is an identity pool identity without user pool tokens
    /// or a federated identity (an identity-pool-only configuration's included). A signed-out record
    /// (`{"noCredentials":{}}`, which a sign-out through the Cognito client's default session saves) is not a
    /// guest's: it counts, as a login does, so a user who signed out is never signed back in by the migration.
    /// With no login to move, a guest's record still counts, so a launch with nothing to migrate never clears
    /// another process's guest identity. Any other item
    /// counts as before; a device record without reading it, since only a sign-in writes one. A session
    /// record that cannot be read or decoded counts as a login.
    ///
    /// - Parameter source: the migration's source store, built only when the shared service holds nothing but
    ///   guests' session records.
    func sharedKeychainHasMigratedItems(accessGroup: String?, source: () -> any KeychainItemStoreBehavior) -> Bool {
        let accounts = sharedKeychainPluginAccounts(accessGroup: accessGroup)
        guard let accessGroup, !accounts.isEmpty else {
            return false
        }
        guard accounts.allSatisfy(Self.isPluginSessionAccount) else {
            return true
        }
        let shared = EngineKeychainStore.quiet(makeKeychainStore(sharedService, accessGroup), logger: logger)
        guard accounts.allSatisfy({ Self.savedSession(at: $0, in: shared) == .guest }) else {
            return true
        }
        guard Self.holdsALogin(source()) else {
            return true
        }
        log.info("[AWSCognitoAuthCredentialStore] Shared keychain holds only a guest session, migrating the signed-in session over it")
        return false
    }

    /// The plugin's own accounts in the shared service under `accessGroup`, the items
    /// `sharedKeychainHasItems(accessGroup:)` counts. Empty without an access group, and when they cannot
    /// be listed.
    private func sharedKeychainPluginAccounts(accessGroup: String?) -> [String] {
        guard let accessGroup else {
            return []
        }

        let sharedKeychain = Self.keychainStore(sharedService, accessGroup, makeKeychainStore, logger: logger)
        // A failed check counts as "no items", as it always has.
        guard let accounts = try? sharedKeychain.itemStore.allAccounts() else {
            return []
        }
        return accounts.filter { account in
            !SessionRecordAccount.isClientSessionRecord(account) && account != Self.authConfigurationAccount
        }
    }

    /// A resumed migration's destination clear: removes each guest's session record in `destination` for
    /// which `source` holds a login under the same account, so the login moves instead of being skipped as
    /// a collision. The run that was interrupted cleared the destination before its first move, so such a
    /// record was saved since, by an app extension or the Cognito client's default session that fetched a
    /// session first. A login or a signed-out record in the destination is never removed, and nothing else is. Best effort: a
    /// record that cannot be read or removed stays, and the move skips it.
    func removeGuestSessionsReplacedByALogin(
        destination: any KeychainItemStoreBehavior,
        source: any KeychainItemStoreBehavior
    ) {
        guard let accounts = try? destination.allAccounts() else {
            return
        }
        for account in accounts where Self.isPluginSessionAccount(account) {
            guard Self.savedSession(at: account, in: destination) == .guest,
                  Self.savedSession(at: account, in: source) == .login else {
                continue
            }
            if (try? destination.remove(account)) != nil {
                log.info("[AWSCognitoAuthCredentialStore] Replacing a guest session in the shared keychain with the signed-in session being migrated")
            }
        }
    }

    /// What a saved session record holds, as the migration weighs it.
    enum SavedSession: Equatable {
        /// User pool tokens or a federated identity: a user signed in.
        case login
        /// An identity pool identity with no user pool tokens and no federated identity: a guest's.
        case guest
        /// A signed-out record (`noCredentials`): it weighs as a login does, so nothing replaces it.
        case signedOut
        /// Missing, unreadable or not a session record.
        case unknown
    }

    /// Whether `account` is one of the plugin's session records (`sessionAccount(for:)`), of any
    /// configuration: `amplify.<pools>.session`, and not a standalone client's record.
    static func isPluginSessionAccount(_ account: String) -> Bool {
        account.hasPrefix("amplify.") && account.hasSuffix(".\(sessionKey)")
            && !SessionRecordAccount.isClientSessionRecord(account)
    }

    /// The session record `store` holds at `account`.
    static func savedSession(at account: String, in store: any KeychainItemStoreBehavior) -> SavedSession {
        guard let data = try? store.dataIfPresent(account),
              let credentials = try? JSONDecoder().decode(AmplifyCredentials.self, from: data) else {
            return .unknown
        }
        switch credentials {
        case .userPoolOnly, .userPoolAndIdentityPool, .identityPoolWithFederation:
            return .login
        case .identityPoolOnly:
            return .guest
        case .noCredentials:
            return .signedOut
        }
    }

    /// Whether `store` holds a plugin session record with a login. `false` when it cannot be listed.
    static func holdsALogin(_ store: any KeychainItemStoreBehavior) -> Bool {
        guard let accounts = try? store.allAccounts() else {
            return false
        }
        return accounts.contains { isPluginSessionAccount($0) && savedSession(at: $0, in: store) == .login }
    }
}
