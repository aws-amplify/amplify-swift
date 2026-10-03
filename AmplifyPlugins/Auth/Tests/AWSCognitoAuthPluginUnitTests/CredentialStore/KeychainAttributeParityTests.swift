//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyKeychainTestCommon
import Foundation
import InternalAmplifyKeychain
import Security
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient
@testable import AWSCognitoAuthPlugin
@testable import InternalAWSCognitoAuth

/// The Cognito client's `.default` writes the Auth plugin's own record, so the items it
/// creates must be indistinguishable from the ones the plugin creates: the same service, access group, protection
/// class and synchronizable flag, or a plugin build would read a different item, or none. The rollback matrix's
/// row 8, and the row that decodes the client's bytes with the released plugin's types: both need
/// the plugin's released types and its item store, so they are here only, not mirrored in the client's
/// `RollbackMatrixClientTests`.
///
/// Each side builds its real item store (the client's `SessionRecordStore(namespace:)`, the plugin's
/// `EngineKeychainStore.makeItemStore(service:accessGroup:)` through its credential store's seam), and a recorder
/// captures the `SecItem` calls that store's attributes give for each write, as `KeychainItemStore` makes them, over
/// the in-memory keychain, since `swift test` runs unsigned.
final class KeychainAttributeParityTests: XCTestCase {

    private let authConfiguration = AuthConfiguration.userPoolsAndIdentityPools(
        UserPoolConfigurationData(poolId: "us-east-1_Pool", clientId: "client", region: "us-east-1"),
        IdentityPoolConfigurationData(poolId: "us-east-1:identity-pool", region: "us-east-1")
    )
    private let pools = PoolNamespace.userPoolAndIdentityPool(userPoolId: "us-east-1_Pool", identityPoolId: "us-east-1:identity-pool")
    private var pluginAccount: String { SessionRecordKey.pluginSessionAccount(in: pools) }
    /// The plugin's two services: without an access group, and the shared one with an access group.
    private let services: [(service: String, accessGroup: String?)] = [
        ("com.amplify.awsCognitoAuthPlugin", nil),
        ("com.amplify.awsCognitoAuthPluginShared", "group.acme")
    ]

    private var userDefaults: UserDefaults!
    private var userDefaultsSuite: String!

