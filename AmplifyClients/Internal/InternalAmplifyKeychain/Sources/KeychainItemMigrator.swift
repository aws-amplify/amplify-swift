//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import Foundation

/// Moves the items of one service and access group to another, one account at a time, except the
/// standalone clients' session records (`SessionRecordAccount`), which stay where they are.
///
/// This is a *move*, not a copy: the moved items no longer exist in the source afterwards, so it is
/// never rollback-safe. If the destination already holds items it is cleared first, sparing session
/// records there too.
/// `AWSPluginsCore.KeychainStoreMigrator` delegates here.
package struct KeychainItemMigrator: Sendable {

    package let source: KeychainItemAttributes
    package let destination: KeychainItemAttributes
    private let sourceStore: any KeychainItemStoreBehavior
    private let destinationStore: any KeychainItemStoreBehavior
    private let logger: any Logger

    /// A migrator over the given stores, which must be scoped to `source` and `destination`: real
    /// `KeychainItemStore`s in production, the in-memory fake in tests. `destinationStore` is only asked
    /// whether it holds items, a check whose failure has always been silent, so it should log failures
    /// at verbose level at most (see `VerboseOnlyLogger`).
    package init(
        source: KeychainItemAttributes,
        destination: KeychainItemAttributes,
        sourceStore: any KeychainItemStoreBehavior,
        destinationStore: any KeychainItemStoreBehavior,
        logger: any Logger
    ) {
        self.source = source
        self.destination = destination
        self.sourceStore = sourceStore
        self.destinationStore = destinationStore
        self.logger = logger
    }

    /// Migrates, clearing a non-empty destination with `removeAllExceptSessionRecords`, as
    /// `AWSPluginsCore.KeychainStoreMigrator` does.
    package func migrate() throws {
        let destinationStore = destinationStore
        let logger = logger
        try migrate(clearingDestinationWith: { try? destinationStore.removeAllExceptSessionRecords(logger: logger) })
    }

    /// Migrates, calling `clearDestination` first if the destination already holds items.
    ///
    /// - `clearDestination` cannot report failure: a failed clear has always been ignored here.
    /// - The source's items are listed with their access groups, then each one that is not a client
    ///   session record is moved with its own `SecItemUpdate`, scoped to that item's group. If the listing
    ///   fails, nothing is moved and the error is thrown.
    /// - An account the destination already holds is skipped with a warning and left in the source; the
    ///   rest still move, and nothing is thrown. The result does not depend on listing order.
    /// - Any other failure stops the migration and is thrown. Accounts moved before it stay moved.
    package func migrate(clearingDestinationWith clearDestination: () -> Void) throws {
        logger.verbose("[KeychainStoreMigrator] Starting to migrate items")

        // Check if there are any existing items under the new service and access group. A failed check
        // counts as "no items", as it always has.
        if (try? destinationStore.hasItems()) == true {
            // Remove existing items to avoid duplicate item error
            clearDestination()
        }

        // A failed listing or move is logged once, by the store that saw its status, and thrown here.
        let entries = try sourceStore.allEntries()

        var movedCount = 0
        // Each listed item is moved on its own, scoped to its access group. An account stored in two
        // visible groups is listed twice. Moved unscoped, such an account would match both copies, and the
        // keychain refuses that update with `errSecDuplicateItem` and moves neither (observed on iOS 26.5
        // with the real keychain), stranding the item. Scoped, the first copy moves; the second then
        // collides with it and is skipped below.
        for entry in entries {
            // Client session records stay where the client put them: it scopes its records by access
            // group itself, and moving one would hide it from the client.
            guard !SessionRecordAccount.isClientSessionRecord(entry.account) else {
                continue
            }
            switch try sourceStore.move(entry, to: destination) {
            case .moved:
                movedCount += 1
            case .notFound:
                break
            case .destinationOccupied:
                // Skip it and keep going, so one collision strands only the colliding item. The account
                // is never logged: device-record accounts contain usernames.
                logger.warn("[KeychainStoreMigrator] An item already exists in the destination, so it was not migrated")
            }
        }

        if movedCount == 0 {
            logger.verbose("[KeychainStoreMigrator] No items to migrate, keychain under new access group is cleared")
        }
        logger.verbose("[KeychainStoreMigrator] Successfully migrated items to new service and access group")
    }
}
