//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Security
import XCTest
@testable import InternalAmplifyKeychain

/// The query dictionaries are part of key identity, so these tests pin them literally.
final class KeychainItemAttributesTests: XCTestCase {

    private let attributes = KeychainItemAttributes(service: "someService")
    private let sharedAttributes = KeychainItemAttributes(service: "someService", accessGroup: "someAccessGroup")

    /// The constants are the Security framework's own keys and values, not look-alikes.
    ///
    /// - Given: the shared constants
    /// - When: they are compared with the Security framework symbols
    /// - Then:
    ///    - every one matches, and the default item class is generic password
    func testConstantsAreTheSecurityFrameworkSymbols() {
        XCTAssertEqual(KeychainConstants.Class, kSecClass as String)
        XCTAssertEqual(KeychainConstants.ClassGenericPassword, kSecClassGenericPassword as String)
        XCTAssertEqual(KeychainConstants.AttributeService, kSecAttrService as String)
        XCTAssertEqual(KeychainConstants.AttributeAccount, kSecAttrAccount as String)
        XCTAssertEqual(KeychainConstants.AttributeAccessGroup, kSecAttrAccessGroup as String)
        XCTAssertEqual(KeychainConstants.AttributeAccessible, kSecAttrAccessible as String)
        XCTAssertEqual(
            KeychainConstants.AttributeAccessibleAfterFirstUnlockThisDeviceOnly,
            kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String
        )
        XCTAssertEqual(KeychainConstants.UseDataProtectionKeyChain, kSecUseDataProtectionKeychain as String)
        XCTAssertEqual(KeychainConstants.ReturnData, kSecReturnData as String)
        XCTAssertEqual(KeychainConstants.ReturnAttributes, kSecReturnAttributes as String)
        XCTAssertEqual(KeychainConstants.MatchLimit, kSecMatchLimit as String)
        XCTAssertEqual(attributes.itemClass, kSecClassGenericPassword as String)
    }

    /// The get query is exactly class, service and data-protection keychain, plus the access group
    /// only when one is configured. Accessibility is absent so reads match any protection class.
    ///
    /// - Given: attributes with and without an access group
    /// - When: the default get query is built
    /// - Then:
    ///    - it has exactly three keys without a group and four with one
    ///    - `kSecUseDataProtectionKeychain` is `true`
    ///    - `kSecAttrAccessible` and `kSecAttrSynchronizable` are absent
    func testDefaultGetQueryIsExact() {
        let query = attributes.defaultGetQuery()
        XCTAssertEqual(Set(query.keys), [
            KeychainConstants.Class,
            KeychainConstants.AttributeService,
            KeychainConstants.UseDataProtectionKeyChain
        ])
        XCTAssertEqual(query[KeychainConstants.Class] as? String, kSecClassGenericPassword as String)
        XCTAssertEqual(query[KeychainConstants.AttributeService] as? String, "someService")
        XCTAssertEqual(query[KeychainConstants.UseDataProtectionKeyChain] as? Bool, true)

        let sharedQuery = sharedAttributes.defaultGetQuery()
        XCTAssertEqual(Set(sharedQuery.keys), [
            KeychainConstants.Class,
            KeychainConstants.AttributeService,
            KeychainConstants.UseDataProtectionKeyChain,
            KeychainConstants.AttributeAccessGroup
        ])
        XCTAssertEqual(sharedQuery[KeychainConstants.AttributeAccessGroup] as? String, "someAccessGroup")
        XCTAssertNil(sharedQuery[KeychainConstants.AttributeAccessible])
        XCTAssertNil(sharedQuery[KeychainConstants.AttributeSynchronizable])
    }

    /// The set query adds only accessibility to the get query. Synchronizable is never set, so no
    /// item syncs to iCloud — including the future challenge record, which must not.
    ///
    /// - Given: attributes with an access group
    /// - When: the default set query is built
    /// - Then:
    ///    - it has exactly five keys
    ///    - accessibility is after-first-unlock, this device only
    ///    - `kSecUseDataProtectionKeychain` is `true` and `kSecAttrSynchronizable` is absent
    func testDefaultSetQueryIsExact() {
        let query = sharedAttributes.defaultSetQuery()
        XCTAssertEqual(Set(query.keys), [
            KeychainConstants.Class,
            KeychainConstants.AttributeService,
            KeychainConstants.UseDataProtectionKeyChain,
            KeychainConstants.AttributeAccessGroup,
            KeychainConstants.AttributeAccessible
        ])
        XCTAssertEqual(
            query[KeychainConstants.AttributeAccessible] as? String,
            kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String
        )
        XCTAssertEqual(query[KeychainConstants.UseDataProtectionKeyChain] as? Bool, true)
        XCTAssertNil(query[KeychainConstants.AttributeSynchronizable])
    }

