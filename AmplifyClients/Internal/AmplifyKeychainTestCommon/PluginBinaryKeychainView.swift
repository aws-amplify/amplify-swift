//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import InternalAmplifyKeychain

/// The keychain as one Auth plugin binary of the rollback matrices sees it (the plugin's `RollbackMatrixPluginTests`
/// and the Cognito client's `RollbackMatrixClientTests`), over `base`.
///
/// Every read of a Cognito client record, an `amplify.<digits>.` account (`SessionRecordAccount.isClientSessionRecord`),
/// is reported to `onClientRecordRead`, so a row can assert that no plugin binary reads one. With
/// `hidesClientRecords` such a read answers "no item": a released plugin (2.62.0) does not know those accounts, and
/// never reads one. That is a guard on the emulation, which makes a row fail if a plugin ever does; it is not
/// something 2.62.0 does, since it never asks.
///
/// Every removal of a client record by its account is reported to `onClientRecordRemove`. With `hidesClientRecords`
/// such a removal does nothing: 2.62.0 never removes a client record outside `removeAll()`. This plugin's credential
/// store, which both binaries run, does remove two on a configuration change that deletes the old login (the Cognito
/// client's `$default.meta` and `$default.challenge` of the old namespace), so without this the `.released` column
/// would remove them as 2.62.0 never does.
///
/// Everything else passes through unchanged, including listing (2.62.0 has no listing API to emulate) and
/// `removeAll()`, which, like the service-wide `_removeAll()` of 2.62.0's access-group transition, reaches every item,
/// client records included.
package struct PluginBinaryKeychainView: KeychainItemStoreBehavior {

    package let base: any KeychainItemStoreBehavior
    package let hidesClientRecords: Bool
    package let onClientRecordRead: @Sendable (String) -> Void
    package let onClientRecordRemove: @Sendable (String) -> Void

    package init(
        base: any KeychainItemStoreBehavior,
        hidesClientRecords: Bool,
        onClientRecordRead: @escaping @Sendable (String) -> Void,
        onClientRecordRemove: @escaping @Sendable (String) -> Void = { _ in }
    ) {
        self.base = base
        self.hidesClientRecords = hidesClientRecords
        self.onClientRecordRead = onClientRecordRead
        self.onClientRecordRemove = onClientRecordRemove
    }

    package func getData(_ key: String) throws -> Data {
        if SessionRecordAccount.isClientSessionRecord(key) {
            onClientRecordRead(key)
            if hidesClientRecords {
                throw KeychainAccessError.itemNotFound
            }
        }
        return try base.getData(key)
    }

    package func set(_ value: Data, key: String) throws {
        try base.set(value, key: key)
    }

    package func addIfAbsent(_ value: Data, key: String) throws -> Bool {
        try base.addIfAbsent(value, key: key)
    }

    package func replaceIfPresent(_ value: Data, key: String) throws -> Bool {
        try base.replaceIfPresent(value, key: key)
    }

    package func move(_ key: String, to destination: KeychainItemAttributes) throws -> KeychainMoveOutcome {
        try base.move(key, to: destination)
    }

    package func move(_ entry: KeychainEntry, to destination: KeychainItemAttributes) throws -> KeychainMoveOutcome {
        try base.move(entry, to: destination)
    }

    package func remove(_ key: String) throws {
        if keepsClientRecord(key) {
            return
        }
        try base.remove(key)
    }

    package func remove(_ entry: KeychainEntry) throws {
        if keepsClientRecord(entry.account) {
            return
        }
        try base.remove(entry)
    }

    package func removeAll() throws {
        try base.removeAll()
    }

    package func hasItems() throws -> Bool {
        try base.hasItems()
    }

    package func allAccounts() throws -> [String] {
        try base.allAccounts()
    }

    package func allEntries() throws -> [KeychainEntry] {
        try base.allEntries()
    }

    /// Reports a removal of a client record, and whether this view keeps it: `.released` (2.62.0) never removes one
    /// outside `removeAll()`.
    private func keepsClientRecord(_ account: String) -> Bool {
        guard SessionRecordAccount.isClientSessionRecord(account) else {
            return false
        }
        onClientRecordRemove(account)
        return hidesClientRecords
    }
}
