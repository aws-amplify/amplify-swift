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
@_spi(KeychainStore) import AWSPluginsCore
@testable import AWSCognitoAuthPlugin
import InternalAWSCognitoAuth

/// When the plugin is first configured with an access group, it either clears its unshared keychain
/// service or migrates it into the shared one. Standalone clients store their `amplify.<digits>.` session
/// records in those same services, so both must touch only the plugin's own items, and a client record
/// must not count as a plugin item when deciding whether to do either.
///
/// Runs over the in-memory fake through the credential store's test seam: `swift test` runs unsigned,
/// so the real keychain is unavailable.
class AWSCognitoAuthCredentialStoreWipeTests: XCTestCase {

    private let service = "com.amplify.awsCognitoAuthPlugin"
    private let sharedService = "com.amplify.awsCognitoAuthPluginShared"
    private let accessGroup = "group"
    private let username = "Alice@Example.com"

    private let authConfiguration = AuthConfiguration.userPoolsAndIdentityPools(
        UserPoolConfigurationData(poolId: "us-east-1_Pool", clientId: "client", region: "us-east-1"),
        IdentityPoolConfigurationData(poolId: "us-east-1:identity-pool", region: "us-east-1")
    )

    /// Session records a standalone client keeps in the plugin's unshared service.
    private let sessionRecordAccounts = [
        "amplify.1.us-east-1_Pool.us-east-1:identity-pool.work.session",
        "amplify.1.us-east-1_Pool.us-east-1:identity-pool.work.challenge",
        "amplify.1.us-east-1_Pool.us-east-1:identity-pool.$default.session",
        // A newer client's schema: a released plugin must spare it too.
        "amplify.2.us-east-1_Pool.us-east-1:identity-pool.work.session"
    ]

    /// A session record the plugin retained under an earlier configuration's namespace.
    private let retainedSessionAccount = "amplify.us-east-1_Pool.session"

    private var keychain: InMemoryKeychain!
    private var userDefaults: UserDefaults!
    private var userDefaultsSuite: String!

