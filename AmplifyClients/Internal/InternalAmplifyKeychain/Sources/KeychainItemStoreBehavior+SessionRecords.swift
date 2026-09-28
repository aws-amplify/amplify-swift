//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import Foundation

package extension KeychainItemStoreBehavior {

    /// Removes every item under this service and access group except session records.
    ///
    /// The scoped replacement for `removeAll()` wherever the service may be shared with the standalone
    /// clients. Every account that `SessionRecordAccount` does not recognise is removed, so on a service
    /// that holds no session records this removes exactly what `removeAll()` would.
    ///
    /// - Throws: If the accounts cannot be listed, logs a warning and throws that error **without removing
    ///   anything**. It never falls back to `removeAll()`: leaving stale items behind is safe, and deleting
    ///   another client's sessions is not. Otherwise, every removal is attempted and the first failure,
    ///   if any, is thrown afterwards.
    func removeAllExceptSessionRecords(logger: any Logger) throws {
        let entries: [KeychainEntry]
        do {
            entries = try allEntries()
        } catch {
            logger.warn(
                "[KeychainStore] Could not list keychain items, so none were removed; stale items may remain",
                error
            )
            throw error
        }

        var sparedCount = 0
        var failureCount = 0
        var firstFailure: Error?
        // One removal per listed item, each scoped to that item's access group. Without an access group
        // the real keychain lists an account once per visible group that holds it. An unscoped delete
        // removes every copy on iOS, but may remove only one match per call on some macOS paths; a scoped
        // delete removes exactly the listed copy on every platform, the same way the migrator moves one.
        // A removal that finds nothing left succeeds.
        for entry in entries {
            if SessionRecordAccount.isClientSessionRecord(entry.account) {
                sparedCount += 1
                continue
            }
            do {
                try remove(entry)
            } catch {
                failureCount += 1
                firstFailure = firstFailure ?? error
            }
        }

        if let firstFailure {
            logger.warn("[KeychainStore] Could not remove \(failureCount) keychain item(s); \(sparedCount) session records were kept")
            throw firstFailure
        }
        logger.verbose("[KeychainStore] Removed items from keychain, keeping \(sparedCount) session records")
    }

    /// Whether this service and access group hold at least one item that is not a client session
    /// record.
    ///
    /// The scoped counterpart of `hasItems()`, for decisions about the plugin's own items that a client
    /// record sharing the service must not sway.
    /// - Throws: If the accounts cannot be listed.
    func hasItemsExceptSessionRecords() throws -> Bool {
        try allAccounts().contains { !SessionRecordAccount.isClientSessionRecord($0) }
    }
}
