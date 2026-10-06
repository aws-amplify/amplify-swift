//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import InternalAmplifyKeychain

/// An in-memory stand-in for the keychain, for tests.
///
/// `swift test` runs unsigned, so the real data-protection keychain fails with
/// `errSecMissingEntitlement`. This fake stores values per (service, access group, account), records
/// every write and removal in order so a test can assert *which key* was written, and can inject a
/// failure status or run a hook between a read and the next operation to simulate a concurrent writer.
///
/// It lives in `AmplifyKeychainTestCommon`, a target only test targets depend on, so it is not compiled
/// into apps. In `scripts/python/unit_test_groups.json` that target belongs to the
/// `InternalAmplifyKeychain` group, so a change here runs the fake's own tests. Another test target
/// that adopts the fake should add this directory to its own group's `paths`, because a target can
/// belong to only one group.
///
/// Simplification, by default: an access group is matched exactly. The real keychain treats a query with
/// no access group as matching every group the app can see. `UnscopedMatching.everyGroup` models that
/// for the operations where it matters.
package final class InMemoryKeychain: @unchecked Sendable {

    /// How a store **without** an access group matches items. A store with an access group always
    /// matches that group exactly, as on a device.
    package enum UnscopedMatching: Sendable {
        /// Only items stored without an access group. The default.
        case exactGroup
        /// Items in every access group, as on iOS, for reads, listing, removal, moves and `hasItems`:
        /// - `getData` returns an item in any group. If the account is stored in more than one group,
        ///   it returns the first in listing order (no group first, then by group name), so the result is
        ///   deterministic; the device's choice is not specified. Observed on the iOS 26.5 simulator by
        ///   the client host app's IO-4 (`AccessGroupRemovalRealKeychainTests`): after the plugin's
        ///   access group is removed, the moved session keeps its group and a group-less read finds it.
        ///   macOS is not verified;
        /// - listing returns one row per item, so an account stored in two groups is listed twice;
        /// - `remove` acts on **one** matching item per call. This is the worst case the code must
        ///   survive: a delete that honours a match limit of one, as some macOS paths may;
        /// - `move` of an account stored in more than one group moves **nothing** and reports
        ///   `.destinationOccupied`, whatever the destination holds. That was observed on iOS 26.5 against the
        ///   real keychain: the matched copies would collide with each other, and the keychain refuses
        ///   the whole update with `errSecDuplicateItem`. A move of an account stored once behaves as usual;
        /// - `removeAll` removes every match.
        ///
        /// The entry-scoped `move` and `remove` always act on exactly the one item named.
        ///
        /// Writes stay exact: an unscoped write lands on (service, no group), even where iOS would
        /// update the existing item in its own group.
        case everyGroup
    }

    /// A write or removal, in the order it happened.
    package enum Mutation: Equatable, Sendable {
        case write(service: String, account: String, value: Data)
        case remove(service: String, account: String)
        case removeAll(service: String)
        case move(service: String, account: String, toService: String)
    }

    /// The operations a failure can be injected into.
    package enum Operation: Hashable, Sendable {
        case read
        case write
        case remove
        case removeAll
        case move
        case hasItems
        case listAccounts
    }

    private struct ItemKey: Hashable {
        let service: String
        let accessGroup: String?
        let account: String
    }

    // `@unchecked Sendable`: every stored property below is only touched while holding `lock`.
    private let lock = NSLock()
    private var items: [ItemKey: Data] = [:]
    private var recordedMutations: [Mutation] = []
    private var injectedFailures: [Operation: OSStatus] = [:]
    private var injectedAccountFailures: [Operation: [String: OSStatus]] = [:]
    private var afterReadHook: (@Sendable (_ service: String, _ account: String) -> Void)?
    private let unscopedMatching: UnscopedMatching

    package init(unscopedMatching: UnscopedMatching = .exactGroup) {
        self.unscopedMatching = unscopedMatching
    }

    /// A store over this keychain, scoped to one service and access group.
    package func store(service: String, accessGroup: String? = nil) -> InMemoryKeychainItemStore {
        InMemoryKeychainItemStore(keychain: self, service: service, accessGroup: accessGroup)
    }

    // MARK: Inspection

    /// Every write and removal so far, oldest first.
    package var mutations: [Mutation] {
        withLock { recordedMutations }
    }

    /// The accounts written so far, in order, one entry per write.
    package var writtenAccounts: [String] {
        mutations.compactMap { mutation in
            guard case .write(_, let account, _) = mutation else { return nil }
            return account
        }
    }

    /// The value currently stored, read without going through a store and without recording anything.
    package func value(service: String, accessGroup: String? = nil, account: String) -> Data? {
        withLock { items[ItemKey(service: service, accessGroup: accessGroup, account: account)] }
    }

    /// Clears the mutation log, leaving stored values in place.
    package func resetMutations() {
        withLock { recordedMutations.removeAll() }
    }

    // MARK: Fault injection

    /// Makes every subsequent `operation` throw `KeychainAccessError.securityError(status)` until cleared.
    package func failing(_ operation: Operation, with status: OSStatus) {
        withLock { injectedFailures[operation] = status }
    }

    /// Makes every subsequent `.read`, `.write`, `.remove` or `.move` of `account` throw
    /// `KeychainAccessError.securityError(status)` until cleared; other accounts are unaffected. Use it to
    /// fail one step in the middle of a loop.
    package func failing(_ operation: Operation, with status: OSStatus, forAccount account: String) {
        withLock { injectedAccountFailures[operation, default: [:]][account] = status }
    }

    /// Removes every injected failure.
    package func clearFailures() {
        withLock {
            injectedFailures.removeAll()
            injectedAccountFailures.removeAll()
        }
    }

    /// Runs `hook` after every successful or not-found read, before the caller's next operation. Use it
    /// to simulate another writer landing between a read and a write.
    package func afterRead(_ hook: (@Sendable (_ service: String, _ account: String) -> Void)?) {
        withLock { afterReadHook = hook }
    }

    // MARK: Operations used by `InMemoryKeychainItemStore`

    fileprivate func read(service: String, accessGroup: String?, account: String) throws -> Data {
        let outcome: Result<Data, KeychainAccessError> = try withLock {
            try throwIfInjected(.read, account: account)
            // In `.exactGroup` mode, and for a store with a group, `firstMatch` is the exact key.
            guard let key = firstMatch(service: service, accessGroup: accessGroup, account: account),
                  let data = items[key] else {
                return .failure(.itemNotFound)
            }
            return .success(data)
        }
        let hook = withLock { afterReadHook }
        hook?(service, account)
        return try outcome.get()
    }

    fileprivate func write(
        _ value: Data,
        service: String,
        accessGroup: String?,
        account: String,
        when condition: (_ exists: Bool) -> Bool
    ) throws -> Bool {
        try withLock {
            try throwIfInjected(.write, account: account)
            let key = ItemKey(service: service, accessGroup: accessGroup, account: account)
            guard condition(items[key] != nil) else {
                return false
            }
            items[key] = value
            recordedMutations.append(.write(service: service, account: account, value: value))
            return true
        }
    }

    fileprivate func remove(service: String, accessGroup: String?, account: String) throws {
        try withLock {
            try throwIfInjected(.remove, account: account)
            if let key = firstMatch(service: service, accessGroup: accessGroup, account: account) {
                items[key] = nil
            }
            recordedMutations.append(.remove(service: service, account: account))
        }
    }

    /// `destination.accessGroup` is `nil` when the destination has none; the item then keeps its own
    /// group, as `moveAttributes(to:)` does on a device.
    fileprivate func move(
        account: String,
        from source: (service: String, accessGroup: String?),
        to destination: (service: String, accessGroup: String?)
    ) throws -> KeychainMoveOutcome {
        try withLock {
            try throwIfInjected(.move, account: account)
            let matchCount = items.keys.count(where: {
                $0.account == account && matches($0, service: source.service, accessGroup: source.accessGroup)
            })
            if matchCount > 1 {
                // The copies would collide with each other, so the whole update is refused.
                return .destinationOccupied
            }
            guard let sourceKey = firstMatch(service: source.service, accessGroup: source.accessGroup, account: account),
                  let value = items[sourceKey] else {
                return .notFound
            }
            let destinationKey = ItemKey(
                service: destination.service,
                accessGroup: destination.accessGroup ?? sourceKey.accessGroup,
                account: account
            )
            guard items[destinationKey] == nil else {
                return .destinationOccupied
            }
            items[sourceKey] = nil
            items[destinationKey] = value
            recordedMutations.append(.move(service: source.service, account: account, toService: destination.service))
            return .moved
        }
    }

    fileprivate func removeAll(service: String, accessGroup: String?) throws {
        try withLock {
            try throwIfInjected(.removeAll)
            items = items.filter { !matches($0.key, service: service, accessGroup: accessGroup) }
            recordedMutations.append(.removeAll(service: service))
        }
    }

    /// One entry per matching item, each with the group it is stored under, as the real listing reports.
    fileprivate func entries(service: String, accessGroup: String?) throws -> [KeychainEntry] {
        try withLock {
            try throwIfInjected(.listAccounts)
            return items.keys
                .filter { matches($0, service: service, accessGroup: accessGroup) }
                .sorted(by: Self.listingOrder)
                .map { KeychainEntry(account: $0.account, accessGroup: $0.accessGroup) }
        }
    }

    /// Acts on exactly the item at (`service`, `accessGroup`, `account`): an entry-scoped query matches
    /// one item whatever the mode.
    fileprivate func removeExactly(service: String, accessGroup: String?, account: String) throws {
        try withLock {
            try throwIfInjected(.remove, account: account)
            items[ItemKey(service: service, accessGroup: accessGroup, account: account)] = nil
            recordedMutations.append(.remove(service: service, account: account))
        }
    }

    fileprivate func moveExactly(
        account: String,
        from source: (service: String, accessGroup: String?),
        to destination: (service: String, accessGroup: String?)
    ) throws -> KeychainMoveOutcome {
        try withLock {
            try throwIfInjected(.move, account: account)
            let sourceKey = ItemKey(service: source.service, accessGroup: source.accessGroup, account: account)
            guard let value = items[sourceKey] else {
                return .notFound
            }
            let destinationKey = ItemKey(
                service: destination.service,
                accessGroup: destination.accessGroup ?? source.accessGroup,
                account: account
            )
            guard items[destinationKey] == nil else {
                return .destinationOccupied
            }
            items[sourceKey] = nil
            items[destinationKey] = value
            recordedMutations.append(.move(service: source.service, account: account, toService: destination.service))
            return .moved
        }
    }

    fileprivate func accounts(service: String, accessGroup: String?, for operation: Operation) throws -> [String] {
        try withLock {
            try throwIfInjected(operation)
            return items.keys
                .filter { matches($0, service: service, accessGroup: accessGroup) }
                .sorted(by: Self.listingOrder)
                .map(\.account)
        }
    }

    /// Must be called while holding `lock`.
    private func matches(_ key: ItemKey, service: String, accessGroup: String?) -> Bool {
        guard key.service == service else {
            return false
        }
        if accessGroup == nil, unscopedMatching == .everyGroup {
            return true
        }
        return key.accessGroup == accessGroup
    }

    /// The single item an unscoped `remove` or `move` acts on: the first in listing order. Must be called
    /// while holding `lock`.
    private func firstMatch(service: String, accessGroup: String?, account: String) -> ItemKey? {
        items.keys
            .filter { $0.account == account && matches($0, service: service, accessGroup: accessGroup) }
            .sorted(by: Self.listingOrder)
            .first
    }

    /// By account, then by access group with no group first, so results are deterministic.
    private static func listingOrder(_ lhs: ItemKey, _ rhs: ItemKey) -> Bool {
        if lhs.account != rhs.account {
            return lhs.account < rhs.account
        }
        switch (lhs.accessGroup, rhs.accessGroup) {
        case (nil, nil), (_?, nil):
            return false
        case (nil, _?):
            return true
        case (let lhsGroup?, let rhsGroup?):
            return lhsGroup < rhsGroup
        }
    }

    /// Local rather than `NSLocking.withLock`, which is not available at every deployment floor here.
    private func withLock<Value>(_ body: () throws -> Value) rethrows -> Value {
        lock.lock()
        defer { lock.unlock() }
        return try body()
    }

    /// Must be called while holding `lock`.
    private func throwIfInjected(_ operation: Operation, account: String? = nil) throws {
        if let account, let status = injectedAccountFailures[operation]?[account] {
            throw KeychainAccessError.securityError(status)
        }
        if let status = injectedFailures[operation] {
            throw KeychainAccessError.securityError(status)
        }
    }
}