    override func setUp() {
        super.setUp()
        userDefaultsSuite = "KeychainAttributeParityTests.\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: userDefaultsSuite)
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: userDefaultsSuite)
        userDefaults = nil
        super.tearDown()
    }

    // MARK: - Row 8: the attributes

    /// The client and the plugin build identical attributes for each of the plugin's services.
    ///
    /// - Given: the service `com.amplify.awsCognitoAuthPlugin` with no access group, and `…Shared` with group `G`
    /// - When:
    ///    - the plugin's credential store saves a session, and, over another keychain, the client's `.default` writes
    ///      the same bytes
    /// - Then:
    ///    - the client's `SessionRecordStore(namespace:)` has the `KeychainItemAttributes` of
    ///      `EngineKeychainStore.makeItemStore(service:accessGroup:)`
    ///    - both add exactly one item under `amplify.<ns>.session`, with the same query key by key: the class,
    ///      service, access group, data-protection keychain, `AfterFirstUnlockThisDeviceOnly`, no synchronizable flag,
    ///      no label, and the same account and bytes, and no other key
    ///
    func testClientAndPluginBuildIdenticalAttributesForEachService() throws {
        for (service, accessGroup) in services {
            let label = accessGroup ?? "no access group"
            let pluginWrites = KeychainCallLog()
            let pluginKeychain = InMemoryKeychain()
            let pluginStore = makePluginStore(accessGroup: accessGroup, keychain: pluginKeychain, log: pluginWrites)
            try pluginStore.saveCredential(LongLivedCredentials.userPoolAndIdentityPool())
            userDefaults.removePersistentDomain(forName: userDefaultsSuite)
            // The plugin's bytes, so both sides add the same value: the encoder's key order is not fixed.
            let payload = try XCTUnwrap(pluginKeychain.value(service: service, accessGroup: accessGroup, account: pluginAccount), label)

            let clientWrites = KeychainCallLog()
            let clientStore = makeClientStore(accessGroup: accessGroup, keychain: InMemoryKeychain(), log: clientWrites)
            XCTAssertEqual(
                try clientAttributes(accessGroup: accessGroup),
                EngineKeychainStore.makeItemStore(service: service, accessGroup: accessGroup, logger: AmplifyEngineLogRouter()).attributes,
                label
            )
            let record = SessionRecord(label: nil, username: "alice", userId: "alice-sub", kind: .userPoolAndIdentityPool, credentials: payload)
            XCTAssertTrue(try clientStore.write(record, for: .default, expecting: nil).didCommit, label)

            let pluginQuery = try XCTUnwrap(pluginWrites.addQueries(for: pluginAccount).first, label)
            let clientQueries = clientWrites.addQueries(for: pluginAccount)
            XCTAssertEqual(clientQueries.count, 1, label)
            let clientQuery = try XCTUnwrap(clientQueries.first, label)
            XCTAssertTrue(NSDictionary(dictionary: clientQuery).isEqual(to: pluginQuery), "\(label): \(clientQuery) vs \(pluginQuery)")

            var expectedKeys = Set([
                kSecClass, kSecAttrService, kSecUseDataProtectionKeychain, kSecAttrAccessible, kSecAttrAccount, kSecValueData
            ].map { $0 as String })
            if accessGroup != nil {
                expectedKeys.insert(kSecAttrAccessGroup as String)
            }
            XCTAssertEqual(Set(clientQuery.keys), expectedKeys, label)
            XCTAssertEqual(clientQuery[kSecClass as String] as? String, kSecClassGenericPassword as String, label)
            XCTAssertEqual(clientQuery[kSecAttrService as String] as? String, service, label)
            XCTAssertEqual(clientQuery[kSecAttrAccessGroup as String] as? String, accessGroup, label)
            XCTAssertEqual(clientQuery[kSecUseDataProtectionKeychain as String] as? Bool, true, label)
            XCTAssertEqual(
                clientQuery[kSecAttrAccessible as String] as? String,
                kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String,
                label
            )
            XCTAssertNil(clientQuery[kSecAttrSynchronizable as String], label)
            XCTAssertNil(clientQuery[kSecAttrLabel as String], label)
            XCTAssertEqual(clientQuery[kSecAttrAccount as String] as? String, pluginAccount, label)
            XCTAssertEqual(clientQuery[kSecValueData as String] as? Data, payload, label)
        }
    }

    /// The client's `.default` sidecar and interrupted sign-in use the plugin's record's attributes.
    ///
    /// - Given: each of the plugin's services
    /// - When:
    ///    - the client's `.default` signs a user in, which adds its sidecar, and saves an interrupted sign-in; and the
    ///      plugin's credential store saves its record
    /// - Then:
    ///    - `$default.meta` and `$default.challenge` are added with the plugin's record's add query, but for their own
    ///      account and bytes: the same class, service, group, protection class, data-protection keychain, and no
    ///      synchronizable flag or label
    ///
    func testSidecarAndChallengeUseTheSameAttributes() throws {
        for (_, accessGroup) in services {
            let label = accessGroup ?? "no access group"
            let pluginWrites = KeychainCallLog()
            try makePluginStore(accessGroup: accessGroup, keychain: InMemoryKeychain(), log: pluginWrites)
                .saveCredential(LongLivedCredentials.userPoolAndIdentityPool())
            userDefaults.removePersistentDomain(forName: userDefaultsSuite)
            let pluginQuery = try XCTUnwrap(pluginWrites.addQueries(for: pluginAccount).first, label)

            let clientWrites = KeychainCallLog()
            let clientStore = makeClientStore(accessGroup: accessGroup, keychain: InMemoryKeychain(), log: clientWrites)
            let payload = try RollbackMatrixBytes.pluginPayload("userPoolAndIdentityPool")
            let record = SessionRecord(label: "Work", username: "alice", userId: "alice-sub", kind: .userPoolAndIdentityPool, credentials: payload)
            XCTAssertTrue(try clientStore.write(record, for: .default, expecting: nil).didCommit, label)
            try clientStore.writeChallenge(
                ChallengeRecord(createdAt: RollbackMatrixBytes.clientWriteTime, state: .totpSetup(ChallengeRecord.TOTPSetup(
                    secretCode: "secret",
                    session: "session",
                    username: "alice",
                    signInUsername: "alice",
                    signInMethod: .init(authFlow: "userSRP")
                ))),
                for: .default
            )

            for account in [SessionRecordKey.metaAccount(in: pools), clientStore.challengeAccount(for: .default)] {
                let query = try XCTUnwrap(clientWrites.addQueries(for: account).first, "\(label): \(account)")
                XCTAssertEqual(query[kSecAttrAccount as String] as? String, account, label)
                XCTAssertTrue(
                    NSDictionary(dictionary: Self.identity(of: query)).isEqual(to: Self.identity(of: pluginQuery)),
                    "\(label): \(account): \(query) vs \(pluginQuery)"
                )
            }
        }
    }

    /// The one difference (plan §1): the client's update keeps the item; the plugin's `set` re-creates it on macOS.
    ///
    /// - Given: the shared record, which the client's `.default` added
    /// - When:
    ///    - the client commits a refresh over it, then the plugin's credential store saves over it
    /// - Then:
    ///    - the client replaces it in place, everywhere: one `SecItemUpdate` of `kSecValueData` only, so no attribute
    ///      changes and the item is never absent
    ///    - the plugin `set`s it: on macOS a `SecItemDelete` then a `SecItemAdd` with the add query the item was
    ///      created with, so the attributes are again the same, but the item is absent in between (hence the client's re-read);
    ///      elsewhere the same in-place update as the client's
    ///
    func testClientUpdateKeepsAttributes_pluginMacOSSetRecreatesThem() throws {
        for (_, accessGroup) in services {
            let label = accessGroup ?? "no access group"
            let keychain = InMemoryKeychain()
            let clientWrites = KeychainCallLog()
            let clientStore = makeClientStore(accessGroup: accessGroup, keychain: keychain, log: clientWrites)
            let payload = try RollbackMatrixBytes.pluginPayload("userPoolAndIdentityPool")
            let record = SessionRecord(label: nil, username: "fixture-user", userId: "fixture-sub", kind: .userPoolAndIdentityPool, credentials: payload)
            guard case .committed(let added) = try clientStore.write(record, for: .default, expecting: nil) else {
                return XCTFail("\(label): the first write commits")
            }
            let created = try XCTUnwrap(clientWrites.addQueries(for: pluginAccount).first, label)

            var refreshed = record
            refreshed.credentials = try RollbackMatrixBytes.replacingRefreshToken(in: payload, with: "rotated-by-the-client")
            clientWrites.reset()
            XCTAssertTrue(try clientStore.write(refreshed, for: .default, expecting: added.version).didCommit, label)
            let clientUpdate = clientWrites.entries(for: pluginAccount)
            XCTAssertEqual(clientUpdate.map(\.method), ["replaceIfPresent"], label)
            guard case .update(let matching, let changed) = clientUpdate.first?.calls.first, clientUpdate.first?.calls.count == 1 else {
                return XCTFail("\(label): the client's update is one SecItemUpdate, got \(clientUpdate)")
            }
            XCTAssertEqual(matching[kSecAttrAccount as String] as? String, pluginAccount, label)
            XCTAssertEqual(Set(changed.keys), [kSecValueData as String], label)

            let pluginWrites = KeychainCallLog()
            try makePluginStore(accessGroup: accessGroup, keychain: keychain, log: pluginWrites)
                .saveCredential(LongLivedCredentials.userPoolAndIdentityPool())
            userDefaults.removePersistentDomain(forName: userDefaultsSuite)
            let pluginUpdate = pluginWrites.entries(for: pluginAccount)
            XCTAssertEqual(pluginUpdate.map(\.method), ["set"], label)
            let calls = try XCTUnwrap(pluginUpdate.first, label).calls
            #if os(macOS)
            guard calls.count == 2, case .delete = calls[0], case .add(let recreated) = calls[1] else {
                return XCTFail("\(label): the plugin's set deletes and adds on macOS, got \(calls)")
            }
            XCTAssertTrue(
                NSDictionary(dictionary: Self.identity(of: recreated)).isEqual(to: Self.identity(of: created)),
                "\(label): \(recreated) vs \(created)"
            )
            #else
            guard calls.count == 1, case .update(_, let pluginChanged) = calls[0] else {
                return XCTFail("\(label): the plugin's set updates in place here, got \(calls)")
            }
            XCTAssertEqual(Set(pluginChanged.keys), [kSecValueData as String], label)
            #endif
        }
    }

    // MARK: - Helpers

    /// The plugin's credential store for `accessGroup`, over `keychain`, recording the calls its item stores make.
    private func makePluginStore(accessGroup: String?, keychain: InMemoryKeychain, log: KeychainCallLog) -> AWSCognitoAuthCredentialStore {
        AWSCognitoAuthCredentialStore(
            authConfiguration: authConfiguration,
            accessGroup: accessGroup,
            migrateKeychainItemsOfUserSession: false,
            userDefaults: userDefaults,
            makeKeychainStore: { service, group in
                let pluginItemStore = EngineKeychainStore.makeItemStore(service: service, accessGroup: group, logger: AmplifyEngineLogRouter())
                return RecordingItemStore(attributes: pluginItemStore.attributes, keychain: keychain, log: log)
            },
            logger: AmplifyEngineLogRouter()
        )
    }

    /// The attributes of the client's real record store for `accessGroup`.
    private func clientAttributes(accessGroup: String?) throws -> KeychainItemAttributes {
        let namespace = SessionStorageNamespace(pools: pools, accessGroup: accessGroup)
        return try XCTUnwrap(SessionRecordStore(namespace: namespace).keychain as? KeychainItemStore).attributes
    }

    /// The client's record store for `accessGroup`, with its real attributes, over `keychain`, recording its calls.
    private func makeClientStore(accessGroup: String?, keychain: InMemoryKeychain, log: KeychainCallLog) -> SessionRecordStore {
        let attributes = (try? clientAttributes(accessGroup: accessGroup)) ?? KeychainItemAttributes(service: "missing")
        return SessionRecordStore(
            namespace: SessionStorageNamespace(pools: pools, accessGroup: accessGroup),
            keychain: RecordingItemStore(attributes: attributes, keychain: keychain, log: log),
            now: { RollbackMatrixBytes.clientWriteTime }
        )
    }

    /// An add query without the item's account and bytes: the attributes it gives the item.
    private static func identity(of query: [String: Any]) -> [String: Any] {
        query.filter { $0.key != kSecAttrAccount as String && $0.key != kSecValueData as String }
    }
}

