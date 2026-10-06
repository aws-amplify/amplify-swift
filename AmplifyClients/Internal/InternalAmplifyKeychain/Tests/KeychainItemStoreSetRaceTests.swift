//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyKeychainTestCommon
import Foundation
import Security
import XCTest
@testable import InternalAmplifyKeychain

/// `KeychainItemStore.set` checks for the item and then adds or updates it, in separate `SecItem` calls. Another
/// writer (the plugin's credential store beside a Cognito client, or an app beside its extension) can create the
/// item between the check and the add, and the add then fails with `errSecDuplicateItem`. `set` treats that as a
/// lost race and updates the item instead, once, so it still ends with its own value written, as a plain set does.
///
/// These tests run `KeychainItemStore` over `SecItemKeychainDouble`, which records each `SecItem` call and can land
/// the other writer between two of them. The normal paths' calls are pinned too: only the race path issues the
/// extra update.
final class KeychainItemStoreSetRaceTests: XCTestCase {

    private static let account = "amplify.pool.authConfiguration"
    private let ours = Data("ours".utf8)
    private let theirs = Data("theirs".utf8)

    private var keychain: SecItemKeychainDouble!
    private var store: KeychainItemStore!

    override func setUp() {
        super.setUp()
        keychain = SecItemKeychainDouble()
        store = KeychainItemStore(
            attributes: KeychainItemAttributes(service: "com.amplify.test.setRace", accessGroup: nil),
            logger: SilentLogger(),
            secItem: keychain.secItemCalls
        )
    }

    override func tearDown() {
        keychain = nil
        store = nil
        super.tearDown()
    }

    // MARK: - The race

    /// Test that a set whose add loses to another writer updates the item instead
    ///
    /// - Given: No item under the account
    /// - When:
    ///    - `set` runs, and another writer adds the item after `set`'s check and before its add, so the add returns
    ///      `errSecDuplicateItem`
    /// - Then:
    ///    - `set` does not throw
    ///    - the item holds `set`'s value, not the other writer's
    ///    - the calls are check, add, update: exactly one update
    ///    - the update sends the normal update branch's query and attributes: the item query, and the data alone
    ///
    func testSetUpdatesWhenAnotherWriterAddsBetweenTheCheckAndTheAdd() throws {
        let theirs = theirs
        keychain.beforeNext(.add) { $0.store(theirs, account: Self.account) }

        try store.set(ours, key: Self.account)

        XCTAssertEqual(keychain.value(for: Self.account), ours)
        XCTAssertEqual(keychain.calls, [.copyMatching, .add, .update])
        XCTAssertEqual(keychain.calls.count { $0 == .update }, 1)
        try assertIsTheNormalUpdate(keychain.requests.last)
    }

    /// Test that on macOS a set whose re-add loses to another writer, after its delete, updates the item instead
    ///
    /// - Given: An item under the account
    /// - When:
    ///    - `set` runs, and another writer adds the item again just before `set`'s add. On macOS that is after
    ///      `set`'s delete, so the add returns `errSecDuplicateItem`; elsewhere `set` updates and never adds
    /// - Then:
    ///    - `set` does not throw, and the item holds `set`'s value
    ///    - on macOS the calls are check, delete, add, update: exactly one update; elsewhere check, update
    ///    - either way the update sends the item query and the data alone
    ///
    func testSetUpdatesWhenAnotherWriterAddsBetweenTheDeleteAndTheAdd() throws {
        keychain.store(Data("old".utf8), account: Self.account)
        let theirs = theirs
        keychain.beforeNext(.add) { $0.store(theirs, account: Self.account) }

        try store.set(ours, key: Self.account)

        XCTAssertEqual(keychain.value(for: Self.account), ours)
        #if os(macOS)
        XCTAssertEqual(keychain.calls, [.copyMatching, .delete, .add, .update])
        #else
        XCTAssertEqual(keychain.calls, [.copyMatching, .update])
        #endif
        try assertIsTheNormalUpdate(keychain.requests.last)
    }

    /// Test that the race path updates once and does not loop when the update fails too
    ///
    /// - Given: No item under the account
    /// - When:
    ///    - another writer adds the item between `set`'s check and its add, and removes it again before `set`'s
    ///      update, so the update returns `errSecItemNotFound`
    /// - Then:
    ///    - `set` throws `securityError(errSecItemNotFound)`
    ///    - the calls are check, add, update: one update, no retry, sending the item query and the data alone
    ///
    func testSetUpdatesOnceAndThrowsWhenTheRacingUpdateFails() throws {
        let theirs = theirs
        keychain.beforeNext(.add) { $0.store(theirs, account: Self.account) }
        keychain.beforeNext(.update) { $0.removeItem(account: Self.account) }

        XCTAssertThrowsError(try store.set(ours, key: Self.account)) { error in
            XCTAssertEqual(error as? KeychainAccessError, .securityError(errSecItemNotFound))
        }
        XCTAssertEqual(keychain.calls, [.copyMatching, .add, .update])
        try assertIsTheNormalUpdate(keychain.requests.last)
    }

