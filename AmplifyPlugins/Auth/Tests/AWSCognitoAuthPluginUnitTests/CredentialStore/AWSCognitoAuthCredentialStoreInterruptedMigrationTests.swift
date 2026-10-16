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
@testable import AWSCognitoAuthPlugin
import InternalAWSCognitoAuth

/// The access-group migration (`migrateKeychainItems: true`) moves the plugin's items one at a time, so an
/// app terminated part-way leaves some moved and the rest in the old service, with no access group
/// recorded. A `UserDefaults` mark set once the destination clear has finished, just before the first move,
/// and removed once the group is recorded, lets the next launch resume the migration instead of taking the
/// moved items as a finished one.
///
/// Runs over the in-memory fake through the credential store's test seam. A termination is modelled by
/// snapshotting the keychain and `UserDefaults` just before a move, stopping the migration there, and
/// putting both snapshots back once the store is built: the state an app killed at that point leaves.
class AWSCognitoAuthCredentialStoreInterruptedMigrationTests: XCTestCase {

    private let service = "com.amplify.awsCognitoAuthPlugin"
    private let sharedService = "com.amplify.awsCognitoAuthPluginShared"
    private let accessGroup = "group"
    private let username = "Alice@Example.com"
    private let accessGroupKey = "amplify_secure_storage_scopes.awsCognitoAuthPlugin.accessGroup"
    private let migrationInProgressKey = "amplify_secure_storage_scopes.awsCognitoAuthPlugin.accessGroupMigrationInProgress"

    private let authConfiguration = AuthConfiguration.userPoolsAndIdentityPools(
        UserPoolConfigurationData(poolId: "us-east-1_Pool", clientId: "client", region: "us-east-1"),
        IdentityPoolConfigurationData(poolId: "us-east-1:identity-pool", region: "us-east-1")
    )

    private var keychain: InMemoryKeychain!
    private var userDefaults: UserDefaults!
    private var userDefaultsSuite: String!