/// One `SecItem` call, as `KeychainItemStore` makes it.
private enum SecItemCall {
    case add([String: Any])
    case update(query: [String: Any], attributes: [String: Any])
    case delete([String: Any])
}

/// The writes an item store made, by account: the `KeychainItemStoreBehavior` method, and the `SecItem` calls the
/// real `KeychainItemStore` makes for it with the same attributes.
private final class KeychainCallLog: @unchecked Sendable {
    // `@unchecked Sendable`: `recorded` is only touched while holding `lock`.
    private let lock = NSLock()
    private var recorded: [(account: String, entry: Entry)] = []

    /// One write: the `KeychainItemStoreBehavior` method, and its `SecItem` calls.
    struct Entry {
        let method: String
        let calls: [SecItemCall]
    }

    func record(_ method: String, account: String, calls: [SecItemCall]) {
        lock.withLock { recorded.append((account, Entry(method: method, calls: calls))) }
    }

    func reset() {
        lock.withLock { recorded.removeAll() }
    }

    func entries(for account: String) -> [Entry] {
        lock.withLock { recorded.filter { $0.account == account }.map(\.entry) }
    }

    /// Every `SecItemAdd` query for `account`.
    func addQueries(for account: String) -> [[String: Any]] {
        entries(for: account).flatMap(\.calls).compactMap { call in
            if case .add(let query) = call { return query }
            return nil
        }
    }
}