    /// The listing query asks for attributes of every match and never for data, so one unreadable
    /// item cannot fail the listing.
    ///
    /// - Given: attributes with an access group
    /// - When: the listing query is built
    /// - Then:
    ///    - `kSecReturnAttributes` is `true` and `kSecMatchLimit` is `kSecMatchLimitAll`
    ///    - `kSecReturnData` is absent, and no account is set
    ///    - the base get query is otherwise unchanged
    func testListAccountsQueryReturnsAttributesOnly() {
        let query = sharedAttributes.listAccountsQuery()
        XCTAssertEqual(query[KeychainConstants.ReturnAttributes] as? Bool, true)
        XCTAssertEqual(query[KeychainConstants.MatchLimit] as? String, kSecMatchLimitAll as String)
        XCTAssertNil(query[KeychainConstants.ReturnData])
        XCTAssertNil(query[KeychainConstants.AttributeAccount])
        XCTAssertEqual(Set(query.keys), Set(sharedAttributes.defaultGetQuery().keys).union([
            KeychainConstants.ReturnAttributes,
            KeychainConstants.MatchLimit
        ]))
    }

    /// A data read matches exactly one account and returns its data, and nothing else.
    ///
    /// - Given: attributes
    /// - When: the get-data query is built for an account
    /// - Then:
    ///    - it adds exactly the account, a match limit of one and `kSecReturnData`
    func testGetDataQuery() {
        let query = attributes.getDataQuery(account: "someKey")
        XCTAssertEqual(query[KeychainConstants.AttributeAccount] as? String, "someKey")
        XCTAssertEqual(query[KeychainConstants.MatchLimit] as? String, kSecMatchLimitOne as String)
        XCTAssertEqual(query[KeychainConstants.ReturnData] as? Bool, true)
        XCTAssertNil(query[KeychainConstants.ReturnAttributes])
        XCTAssertEqual(Set(query.keys), Set(attributes.defaultGetQuery().keys).union([
            KeychainConstants.AttributeAccount,
            KeychainConstants.MatchLimit,
            KeychainConstants.ReturnData
        ]))
    }

    /// The single-item query used for existence checks, updates and deletes is the get query plus the
    /// account, with no match limit and no return keys.
    ///
    /// - Given: attributes
    /// - When: the item query is built for an account
    /// - Then:
    ///    - it is the get query plus exactly the account
    func testItemQuery() {
        let query = attributes.itemQuery(account: "someKey")
        XCTAssertEqual(query[KeychainConstants.AttributeAccount] as? String, "someKey")
        XCTAssertEqual(Set(query.keys), Set(attributes.defaultGetQuery().keys).union([KeychainConstants.AttributeAccount]))
    }

    /// An add carries the set query's attributes, so new items get the pinned accessibility.
    ///
    /// - Given: attributes and a value
    /// - When: the add query is built
    /// - Then:
    ///    - it is the set query plus exactly the account and the value data
    func testAddQuery() {
        let value = Data("value".utf8)
        let query = sharedAttributes.addQuery(account: "someKey", value: value)
        XCTAssertEqual(query[KeychainConstants.AttributeAccount] as? String, "someKey")
        XCTAssertEqual(query[KeychainConstants.ValueData] as? Data, value)
        XCTAssertEqual(
            query[KeychainConstants.AttributeAccessible] as? String,
            kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String
        )
        XCTAssertEqual(Set(query.keys), Set(sharedAttributes.defaultSetQuery().keys).union([
            KeychainConstants.AttributeAccount,
            KeychainConstants.ValueData
        ]))
    }

    /// An update changes the data and nothing else — in particular not the accessibility.
    ///
    /// - Given: a value
    /// - When: the update attributes are built
    /// - Then:
    ///    - they contain only the value data
    func testUpdateAttributesChangeOnlyData() {
        let value = Data("value".utf8)
        let update = attributes.updateAttributes(value: value)
        XCTAssertEqual(Array(update.keys), [KeychainConstants.ValueData])
        XCTAssertEqual(update[KeychainConstants.ValueData] as? Data, value)
    }

