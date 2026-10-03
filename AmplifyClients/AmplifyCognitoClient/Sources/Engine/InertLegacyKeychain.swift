//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import InternalAmplifyKeychain

/// A keychain that holds nothing and keeps nothing: what the client hands the Cognito engine as its
/// `legacyKeychainStoreFactory`, for every service it asks for.
///
/// The engine's credential-store machine runs the AWSMobileClient legacy migration on its first event.
/// That migration copies the legacy logins forward, and deletes the legacy services only after the copy is
/// saved; it keeps them when a read fails (`c57dd1094`). When a newer saved session exists, it writes nothing
/// and clears the legacy services without a copy; when reading that session fails with a keychain error it
/// keeps them, and an undecodable session counts as absent (`f3b06afef`). The inert store is still needed:
/// the client must never migrate, clear or rewrite AWSMobileClient data, which stays the Auth plugin's job.
/// So the engine must see empty legacy services and must not be able to change them:
/// - every read is `KeychainAccessError.itemNotFound`, and every listing is empty;
/// - every write and removal succeeds and is dropped. `addIfAbsent` reports the add as accepted, as `set`
///   does; `replaceIfPresent` and `move` report that nothing was there.
///
/// Nothing reaches the real keychain: this type holds no store and makes no `SecItem` call. It also backs
/// `DeviceRecordStore.inert(namespace:)`, the stateless revoker's device store. Pinpoint's endpoint ID,
/// which the plugin reads through the legacy factory, does not go through here: `LazyUserPoolAnalytics`
/// reads it itself.
struct InertLegacyKeychain: KeychainItemStoreBehavior {

    /// The engine's `legacyKeychainStoreFactory` shape (`@Sendable (String) -> any
    /// KeychainItemStoreBehavior`): an inert store whatever service is asked for.
    static let factory: @Sendable (_ service: String) -> any KeychainItemStoreBehavior = { _ in InertLegacyKeychain() }

    init() {}

    func getData(_ key: String) throws -> Data {
        throw KeychainAccessError.itemNotFound
    }

    func set(_ value: Data, key: String) throws {}

    func addIfAbsent(_ value: Data, key: String) throws -> Bool {
        true
    }

    func replaceIfPresent(_ value: Data, key: String) throws -> Bool {
        false
    }

    func move(_ key: String, to destination: KeychainItemAttributes) throws -> KeychainMoveOutcome {
        .notFound
    }

    func move(_ entry: KeychainEntry, to destination: KeychainItemAttributes) throws -> KeychainMoveOutcome {
        .notFound
    }

    func remove(_ key: String) throws {}

    func remove(_ entry: KeychainEntry) throws {}

    func removeAll() throws {}

    func hasItems() throws -> Bool {
        false
    }

    func allAccounts() throws -> [String] {
        []
    }

    func allEntries() throws -> [KeychainEntry] {
        []
    }
}