/// An item store over the in-memory keychain that records, for every write, the `SecItem` calls the real
/// `KeychainItemStore` with `attributes` makes (`InternalAmplifyKeychain/Sources/KeychainItemStore.swift`): an add
/// query for an item it creates, an update of the data alone for one it replaces, and, for `set` over an existing
/// item, a delete and an add on macOS and an update elsewhere.
private struct RecordingItemStore: KeychainItemStoreBehavior {
    let attributes: KeychainItemAttributes
    let base: InMemoryKeychainItemStore
    let log: KeychainCallLog

    init(attributes: KeychainItemAttributes, keychain: InMemoryKeychain, log: KeychainCallLog) {
        self.attributes = attributes
        self.base = keychain.store(service: attributes.service, accessGroup: attributes.accessGroup)
        self.log = log
    }

    func getData(_ key: String) throws -> Data {
        try base.getData(key)
    }

    func set(_ value: Data, key: String) throws {
        let calls: [SecItemCall]
        if try base.dataIfPresent(key) == nil {
            calls = [.add(attributes.addQuery(account: key, value: value))]
        } else {
            #if os(macOS)
            calls = [.delete(attributes.itemQuery(account: key)), .add(attributes.addQuery(account: key, value: value))]
            #else
            calls = [.update(query: attributes.itemQuery(account: key), attributes: attributes.updateAttributes(value: value))]
            #endif
        }
        log.record("set", account: key, calls: calls)
        try base.set(value, key: key)
    }