    override func setUp() {
        super.setUp()
        keychain = InMemoryKeychain()
        userDefaultsSuite = "AWSCognitoAuthCredentialStoreInterruptedMigrationTests.\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: userDefaultsSuite)
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: userDefaultsSuite)
        keychain = nil
        userDefaults = nil
        super.tearDown()
    }

    /// A migration the app was killed in after its first move finishes on the next launch.
    ///
    /// - Given: a signed-in plugin without an access group, whose first launch with the access group and
    ///   migration is killed just before its second move
    /// - When:
    ///    - the app launches again with the same access group and migration
    /// - Then:
    ///    - at the kill, the mark names the access group, no access group is recorded, and the shared
    ///      service holds only the first item moved
    ///    - after the relaunch, every plugin item is in the shared service and none is in the unshared one
    ///    - the user's session reads back unchanged
    ///    - the access group is recorded and the mark is gone
    func testAMigrationKilledAfterTheFirstMoveResumesOnTheNextLaunch() throws {
        let pluginAccounts = try populateUnsharedServiceAsAPluginWould()
        let session = try makeStore(accessGroup: nil).retrieveCredential()

        try killFirstMigration(beforeMove: 2)

        XCTAssertEqual(userDefaults.string(forKey: migrationInProgressKey), accessGroup)
        XCTAssertNil(userDefaults.string(forKey: accessGroupKey))
        XCTAssertEqual(
            try keychain.store(service: sharedService, accessGroup: accessGroup).allAccounts(),
            [pluginAccounts.sorted()[0]]
        )

        let relaunched = makeStore(accessGroup: accessGroup, migrate: true)

        XCTAssertEqual(try keychain.store(service: service).allAccounts(), [])
        XCTAssertEqual(
            try keychain.store(service: sharedService, accessGroup: accessGroup).allAccounts(),
            pluginAccounts.sorted()
        )
        XCTAssertEqual(try relaunched.retrieveCredential(), session)
        XCTAssertEqual(userDefaults.string(forKey: accessGroupKey), accessGroup)
        XCTAssertNil(userDefaults.object(forKey: migrationInProgressKey))
    }

    /// A migration the app was killed in during its destination clear runs from the start on the next
    /// launch: the mark is only set once the clear has finished, so that launch clears again, and a stale
    /// item the first clear hadn't reached doesn't win over the item the migration moves.
    ///
    /// - Given: a signed-in plugin with the access group, and an older session and device record left in
    ///   the unshared service; its first launch without the access group, with migration, is killed during
    ///   the clear of the unshared service, just before it removes the stale session
    /// - When:
    ///    - the app launches again without the access group, with migration
    /// - Then:
    ///    - at the kill, no mark is set, the access group is still recorded, and the stale session is still
    ///      in the unshared service
    ///    - after the relaunch, the user's session reads back as the one in the shared service, not the
    ///      stale one
    ///    - every plugin item is under the unshared service with the shared service's bytes, the stale
    ///      session is gone, and the shared service is empty
    ///    - no access group is recorded and the mark is gone
    func testAMigrationKilledDuringTheDestinationClearRunsFromTheStartOnTheNextLaunch() throws {
        // A store without an access group sees items in every group, as on iOS, so the moved items, which
        // keep the shared group, are found from the unshared service.
        keychain = InMemoryKeychain(unscopedMatching: .everyGroup)
        let sessionAccount = "amplify.us-east-1_Pool.us-east-1:identity-pool.session"
        let unshared = keychain.store(service: service)

        // What an earlier plugin without the access group left in the unshared service.
        let staleStore = makeStore(accessGroup: nil)
        try staleStore.saveCredential(.testDataWithExpiredTokens)
        try staleStore.saveDevice(
            .metadata(.init(deviceKey: "stale-device", deviceGroupKey: "group", deviceSecret: "secret")),
            for: username
        )
        let staleItems = try unshared.allAccounts().map { account in
            (account, try XCTUnwrap(keychain.value(service: service, account: account)))
        }
        XCTAssertTrue(staleItems.contains { $0.0 == sessionAccount })

        // The signed-in plugin with the access group. Its first configuration clears the unshared service,
        // so the stale items are put back after it.
        let sharedStore = makeStore(accessGroup: accessGroup)
        try sharedStore.saveCredential(.testData)
        try sharedStore.saveDevice(
            .metadata(.init(deviceKey: "device", deviceGroupKey: "group", deviceSecret: "secret")),
            for: username
        )
        try sharedStore.saveASFDevice("asf-device", for: username)
        let session = try sharedStore.retrieveCredential()
        let sharedAccounts = try keychain.store(service: sharedService, accessGroup: accessGroup).allAccounts()
        let sharedValues = sharedAccounts.map { keychain.value(service: sharedService, accessGroup: accessGroup, account: $0) }
        for (account, value) in staleItems {
            try unshared.set(value, key: account)
        }

        let killPoint = KillPoint(keychain: keychain, userDefaults: userDefaults, suite: userDefaultsSuite)
        let unsharedService = service
        keychain.beforeRemove { removedFrom, account in
            if removedFrom == unsharedService, account == sessionAccount {
                killPoint.capture()
            }
        }
        _ = makeStore(accessGroup: nil, migrate: true)
        keychain.beforeRemove(nil)
        try killPoint.restore()

        XCTAssertNil(userDefaults.object(forKey: migrationInProgressKey))
        XCTAssertEqual(userDefaults.string(forKey: accessGroupKey), accessGroup)
        XCTAssertNotNil(keychain.value(service: service, account: sessionAccount))

        let relaunched = makeStore(accessGroup: nil, migrate: true)

        XCTAssertEqual(try relaunched.retrieveCredential(), session)
        XCTAssertEqual(try keychain.store(service: sharedService, accessGroup: accessGroup).allAccounts(), [])
        XCTAssertNil(keychain.value(service: service, account: sessionAccount))
        for (account, value) in zip(sharedAccounts, sharedValues) {
            XCTAssertEqual(keychain.value(service: service, accessGroup: accessGroup, account: account), value, account)
        }
        XCTAssertNil(userDefaults.string(forKey: accessGroupKey))
        XCTAssertNil(userDefaults.object(forKey: migrationInProgressKey))
    }

    /// A resumed migration keeps the items already moved: it never runs the destination clear.
    ///
    /// - Given: the state a first migration killed after its first move leaves
    /// - When:
    ///    - the app launches again with the same access group and migration
    /// - Then:
    ///    - nothing in the shared service is removed, and the item moved before the kill keeps its bytes
    func testAResumedMigrationDoesNotClearTheDestination() throws {
        let pluginAccounts = try populateUnsharedServiceAsAPluginWould()
        let firstMoved = pluginAccounts.sorted()[0]
        let firstMovedValue = keychain.value(service: service, account: firstMoved)
        try killFirstMigration(beforeMove: 2)
        keychain.resetMutations()

        _ = makeStore(accessGroup: accessGroup, migrate: true)

        let sharedRemovals = keychain.mutations.filter { mutation in
            switch mutation {
            case .remove(let removedFrom, _), .removeAll(let removedFrom):
                return removedFrom == sharedService
            case .write, .move:
                return false
            }
        }
        XCTAssertEqual(sharedRemovals, [])
        XCTAssertEqual(keychain.value(service: sharedService, accessGroup: accessGroup, account: firstMoved), firstMovedValue)
    }

    /// A migration that completes leaves no mark behind, and the mark is set while it moves.
    ///
    /// - Given: a signed-in plugin without an access group
    /// - When:
    ///    - it is configured with the access group and migration, and finishes
    /// - Then:
    ///    - during every move the mark names the access group
    ///    - afterwards the mark is gone and the access group is recorded
    func testACompletedMigrationLeavesNoMark() throws {
        let pluginAccounts = try populateUnsharedServiceAsAPluginWould()
        let recorder = MoveRecorder(userDefaults: userDefaults, key: migrationInProgressKey)
        keychain.beforeMove { _ in recorder.record() }

        _ = makeStore(accessGroup: accessGroup, migrate: true)

        XCTAssertEqual(recorder.marks, Array(repeating: Optional(accessGroup), count: pluginAccounts.count))
        XCTAssertNil(userDefaults.object(forKey: migrationInProgressKey))
        XCTAssertEqual(userDefaults.string(forKey: accessGroupKey), accessGroup)
    }

    /// Without the mark, an app extension's first launch after the app migrated still skips the migration.
    ///
    /// - Given: a shared service holding the session the app migrated, and an extension whose own
    ///   `UserDefaults` hold no access group and no mark, with its own items in the unshared service
    /// - When:
    ///    - the extension is configured with the access group and migration
    /// - Then:
    ///    - nothing moves: the extension's items stay in the unshared service, and the app's session in the
    ///      shared service is unchanged
    ///    - no mark is left behind
    func testAnAppExtensionWithoutTheMarkStillSkipsTheMigration() throws {
        let pluginAccounts = try populateUnsharedServiceAsAPluginWould()
        let sessionAccount = "amplify.us-east-1_Pool.us-east-1:identity-pool.session"
        let appsSession = Data("the app's migrated session".utf8)
        try keychain.store(service: sharedService, accessGroup: accessGroup).set(appsSession, key: sessionAccount)
        userDefaults.removePersistentDomain(forName: userDefaultsSuite)
        keychain.resetMutations()

        _ = makeStore(accessGroup: accessGroup, migrate: true)

        XCTAssertFalse(keychain.mutations.contains { mutation in
            if case .move = mutation { return true }
            return false
        })
        XCTAssertEqual(try keychain.store(service: service).allAccounts(), pluginAccounts.sorted())
        XCTAssertEqual(keychain.value(service: sharedService, accessGroup: accessGroup, account: sessionAccount), appsSession)
        XCTAssertNil(userDefaults.object(forKey: migrationInProgressKey))
    }

    /// A mark left for another access group does not make this migration resume.
    ///
    /// - Given: a mark naming `other-group`, no access group recorded, and a shared service under `group`
    ///   that already holds a plugin session
    /// - When:
    ///    - the plugin is configured with `group` and migration
    /// - Then:
    ///    - the migration is skipped as before, and the mark is removed once the group is recorded
    func testAMarkForAnotherAccessGroupDoesNotResume() throws {
        let pluginAccounts = try populateUnsharedServiceAsAPluginWould()
        try keychain.store(service: sharedService, accessGroup: accessGroup)
            .set(Data("session".utf8), key: "amplify.us-east-1_Pool.us-east-1:identity-pool.session")
        userDefaults.set("other-group", forKey: migrationInProgressKey)

        _ = makeStore(accessGroup: accessGroup, migrate: true)

        XCTAssertEqual(try keychain.store(service: service).allAccounts(), pluginAccounts.sorted())
        XCTAssertNil(userDefaults.object(forKey: migrationInProgressKey))
    }

    // MARK: Helpers

    /// Runs the first launch with the access group and migration, killed just before move number `move`
    /// (1-based): the keychain and `UserDefaults` are put back as they were at that moment.
    private func killFirstMigration(beforeMove move: Int) throws {
        let killPoint = KillPoint(keychain: keychain, userDefaults: userDefaults, suite: userDefaultsSuite, atMove: move)
        keychain.beforeMove { account in killPoint.moveStarting(account) }
        let accountAtKill = try keychain.store(service: service).allAccounts()[move - 1]
        // Stops the loop there; everything the store does after it is undone by the restore below.
        keychain.failing(.move, with: errSecIO, forAccount: accountAtKill)

        _ = makeStore(accessGroup: accessGroup, migrate: true)

        keychain.beforeMove(nil)
        keychain.clearFailures()
        try killPoint.restore()
    }

    private func makeStore(accessGroup: String?, migrate: Bool = false) -> AWSCognitoAuthCredentialStore {
        let keychain = keychain!
        return AWSCognitoAuthCredentialStore(
            authConfiguration: authConfiguration,
            accessGroup: accessGroup,
            migrateKeychainItemsOfUserSession: migrate,
            userDefaults: userDefaults,
            makeKeychainStore: { service, accessGroup in
                keychain.store(service: service, accessGroup: accessGroup)
            },
            logger: AmplifyEngineLogRouter()
        )
    }

    /// Configures a plugin without an access group and stores a session, device metadata and an ASF
    /// device ID. Returns every account it wrote.
    private func populateUnsharedServiceAsAPluginWould() throws -> [String] {
        let store = makeStore(accessGroup: nil)
        try store.saveCredential(.testData)
        try store.saveDevice(
            .metadata(.init(deviceKey: "device", deviceGroupKey: "group", deviceSecret: "secret")),
            for: username
        )
        try store.saveASFDevice("asf-device", for: username)
        let accounts = [
            "authConfiguration",
            "amplify.us-east-1_Pool.us-east-1:identity-pool.session",
            store.generateDeviceMetadataKey(for: username),
            store.generateASFDeviceKey(for: username)
        ]
        XCTAssertEqual(try keychain.store(service: service).allAccounts(), accounts.sorted())
        return accounts
    }
}

