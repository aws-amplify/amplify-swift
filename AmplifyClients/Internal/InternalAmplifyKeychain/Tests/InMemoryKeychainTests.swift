//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyFoundation
import Foundation
import Security
import XCTest
import AmplifyKeychainTestCommon
@testable import InternalAmplifyKeychain

/// The fake is only useful if it behaves like the keychain where tests depend on it, so it is tested
/// like production code.
final class InMemoryKeychainTests: XCTestCase {

    private let first = Data("first".utf8)
    private let second = Data("second".utf8)

    /// Values round-trip per key, and `set` replaces.
    ///
    /// - Given: an empty fake
    /// - When: a value is set, read, then set again
    /// - Then:
    ///    - each read returns the latest value
    func testSetAndGetRoundTrip() throws {
        let store = InMemoryKeychain().store(service: "service")

        try store.set(first, key: "key")
        XCTAssertEqual(try store.getData("key"), first)

        try store.set(second, key: "key")
        XCTAssertEqual(try store.getData("key"), second)
    }

    /// An absent key reads as `itemNotFound`, like the real store, and `dataIfPresent` turns that into
    /// `nil`.
    ///
    /// - Given: an empty fake
    /// - When: a key is read
    /// - Then:
    ///    - `getData` throws `itemNotFound` and `dataIfPresent` returns `nil`
    func testMissingKeyIsItemNotFound() throws {
        let store = InMemoryKeychain().store(service: "service")

        XCTAssertThrowsError(try store.getData("missing")) { error in
            XCTAssertEqual(error as? KeychainAccessError, .itemNotFound)
        }
        XCTAssertNil(try store.dataIfPresent("missing"))
    }

    /// Values are scoped by service and by access group, so two stores cannot see each other's items.
    ///
    /// - Given: the same key written under two services and under an access group
    /// - When: each store reads and lists
    /// - Then:
    ///    - each sees only its own value and its own accounts
    func testValuesAreScopedByServiceAndAccessGroup() throws {
        let keychain = InMemoryKeychain()
        let plain = keychain.store(service: "plain")
        let shared = keychain.store(service: "shared")
        let grouped = keychain.store(service: "plain", accessGroup: "group")

        try plain.set(first, key: "key")
        try shared.set(second, key: "key")
        try grouped.set(second, key: "groupOnly")

        XCTAssertEqual(try plain.getData("key"), first)
        XCTAssertEqual(try shared.getData("key"), second)
        XCTAssertEqual(try plain.allAccounts(), ["key"])
        XCTAssertEqual(try grouped.allAccounts(), ["groupOnly"])
        XCTAssertNil(keychain.value(service: "plain", account: "groupOnly"))
    }

    /// The mutation log records which key was written or removed, in order, and reads are not logged.
    ///
    /// - Given: an empty fake
    /// - When: two keys are written, one is read, one is removed, and the service is cleared
    /// - Then:
    ///    - the log lists exactly those writes and removals, in order, and `writtenAccounts` names the keys
    func testRecordsWritesAndRemovalsInOrder() throws {
        let keychain = InMemoryKeychain()
        let store = keychain.store(service: "service")

        try store.set(first, key: "a")
        try store.set(second, key: "b")
        _ = try store.getData("a")
        try store.remove("a")
        try store.removeAll()

        XCTAssertEqual(keychain.mutations, [
            .write(service: "service", account: "a", value: first),
            .write(service: "service", account: "b", value: second),
            .remove(service: "service", account: "a"),
            .removeAll(service: "service")
        ])
        XCTAssertEqual(keychain.writtenAccounts, ["a", "b"])
    }

