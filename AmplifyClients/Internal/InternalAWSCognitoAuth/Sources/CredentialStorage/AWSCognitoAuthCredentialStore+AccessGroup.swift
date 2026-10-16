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

        // If the shared keychain already has items, migration has already occurred
        // (likely by the main app). Skip migration to prevent data loss.
        // This check is necessary because UserDefaults is not shared between app and extensions,
        // so the extension may not know that migration already happened.
        if !resuming, sharedKeychainHasItems(accessGroup: accessGroup) {
            log.info("[AWSCognitoAuthCredentialStore] Shared keychain already has items, migration already completed, aborting")
            return
        }

        let oldService = oldAccessGroup != nil ? sharedService : service
        let newService = accessGroup != nil ? sharedService : service

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
                    // already there is skipped, as any collision is.
                    try migrator.migrate(clearingDestinationWith: {}, willMove: markInProgress)
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
    /// clears the shared service over a login the app has already migrated.
    func sharedKeychainHasItems(accessGroup: String?) -> Bool {
        guard let accessGroup else { return false }

        let sharedKeychain = Self.keychainStore(sharedService, accessGroup, makeKeychainStore, logger: logger)
        // A failed check counts as "no items", as it always has.
        guard let accounts = try? sharedKeychain.itemStore.allAccounts() else {
            return false
        }
        return accounts.contains { account in
            !SessionRecordAccount.isClientSessionRecord(account) && account != Self.authConfigurationAccount
        }
    }
}