/// Snapshots the keychain and `UserDefaults` just before one move (or wherever `capture()` is called), and
/// puts both back on `restore()`.
private final class KillPoint: @unchecked Sendable {
    // `@unchecked Sendable`: the mutable state is only touched while holding `lock`.
    private let lock = NSLock()
    private let keychain: InMemoryKeychain
    private let userDefaults: UserDefaults
    private let suite: String
    private let atMove: Int?
    private var moves = 0
    private var keychainAtKill: InMemoryKeychain.Snapshot?
    private var userDefaultsAtKill: [String: Any]?

    init(keychain: InMemoryKeychain, userDefaults: UserDefaults, suite: String, atMove: Int? = nil) {
        self.keychain = keychain
        self.userDefaults = userDefaults
        self.suite = suite
        self.atMove = atMove
    }

    func moveStarting(_ account: String) {
        lock.lock()
        defer { lock.unlock() }
        moves += 1
        guard moves == atMove else { return }
        snapshotOnce()
    }

    /// Snapshots now, unless a snapshot was already taken.
    func capture() {
        lock.lock()
        defer { lock.unlock() }
        snapshotOnce()
    }

    /// Must be called while holding `lock`.
    private func snapshotOnce() {
        guard keychainAtKill == nil else { return }
        keychainAtKill = keychain.snapshot()
        userDefaultsAtKill = userDefaults.persistentDomain(forName: suite) ?? [:]
    }

    func restore() throws {
        lock.lock()
        defer { lock.unlock() }
        keychain.restore(try XCTUnwrap(keychainAtKill, "the migration never reached the kill point"))
        userDefaults.setPersistentDomain(try XCTUnwrap(userDefaultsAtKill), forName: suite)
    }
}

/// Records the mark's value at each move.
private final class MoveRecorder: @unchecked Sendable {
    // `@unchecked Sendable`: `recorded` is only touched while holding `lock`.
    private let lock = NSLock()
    private let userDefaults: UserDefaults
    private let key: String
    private var recorded: [String?] = []

    init(userDefaults: UserDefaults, key: String) {
        self.userDefaults = userDefaults
        self.key = key
    }

    var marks: [String?] {
        lock.lock()
        defer { lock.unlock() }
        return recorded
    }

    func record() {
        lock.lock()
        defer { lock.unlock() }
        recorded.append(userDefaults.string(forKey: key))
    }
}