    /// `removeAll` clears one service and spares every other.
    ///
    /// - Given: items under two services
    /// - When: one service is cleared
    /// - Then:
    ///    - that service is empty and the other is intact
    func testRemoveAllIsScopedToService() throws {
        let keychain = InMemoryKeychain()
        let cleared = keychain.store(service: "cleared")
        let spared = keychain.store(service: "spared")
        try cleared.set(first, key: "a")
        try spared.set(second, key: "b")

        try cleared.removeAll()

        XCTAssertFalse(try cleared.hasItems())
        XCTAssertTrue(try spared.hasItems())
        XCTAssertEqual(try spared.getData("b"), second)
    }

    /// Removing an absent key succeeds, as it does in the real store.
    ///
    /// - Given: an empty fake
    /// - When: a missing key is removed
    /// - Then:
    ///    - no error is thrown
    func testRemovingAbsentKeySucceeds() {
        XCTAssertNoThrow(try InMemoryKeychain().store(service: "service").remove("missing"))
    }

    /// Listing returns every account in the service, including unrelated records, and an empty service
    /// lists as empty.
    ///
    /// - Given: an empty service, then three accounts including an unrelated configuration record
    /// - When: accounts are listed
    /// - Then:
    ///    - the first listing is empty and the second has all three accounts, sorted
    func testAllAccounts() throws {
        let store = InMemoryKeychain().store(service: "service")
        XCTAssertEqual(try store.allAccounts(), [])

        try store.set(first, key: "session.b")
        try store.set(first, key: "session.a")
        try store.set(first, key: "authConfiguration")

        XCTAssertEqual(try store.allAccounts(), ["authConfiguration", "session.a", "session.b"])
    }

    /// Conditional writes follow `SecItemAdd` and `SecItemUpdate`: add refuses a duplicate, replace
    /// refuses a missing item, and a refusal writes nothing.
    ///
    /// - Given: an empty fake
    /// - When: `replaceIfPresent`, then `addIfAbsent` twice, then `replaceIfPresent` are called
    /// - Then:
    ///    - they return `false`, `true`, `false`, `true`, and only the two successes are recorded
    func testConditionalWrites() throws {
        let keychain = InMemoryKeychain()
        let store = keychain.store(service: "service")

        XCTAssertFalse(try store.replaceIfPresent(first, key: "key"))
        XCTAssertTrue(try store.addIfAbsent(first, key: "key"))
        XCTAssertFalse(try store.addIfAbsent(second, key: "key"))
        XCTAssertEqual(try store.getData("key"), first)
        XCTAssertTrue(try store.replaceIfPresent(second, key: "key"))
        XCTAssertEqual(try store.getData("key"), second)

        XCTAssertEqual(keychain.mutations, [
            .write(service: "service", account: "key", value: first),
            .write(service: "service", account: "key", value: second)
        ])
    }

    /// An injected failure makes the chosen operation throw that status until cleared, without
    /// affecting the others. A locked listing throws rather than returning `[]`.
    ///
    /// - Given: a stored item, and listing made to fail as if the device were locked
    /// - When: accounts are listed, the item is read, and the failure is cleared
    /// - Then:
    ///    - listing throws the locked status, the read succeeds, and listing works after clearing
    func testInjectedFailure() throws {
        let keychain = InMemoryKeychain()
        let store = keychain.store(service: "service")
        try store.set(first, key: "key")
        keychain.failing(.listAccounts, with: errSecInteractionNotAllowed)

        XCTAssertThrowsError(try store.allAccounts()) { error in
            XCTAssertEqual((error as? KeychainAccessError)?.storageUnavailableReason, .locked)
        }
        XCTAssertEqual(try store.getData("key"), first)

        keychain.clearFailures()
        XCTAssertEqual(try store.allAccounts(), ["key"])
    }