    override func setUp() {
        super.setUp()
        keychain = InMemoryKeychain()
        userDefaultsSuite = "AWSCognitoAuthCredentialStoreWipeTests.\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: userDefaultsSuite)
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: userDefaultsSuite)
        keychain = nil
        userDefaults = nil
        super.tearDown()
    }

    /// The access-group transition removes every plugin item and keeps the client's session records.
    ///
    /// - Given: an app whose plugin, configured without an access group, has stored its configuration,
    ///   session, device metadata, ASF device ID and a session retained from an earlier configuration,
    ///   and in whose unshared service a standalone client has stored session and challenge records
    /// - When:
    ///    - the plugin is configured with an access group for the first time, without migration, and the
    ///      shared service is empty
    /// - Then:
    ///    - every plugin item in the unshared service is gone
    ///    - every client session record is still there, unchanged
    func testAccessGroupTransitionRemovesPluginItemsAndSparesSessionRecords() throws {
        let pluginAccounts = try populateUnsharedServiceAsAPluginWould()
        try writeSessionRecords()

        _ = makeStore(accessGroup: accessGroup)

        for account in pluginAccounts {
            XCTAssertNil(keychain.value(service: service, account: account), "\(account) should be removed")
        }
        XCTAssertEqual(try keychain.store(service: service).allAccounts(), sessionRecordAccounts.sorted())
        for account in sessionRecordAccounts {
            XCTAssertEqual(keychain.value(service: service, account: account), Data(account.utf8))
        }
    }

    /// If the unshared service cannot be listed, the transition removes nothing at all.
    ///
    /// - Given: the same unshared service, holding plugin items and client session records, whose
    ///   listing fails as a locked device's does
    /// - When:
    ///    - the plugin is configured with an access group for the first time, without migration
    /// - Then:
    ///    - nothing in the unshared service is removed, plugin items included: stale plugin items are
    ///      safe to leave, and a service-wide fall-back would delete the client's sessions
    func testAccessGroupTransitionRemovesNothingWhenListingFails() throws {
        let pluginAccounts = try populateUnsharedServiceAsAPluginWould()
        try writeSessionRecords()
        keychain.resetMutations()
        keychain.failing(.listAccounts, with: errSecInteractionNotAllowed)

        _ = makeStore(accessGroup: accessGroup)

        for account in pluginAccounts + sessionRecordAccounts {
            XCTAssertNotNil(keychain.value(service: service, account: account), "\(account) should be kept")
        }
        let unsharedRemovals = keychain.mutations.filter { mutation in
            switch mutation {
            case .remove(let removedFrom, _), .removeAll(let removedFrom):
                return removedFrom == service
            case .write, .move:
                return false
            }
        }
        XCTAssertEqual(unsharedRemovals, [])
    }

    /// With no client session records, the transition leaves the unshared service empty, as it always
    /// has.
    ///
    /// - Given: an unshared service holding only the plugin's items, plus one item the plugin does not
    ///   write today
    /// - When:
    ///    - the plugin is configured with an access group for the first time, without migration
    /// - Then:
    ///    - the unshared service is empty, exactly as after the service-wide clear it replaces
    ///    - the new configuration is stored in the shared service
    func testAccessGroupTransitionWithoutSessionRecordsEmptiesTheUnsharedService() throws {
        _ = try populateUnsharedServiceAsAPluginWould()
        try keychain.store(service: service).set(Data("x".utf8), key: "some.unrecognised.item")

        _ = makeStore(accessGroup: accessGroup)

        XCTAssertEqual(try keychain.store(service: service).allAccounts(), [])
        XCTAssertNotNil(keychain.value(service: sharedService, accessGroup: accessGroup, account: "authConfiguration"))
    }

    // MARK: Migration (`migrateKeychainItems: true`)

    /// The migration moves every plugin item into the shared service, with its data.
    ///
    /// - Given: an unshared service holding every plugin item
    /// - When:
    ///    - the plugin is configured with an access group for the first time, with migration
    /// - Then:
    ///    - every plugin item is in the shared service under the access group, with its bytes unchanged
    ///    - the unshared service is empty
    func testMigrationMovesPluginItemsToTheSharedService() throws {
        let pluginAccounts = try populateUnsharedServiceAsAPluginWould()
        let before = Dictionary(uniqueKeysWithValues: pluginAccounts.map { ($0, keychain.value(service: service, account: $0)) })

        _ = makeStore(accessGroup: accessGroup, migrate: true)

        XCTAssertEqual(try keychain.store(service: service).allAccounts(), [])
        XCTAssertEqual(
            try keychain.store(service: sharedService, accessGroup: accessGroup).allAccounts(),
            pluginAccounts.sorted()
        )
        // `authConfiguration` is rewritten after the migration, so only the other items' bytes are compared.
        for account in pluginAccounts where account != "authConfiguration" {
            XCTAssertEqual(keychain.value(service: sharedService, accessGroup: accessGroup, account: account), before[account] ?? nil, account)
        }
    }

    /// A session record stored in two access groups still reaches the shared service, so the user stays
    /// signed in.
    ///
    /// On iOS 26.5 an unscoped per-account move of such an account moves neither copy (measured on a real
    /// keychain). The migration now moves each listed copy on its own: the first moves, and
    /// the second collides and stays behind.
    ///
    /// - Given: with the fake matching every group for unscoped queries, as a device does, an unshared
    ///   service holding every plugin item, plus a second copy of the session record under `group-x`
    /// - When:
    ///    - the plugin is configured with an access group for the first time, with migration
    /// - Then:
    ///    - the shared service holds every plugin item, the session record being the ungrouped copy
    ///    - the unshared service keeps only the `group-x` copy of the session record
    func testMigrationMovesASessionStoredInTwoGroups() throws {
        keychain = InMemoryKeychain(unscopedMatching: .everyGroup)
        let pluginAccounts = try populateUnsharedServiceAsAPluginWould()
        let sessionAccount = "amplify.us-east-1_Pool.us-east-1:identity-pool.session"
        let session = keychain.value(service: service, account: sessionAccount)
        try keychain.store(service: service, accessGroup: "group-x").set(Data("group-x".utf8), key: sessionAccount)

        _ = makeStore(accessGroup: accessGroup, migrate: true)

        XCTAssertEqual(
            try keychain.store(service: sharedService, accessGroup: accessGroup).allAccounts(),
            pluginAccounts.sorted()
        )
        XCTAssertEqual(keychain.value(service: sharedService, accessGroup: accessGroup, account: sessionAccount), session)
        XCTAssertEqual(try keychain.store(service: service).allEntries(), [KeychainEntry(account: sessionAccount, accessGroup: "group-x")])
    }

    /// After the access group is removed, the moved session is still found, as on iOS.
    ///
    /// The `accessGroupRemoved` path: a group, then no group, both with migration. A move to a
    /// group-less destination keeps each item's own group, so the session lands in (unshared service,
    /// `group`). On the iOS 26.5 simulator a group-less read still finds it (the client host app's IO-4,
    /// `AccessGroupRemovalRealKeychainTests`), which `.everyGroup` mode now models. The default
    /// `.exactGroup` mode does not, which is why the locked `accessGroupRemoved` baseline ends in
    /// `itemNotFound`.
    ///
    /// - Given: with the fake matching every group for unscoped queries, a plugin's items migrated into
    ///   the shared service under `group`
    /// - When:
    ///    - the plugin is configured again without an access group, with migration
    /// - Then:
    ///    - the session record is in the unshared service, still under `group`, and not in the shared
    ///      service
    ///    - the new store retrieves the same credentials
    func testAccessGroupRemovedStillFindsTheMovedSession() throws {
        keychain = InMemoryKeychain(unscopedMatching: .everyGroup)
        _ = try populateUnsharedServiceAsAPluginWould()
        let sessionAccount = "amplify.us-east-1_Pool.us-east-1:identity-pool.session"
        // Compared with what the grouped store reads back, not `.testData`, whose dates do not survive
        // an encode and decode exactly.
        let expected = try makeStore(accessGroup: accessGroup, migrate: true).retrieveCredential()
        let session = keychain.value(service: sharedService, accessGroup: accessGroup, account: sessionAccount)
        XCTAssertNotNil(session)

        let store = makeStore(accessGroup: nil, migrate: true)

        XCTAssertEqual(keychain.value(service: service, accessGroup: accessGroup, account: sessionAccount), session)
        XCTAssertNil(keychain.value(service: service, account: sessionAccount))
        XCTAssertEqual(try keychain.store(service: sharedService, accessGroup: accessGroup).allAccounts(), [])
        XCTAssertEqual(try store.retrieveCredential(), expected)
    }

    /// The migration leaves the client's session records in the unshared service.
    ///
    /// - Given: an unshared service holding every plugin item and client session records
    /// - When:
    ///    - the plugin is configured with an access group for the first time, with migration
    /// - Then:
    ///    - the shared service holds exactly the plugin items
    ///    - the unshared service holds exactly the client records, unchanged
    func testMigrationLeavesClientRecordsInTheUnsharedService() throws {
        let pluginAccounts = try populateUnsharedServiceAsAPluginWould()
        try writeSessionRecords()

        _ = makeStore(accessGroup: accessGroup, migrate: true)

        XCTAssertEqual(
            try keychain.store(service: sharedService, accessGroup: accessGroup).allAccounts(),
            pluginAccounts.sorted()
        )
        XCTAssertEqual(try keychain.store(service: service).allAccounts(), sessionRecordAccounts.sorted())
        for account in sessionRecordAccounts {
            XCTAssertEqual(keychain.value(service: service, account: account), Data(account.utf8))
        }
    }

    // MARK: Whether the shared service "already has items"

    /// A client record in the shared service does not make the plugin skip its migration.
    ///
    /// - Given: an unshared service holding every plugin item, and a shared service holding only a
    ///   client session record
    /// - When:
    ///    - the plugin is configured with an access group for the first time, with migration
    /// - Then:
    ///    - the plugin items are migrated into the shared service
    ///    - the shared client record is untouched
    func testClientRecordInSharedServiceDoesNotSkipMigration() throws {
        let pluginAccounts = try populateUnsharedServiceAsAPluginWould()
        let sharedClientAccount = "amplify.1.us-east-1_Pool.us-east-1:identity-pool.shared.session"
        try keychain.store(service: sharedService, accessGroup: accessGroup).set(Data("client".utf8), key: sharedClientAccount)

        _ = makeStore(accessGroup: accessGroup, migrate: true)

        XCTAssertEqual(try keychain.store(service: service).allAccounts(), [])
        XCTAssertEqual(
            try keychain.store(service: sharedService, accessGroup: accessGroup).allAccounts(),
            (pluginAccounts + [sharedClientAccount]).sorted()
        )
        XCTAssertEqual(keychain.value(service: sharedService, accessGroup: accessGroup, account: sharedClientAccount), Data("client".utf8))
    }

    /// A client record in the shared service does not make the plugin skip its clear.
    ///
    /// - Given: an unshared service holding every plugin item, and a shared service holding only a
    ///   client session record
    /// - When:
    ///    - the plugin is configured with an access group for the first time, without migration
    /// - Then:
    ///    - the unshared plugin items are removed
    ///    - the shared client record is untouched
    func testClientRecordInSharedServiceDoesNotSkipTheClear() throws {
        _ = try populateUnsharedServiceAsAPluginWould()
        let sharedClientAccount = "amplify.1.us-east-1_Pool.us-east-1:identity-pool.shared.session"
        try keychain.store(service: sharedService, accessGroup: accessGroup).set(Data("client".utf8), key: sharedClientAccount)

        _ = makeStore(accessGroup: accessGroup)

        XCTAssertEqual(try keychain.store(service: service).allAccounts(), [])
        XCTAssertEqual(keychain.value(service: sharedService, accessGroup: accessGroup, account: sharedClientAccount), Data("client".utf8))
    }

    /// A plugin item in the shared service still means "already migrated", as it always has.
    ///
    /// - Given: an unshared service holding every plugin item, and a shared service already holding the
    ///   plugin's configuration record (another process, such as the main app, migrated first)
    /// - When:
    ///    - an app extension configures the plugin with the access group, with migration
    /// - Then:
    ///    - nothing is moved out of the unshared service
    func testPluginItemInSharedServiceStillSkipsMigration() throws {
        let pluginAccounts = try populateUnsharedServiceAsAPluginWould()
        try keychain.store(service: sharedService, accessGroup: accessGroup).set(Data("config".utf8), key: "authConfiguration")

        _ = makeStore(accessGroup: accessGroup, migrate: true)

        XCTAssertEqual(try keychain.store(service: service).allAccounts(), pluginAccounts.sorted())
    }

    // MARK: Helpers

    private func makeStore(accessGroup: String?, migrate: Bool = false) -> AWSCognitoAuthCredentialStore {
        let keychain = keychain!
        return AWSCognitoAuthCredentialStore(
            authConfiguration: authConfiguration,
            accessGroup: accessGroup,
            migrateKeychainItemsOfUserSession: migrate,
            userDefaults: userDefaults,
            makeKeychainStore: { service, accessGroup in
                keychain.store(service: service, accessGroup: accessGroup)
            }
        )
    }

    /// Configures a plugin without an access group and stores everything it stores, through its own
    /// methods. Returns every account it wrote.
    private func populateUnsharedServiceAsAPluginWould() throws -> [String] {
        let store = makeStore(accessGroup: nil)
        try store.saveCredential(.testData)
        try store.saveDevice(
            .metadata(.init(deviceKey: "device", deviceGroupKey: "group", deviceSecret: "secret")),
            for: username
        )
        try store.saveASFDevice("asf-device", for: username)
        try keychain.store(service: service).set(Data("retained".utf8), key: retainedSessionAccount)

        let accounts = [
            "authConfiguration",
            "amplify.us-east-1_Pool.us-east-1:identity-pool.session",
            store.generateDeviceMetadataKey(for: username),
            store.generateASFDeviceKey(for: username),
            retainedSessionAccount
        ]
        XCTAssertEqual(try keychain.store(service: service).allAccounts(), accounts.sorted())
        return accounts
    }

    private func writeSessionRecords() throws {
        let store = keychain.store(service: service)
        for account in sessionRecordAccounts {
            try store.set(Data(account.utf8), key: account)
        }
    }
}
