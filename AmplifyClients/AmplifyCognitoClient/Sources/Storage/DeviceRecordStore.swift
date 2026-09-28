//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import InternalAmplifyKeychain

/// The per-**user** device records the Cognito engine keeps: the remembered device's metadata and the
/// advanced-security (ASF) device ID. Stored at exactly the Auth plugin's keys, so a device the plugin
/// remembered is still remembered by the client, and the reverse.
///
/// **Per user, not per session.** Every session in one storage namespace reads and writes the same
/// user's records: one person signed in on two sessions is one device to Cognito, with one ASF ID
/// (design §6, "three levels of scoping"). Session-level operations — sign-out, purge, adoption,
/// listing — never touch these records; only the engine does, through this store.
///
/// | Record | Account |
/// |---|---|
/// | device metadata | `amplify.<poolNamespace>.<username.lowercased()>.deviceMetadata` |
/// | ASF device ID | `amplify.<poolNamespace>.<username>.deviceASF` — **not** lowercased |
///
/// The casing asymmetry is the plugin's and must be kept: existing records are stored under both keys
/// as they are. Both live under the session records' service (`SessionRecordStore.service(forAccessGroup:)`)
/// and, when one is configured, scoped to the access group. This store never names the plugin's session
/// key (`amplify.<poolNamespace>.session`), a client session record, or `authConfiguration`.
///
/// Values are encoded as the plugin encodes them: a default `JSONEncoder()`, decoded with a default
/// `JSONDecoder()`. The device metadata's type is the engine's; this store is generic over it, so it
/// needs no engine import.
///
/// **A keychain failure is never "absent".** A read returns `.absent` only when no item is stored;
/// every keychain failure throws `AuthClientError.storageUnavailable`. Bytes that do not decode are
/// `.undecodable`, which is present, and not an error of the keychain.
///
/// Synchronous: each call blocks on the keychain. Async callers go through `DeviceRecordIO`, which runs
/// the calls off the cooperative pool.
struct DeviceRecordStore: Sendable {

    /// What a read found.
    enum Read<Value> {
        /// No item is stored. The only result that means "no record".
        case absent
        case value(Value)
        /// An item is stored, but it is not a value of the requested type.
        case undecodable
    }

    static let deviceMetadataSuffix = "deviceMetadata"
    static let asfDeviceSuffix = "deviceASF"

    let namespace: SessionStorageNamespace
    private let keychain: any KeychainItemStoreBehavior

    init(namespace: SessionStorageNamespace, keychain: any KeychainItemStoreBehavior) {
        self.namespace = namespace
        self.keychain = keychain
    }

    /// A store over the real keychain, under the session records' service and access group.
    init(namespace: SessionStorageNamespace) {
        self.init(
            namespace: namespace,
            keychain: KeychainItemStore(
                service: SessionRecordStore.service(forAccessGroup: namespace.accessGroup),
                accessGroup: namespace.accessGroup
            )
        )
    }

    /// A store that keeps nothing: every read is `.absent`, every write and removal is dropped. For the
    /// stateless revoker, which must touch no keychain.
    static func inert(namespace: SessionStorageNamespace) -> DeviceRecordStore {
        DeviceRecordStore(namespace: namespace, keychain: InertLegacyKeychain())
    }

    // MARK: Accounts — the plugin's derivation, verbatim

    static func deviceMetadataAccount(for username: String, in pools: PoolNamespace) -> String {
        "amplify.\(pools.keyComponent).\(username.lowercased()).\(deviceMetadataSuffix)"
    }

    static func asfDeviceAccount(for username: String, in pools: PoolNamespace) -> String {
        "amplify.\(pools.keyComponent).\(username).\(asfDeviceSuffix)"
    }

    func deviceMetadataAccount(for username: String) -> String {
        Self.deviceMetadataAccount(for: username, in: namespace.pools)
    }

    func asfDeviceAccount(for username: String) -> String {
        Self.asfDeviceAccount(for: username, in: namespace.pools)
    }

    // MARK: Device metadata

    func deviceMetadata<Metadata: Decodable>(_ type: Metadata.Type, for username: String) throws -> Read<Metadata> {
        try read(type, at: deviceMetadataAccount(for: username), operation: "read the device metadata")
    }

    func saveDeviceMetadata(_ metadata: some Encodable, for username: String) throws {
        try write(metadata, at: deviceMetadataAccount(for: username), operation: "write the device metadata")
    }

    func removeDeviceMetadata(for username: String) throws {
        try perform("delete the device metadata") { try keychain.remove(deviceMetadataAccount(for: username)) }
    }

    // MARK: ASF device ID

    func asfDeviceId(for username: String) throws -> Read<String> {
        try read(String.self, at: asfDeviceAccount(for: username), operation: "read the advanced security device ID")
    }

    func saveASFDeviceId(_ deviceId: String, for username: String) throws {
        try write(deviceId, at: asfDeviceAccount(for: username), operation: "write the advanced security device ID")
    }

    func removeASFDeviceId(for username: String) throws {
        try perform("delete the advanced security device ID") { try keychain.remove(asfDeviceAccount(for: username)) }
    }

    // MARK: Keychain access

    private func read<Value: Decodable>(_ type: Value.Type, at account: String, operation: String) throws -> Read<Value> {
        guard let data = try perform(operation, { try keychain.dataIfPresent(account) }) else {
            return .absent
        }
        guard let value = try? JSONDecoder().decode(type, from: data) else {
            return .undecodable
        }
        return .value(value)
    }

    private func write(_ value: some Encodable, at account: String, operation: String) throws {
        let data: Data
        do {
            data = try JSONEncoder().encode(value)
        } catch {
            // Not a storage failure: nothing was written, and retrying cannot help.
            throw AuthClientError.unknown("Could not encode the value to \(operation).", "This is a bug; please report it.", error)
        }
        try perform(operation) { try keychain.set(data, key: account) }
    }

    private func perform<Value>(_ operation: String, _ body: () throws -> Value) throws -> Value {
        do {
            return try body()
        } catch {
            throw AuthClientError.storageUnavailable(from: error, operation: operation)
        }
    }
}

extension DeviceRecordStore.Read: Sendable where Value: Sendable {}
extension DeviceRecordStore.Read: Equatable where Value: Equatable {}
