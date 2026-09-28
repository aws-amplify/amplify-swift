//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
@preconcurrency import Foundation
import InternalAmplifyKeychain

// swiftlint:disable identifier_name
/// - Note: `Sendable` because keychain stores are shared across concurrency domains by the auth and
///   analytics plugins; the underlying Security framework calls are thread-safe.
public protocol KeychainStoreBehavior: Sendable {

    /// Get a string value from the Keychain based on the key.
    /// This System Programming Interface (SPI) may have breaking changes in future updates.
    /// - Parameter key: A String key use to look up the value in the Keychain
    /// - Returns: A string value
    @_spi(KeychainStore)
    func _getString(_ key: String) throws -> String

    /// Get a data value from the Keychain based on the key.
    /// This System Programming Interface (SPI) may have breaking changes in future updates.
    /// - Parameter key: A String key use to look up the value in the Keychain
    /// - Returns: A data value
    @_spi(KeychainStore)
    func _getData(_ key: String) throws -> Data

    /// Set a key-value pair in the Keychain.
    /// This System Programming Interface (SPI) may have breaking changes in future updates.
    /// - Parameters:
    ///   - value: A string value to store in Keychain
    ///   - key: A String key for the value to store in the Keychain
    @_spi(KeychainStore)
    func _set(_ value: String, key: String) throws

    /// Set a key-value pair in the Keychain.
    /// This iSystem Programming Interface (SPI) may have breaking changes in future updates.
    /// - Parameters:
    ///   - value: A data value to store in Keychain
    ///   - key: A String key for the value to store in the Keychain
    @_spi(KeychainStore)
    func _set(_ value: Data, key: String) throws

    /// Remove key-value pair from Keychain based on the provided key.
    /// This System Programming Interface (SPI) may have breaking changes in future updates.
    /// - Parameter key: A String key to delete the key-value pair
    @_spi(KeychainStore)
    func _remove(_ key: String) throws

    /// Removes all key-value pair in the Keychain.
    /// This System Programming Interface (SPI) may have breaking changes in future updates.
    @_spi(KeychainStore)
    func _removeAll() throws

    /// Checks if the Keychain contains any items for this service and access group.
    /// This System Programming Interface (SPI) may have breaking changes in future updates.
    /// - Returns: `true` if at least one item exists, `false` otherwise
    @_spi(KeychainStore)
    func _hasItems() throws -> Bool

}

public struct KeychainStore: KeychainStoreBehavior {

    let attributes: KeychainStoreAttributes

    /// Replaces the `SecItem` implementation, for tests only. `nil` in every store an app creates.
    private let injectedItemStore: (any KeychainItemStoreBehavior)?

    private init(attributes: KeychainStoreAttributes) {
        self.attributes = attributes
        self.injectedItemStore = nil
    }