    /// A move relocates the value, refuses an occupied destination, and reports an absent item.
    ///
    /// - Given: a value in one scope, and a destination scope
    /// - When: it is moved, moved again, and moved onto an occupied account
    /// - Then:
    ///    - the first move relocates it and is recorded; the second finds nothing; the third changes nothing
    func testMove() throws {
        let keychain = InMemoryKeychain()
        let source = keychain.store(service: "source")
        let destination = keychain.store(service: "destination", accessGroup: "group")
        let destinationAttributes = KeychainItemAttributes(service: "destination", accessGroup: "group")
        try source.set(first, key: "key")
        try source.set(second, key: "taken")
        try destination.set(first, key: "taken")
        keychain.resetMutations()

        XCTAssertEqual(try source.move("key", to: destinationAttributes), .moved)
        XCTAssertNil(keychain.value(service: "source", account: "key"))
        XCTAssertEqual(keychain.value(service: "destination", accessGroup: "group", account: "key"), first)
        XCTAssertEqual(keychain.mutations, [.move(service: "source", account: "key", toService: "destination")])

        XCTAssertEqual(try source.move("key", to: destinationAttributes), .notFound)
        XCTAssertEqual(try source.move("taken", to: destinationAttributes), .destinationOccupied)
        XCTAssertEqual(keychain.value(service: "source", account: "taken"), second)
        XCTAssertEqual(keychain.value(service: "destination", accessGroup: "group", account: "taken"), first)
        XCTAssertEqual(keychain.mutations.count, 1)
    }

    /// In `.everyGroup` mode an unscoped store sees every group, one item per call, as on a device.
    ///
    /// - Given: an account stored in no group and in `group-x`, in `.everyGroup` mode
    /// - When: the unscoped store lists, removes once, then removes again
    /// - Then:
    ///    - the account is listed twice
    ///    - each removal takes one copy, the ungrouped one first
    ///    - a grouped store still matches its group exactly
    func testEveryGroupModeListsOncePerGroupAndRemovesOneMatchPerCall() throws {
        let keychain = InMemoryKeychain(unscopedMatching: .everyGroup)
        let unscoped = keychain.store(service: "service")
        try unscoped.set(first, key: "key")
        try keychain.store(service: "service", accessGroup: "group-x").set(second, key: "key")

        XCTAssertEqual(try unscoped.allAccounts(), ["key", "key"])
        XCTAssertEqual(try keychain.store(service: "service", accessGroup: "group-x").allAccounts(), ["key"])

        try unscoped.remove("key")
        XCTAssertNil(keychain.value(service: "service", account: "key"))
        XCTAssertEqual(keychain.value(service: "service", accessGroup: "group-x", account: "key"), second)

        try unscoped.remove("key")
        XCTAssertEqual(try unscoped.allAccounts(), [])
    }

    /// In `.everyGroup` mode an unscoped read finds an item in any group, deterministically, as on iOS
    /// (the client host app's IO-4); `.exactGroup` mode still reads only ungrouped items.
    ///
    /// - Given: an account stored only in `group-x`, and another stored in no group and in `group-x`
    /// - When: an unscoped store reads each, in `.everyGroup` and in `.exactGroup` mode
    /// - Then:
    ///    - `.everyGroup`: the grouped-only account is found, and the two-group account reads its
    ///      ungrouped copy (the first in listing order)
    ///    - `.exactGroup`: the grouped-only account is `itemNotFound`
    ///    - a store scoped to another group still reads nothing
    func testEveryGroupModeReadsAnItemInAnyGroup() throws {
        for mode in [InMemoryKeychain.UnscopedMatching.everyGroup, .exactGroup] {
            let keychain = InMemoryKeychain(unscopedMatching: mode)
            let unscoped = keychain.store(service: "service")
            try keychain.store(service: "service", accessGroup: "group-x").set(second, key: "grouped")
            try unscoped.set(first, key: "both")
            try keychain.store(service: "service", accessGroup: "group-x").set(second, key: "both")

            if mode == .everyGroup {
                XCTAssertEqual(try unscoped.getData("grouped"), second)
            } else {
                XCTAssertThrowsError(try unscoped.getData("grouped")) { error in
                    XCTAssertEqual(error as? KeychainAccessError, .itemNotFound)
                }
            }
            XCTAssertEqual(try unscoped.getData("both"), first, "\(mode)")
            XCTAssertThrowsError(try keychain.store(service: "service", accessGroup: "group-y").getData("grouped"))
        }
    }

