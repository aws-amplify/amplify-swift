//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import Foundation
import InternalAmplifyKeychain

// swiftlint:disable identifier_name
/// The engine's copy of `AWSPluginsCore.KeychainStore`: the members the credential store,
/// the legacy-store migration and the Pinpoint endpoint read use, over any `KeychainItemStoreBehavior`.
///
/// `KeychainStore` delegates every member to a `KeychainItemStore`, so the queries are
/// the item store's own. What this type adds is exactly what `KeychainStore` adds on top of it:
/// - failures are rethrown as `EngineCredentialStoreError`, the copy of `KeychainStoreError`, case for case;
/// - `_getString` and `_set(_: String, key:)` convert through UTF-8 with the same errors and log lines;
/// - everything is logged under the `KeychainStore` namespace, as `KeychainStore.log` is, through the
///   caller's logger: the plugin's resolves it to `Amplify.Logging.logger(forNamespace: "KeychainStore")`.
///
/// Members are named as in `KeychainStore`, so the code that used one changes only its type names.
package struct EngineKeychainStore: Sendable {

    /// The store every member operates on: a `KeychainItemStore` in production (see `makeItemStore`), the
    /// in-memory fake or a recorder in tests.
    package let itemStore: any KeychainItemStoreBehavior

    /// The caller's logger, at the `KeychainStore` namespace.
    let log: EngineLogger

    package init(_ itemStore: any KeychainItemStoreBehavior, logger: any EngineScopedLogger) {
        self.itemStore = itemStore
        self.log = logger.scoped(Self.logScope)
    }

    /// Get a string value from the Keychain based on the key.
    package func _getString(_ key: String) throws -> String {
        log.verbose("[KeychainStore] Started retrieving `String` from the store with kind=\(KeychainItemStore.recordKind(of: key))")
        let data = try _getData(key)
        guard let string = String(data: data, encoding: .utf8) else {
            log.error("[KeychainStore] Unable to create String from Data retrieved")
            throw EngineCredentialStoreError.conversionError("Unable to create String from Data retrieved")
        }
        log.verbose("[KeychainStore] Successfully retrieved `String` from the store")
        return string

    }

    /// Get a data value from the Keychain based on the key.
    package func _getData(_ key: String) throws -> Data {
        try EngineCredentialStoreError.mapping { try itemStore.getData(key) }
    }

    /// Set a key-value pair in the Keychain.
    package func _set(_ value: String, key: String) throws {
        log.verbose("[KeychainStore] Started setting `String` for kind=\(KeychainItemStore.recordKind(of: key))")
        guard let data = value.data(using: .utf8, allowLossyConversion: false) else {
            log.error("[KeychainStore] Unable to create Data from String retrieved for kind=\(KeychainItemStore.recordKind(of: key))")
            throw EngineCredentialStoreError.conversionError("Unable to create Data from String retrieved")
        }
        try _set(data, key: key)
        log.verbose("[KeychainStore] Successfully added `String` for kind=\(KeychainItemStore.recordKind(of: key))")
    }

    /// Set a key-value pair in the Keychain.
    package func _set(_ value: Data, key: String) throws {
        try EngineCredentialStoreError.mapping { try itemStore.set(value, key: key) }
    }

    /// Remove key-value pair from Keychain based on the provided key.
    package func _remove(_ key: String) throws {
        try EngineCredentialStoreError.mapping { try itemStore.remove(key) }
    }

    /// Removes all key-value pair in the Keychain.
    package func _removeAll() throws {
        try EngineCredentialStoreError.mapping { try itemStore.removeAll() }
    }

    /// Removes every item under this service and access group except the standalone clients' session
    /// records (`amplify.<digits>.…` accounts), which may share the service. See
    /// `KeychainStore.removeAllExceptSessionRecords(sparingDefaultSessionItems:)`.
    ///
    /// - Parameter sparingDefaultSessionItems: `false` also removes the Cognito client's default-session
    ///   sidecar and challenge items, which belong to the plugin's session. Other session records are
    ///   spared either way. No default: every caller says which it wants.
    package func removeAllExceptSessionRecords(sparingDefaultSessionItems: Bool) throws {
        try EngineCredentialStoreError.mapping {
            try itemStore.removeAllExceptSessionRecords(logger: log, sparingDefaultSessionItems: sparingDefaultSessionItems)
        }
    }

    /// Whether this service and access group hold at least one item other than the standalone clients'
    /// session records.
    package func hasItemsExceptSessionRecords() throws -> Bool {
        try EngineCredentialStoreError.mapping { try itemStore.hasItemsExceptSessionRecords() }
    }

    /// Checks if the Keychain contains any items for this service and access group.
    package func _hasItems() throws -> Bool {
        try EngineCredentialStoreError.mapping { try itemStore.hasItems() }
    }
}
// swiftlint:enable identifier_name

package extension EngineKeychainStore {

    /// `KeychainStore.log`'s scope: `Amplify.Logging.logger(forNamespace: "KeychainStore")` through the
    /// plugin's logger.
    static let logScope = EngineLogScope.namespace("KeychainStore")

    /// The item store `KeychainStore(service:accessGroup:)` operates on, built the same way: generic
    /// password, the given service and access group, logging under the `KeychainStore` namespace of
    /// `logger`, the caller's. Logs the line that initializer logs.
    static func makeItemStore(
        service: String,
        accessGroup: String? = nil,
        logger: any EngineScopedLogger
    ) -> KeychainItemStore {
        let log = logger.scoped(logScope)
        let attributes = KeychainStoreAttributes(service: service, accessGroup: accessGroup)
        log.verbose(
            "[KeychainStore] Initialized keychain with service=\(service), " +
            "attributes=\(attributes), " +
            "accessGroup=\(attributes.accessGroup ?? "No access group specified")"
        )
        return KeychainItemStore(attributes: attributes.itemAttributes, logger: log)
    }

    /// `store`, but logging everything at verbose level when it is a production `KeychainItemStore`:
    /// `KeychainStore.quietBackingStore`, for checks whose failure has always been silent, such as the
    /// access-group migrator's "does the destination hold items" check. Any other store (a test's) is
    /// returned as it is, as `quietBackingStore` returns an injected one.
    static func quiet(_ store: any KeychainItemStoreBehavior, logger: any EngineScopedLogger) -> any KeychainItemStoreBehavior {
        guard let itemStore = store as? KeychainItemStore else {
            return store
        }
        // Rebuilt with `.system` `SecItem` calls: a test's `SecItemCalls` seam is not carried over, which only
        // tests could notice.
        return KeychainItemStore(attributes: itemStore.attributes, logger: VerboseOnlyLogger(logger.scoped(logScope)))
    }
}

/// `AWSPluginsCore.KeychainStoreAttributes`, field for field, so the "Initialized keychain" line prints
/// the attributes exactly as `KeychainStore` does. `EngineKeychainStoreTests` compares the two.
private struct KeychainStoreAttributes {

    var itemClass: String = KeychainConstants.ClassGenericPassword
    var service: String
    var accessGroup: String?

    var itemAttributes: KeychainItemAttributes {
        KeychainItemAttributes(itemClass: itemClass, service: service, accessGroup: accessGroup)
    }
}