    public init() {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            fatalError("Unable to retrieve bundle identifier to initialize keychain")
        }
        self.init(service: bundleIdentifier)
    }

    public init(service: String) {
        self.init(service: service, accessGroup: nil)
    }

    public init(service: String, accessGroup: String? = nil) {
        self.attributes = KeychainStoreAttributes(service: service, accessGroup: accessGroup)
        self.injectedItemStore = nil
        log.verbose(
            "[KeychainStore] Initialized keychain with service=\(service), " +
            "attributes=\(attributes), " +
            "accessGroup=\(attributes.accessGroup ?? "No access group specified")"
        )
    }

    /// A store whose items live in `itemStore` rather than the real keychain.
    ///
    /// A test seam: `swift test` runs unsigned, so the real data-protection keychain is unavailable, and
    /// this lets code that creates `KeychainStore`s run over the in-memory fake in
    /// `AmplifyKeychainTestCommon` while still exercising this type's own logic. `package`, so apps
    /// cannot reach it.
    package init(service: String, accessGroup: String? = nil, itemStore: any KeychainItemStoreBehavior) {
        self.attributes = KeychainStoreAttributes(service: service, accessGroup: accessGroup)
        self.injectedItemStore = itemStore
    }

    /// Get a string value from the Keychain based on the key.
    /// This System Programming Interface (SPI) may have breaking changes in future updates.
    /// - Parameter key: A String key use to look up the value in the Keychain
    /// - Returns: A string value
    @_spi(KeychainStore)
    public func _getString(_ key: String) throws -> String {
        log.verbose("[KeychainStore] Started retrieving `String` from the store with key=\(key)")
        let data = try _getData(key)
        guard let string = String(data: data, encoding: .utf8) else {
            log.error("[KeychainStore] Unable to create String from Data retrieved")
            throw KeychainStoreError.conversionError("Unable to create String from Data retrieved")
        }
        log.verbose("[KeychainStore] Successfully retrieved `String` from the store")
        return string

    }

    /// Get a data value from the Keychain based on the key.
    /// This System Programming Interface (SPI) may have breaking changes in future updates.
    /// - Parameter key: A String key use to look up the value in the Keychain
    /// - Returns: A data value
    @_spi(KeychainStore)
    public func _getData(_ key: String) throws -> Data {
        try KeychainStoreError.mapping { try backingStore.getData(key) }
    }

    /// Set a key-value pair in the Keychain.
    /// This System Programming Interface (SPI) may have breaking changes in future updates.
    /// - Parameters:
    ///   - value: A string value to store in Keychain
    ///   - key: A String key for the value to store in the Keychain
    @_spi(KeychainStore)
    public func _set(_ value: String, key: String) throws {
        log.verbose("[KeychainStore] Started setting `String` for key=\(key)")
        guard let data = value.data(using: .utf8, allowLossyConversion: false) else {
            log.error("[KeychainStore] Unable to create Data from String retrieved for key=\(key)")
            throw KeychainStoreError.conversionError("Unable to create Data from String retrieved")
        }
        try _set(data, key: key)
        log.verbose("[KeychainStore] Successfully added `String` for key=\(key)")
    }

    /// Set a key-value pair in the Keychain.
    /// This iSystem Programming Interface (SPI) may have breaking changes in future updates.
    /// - Parameters:
    ///   - value: A data value to store in Keychain
    ///   - key: A String key for the value to store in the Keychain
    @_spi(KeychainStore)
    public func _set(_ value: Data, key: String) throws {
        try KeychainStoreError.mapping { try backingStore.set(value, key: key) }
    }

    /// Remove key-value pair from Keychain based on the provided key.
    /// This System Programming Interface (SPI) may have breaking changes in future updates.
    /// - Parameter key: A String key to delete the key-value pair
    @_spi(KeychainStore)
    public func _remove(_ key: String) throws {
        try KeychainStoreError.mapping { try backingStore.remove(key) }
    }

    /// Removes all key-value pair in the Keychain.
    /// This System Programming Interface (SPI) may have breaking changes in future updates.
    @_spi(KeychainStore)
    public func _removeAll() throws {
        try KeychainStoreError.mapping { try backingStore.removeAll() }
    }

    /// Removes every item under this service and access group except the standalone clients' session
    /// records (`amplify.<digits>.…` accounts), which may share the service.
    ///
    /// Use this, not `_removeAll()`, to clear a service a standalone client may also store in. With no
    /// session records present it removes exactly what `_removeAll()` would. If the items cannot be
    /// listed it logs a warning and removes nothing, never falling back to `_removeAll()`.
    package func removeAllExceptSessionRecords() throws {
        try KeychainStoreError.mapping {
            try backingStore.removeAllExceptSessionRecords(logger: AmplifyLoggerBridge<KeychainStore>())
        }
    }

    /// Whether this service and access group hold at least one item other than the standalone clients'
    /// session records. Use this, not `_hasItems()`, where a client record sharing the service must not
    /// count as one of the caller's items.
    package func hasItemsExceptSessionRecords() throws -> Bool {
        try KeychainStoreError.mapping { try backingStore.hasItemsExceptSessionRecords() }
    }

    /// Checks if the Keychain contains any items for this service and access group.
    /// This System Programming Interface (SPI) may have breaking changes in future updates.
    /// - Returns: `true` if at least one item exists, `false` otherwise
    @_spi(KeychainStore)
    public func _hasItems() throws -> Bool {
        try KeychainStoreError.mapping { try backingStore.hasItems() }
    }

    /// The shared implementation every member delegates to. Built per call from `attributes`, so this
    /// type's stored layout is unchanged, and logging through `KeychainStore.log` as it always has.
    var itemStore: KeychainItemStore {
        KeychainItemStore(attributes: attributes.itemAttributes, logger: AmplifyLoggerBridge<KeychainStore>())
    }

    /// What every member actually operates on: the injected store in tests, `itemStore` otherwise.
    var backingStore: any KeychainItemStoreBehavior {
        injectedItemStore ?? itemStore
    }

    /// `backingStore`, but logging everything at verbose level. For checks whose failure has always been
    /// silent, such as the migrator's "does the destination hold items" check, so they do not start
    /// logging errors.
    var quietBackingStore: any KeychainItemStoreBehavior {
        injectedItemStore ?? KeychainItemStore(
            attributes: attributes.itemAttributes,
            logger: VerboseOnlyLogger(AmplifyLoggerBridge<KeychainStore>())
        )
    }

}

extension KeychainStore {
    /// The `SecItem` constants, now defined once in `InternalAmplifyKeychain`.
    typealias Constants = KeychainConstants
}
// swiftlint:enable identifier_name

extension KeychainStore: DefaultLogger {
    public static var log: Logger {
        Amplify.Logging.logger(forNamespace: String(describing: self))
    }

    public nonisolated var log: Logger { Self.log }
}
