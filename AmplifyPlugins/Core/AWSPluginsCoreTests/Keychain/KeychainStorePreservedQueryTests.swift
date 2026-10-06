//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import InternalAmplifyKeychain
import Security
import XCTest
@testable import AWSPluginsCore

/// Pins every query `KeychainStore` sends to the keychain, as literal dictionaries.
///
/// The expected values are what `KeychainStore` and `KeychainStoreAttributes` built before the keychain
/// code moved into `InternalAmplifyKeychain`. They are written out from the Security
/// framework's own symbols rather than from `KeychainConstants` or `KeychainItemAttributes`, so a change to
/// any query fails here instead of changing the expected value along with it. Each dictionary identifies
/// items that already exist on users' devices: a changed key or value makes them unreadable, or matches
/// items it should not.
///
/// The queries come from the attributes `KeychainStore.itemStore` is built with, which is the object every
/// `KeychainStore` member delegates to.
class KeychainStorePreservedQueryTests: XCTestCase {

    private let service = "someService"
    private let accessGroup = "someAccessGroup"
    private let key = "someKey"
    private let value = Data("someValue".utf8)

    private func attributes(accessGroup: String?) -> KeychainItemAttributes {
        KeychainStore(service: service, accessGroup: accessGroup).itemStore.attributes
    }

    /// `_getData` reads one item's data.
    ///
    /// - Given: stores with and without an access group
    /// - When: the query for `_getData` is built
    /// - Then:
    ///    - it is class, service, data-protection keychain, match limit one, return data and account,
    ///      plus the access group only when one is configured, and nothing else
    func testGetDataQuery() {
        assertQuery(attributes(accessGroup: nil).getDataQuery(account: key), equals: [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrService as String: service,
            kSecUseDataProtectionKeychain as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne as String,
            kSecReturnData as String: true,
            kSecAttrAccount as String: key
        ])
        assertQuery(attributes(accessGroup: accessGroup).getDataQuery(account: key), equals: [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrService as String: service,
            kSecUseDataProtectionKeychain as String: true,
            kSecAttrAccessGroup as String: accessGroup,
            kSecMatchLimit as String: kSecMatchLimitOne as String,
            kSecReturnData as String: true,
            kSecAttrAccount as String: key
        ])
    }

    /// `_set` on a key with no item adds one.
    ///
    /// - Given: stores with and without an access group
    /// - When: the add query for `_set` is built
    /// - Then:
    ///    - it is class, service, data-protection keychain, after-first-unlock-this-device-only
    ///      accessibility, account and value data, plus the access group only when one is configured
    ///    - it has no `kSecAttrSynchronizable`, so the item is never synced
    func testSetAddQuery() {
        assertQuery(attributes(accessGroup: nil).addQuery(account: key, value: value), equals: [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrService as String: service,
            kSecUseDataProtectionKeychain as String: true,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String,
            kSecAttrAccount as String: key,
            kSecValueData as String: value
        ])
        assertQuery(attributes(accessGroup: accessGroup).addQuery(account: key, value: value), equals: [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrService as String: service,
            kSecUseDataProtectionKeychain as String: true,
            kSecAttrAccessGroup as String: accessGroup,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String,
            kSecAttrAccount as String: key,
            kSecValueData as String: value
        ])
    }

    /// `_set` on a key that has an item first looks it up with the item query, then updates it with
    /// that query and the new data. On macOS it instead deletes with the item query and falls through to
    /// the add query pinned in `testSetAddQuery`.
    ///
    /// - Given: stores with and without an access group
    /// - When: the lookup/update query and the update attributes for `_set` are built
    /// - Then:
    ///    - the query is class, service, data-protection keychain and account, plus the access group
    ///      only when one is configured; it has no accessibility, so it matches an item whatever
    ///      protection class it was written under
    ///    - the attributes to update are the value data only
    func testSetUpdateQueryAndAttributes() {
        assertQuery(attributes(accessGroup: nil).itemQuery(account: key), equals: [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrService as String: service,
            kSecUseDataProtectionKeychain as String: true,
            kSecAttrAccount as String: key
        ])
        assertQuery(attributes(accessGroup: accessGroup).itemQuery(account: key), equals: [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrService as String: service,
            kSecUseDataProtectionKeychain as String: true,
            kSecAttrAccessGroup as String: accessGroup,
            kSecAttrAccount as String: key
        ])
        assertQuery(attributes(accessGroup: accessGroup).updateAttributes(value: value), equals: [
            kSecValueData as String: value
        ])
    }

    /// `_remove` deletes one item, with the same item query as the `_set` lookup.
    ///
    /// - Given: stores with and without an access group
    /// - When: the query for `_remove` is built
    /// - Then:
    ///    - it is class, service, data-protection keychain and account, plus the access group only when
    ///      one is configured, and nothing else
    func testRemoveQuery() {
        assertQuery(attributes(accessGroup: nil).itemQuery(account: key), equals: [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrService as String: service,
            kSecUseDataProtectionKeychain as String: true,
            kSecAttrAccount as String: key
        ])
        assertQuery(attributes(accessGroup: accessGroup).itemQuery(account: key), equals: [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrService as String: service,
            kSecUseDataProtectionKeychain as String: true,
            kSecAttrAccessGroup as String: accessGroup,
            kSecAttrAccount as String: key
        ])
    }

    /// `_removeAll` deletes every item under the service and access group.
    ///
    /// - Given: stores with and without an access group
    /// - When: the query for `_removeAll` is built
    /// - Then:
    ///    - it is class, service and data-protection keychain, plus the access group only when one is
    ///      configured, and no account
    ///    - it has match limit all on macOS only
    func testRemoveAllQuery() {
        var expected: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrService as String: service,
            kSecUseDataProtectionKeychain as String: true
        ]
        #if os(macOS)
        expected[kSecMatchLimit as String] = kSecMatchLimitAll as String
        #endif
        assertQuery(attributes(accessGroup: nil).removeAllQuery(), equals: expected)

        expected[kSecAttrAccessGroup as String] = accessGroup
        assertQuery(attributes(accessGroup: accessGroup).removeAllQuery(), equals: expected)
    }

    /// `_hasItems` checks whether any item exists under the service and access group.
    ///
    /// - Given: stores with and without an access group
    /// - When: the query for `_hasItems` is built
    /// - Then:
    ///    - it is class, service, data-protection keychain and match limit one, plus the access group
    ///      only when one is configured; it has no account and returns no data
    func testHasItemsQuery() {
        assertQuery(attributes(accessGroup: nil).hasItemsQuery(), equals: [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrService as String: service,
            kSecUseDataProtectionKeychain as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne as String
        ])
        assertQuery(attributes(accessGroup: accessGroup).hasItemsQuery(), equals: [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrService as String: service,
            kSecUseDataProtectionKeychain as String: true,
            kSecAttrAccessGroup as String: accessGroup,
            kSecMatchLimit as String: kSecMatchLimitOne as String
        ])
    }

    /// Compares as `NSDictionary`, which is how the Security framework receives the query: the same keys,
    /// no extra keys, and equal values. `true` and `kCFBooleanTrue` bridge to the same `NSNumber`.
    private func assertQuery(
        _ actual: [String: Any],
        equals expected: [String: Any],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(
            Set(actual.keys),
            Set(expected.keys),
            "query keys differ",
            file: file,
            line: line
        )
        XCTAssertEqual(
            NSDictionary(dictionary: actual),
            NSDictionary(dictionary: expected),
            file: file,
            line: line
        )
    }
}
