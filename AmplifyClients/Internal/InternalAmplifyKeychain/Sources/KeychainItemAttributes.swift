//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Security

/// The attribute set that identifies a keychain item, and every query dictionary built from it.
///
/// These attributes are part of key identity: change any of them and every existing record becomes
/// unreadable. Every query is built here, as a pure function, so the exact dictionaries can be asserted
/// in unit tests without touching the real keychain.
///
/// - `kSecAttrAccessible` is deliberately absent from the get query, so a read matches an item whatever
///   protection class it was written under.
/// - `kSecAttrSynchronizable` is never set, so items are never synced to iCloud.
package struct KeychainItemAttributes: Sendable, Equatable {

    package var itemClass: String
    package var service: String
    package var accessGroup: String?

    package init(
        itemClass: String = KeychainConstants.ClassGenericPassword,
        service: String,
        accessGroup: String? = nil
    ) {
        self.itemClass = itemClass
        self.service = service
        self.accessGroup = accessGroup
    }
}

package extension KeychainItemAttributes {

    /// The base query every read, update and delete starts from.
    func defaultGetQuery() -> [String: Any] {
        var query: [String: Any] = [
            KeychainConstants.Class: itemClass,
            KeychainConstants.AttributeService: service,
            KeychainConstants.UseDataProtectionKeyChain: kCFBooleanTrue as Any
        ]

        if let accessGroup {
            query[KeychainConstants.AttributeAccessGroup] = accessGroup
        }
        return query
    }

    /// The base query every add starts from.
    func defaultSetQuery() -> [String: Any] {
        var query: [String: Any] = defaultGetQuery()
        query[KeychainConstants.AttributeAccessible] = KeychainConstants.AttributeAccessibleAfterFirstUnlockThisDeviceOnly
        query[KeychainConstants.UseDataProtectionKeyChain] = kCFBooleanTrue
        return query
    }

    /// Matches the single item stored under `account`. Used for existence checks, updates and deletes.
    func itemQuery(account: String) -> [String: Any] {
        var query = defaultGetQuery()
        query[KeychainConstants.AttributeAccount] = account
        return query
    }

    /// Matches exactly the one item `entry` names: `itemQuery(account:)` scoped to the entry's access
    /// group, or left with this store's own group (or none) if the entry has none.
    func itemQuery(for entry: KeychainEntry) -> [String: Any] {
        var query = itemQuery(account: entry.account)
        if let accessGroup = entry.accessGroup {
            query[KeychainConstants.AttributeAccessGroup] = accessGroup
        }
        return query
    }

    /// Reads the data of the single item stored under `account`.
    func getDataQuery(account: String) -> [String: Any] {
        var query = defaultGetQuery()
        query[KeychainConstants.MatchLimit] = KeychainConstants.MatchLimitOne
        query[KeychainConstants.ReturnData] = kCFBooleanTrue
        query[KeychainConstants.AttributeAccount] = account
        return query
    }

    /// Adds a new item holding `value` under `account`.
    func addQuery(account: String, value: Data) -> [String: Any] {
        var query = defaultSetQuery()
        query[KeychainConstants.AttributeAccount] = account
        query[KeychainConstants.ValueData] = value
        return query
    }

    /// The attributes to change when replacing the data of an existing item.
    func updateAttributes(value: Data) -> [String: Any] {
        [KeychainConstants.ValueData: value]
    }

    /// The attributes to change when moving an item to `destination`: its service and, if `destination`
    /// has one, its access group. Account, data and protection class are left as they are.
    func moveAttributes(to destination: KeychainItemAttributes) -> [String: Any] {
        var attributes: [String: Any] = [KeychainConstants.AttributeService: destination.service]
        attributes[KeychainConstants.AttributeAccessGroup] = destination.accessGroup
        return attributes
    }

    /// Deletes every item under this service and access group.
    ///
    /// `kSecMatchLimitAll` is added on macOS only. This asymmetry predates the extraction, its original
    /// rationale was never recorded, and it is preserved exactly. The commonly cited reason is that
    /// `SecItemDelete` already removes every match on iOS-family platforms while some macOS keychain
    /// paths honour a match limit; that has not been re-verified here, so do not "tidy" it without a
    /// real-keychain test on every platform.
    func removeAllQuery() -> [String: Any] {
        var query = defaultGetQuery()
        #if os(macOS)
        query[KeychainConstants.MatchLimit] = KeychainConstants.MatchLimitAll
        #endif
        return query
    }

    /// Checks whether any item exists under this service and access group. Returns no data.
    func hasItemsQuery() -> [String: Any] {
        var query = defaultGetQuery()
        query[KeychainConstants.MatchLimit] = KeychainConstants.MatchLimitOne
        return query
    }

    /// Lists every item under this service and access group, attributes only.
    ///
    /// `kSecReturnData` is deliberately **not** set. A bulk data read is all-or-nothing: one item that
    /// cannot be read (for example because of its protection class while the device is locked) fails
    /// the whole call. Listing returns account names only; callers read data per key, so one unreadable
    /// item cannot hide the others.
    ///
    /// `kSecMatchLimitAll` is set on every platform, unlike `removeAllQuery()`: `SecItemCopyMatching`
    /// defaults to a limit of one on all platforms, so without it a listing returns a single item.
    func listAccountsQuery() -> [String: Any] {
        var query = defaultGetQuery()
        query[KeychainConstants.MatchLimit] = KeychainConstants.MatchLimitAll
        query[KeychainConstants.ReturnAttributes] = kCFBooleanTrue
        return query
    }
}