/// A `KeychainItemStoreBehavior` over an `InMemoryKeychain`, scoped to one service and access group.
package struct InMemoryKeychainItemStore: KeychainItemStoreBehavior {

    package let keychain: InMemoryKeychain
    package let service: String
    package let accessGroup: String?

    package init(keychain: InMemoryKeychain, service: String, accessGroup: String? = nil) {
        self.keychain = keychain
        self.service = service
        self.accessGroup = accessGroup
    }

    package func getData(_ key: String) throws -> Data {
        try keychain.read(service: service, accessGroup: accessGroup, account: key)
    }

    package func set(_ value: Data, key: String) throws {
        _ = try keychain.write(value, service: service, accessGroup: accessGroup, account: key, when: { _ in true })
    }

    package func addIfAbsent(_ value: Data, key: String) throws -> Bool {
        try keychain.write(value, service: service, accessGroup: accessGroup, account: key, when: { exists in !exists })
    }

    package func replaceIfPresent(_ value: Data, key: String) throws -> Bool {
        try keychain.write(value, service: service, accessGroup: accessGroup, account: key, when: { exists in exists })
    }

    package func remove(_ key: String) throws {
        try keychain.remove(service: service, accessGroup: accessGroup, account: key)
    }

    /// Moves within the same `InMemoryKeychain`; `destination.itemClass` is ignored.
    ///
    /// As on a device, a destination without an access group leaves the item's own group unchanged:
    /// `moveAttributes(to:)` sets `kSecAttrAccessGroup` only when the destination has one.
    package func move(_ key: String, to destination: KeychainItemAttributes) throws -> KeychainMoveOutcome {
        try keychain.move(
            account: key,
            from: (service, accessGroup),
            to: (destination.service, destination.accessGroup)
        )
    }

    package func move(_ entry: KeychainEntry, to destination: KeychainItemAttributes) throws -> KeychainMoveOutcome {
        try keychain.moveExactly(
            account: entry.account,
            from: (service, entry.accessGroup ?? accessGroup),
            to: (destination.service, destination.accessGroup)
        )
    }

    package func remove(_ entry: KeychainEntry) throws {
        try keychain.removeExactly(service: service, accessGroup: entry.accessGroup ?? accessGroup, account: entry.account)
    }

    package func allEntries() throws -> [KeychainEntry] {
        try keychain.entries(service: service, accessGroup: accessGroup)
    }

    package func removeAll() throws {
        try keychain.removeAll(service: service, accessGroup: accessGroup)
    }

    package func hasItems() throws -> Bool {
        try !keychain.accounts(service: service, accessGroup: accessGroup, for: .hasItems).isEmpty
    }

    package func allAccounts() throws -> [String] {
        try keychain.accounts(service: service, accessGroup: accessGroup, for: .listAccounts)
    }
}
