//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
@preconcurrency import Foundation
import Security

/// The one implementation of keychain access in the repo, over the `SecItem` API.
///
/// `AWSPluginsCore.KeychainStore` delegates here, so the plugin and the client read and write the same
/// items with the same attributes. Query dictionaries come from `KeychainItemAttributes`; status and
/// result interpretation is split into static functions so it can be unit tested without the keychain.
package struct KeychainItemStore: KeychainItemStoreBehavior {

    package let attributes: KeychainItemAttributes
    private let logger: any Logger

    package init(attributes: KeychainItemAttributes, logger: any Logger) {
        self.attributes = attributes
        self.logger = logger
    }

    package init(
        service: String,
        accessGroup: String? = nil,
        logger: any Logger = AmplifyLogging.logger(for: KeychainItemStore.self)
    ) {
        self.init(attributes: KeychainItemAttributes(service: service, accessGroup: accessGroup), logger: logger)
    }

    package func getData(_ key: String) throws -> Data {
        logger.verbose("[KeychainStore] Started retrieving `Data` from the store with kind=\(Self.recordKind(of: key))")
        let query = attributes.getDataQuery(account: key)

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        return try Self.data(fromStatus: status, result: result, key: key, logger: logger)
    }

    package func set(_ value: Data, key: String) throws {
        logger.verbose("[KeychainStore] Started setting `Data` for kind=\(Self.recordKind(of: key))")
        let getQuery = attributes.itemQuery(account: key)
        logger.verbose("[KeychainStore] Initialized fetching to decide whether update or add")
        let fetchStatus = SecItemCopyMatching(getQuery as CFDictionary, nil)
        switch fetchStatus {
        case errSecSuccess:
            #if os(macOS)
            logger.verbose("[KeychainStore] Deleting item on MacOS to add an item.")
            SecItemDelete(getQuery as CFDictionary)
            fallthrough
            #else
            logger.verbose("[KeychainStore] Found existing item, updating")
            let attributesToUpdate = attributes.updateAttributes(value: value)

            let updateStatus = SecItemUpdate(getQuery as CFDictionary, attributesToUpdate as CFDictionary)
            if updateStatus != errSecSuccess {
                logger.error("[KeychainStore] Error updating item to keychain with status=\(updateStatus)")
                throw KeychainAccessError.securityError(updateStatus)
            }
            logger.verbose("[KeychainStore] Successfully updated `Data` in keychain for kind=\(Self.recordKind(of: key))")
            #endif
        case errSecItemNotFound:
            logger.verbose("[KeychainStore] Unable to find an existing item, creating new item")
            let attributesToSet = attributes.addQuery(account: key, value: value)

            let addStatus = SecItemAdd(attributesToSet as CFDictionary, nil)
            if addStatus != errSecSuccess {
                logger.error("[KeychainStore] Error adding item to keychain with status=\(addStatus)")
                throw KeychainAccessError.securityError(addStatus)
            }
            logger.verbose("[KeychainStore] Successfully added `Data` in keychain for kind=\(Self.recordKind(of: key))")
        default:
            logger.error("[KeychainStore] Error occurred while retrieving data from keychain when deciding to update or add with status=\(fetchStatus)")
            throw KeychainAccessError.securityError(fetchStatus)
        }
    }

    /// A single `SecItemAdd`. The keychain itself refuses a duplicate, so this never replaces an item.
    package func addIfAbsent(_ value: Data, key: String) throws -> Bool {
        logger.verbose("[KeychainStore] Adding `Data` only if absent for kind=\(Self.recordKind(of: key))")
        let status = SecItemAdd(attributes.addQuery(account: key, value: value) as CFDictionary, nil)
        return try Self.writeOutcome(fromStatus: status, refusedBy: errSecDuplicateItem, key: key, logger: logger)
    }

    /// A single `SecItemUpdate`, on every platform.
    ///
    /// Unlike `set(_:key:)`, this does not use the delete-then-add path on macOS: between that delete and
    /// add the item is absent, and a concurrent reader would see "no item" — for a credential record,
    /// "signed out". An update never exposes that state.
    package func replaceIfPresent(_ value: Data, key: String) throws -> Bool {
        logger.verbose("[KeychainStore] Replacing `Data` only if present for kind=\(Self.recordKind(of: key))")
        let status = SecItemUpdate(
            attributes.itemQuery(account: key) as CFDictionary,
            attributes.updateAttributes(value: value) as CFDictionary
        )
        return try Self.writeOutcome(fromStatus: status, refusedBy: errSecItemNotFound, key: key, logger: logger)
    }

    package func remove(_ key: String) throws {
        logger.verbose("[KeychainStore] Starting to remove item from keychain with kind=\(Self.recordKind(of: key))")
        let query = attributes.itemQuery(account: key)

        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            logger.error("[KeychainStore] Error removing items from keychain with status=\(status)")
            throw KeychainAccessError.securityError(status)
        }
        logger.verbose("[KeychainStore] Successfully removed item from keychain")
    }

    package func remove(_ entry: KeychainEntry) throws {
        // The account is never logged here: device-record accounts contain usernames.
        logger.verbose("[KeychainStore] Removing one listed item from keychain")
        let status = SecItemDelete(attributes.itemQuery(for: entry) as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            logger.error("[KeychainStore] Error removing an item from keychain with status=\(status)")
            throw KeychainAccessError.securityError(status)
        }
    }

    /// A single `SecItemUpdate` of one listed item's service and access group.
    package func move(_ entry: KeychainEntry, to destination: KeychainItemAttributes) throws -> KeychainMoveOutcome {
        logger.verbose("[KeychainStore] Moving one listed item to service=\(destination.service)")
        let status = SecItemUpdate(
            attributes.itemQuery(for: entry) as CFDictionary,
            attributes.moveAttributes(to: destination) as CFDictionary
        )
        return try Self.moveOutcome(fromStatus: status, logger: logger)
    }

    /// A single `SecItemUpdate` of the item's service and access group.
    package func move(_ key: String, to destination: KeychainItemAttributes) throws -> KeychainMoveOutcome {
        // The account is never logged here: device-record accounts contain usernames.
        logger.verbose("[KeychainStore] Moving an item to service=\(destination.service)")
        let status = SecItemUpdate(
            attributes.itemQuery(account: key) as CFDictionary,
            attributes.moveAttributes(to: destination) as CFDictionary
        )
        return try Self.moveOutcome(fromStatus: status, logger: logger)
    }

    package func removeAll() throws {
        logger.verbose("[KeychainStore] Starting to remove all items from keychain")
        let query = attributes.removeAllQuery()

        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            logger.error("[KeychainStore] Error removing all items from keychain with status=\(status)")
            throw KeychainAccessError.securityError(status)
        }
        logger.verbose("[KeychainStore] Successfully removed all items from keychain")
    }

    package func hasItems() throws -> Bool {
        logger.verbose("[KeychainStore] Checking if keychain has any items")
        let query = attributes.hasItemsQuery()

        let status = SecItemCopyMatching(query as CFDictionary, nil)
        switch status {
        case errSecSuccess:
            logger.verbose("[KeychainStore] Keychain has items")
            return true
        case errSecItemNotFound:
            logger.verbose("[KeychainStore] Keychain has no items")
            return false
        default:
            logger.error("[KeychainStore] Error checking keychain items with status=\(status)")
            throw KeychainAccessError.securityError(status)
        }
    }

    package func allAccounts() throws -> [String] {
        logger.verbose("[KeychainStore] Listing accounts in keychain")
        let query = attributes.listAccountsQuery()

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        return try Self.accounts(fromStatus: status, result: result, logger: logger)
    }

    package func allEntries() throws -> [KeychainEntry] {
        logger.verbose("[KeychainStore] Listing items in keychain")
        let query = attributes.listAccountsQuery()

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        return try Self.entries(fromStatus: status, result: result, logger: logger)
    }
}