    /// An entry's query matches only that entry's item: it adds the entry's access group.
    ///
    /// - Given: an ungrouped store and a grouped store
    /// - When: item queries are built for entries with and without an access group
    /// - Then:
    ///    - an entry with a group gets exactly `itemQuery(account:)` plus that group
    ///    - an entry without one gets exactly `itemQuery(account:)`, keeping the store's own group if any
    func testItemQueryForEntryIsScopedToTheEntrysGroup() {
        let entry = KeychainItemAttributes(service: "someService").itemQuery(
            for: KeychainEntry(account: "account", accessGroup: "TEAM.shared")
        )
        XCTAssertEqual(entry[KeychainConstants.AttributeAccessGroup] as? String, "TEAM.shared")
        XCTAssertEqual(entry[KeychainConstants.AttributeAccount] as? String, "account")
        XCTAssertEqual(Set(entry.keys), Set(attributes.itemQuery(account: "account").keys).union([KeychainConstants.AttributeAccessGroup]))

        let ungrouped = attributes.itemQuery(for: KeychainEntry(account: "account", accessGroup: nil))
        XCTAssertEqual(Set(ungrouped.keys), Set(attributes.itemQuery(account: "account").keys))
        XCTAssertNil(ungrouped[KeychainConstants.AttributeAccessGroup])

        let grouped = KeychainItemAttributes(service: "someService", accessGroup: "TEAM.own")
            .itemQuery(for: KeychainEntry(account: "account", accessGroup: nil))
        XCTAssertEqual(grouped[KeychainConstants.AttributeAccessGroup] as? String, "TEAM.own")
    }

    /// A move changes the service and access group and nothing else.
    ///
    /// - Given: destinations with and without an access group
    /// - When: the move attributes are built
    /// - Then:
    ///    - they hold the destination's service, plus its access group only when it has one
    func testMoveAttributesChangeOnlyServiceAndAccessGroup() {
        let grouped = attributes.moveAttributes(to: KeychainItemAttributes(service: "shared", accessGroup: "group"))
        XCTAssertEqual(Set(grouped.keys), [KeychainConstants.AttributeService, KeychainConstants.AttributeAccessGroup])
        XCTAssertEqual(grouped[KeychainConstants.AttributeService] as? String, "shared")
        XCTAssertEqual(grouped[KeychainConstants.AttributeAccessGroup] as? String, "group")

        let ungrouped = attributes.moveAttributes(to: KeychainItemAttributes(service: "plain"))
        XCTAssertEqual(Array(ungrouped.keys), [KeychainConstants.AttributeService])
        XCTAssertEqual(ungrouped[KeychainConstants.AttributeService] as? String, "plain")
    }

    /// The existence check returns no data and stops at the first match.
    ///
    /// - Given: attributes
    /// - When: the has-items query is built
    /// - Then:
    ///    - it adds only a match limit of one, and neither return key
    func testHasItemsQuery() {
        let query = attributes.hasItemsQuery()
        XCTAssertEqual(query[KeychainConstants.MatchLimit] as? String, kSecMatchLimitOne as String)
        XCTAssertNil(query[KeychainConstants.ReturnData])
        XCTAssertNil(query[KeychainConstants.ReturnAttributes])
        XCTAssertEqual(Set(query.keys), Set(attributes.defaultGetQuery().keys).union([KeychainConstants.MatchLimit]))
    }

    /// The service-wide delete keeps its long-standing platform asymmetry exactly.
    ///
    /// - Given: attributes
    /// - When: the remove-all query is built
    /// - Then:
    ///    - on macOS it adds `kSecMatchLimitAll`; elsewhere it is exactly the get query
    func testRemoveAllQueryPlatformAsymmetry() {
        let query = attributes.removeAllQuery()
        #if os(macOS)
        XCTAssertEqual(query[KeychainConstants.MatchLimit] as? String, kSecMatchLimitAll as String)
        XCTAssertEqual(Set(query.keys), Set(attributes.defaultGetQuery().keys).union([KeychainConstants.MatchLimit]))
        #else
        XCTAssertNil(query[KeychainConstants.MatchLimit])
        XCTAssertEqual(Set(query.keys), Set(attributes.defaultGetQuery().keys))
        #endif
    }
}
