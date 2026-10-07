//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyKeychainTestCommon
import Foundation
import InternalAmplifyKeychain

/// Records every keychain query the plugin's credential store and the legacy AWSMobileClient migration
/// issue, for the keychain query-parity gate (`KeychainQueryParityTests`).
///
/// Queries are recorded at the `KeychainItemStoreBehavior` layer, the one both seams return:
/// `AWSCognitoAuthCredentialStore`'s `makeKeychainStore` and `legacyKeychainStoreFactory` build an item
/// store for a service (and access group), and every keychain store the plugin uses, including the
/// access-group migration's, operates on one of them. The recording store is passed in directly, so
/// nothing the store does bypasses the recorder, and the vocabulary is the one the baseline recorded through
/// `KeychainStore.init(service:accessGroup:itemStore:)`: the baseline compares without translation.
final class KeychainQueryRecorder: @unchecked Sendable {

    /// Which seam created the store a query went through.
    enum Origin: String {
        /// `AWSCognitoAuthCredentialStore`'s `makeKeychainStore`.
        case store
        /// `CredentialStoreEnvironment.legacyKeychainStoreFactory`.
        case legacy
    }

    let keychain: InMemoryKeychain
    private let lock = NSLock()
    private var recorded: [String] = []
    private var substitutions: [(String, String)] = []

    init(keychain: InMemoryKeychain) {
        self.keychain = keychain
    }

    /// Replaces `value` with `placeholder` in `queries`, for values that differ from run to run or host to
    /// host: `Bundle.main.bundleIdentifier`, or an ID the code under test generates. Applies to queries
    /// already recorded too, so a generated value can be substituted once it is known.
    func substitute(_ value: String, with placeholder: String) {
        locked { substitutions.append((value, placeholder)) }
    }

    /// Every query recorded since the last `reset()`, in order, with the substitutions applied.
    var queries: [String] {
        locked {
            recorded.map { line in
                substitutions.reduce(line) { $0.replacingOccurrences(of: $1.0, with: $1.1) }
            }
        }
    }

    /// Every query recorded since the last `reset()`, in order, before any substitution.
    var rawQueries: [String] { locked { recorded } }

    func reset() {
        locked { recorded.removeAll() }
    }

    /// The `makeKeychainStore` seam of `AWSCognitoAuthCredentialStore`, recording through `self`.
    var makeKeychainStore: @Sendable (_ service: String, _ accessGroup: String?) -> any KeychainItemStoreBehavior {
        { [self] service, accessGroup in
            itemStore(origin: .store, service: service, accessGroup: accessGroup)
        }
    }

    /// The `legacyKeychainStoreFactory` of `BasicCredentialStoreEnvironment`, recording through `self`.
    /// The plugin's factory builds the store without an access group, so there is none.
    var legacyKeychainStoreFactory: @Sendable (_ service: String) -> any KeychainItemStoreBehavior {
        { [self] service in
            itemStore(origin: .legacy, service: service, accessGroup: nil)
        }
    }

    func itemStore(origin: Origin, service: String, accessGroup: String?) -> RecordingKeychainItemStore {
        RecordingKeychainItemStore(
            recorder: self,
            origin: origin,
            inner: keychain.store(service: service, accessGroup: accessGroup)
        )
    }

    /// Appends `<origin> | <operation> | <service> | <access group or -> | <key or -> -> <outcome>`.
    fileprivate func record<Value>(
        _ origin: Origin,
        _ operation: String,
        _ store: InMemoryKeychainItemStore,
        key: String?,
        outcome: (Value) -> String = { _ in "ok" },
        _ body: () throws -> Value
    ) throws -> Value {
        let result: Result<Value, Error> = Result { try body() }
        let outcomeText: String = switch result {
        case .success(let value): outcome(value)
        case .failure(let error): Self.describe(error)
        }
        let line = [
            origin.rawValue,
            operation,
            store.service,
            store.accessGroup ?? "-",
            key ?? "-"
        ].joined(separator: " | ") + " -> " + outcomeText
        locked { recorded.append(line) }
        return try result.get()
    }

    private static func describe(_ error: Error) -> String {
        if let error = error as? KeychainAccessError {
            if case .itemNotFound = error {
                return "itemNotFound"
            }
            return "error(\(error))"
        }
        return "error(\(type(of: error)))"
    }

    private func locked<T>(_ body: () throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try body()
    }
}

/// A `KeychainItemStoreBehavior` over the in-memory fake that records each call before returning its
/// result. The `package` extensions on the protocol (`removeAllExceptSessionRecords`,
/// `hasItemsExceptSessionRecords`, `dataIfPresent`) are built on these requirements, so their queries
/// are recorded too.
struct RecordingKeychainItemStore: KeychainItemStoreBehavior {
    let recorder: KeychainQueryRecorder
    let origin: KeychainQueryRecorder.Origin
    let inner: InMemoryKeychainItemStore

    func getData(_ key: String) throws -> Data {
        try recorder.record(origin, "getData", inner, key: key) { try inner.getData(key) }
    }

    func set(_ value: Data, key: String) throws {
        try recorder.record(origin, "set", inner, key: key) { try inner.set(value, key: key) }
    }

    func addIfAbsent(_ value: Data, key: String) throws -> Bool {
        try recorder.record(origin, "addIfAbsent", inner, key: key, outcome: { "\($0)" }) {
            try inner.addIfAbsent(value, key: key)
        }
    }

    func replaceIfPresent(_ value: Data, key: String) throws -> Bool {
        try recorder.record(origin, "replaceIfPresent", inner, key: key, outcome: { "\($0)" }) {
            try inner.replaceIfPresent(value, key: key)
        }
    }

    func move(_ key: String, to destination: KeychainItemAttributes) throws -> KeychainMoveOutcome {
        try recorder.record(origin, "move(to: \(Self.describe(destination)))", inner, key: key, outcome: { "\($0)" }) {
            try inner.move(key, to: destination)
        }
    }

    func move(_ entry: KeychainEntry, to destination: KeychainItemAttributes) throws -> KeychainMoveOutcome {
        try recorder.record(
            origin,
            "moveEntry(group: \(entry.accessGroup ?? "-"), to: \(Self.describe(destination)))",
            inner,
            key: entry.account,
            outcome: { "\($0)" }
        ) {
            try inner.move(entry, to: destination)
        }
    }

    func remove(_ key: String) throws {
        try recorder.record(origin, "remove", inner, key: key) { try inner.remove(key) }
    }

    func remove(_ entry: KeychainEntry) throws {
        try recorder.record(origin, "removeEntry(group: \(entry.accessGroup ?? "-"))", inner, key: entry.account) {
            try inner.remove(entry)
        }
    }

    func removeAll() throws {
        try recorder.record(origin, "removeAll", inner, key: nil) { try inner.removeAll() }
    }

    func hasItems() throws -> Bool {
        try recorder.record(origin, "hasItems", inner, key: nil, outcome: { "\($0)" }) { try inner.hasItems() }
    }

    func allAccounts() throws -> [String] {
        try recorder.record(origin, "allAccounts", inner, key: nil, outcome: { "\($0.count) accounts" }) {
            try inner.allAccounts()
        }
    }

    func allEntries() throws -> [KeychainEntry] {
        try recorder.record(origin, "allEntries", inner, key: nil, outcome: { "\($0.count) entries" }) {
            try inner.allEntries()
        }
    }

    private static func describe(_ destination: KeychainItemAttributes) -> String {
        "\(destination.service) / \(destination.accessGroup ?? "-")"
    }
}