// MARK: - Status and result interpretation

package extension KeychainItemStore {

    /// Interprets the outcome of a single-item data read.
    static func data(fromStatus status: OSStatus, result: AnyObject?, key: String, logger: any Logger) throws -> Data {
        switch status {
        case errSecSuccess:
            guard let data = result as? Data else {
                logger.error("[KeychainStore] The keychain item retrieved is not the correct type")
                throw KeychainAccessError.unknown("The keychain item retrieved is not the correct type")
            }
            logger.verbose("[KeychainStore] Successfully retrieved `Data` from the store with kind=\(Self.recordKind(of: key))")
            return data
        case errSecItemNotFound:
            logger.verbose("[KeychainStore] No Keychain item found for kind=\(recordKind(of: key))")
            throw KeychainAccessError.itemNotFound
        default:
            logger.error("[KeychainStore] Error of status=\(status) occurred when attempting to retrieve a Keychain item of kind=\(recordKind(of: key))")
            throw KeychainAccessError.securityError(status)
        }
    }

    /// Interprets the outcome of an attributes-only listing.
    ///
    /// `errSecItemNotFound` is an empty service, so it maps to `[]`. Every other failure throws: a
    /// listing that failed must never be mistaken for a listing that found nothing.
    static func accounts(fromStatus status: OSStatus, result: AnyObject?, logger: any Logger) throws -> [String] {
        try entries(fromStatus: status, result: result, logger: logger).map(\.account)
    }

    /// Interprets the outcome of an attributes-only listing as one entry per item, each with its access
    /// group. Items without a `String` account are dropped. Failure is as for `accounts(fromStatus:)`.
    static func entries(fromStatus status: OSStatus, result: AnyObject?, logger: any Logger) throws -> [KeychainEntry] {
        switch status {
        case errSecSuccess:
            let items: [[String: Any]]
            if let many = result as? [[String: Any]] {
                items = many
            } else if let one = result as? [String: Any] {
                items = [one]
            } else {
                logger.error("[KeychainStore] The keychain listing retrieved is not the correct type")
                throw KeychainAccessError.unknown("The keychain listing retrieved is not the correct type")
            }
            let entries = items.compactMap { item -> KeychainEntry? in
                guard let account = item[KeychainConstants.AttributeAccount] as? String else {
                    return nil
                }
                return KeychainEntry(account: account, accessGroup: item[KeychainConstants.AttributeAccessGroup] as? String)
            }
            logger.verbose("[KeychainStore] Listed \(entries.count) account(s) in keychain")
            return entries
        case errSecItemNotFound:
            logger.verbose("[KeychainStore] Keychain has no accounts to list")
            return []
        default:
            logger.error("[KeychainStore] Error listing keychain accounts with status=\(status)")
            throw KeychainAccessError.securityError(status)
        }
    }

    /// Interprets the outcome of a single-item move.
    static func moveOutcome(fromStatus status: OSStatus, logger: any Logger) throws -> KeychainMoveOutcome {
        switch status {
        case errSecSuccess:
            logger.verbose("[KeychainStore] Moved an item")
            return .moved
        case errSecItemNotFound:
            logger.verbose("[KeychainStore] No item to move")
            return .notFound
        case errSecDuplicateItem:
            logger.verbose("[KeychainStore] The destination already holds the item, so it was not moved")
            return .destinationOccupied
        default:
            logger.error("[KeychainStore] Error moving an item with status=\(status)")
            throw KeychainAccessError.securityError(status)
        }
    }

    /// Interprets the outcome of a conditional write: success is `true`, the one status that means
    /// "the precondition did not hold" is `false`, and anything else throws.
    static func writeOutcome(
        fromStatus status: OSStatus,
        refusedBy refusal: OSStatus,
        key: String,
        logger: any Logger
    ) throws -> Bool {
        switch status {
        case errSecSuccess:
            logger.verbose("[KeychainStore] Conditional write succeeded for kind=\(recordKind(of: key))")
            return true
        case refusal:
            logger.verbose("[KeychainStore] Conditional write refused with status=\(status) for kind=\(recordKind(of: key))")
            return false
        default:
            logger.error("[KeychainStore] Error during conditional write with status=\(status) for kind=\(recordKind(of: key))")
            throw KeychainAccessError.securityError(status)
        }
    }

    /// The record kind a key ends in (`….session`, `….deviceMetadata`, `….deviceASF`), for error logs. They
    /// leave the key out: a device key holds the username. A key without a `.` gives no hint.
    static func recordKind(of key: String) -> String {
        guard let dot = key.lastIndex(of: "."), key.index(after: dot) < key.endIndex else {
            return "unknown"
        }
        return String(key[key.index(after: dot)...])
    }
}