    func addIfAbsent(_ value: Data, key: String) throws -> Bool {
        let added = try base.addIfAbsent(value, key: key)
        if added {
            log.record("addIfAbsent", account: key, calls: [.add(attributes.addQuery(account: key, value: value))])
        }
        return added
    }

    func replaceIfPresent(_ value: Data, key: String) throws -> Bool {
        let replaced = try base.replaceIfPresent(value, key: key)
        if replaced {
            log.record(
                "replaceIfPresent",
                account: key,
                calls: [.update(query: attributes.itemQuery(account: key), attributes: attributes.updateAttributes(value: value))]
            )
        }
        return replaced
    }

    func move(_ key: String, to destination: KeychainItemAttributes) throws -> KeychainMoveOutcome {
        try base.move(key, to: destination)
    }

    func move(_ entry: KeychainEntry, to destination: KeychainItemAttributes) throws -> KeychainMoveOutcome {
        try base.move(entry, to: destination)
    }

    func remove(_ key: String) throws {
        try base.remove(key)
    }

    func remove(_ entry: KeychainEntry) throws {
        try base.remove(entry)
    }

    func removeAll() throws {
        try base.removeAll()
    }

    func hasItems() throws -> Bool {
        try base.hasItems()
    }

    func allAccounts() throws -> [String] {
        try base.allAccounts()
    }

    func allEntries() throws -> [KeychainEntry] {
        try base.allEntries()
    }
}
