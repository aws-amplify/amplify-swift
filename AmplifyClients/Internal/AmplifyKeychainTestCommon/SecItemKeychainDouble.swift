//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import InternalAmplifyKeychain
import Security

/// A stand-in for the keychain at the `SecItem` layer, for tests of `KeychainItemStore` itself.
///
/// `InMemoryKeychain` replaces a whole `KeychainItemStoreBehavior`, so it cannot see the separate
/// `SecItem` calls one member makes. This double is what `KeychainItemStore(attributes:logger:secItem:)`
/// calls instead: it holds one service's items by account, records every call in order with the dictionaries it
/// was sent, and can run a hook just before the next call of a kind, to land another writer between two calls of
/// one member.
///
/// Simplification: items are matched by account alone. Every query a test sends comes from one store, so
/// service, class and access group are the same in all of them; a test that cares asserts the recorded
/// dictionaries (`requests`). A query without an account (`hasItems`) matches every item; listing is not
/// modelled.
package final class SecItemKeychainDouble: @unchecked Sendable {

    /// One `SecItem` call.
    package enum Call: Equatable, Sendable {
        case copyMatching
        case add
        case update
        case delete
    }

    /// One recorded call with what it was sent: the query (for an add, the item's attributes) and, for an update,
    /// the attributes to change.
    package struct Request {
        package let call: Call
        package let query: [String: Any]
        package let attributesToUpdate: [String: Any]?
    }

    private let lock = NSLock()
    private var items: [String: Data] = [:]
    private var recorded: [Request] = []
    private var hooks: [Call: @Sendable (SecItemKeychainDouble) -> Void] = [:]
    private var failures: [Call: OSStatus] = [:]

    package init() {}

    /// Every call made so far, in order.
    package var calls: [Call] {
        locked { recorded.map(\.call) }
    }

    /// Every call made so far, in order, with the dictionaries it was sent.
    package var requests: [Request] {
        locked { recorded }
    }

    /// The data stored under `account`, if any.
    package func value(for account: String) -> Data? {
        locked { items[account] }
    }

    /// Stores `value` under `account` directly, without recording a call: as another writer (another task,
    /// an app extension, another process) would.
    package func store(_ value: Data, account: String) {
        locked { items[account] = value }
    }

    /// Removes the item under `account` directly, without recording a call.
    package func removeItem(account: String) {
        locked { _ = items.removeValue(forKey: account) }
    }

    /// Runs `hook` once, just before the next `call` is carried out (after it is recorded).
    package func beforeNext(_ call: Call, run hook: @escaping @Sendable (SecItemKeychainDouble) -> Void) {
        locked { hooks[call] = hook }
    }

    /// Makes the next `call` return `status` without changing anything (after its hook, if any, has run).
    package func failNext(_ call: Call, with status: OSStatus) {
        locked { failures[call] = status }
    }

    /// The `SecItem` functions a `KeychainItemStore` over this double calls.
    package var secItemCalls: SecItemCalls {
        SecItemCalls(
            copyMatching: { [self] query, result in copyMatching(query, result) },
            add: { [self] attributes, _ in add(attributes) },
            update: { [self] query, attributes in update(query, attributes) },
            delete: { [self] query in delete(query) }
        )
    }

    // MARK: - The calls

    private func copyMatching(_ query: CFDictionary, _ result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus {
        let dictionary = Self.dictionary(query)
        if let failure = begin(.copyMatching, query: dictionary) {
            return failure
        }
        return locked {
            guard let account = dictionary[KeychainConstants.AttributeAccount] as? String else {
                return items.isEmpty ? errSecItemNotFound : errSecSuccess
            }
            guard let data = items[account] else {
                return errSecItemNotFound
            }
            if dictionary[KeychainConstants.ReturnData] as? Bool == true {
                result?.pointee = data as CFData
            }
            return errSecSuccess
        }
    }

    private func add(_ attributes: CFDictionary) -> OSStatus {
        let dictionary = Self.dictionary(attributes)
        if let failure = begin(.add, query: dictionary) {
            return failure
        }
        guard let account = dictionary[KeychainConstants.AttributeAccount] as? String,
              let data = dictionary[KeychainConstants.ValueData] as? Data else {
            return errSecParam
        }
        return locked {
            guard items[account] == nil else {
                return errSecDuplicateItem
            }
            items[account] = data
            return errSecSuccess
        }
    }

    private func update(_ query: CFDictionary, _ attributes: CFDictionary) -> OSStatus {
        let query = Self.dictionary(query)
        let attributes = Self.dictionary(attributes)
        if let failure = begin(.update, query: query, attributesToUpdate: attributes) {
            return failure
        }
        guard let account = query[KeychainConstants.AttributeAccount] as? String,
              let data = attributes[KeychainConstants.ValueData] as? Data else {
            return errSecParam
        }
        return locked {
            guard items[account] != nil else {
                return errSecItemNotFound
            }
            items[account] = data
            return errSecSuccess
        }
    }

    private func delete(_ query: CFDictionary) -> OSStatus {
        let query = Self.dictionary(query)
        if let failure = begin(.delete, query: query) {
            return failure
        }
        guard let account = query[KeychainConstants.AttributeAccount] as? String else {
            return errSecParam
        }
        return locked {
            items.removeValue(forKey: account) == nil ? errSecItemNotFound : errSecSuccess
        }
    }

    // MARK: - Support

    /// Records `call` with its dictionaries, runs its hook outside the lock (a hook may call `store`), and returns its injected
    /// failure, if any.
    private func begin(_ call: Call, query: [String: Any], attributesToUpdate: [String: Any]? = nil) -> OSStatus? {
        let hook = locked {
            recorded.append(Request(call: call, query: query, attributesToUpdate: attributesToUpdate))
            return hooks.removeValue(forKey: call)
        }
        hook?(self)
        return locked { failures.removeValue(forKey: call) }
    }

    private static func dictionary(_ value: CFDictionary) -> [String: Any] {
        (value as NSDictionary) as? [String: Any] ?? [:]
    }

    private func locked<T>(_ body: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return body()
    }
}