    /// Test that an add failing with any other status still throws, with no update
    ///
    /// - Given: No item under the account
    /// - When:
    ///    - `set` runs, and its add returns `errSecInteractionNotAllowed`
    /// - Then:
    ///    - `set` throws `securityError(errSecInteractionNotAllowed)`
    ///    - the calls are check, add: no update
    ///
    func testSetThrowsOtherAddFailuresWithoutUpdating() {
        keychain.failNext(.add, with: errSecInteractionNotAllowed)

        XCTAssertThrowsError(try store.set(ours, key: Self.account)) { error in
            XCTAssertEqual(error as? KeychainAccessError, .securityError(errSecInteractionNotAllowed))
        }
        XCTAssertEqual(keychain.calls, [.copyMatching, .add])
    }

    // MARK: - The normal paths are unchanged

    /// Test that a set with no item and no race is a check and an add
    ///
    /// - Given: No item under the account
    /// - When:
    ///    - `set` runs
    /// - Then:
    ///    - the item holds the value, and the calls are check, add, with no update
    ///
    func testSetOfAnAbsentItemIsACheckAndAnAdd() throws {
        try store.set(ours, key: Self.account)

        XCTAssertEqual(keychain.value(for: Self.account), ours)
        XCTAssertEqual(keychain.calls, [.copyMatching, .add])
    }

    /// Test that a set over an existing item makes the same calls as before
    ///
    /// - Given: An item under the account
    /// - When:
    ///    - `set` runs
    /// - Then:
    ///    - the item holds the new value
    ///    - on macOS the calls are check, delete, add; elsewhere check, update, and the update sends the item
    ///      query and the data alone: what the race path's update is checked against
    ///
    func testSetOfAPresentItemIsUnchanged() throws {
        keychain.store(theirs, account: Self.account)

        try store.set(ours, key: Self.account)

        XCTAssertEqual(keychain.value(for: Self.account), ours)
        #if os(macOS)
        XCTAssertEqual(keychain.calls, [.copyMatching, .delete, .add])
        #else
        XCTAssertEqual(keychain.calls, [.copyMatching, .update])
        try assertIsTheNormalUpdate(keychain.requests.last)
        #endif
    }

    // MARK: - The conditional writes keep their own semantics

    /// Test that add-if-absent still reports an existing item and never overwrites it
    ///
    /// - Given: An item another writer stored under the account
    /// - When:
    ///    - `addIfAbsent` runs
    /// - Then:
    ///    - it returns `false`, the item keeps the other writer's value, and the only call is the add
    ///
    func testAddIfAbsentStillReportsAlreadyPresent() throws {
        keychain.store(theirs, account: Self.account)

        XCTAssertFalse(try store.addIfAbsent(ours, key: Self.account))

        XCTAssertEqual(keychain.value(for: Self.account), theirs)
        XCTAssertEqual(keychain.calls, [.add])
    }

    /// Test that set-if-unchanged expecting no item does not overwrite an item another writer adds in its window
    ///
    /// - Given: No item under the account
    /// - When:
    ///    - `setIfUnchanged` runs expecting no item, and another writer adds the item after its re-read and before
    ///      its add
    /// - Then:
    ///    - it returns `false`, the item keeps the other writer's value, and no update is issued
    ///
    func testSetIfUnchangedExpectingAbsenceDoesNotOverwriteARacingWriter() throws {
        let theirs = theirs
        keychain.beforeNext(.add) { $0.store(theirs, account: Self.account) }

        XCTAssertFalse(try store.setIfUnchanged(ours, key: Self.account, expecting: nil))

        XCTAssertEqual(keychain.value(for: Self.account), theirs)
        XCTAssertEqual(keychain.calls, [.copyMatching, .add])
    }

    /// Test that replace-if-present still reports a missing item and never adds it
    ///
    /// - Given: No item under the account
    /// - When:
    ///    - `replaceIfPresent` runs
    /// - Then:
    ///    - it returns `false`, nothing is stored, and the only call is the update
    ///
    func testReplaceIfPresentStillReportsAbsent() throws {
        XCTAssertFalse(try store.replaceIfPresent(ours, key: Self.account))

        XCTAssertNil(keychain.value(for: Self.account))
        XCTAssertEqual(keychain.calls, [.update])
    }

    // MARK: - Support

    /// Asserts that `request` is the update `set`'s normal update branch sends: `itemQuery(account:)`, here the
    /// class, service, data-protection flag and account, and `updateAttributes(value:)`, `kSecValueData` alone,
    /// holding `ours`. Written out from the Security framework's symbols, so a change to either fails here.
    private func assertIsTheNormalUpdate(
        _ request: SecItemKeychainDouble.Request?,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let request = try XCTUnwrap(request, "no call was recorded", file: file, line: line)
        XCTAssertEqual(request.call, .update, file: file, line: line)
        let expectedQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrService as String: "com.amplify.test.setRace",
            kSecUseDataProtectionKeychain as String: true,
            kSecAttrAccount as String: Self.account
        ]
        XCTAssertEqual(request.query as NSDictionary, expectedQuery as NSDictionary, file: file, line: line)
        XCTAssertEqual(
            request.query as NSDictionary,
            store.attributes.itemQuery(account: Self.account) as NSDictionary,
            file: file,
            line: line
        )
        let attributes = try XCTUnwrap(request.attributesToUpdate, "the update sent no attributes", file: file, line: line)
        XCTAssertEqual(attributes as NSDictionary, [kSecValueData as String: ours] as NSDictionary, file: file, line: line)
    }
}
