//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import InternalAmplifyKeychain

/// The access-group handling of `AWSCognitoAuthCredentialStore.init`: the access group recorded in
/// `UserDefaults`, and the migration of the plugin's keychain items when the access group changes.
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

    func migrateKeychainItemsToAccessGroup() throws {
        let oldAccessGroup = retrieveStoredAccessGroup()

        if oldAccessGroup == accessGroup {
            log.info("[AWSCognitoAuthCredentialStore] Stored access group is the same as current access group, aborting migration")
            return
        }

        // If the shared keychain already has items, migration has already occurred
        // (likely by the main app). Skip migration to prevent data loss.
        // This check is necessary because UserDefaults is not shared between app and extensions,
        // so the extension may not know that migration already happened.
        if sharedKeychainHasItems(accessGroup: accessGroup) {
            log.info("[AWSCognitoAuthCredentialStore] Shared keychain already has items, migration already completed, aborting")
            return
        }

        let oldService = oldAccessGroup != nil ? sharedService : service
        let newService = accessGroup != nil ? sharedService : service

        // What `KeychainStoreMigrator.migrate()` does, over this store's own factory.
        let newAccessGroup = accessGroup
        let migrator = KeychainItemMigrator(
            source: KeychainItemAttributes(service: oldService, accessGroup: oldAccessGroup),
            destination: KeychainItemAttributes(service: newService, accessGroup: newAccessGroup),
            sourceStore: makeKeychainStore(oldService, oldAccessGroup),
            // Only asked whether it holds items, which has always been silent on failure.
            destinationStore: EngineKeychainStore.quiet(makeKeychainStore(newService, newAccessGroup), logger: logger),
            logger: migratorLog
        )
        do {
            try EngineCredentialStoreError.mapping {
                // Clears a non-empty destination first, sparing the standalone clients' session records but
                // not the Cognito client's default-session sidecar and challenge items, which belong to the
                // plugin's session and are moved with it. If it cannot be listed, nothing is removed.
                try migrator.migrate(clearingDestinationWith: { [makeKeychainStore, logger] in
                    try? Self.keychainStore(newService, newAccessGroup, makeKeychainStore, logger: logger)
                        .removeAllExceptSessionRecords(sparingDefaultSessionItems: false)
                })
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
    func sharedKeychainHasItems(accessGroup: String?) -> Bool {
        guard let accessGroup else { return false }

        let sharedKeychain = Self.keychainStore(sharedService, accessGroup, makeKeychainStore, logger: logger)
        return (try? sharedKeychain.hasItemsExceptSessionRecords()) ?? false
    }
}