    /// In `.everyGroup` mode an unscoped move of an account in two groups moves nothing, as on iOS 26.5.
    ///
    /// - Given: in `.everyGroup` mode, an account stored in no group and in `group-x`, and an empty
    ///   destination
    /// - When: the unscoped store moves the account, twice
    /// - Then:
    ///    - both moves report `.destinationOccupied`
    ///    - neither copy has moved, and nothing is recorded
    func testEveryGroupModeRefusesAnUnscopedMoveOfAnAccountInTwoGroups() throws {
        let keychain = InMemoryKeychain(unscopedMatching: .everyGroup)
        let unscoped = keychain.store(service: "service")
        try unscoped.set(first, key: "key")
        try keychain.store(service: "service", accessGroup: "group-x").set(second, key: "key")
        keychain.resetMutations()
        let destination = KeychainItemAttributes(service: "destination", accessGroup: "group")

        XCTAssertEqual(try unscoped.move("key", to: destination), .destinationOccupied)
        XCTAssertEqual(try unscoped.move("key", to: destination), .destinationOccupied)

        XCTAssertEqual(keychain.value(service: "service", account: "key"), first)
        XCTAssertEqual(keychain.value(service: "service", accessGroup: "group-x", account: "key"), second)
        XCTAssertNil(keychain.value(service: "destination", accessGroup: "group", account: "key"))
        XCTAssertEqual(keychain.mutations, [])
    }

    /// Entries name each copy of an account, and entry-scoped operations act on exactly that copy.
    ///
    /// - Given: in `.everyGroup` mode, an account stored in no group and in `group-x`
    /// - When: the unscoped store lists entries, removes the `group-x` entry, then moves the other entry
    /// - Then:
    ///    - there is one entry per copy, with its group
    ///    - the removal takes only the `group-x` copy
    ///    - the move takes the remaining copy to the destination
    func testEntriesNameEachCopyAndScopeOperations() throws {
        let keychain = InMemoryKeychain(unscopedMatching: .everyGroup)
        let unscoped = keychain.store(service: "service")
        try unscoped.set(first, key: "key")
        try keychain.store(service: "service", accessGroup: "group-x").set(second, key: "key")

        let entries = try unscoped.allEntries()
        XCTAssertEqual(entries, [
            KeychainEntry(account: "key", accessGroup: nil),
            KeychainEntry(account: "key", accessGroup: "group-x")
        ])

        try unscoped.remove(entries[1])
        XCTAssertEqual(keychain.value(service: "service", account: "key"), first)
        XCTAssertNil(keychain.value(service: "service", accessGroup: "group-x", account: "key"))

        let destination = KeychainItemAttributes(service: "destination", accessGroup: "group")
        XCTAssertEqual(try unscoped.move(entries[0], to: destination), .moved)
        XCTAssertEqual(keychain.value(service: "destination", accessGroup: "group", account: "key"), first)
        XCTAssertEqual(try unscoped.allEntries(), [])
    }

    /// A failed write stores nothing and records nothing.
    ///
    /// - Given: writes made to fail
    /// - When: a value is set
    /// - Then:
    ///    - it throws, the key stays absent, and the log is empty
    func testFailedWriteRecordsNothing() {
        let keychain = InMemoryKeychain()
        let store = keychain.store(service: "service")
        keychain.failing(.write, with: errSecIO)

        XCTAssertThrowsError(try store.set(first, key: "key")) { error in
            XCTAssertEqual(error as? KeychainAccessError, .securityError(errSecIO))
        }
        XCTAssertNil(keychain.value(service: "service", account: "key"))
        XCTAssertEqual(keychain.mutations, [])
    }
}
