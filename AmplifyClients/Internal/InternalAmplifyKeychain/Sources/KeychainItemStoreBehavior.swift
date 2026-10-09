//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Access to the generic-password items stored under one keychain service and access group.
///
/// Every member throws `KeychainAccessError`. `KeychainItemStore` is the `SecItem` implementation;
/// `InMemoryKeychainItemStore`, in the test-only `AmplifyKeychainTestCommon` target, is the fake for tests.
package protocol KeychainItemStoreBehavior: Sendable {

    /// Returns the data stored under `key`.
    /// - Throws: `KeychainAccessError.itemNotFound` if nothing is stored under `key`.
    func getData(_ key: String) throws -> Data

    /// Stores `value` under `key`, replacing any existing value.
    func set(_ value: Data, key: String) throws

    /// Stores `value` under `key` only if nothing is stored there yet.
    /// - Returns: `true` if the item was added, `false` if an item already existed (nothing is written).
    func addIfAbsent(_ value: Data, key: String) throws -> Bool

    /// Replaces the value stored under `key` only if an item is stored there.
    /// - Returns: `true` if the item was replaced, `false` if no item existed (nothing is written).
    func replaceIfPresent(_ value: Data, key: String) throws -> Bool

    /// Moves the item stored under `key` to `destination`'s service and access group, keeping its
    /// account, data and protection class. This is a move, not a copy: afterwards the item is no longer
    /// here.
    /// - Returns: `.moved`; `.notFound` if nothing is stored under `key`; or `.destinationOccupied` if
    ///   `destination` already holds an item under `key` (nothing is changed).
    func move(_ key: String, to destination: KeychainItemAttributes) throws -> KeychainMoveOutcome

    /// `move(_:to:)` for exactly the one item `entry` names: the query is scoped to `entry.accessGroup`,
    /// or to this store's own group if the entry has none.
    ///
    /// Use this, not `move(_:to:)`, for entries from `allEntries()`. Without an access group,
    /// `move(_:to:)` matches the account in every visible group. When the account is stored in two groups
    /// the keychain then refuses the whole update with `errSecDuplicateItem` and moves **neither** copy
    /// (observed on iOS 26.5). Scoped to one entry, the first copy moves and a later one collides.
    func move(_ entry: KeychainEntry, to destination: KeychainItemAttributes) throws -> KeychainMoveOutcome

    /// Removes the item stored under `key`. Removing an absent item succeeds.
    func remove(_ key: String) throws

    /// `remove(_:)` for exactly the one item `entry` names, scoped like `move(_:to:)` for an entry.
    /// Removing an absent item succeeds.
    func remove(_ entry: KeychainEntry) throws

    /// Removes every item under this service and access group.
    func removeAll() throws

    /// Whether at least one item exists under this service and access group.
    func hasItems() throws -> Bool

    /// Every account name (`kSecAttrAccount`) stored under this service and access group.
    ///
    /// Attributes only: no item data is read, so one unreadable item cannot fail the listing. Read each
    /// item's data with `getData(_:)`. An empty service returns `[]`; any other failure — including a
    /// locked device — throws, and never returns `[]`.
    ///
    /// The account namespace is flat and shared with unrelated records, so callers must filter the
    /// result themselves. Order is unspecified.
    func allAccounts() throws -> [String]

    /// Every item stored under this service and access group, as its account and access group.
    ///
    /// The same listing as `allAccounts()`, but one entry per item. Without an access group the real
    /// keychain lists an account once for each visible group that holds it, and each entry says which,
    /// so `move(_:to:)` and `remove(_:)` for an entry can act on that one item. Failure behaves as for
    /// `allAccounts()`. Order is unspecified.
    func allEntries() throws -> [KeychainEntry]
}

/// One keychain item as listed by `KeychainItemStoreBehavior.allEntries()`: its account, and the access
/// group it is stored under (`kSecAttrAccessGroup`), if the listing reported one.
package struct KeychainEntry: Hashable, Sendable {
    package let account: String
    package let accessGroup: String?

    package init(account: String, accessGroup: String?) {
        self.account = account
        self.accessGroup = accessGroup
    }
}

/// What `KeychainItemStoreBehavior.move(_:to:)` did.
package enum KeychainMoveOutcome: Equatable, Sendable {
    case moved
    case notFound
    case destinationOccupied
}

package extension KeychainItemStoreBehavior {

    /// Returns the data stored under `key`, or `nil` if nothing is stored there. Every other failure
    /// throws.
    func dataIfPresent(_ key: String) throws -> Data? {
        do {
            return try getData(key)
        } catch KeychainAccessError.itemNotFound {
            return nil
        }
    }

    /// Writes `value` under `key` only if the stored value still equals `expecting`.
    ///
    /// Re-reads the current value and compares it byte-for-byte with `expecting`; `nil` means "expect no
    /// item". If they match, writes (an add when expecting absence, a replace otherwise) and returns
    /// `true`. If they differ, writes nothing and returns `false` — not an error.
    ///
    /// **This is not atomic, and cannot be made atomic.** The Security framework has no compare-and-set:
    /// `SecItemUpdate` takes no expected-value precondition, so a window remains between the re-read and
    /// the write in which another writer (another task, an app extension, another process sharing the
    /// access group) can land. The expect-absent path is narrower, because `SecItemAdd` itself refuses a
    /// duplicate, but the replace path can still overwrite a value written inside that window. This guard
    /// *bounds* the lost-update race; it does not eliminate it. It is not a lock.
    ///
    /// **`false` means "your view is stale", and the right response is to discard the write and re-read.**
    /// Do not "fix" a discarded write with a forcing retry — re-reading and writing unconditionally, or
    /// looping until this returns `true`. The value that moved is newer than yours: typically a
    /// concurrent refresh that already rotated the credentials. Forcing your write replaces it with the
    /// older state, which is exactly the lost update this guard exists to prevent — for a rotated refresh
    /// token, it can restore a token the server has already invalidated, and the next refresh fails.
    ///
    /// - Parameters:
    ///   - value: The value to store.
    ///   - key: The key to store it under.
    ///   - expecting: The value the caller last read under `key`, or `nil` if it read no item.
    /// - Returns: Whether `value` was written.
    func setIfUnchanged(_ value: Data, key: String, expecting: Data?) throws -> Bool {
        let current = try dataIfPresent(key)
        guard current == expecting else {
            return false
        }
        if expecting == nil {
            return try addIfAbsent(value, key: key)
        }
        return try replaceIfPresent(value, key: key)
    }
}
