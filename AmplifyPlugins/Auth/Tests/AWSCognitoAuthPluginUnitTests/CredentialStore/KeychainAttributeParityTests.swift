//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyFoundation
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
/// Each side builds its real item store's attributes (the client's `SessionRecordStore(namespace:)`, the plugin's
/// `EngineKeychainStore.makeItemStore(service:accessGroup:)` through its credential store's seam), and runs the real
/// `KeychainItemStore` with them over `SecItemKeychainDouble`, since `swift test` runs unsigned: the `SecItem` calls
/// recorded for each write are the ones `KeychainItemStore` makes.
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
            let pluginKeychain = SecItemKeychain()
            let pluginStore = makePluginStore(accessGroup: accessGroup, keychain: pluginKeychain, log: pluginWrites)
            try pluginStore.saveCredential(LongLivedCredentials.userPoolAndIdentityPool())
            userDefaults.removePersistentDomain(forName: userDefaultsSuite)
            // The plugin's bytes, so both sides add the same value: the encoder's key order is not fixed.
            let payload = try XCTUnwrap(pluginKeychain.value(service: service, accessGroup: accessGroup, account: pluginAccount), label)

            let clientWrites = KeychainCallLog()
            let clientStore = makeClientStore(accessGroup: accessGroup, keychain: SecItemKeychain(), log: clientWrites)
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
            try makePluginStore(accessGroup: accessGroup, keychain: SecItemKeychain(), log: pluginWrites)
                .saveCredential(LongLivedCredentials.userPoolAndIdentityPool())
            userDefaults.removePersistentDomain(forName: userDefaultsSuite)
            let pluginQuery = try XCTUnwrap(pluginWrites.addQueries(for: pluginAccount).first, label)

            let clientWrites = KeychainCallLog()
            let clientStore = makeClientStore(accessGroup: accessGroup, keychain: SecItemKeychain(), log: clientWrites)
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

    /// The one difference: the client's update keeps the item; the plugin's `set` re-creates it on macOS.
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
            let keychain = SecItemKeychain()
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
    private func makePluginStore(accessGroup: String?, keychain: SecItemKeychain, log: KeychainCallLog) -> AWSCognitoAuthCredentialStore {
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
    private func makeClientStore(accessGroup: String?, keychain: SecItemKeychain, log: KeychainCallLog) -> SessionRecordStore {
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

/// One `SecItem` call that changes an item, as `KeychainItemStore` makes it.
private enum SecItemCall {
    case add([String: Any])
    case update(query: [String: Any], attributes: [String: Any])
    case delete([String: Any])

    /// `request` if it changes an item; `nil` for a read.
    init?(_ request: SecItemKeychainDouble.Request) {
        switch request.call {
        case .add: self = .add(request.query)
        case .update: self = .update(query: request.query, attributes: request.attributesToUpdate ?? [:])
        case .delete: self = .delete(request.query)
        case .copyMatching: return nil
        }
    }
}

/// The writes an item store made, by account: the `KeychainItemStoreBehavior` method, and the `SecItem` calls the
/// real `KeychainItemStore` made for it.
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

/// A keychain made of one `SecItemKeychainDouble` per service and access group, as the real keychain keeps each
/// service's items apart.
private final class SecItemKeychain: @unchecked Sendable {
    // `@unchecked Sendable`: `doubles` is only touched while holding `lock`.
    private let lock = NSLock()
    private var doubles: [String: SecItemKeychainDouble] = [:]

    func double(service: String, accessGroup: String?) -> SecItemKeychainDouble {
        lock.withLock {
            let key = "\(service)|\(accessGroup ?? "")"
            if let double = doubles[key] {
                return double
            }
            let double = SecItemKeychainDouble()
            doubles[key] = double
            return double
        }
    }

    func value(service: String, accessGroup: String?, account: String) -> Data? {
        double(service: service, accessGroup: accessGroup).value(for: account)
    }
}

/// The real `KeychainItemStore` with `attributes`, over the keychain's double for its service, recording for every
/// write the method and the `SecItem` calls the store made for it.
private struct RecordingItemStore: KeychainItemStoreBehavior {
    let attributes: KeychainItemAttributes
    let store: KeychainItemStore
    let double: SecItemKeychainDouble
    let log: KeychainCallLog

    init(attributes: KeychainItemAttributes, keychain: SecItemKeychain, log: KeychainCallLog) {
        self.attributes = attributes
        self.double = keychain.double(service: attributes.service, accessGroup: attributes.accessGroup)
        self.store = KeychainItemStore(
            attributes: attributes,
            logger: AmplifyLogging.logger(for: KeychainItemStore.self),
            secItem: double.secItemCalls
        )
        self.log = log
    }

    /// Runs `body`, then records the `SecItem` writes it made, if any, under `method` and `key`.
    private func recording<T>(_ method: String, _ key: String, _ body: () throws -> T) rethrows -> T {
        let start = double.requests.count
        defer {
            let calls = double.requests.dropFirst(start).compactMap(SecItemCall.init)
            if !calls.isEmpty {
                log.record(method, account: key, calls: calls)
            }
        }
        return try body()
    }

    func getData(_ key: String) throws -> Data {
        try store.getData(key)
    }

    func set(_ value: Data, key: String) throws {
        try recording("set", key) { try store.set(value, key: key) }
    }

    func addIfAbsent(_ value: Data, key: String) throws -> Bool {
        try recording("addIfAbsent", key) { try store.addIfAbsent(value, key: key) }
    }

    func replaceIfPresent(_ value: Data, key: String) throws -> Bool {
        try recording("replaceIfPresent", key) { try store.replaceIfPresent(value, key: key) }
    }

    func move(_ key: String, to destination: KeychainItemAttributes) throws -> KeychainMoveOutcome {
        try store.move(key, to: destination)
    }

    func move(_ entry: KeychainEntry, to destination: KeychainItemAttributes) throws -> KeychainMoveOutcome {
        try store.move(entry, to: destination)
    }

    func remove(_ key: String) throws {
        try recording("remove", key) { try store.remove(key) }
    }

    func remove(_ entry: KeychainEntry) throws {
        try store.remove(entry)
    }

    func removeAll() throws {
        try store.removeAll()
    }

    func hasItems() throws -> Bool {
        try store.hasItems()
    }

    func allAccounts() throws -> [String] {
        try store.allAccounts()
    }

    func allEntries() throws -> [KeychainEntry] {
        try store.allEntries()
    }
}
