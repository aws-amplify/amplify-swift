//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyKeychainTestCommon
import AWSCognitoIdentity
import AWSCognitoIdentityProvider
import Foundation
import InternalAmplifyKeychain
import XCTest
@testable import Amplify
@_spi(KeychainStore) @testable import AWSPluginsCore
@testable import AWSCognitoAuthPlugin
@testable import InternalAWSCognitoAuth

/// The keychain query-parity gate, recorded before the credential store moved into the engine.
///
/// Every scenario runs the plugin's real credential store (`AWSCognitoAuthCredentialStore`, through its
/// `makeKeychainStore` seam) and the real legacy AWSMobileClient migration (through
/// `legacyKeychainStoreFactory`) over the in-memory keychain, and records each query they issue as
/// `<origin> | <operation> | <service> | <access group> | <key> -> <outcome>` (see
/// `KeychainQueryRecorder`). The sequences are compared with `GoldenKeychainQueries/queries.json`,
/// in order and count-sensitively.
///
/// A drift here means a stored item moved: a changed service, access group or key orphans every
/// session stored under the old one. The credential store over `KeychainItemStore`, and the storage code
/// in the engine, must reproduce the baseline exactly.
///
/// Scenarios run through the plugin's own paths where it matters: the whole plugin for configure,
/// sign-in, refresh, sign-out and delete user (only the Cognito service calls are mocked), and the
/// credential-store state machine for the rest.
///
/// - Note: `@unchecked Sendable` so the test body can be captured by the `@Sendable` closures the
///   production API takes. `XCTestCase` is not `Sendable`, and each test runs alone.
final class KeychainQueryParityTests: XCTestCase, @unchecked Sendable {

    /// SHA-256 of `queries.json`. Regenerating the baseline changes it, so a regeneration also has to
    /// edit this line, in review.
    static let pinnedBaselineSHA256 = "a15ab080c3d381328cb42a98b0366daeb5eac8755e1e4fba2cf8a73701464fe6"

    static var baselineURL: URL {
        GoldenFiles.directory("GoldenKeychainQueries").appendingPathComponent("queries.json")
    }

    struct Baseline: Codable, Equatable {
        struct Scenario: Codable, Equatable {
            let name: String
            let summary: String
            let queries: [String]
        }

        let note: String
        let format: String
        let bundlePlaceholder: String
        let scenarios: [Scenario]
    }

    static let note = "Recorded at M2 step S4q over the in-memory keychain. S4 and S8c must reproduce it exactly. Never regenerate."
    static let format = "<origin: store | legacy> | <operation> | <service> | <access group or -> | <key or -> -> <outcome>"
    static let bundlePlaceholder = "<bundle>"

    override func tearDown() async throws {
        await Amplify.reset()
    }

    // MARK: Tests

    /// Test that the credential store and the legacy migration issue exactly the recorded keychain queries
    ///
    /// - Given: Each scenario of the baseline, run twice over a fresh in-memory keychain
    /// - When:
    ///    - The queries issued through `makeKeychainStore` and `legacyKeychainStoreFactory` are recorded
    /// - Then:
    ///    - Both runs record the same sequences, so the baseline is deterministic
    ///    - The scenario names, and each scenario's sequence of (origin, operation, service, access
    ///      group, key, outcome), equal `queries.json`
    ///
    func testKeychainQueriesMatchTheS4qBaseline() async throws {
        let bundle = try XCTUnwrap(Bundle.main.bundleIdentifier, "The legacy migration needs a bundle identifier")
        let current = try await Self.recordAll(bundle: bundle)
        let again = try await Self.recordAll(bundle: bundle)
        XCTAssertEqual(current, again, "The recorded queries are not deterministic")

        let baseline = Baseline(
            note: Self.note,
            format: Self.format,
            bundlePlaceholder: Self.bundlePlaceholder,
            scenarios: current
        )
        if GoldenFiles.isGenerating {
            if FileManager.default.fileExists(atPath: Self.baselineURL.path),
               ProcessInfo.processInfo.environment["AMPLIFY_GOLDEN_OVERWRITE_FROZEN"] != "1" {
                XCTFail("The keychain query baseline is frozen since S4q. Regenerating it defeats the parity gate.")
                return
            }
            try GoldenFiles.write(GoldenFiles.snapshotData(baseline), to: Self.baselineURL)
            return
        }

        let recorded = try JSONDecoder().decode(Baseline.self, from: Data(contentsOf: Self.baselineURL))
        XCTAssertEqual(recorded.format, Self.format)
        XCTAssertEqual(recorded.bundlePlaceholder, Self.bundlePlaceholder)
        XCTAssertEqual(recorded.scenarios.map(\.name), current.map(\.name), "The scenario list changed")
        let recordedByName = Dictionary(uniqueKeysWithValues: recorded.scenarios.map { ($0.name, $0) })
        for scenario in current {
            guard let expected = recordedByName[scenario.name] else { continue }
            XCTAssertFalse(expected.queries.isEmpty, "\(scenario.name): the baseline records no queries")
            if scenario.queries != expected.queries {
                XCTFail(
                    """
                    \(scenario.name): the keychain queries drifted from the S4q baseline.
                    first difference: \(Self.firstDifference(scenario.queries, expected.queries))
                    recorded now:
                    \(scenario.queries.joined(separator: "\n"))
                    baseline:
                    \(expected.queries.joined(separator: "\n"))
                    """
                )
            }
        }
    }

    /// Test that the baseline file is the one pinned in code
    ///
    /// - Given: `GoldenKeychainQueries/queries.json`
    /// - When:
    ///    - Its SHA-256 is computed
    /// - Then:
    ///    - It equals `pinnedBaselineSHA256`
    ///
    func testBaselineIsPinned() throws {
        let data = try Data(contentsOf: Self.baselineURL)
        XCTAssertEqual(GoldenFiles.sha256Hex(data), Self.pinnedBaselineSHA256)
    }

    /// Test that the recorder sees what the credential store does, so an empty or blind recording cannot pass
    ///
    /// - Given: A credential store built through the recording seam
    /// - When:
    ///    - A session is saved and read back
    /// - Then:
    ///    - The `set` and `getData` of the session key are recorded, with the plugin's service and no
    ///      access group
    ///
    func testRecorderSeesTheCredentialStoresQueries() throws {
        let harness = Harness()
        defer { harness.tearDown() }
        let store = harness.credentialStore(Self.userPoolConfiguration)
        harness.recorder.reset()
        try store.saveCredential(LongLivedCredentials.userPoolAndIdentityPool())
        _ = try store.retrieveCredential()
        XCTAssertEqual(harness.recorder.queries, [
            "store | set | com.amplify.awsCognitoAuthPlugin | - | amplify.us-east-1_FixturePool.session -> ok",
            "store | getData | com.amplify.awsCognitoAuthPlugin | - | amplify.us-east-1_FixturePool.session -> ok"
        ])
    }

    /// Test that the recorder records every `KeychainItemStoreBehavior` requirement, in the baseline's format
    ///
    /// - Given: A recording item store with an access group, and a legacy one without
    /// - When:
    ///    - Each of the protocol's 12 requirements is called at least once, plus a not-found and a
    ///      failed read
    /// - Then:
    ///    - Each call is recorded once, in order, with its origin, service, group, key and outcome, so a
    ///      re-typed recorder that drops or reshapes a requirement fails here rather than silently
    ///
    func testRecorderRecordsEveryItemStoreRequirement() throws {
        let keychain = InMemoryKeychain()
        let recorder = KeychainQueryRecorder(keychain: keychain)
        let store = recorder.itemStore(origin: .store, service: "svc", accessGroup: "grp")
        let destination = KeychainItemAttributes(service: "dst", accessGroup: "dgrp")

        try store.set(Data("a".utf8), key: "a")
        _ = try store.getData("a")
        _ = try store.addIfAbsent(Data("b".utf8), key: "b")
        _ = try store.replaceIfPresent(Data("b2".utf8), key: "b")
        _ = try store.hasItems()
        _ = try store.allAccounts()
        _ = try store.allEntries()
        _ = try store.move("a", to: destination)
        _ = try store.move(KeychainEntry(account: "b", accessGroup: "grp"), to: destination)
        try store.set(Data("c".utf8), key: "c")
        try store.remove(KeychainEntry(account: "c", accessGroup: "grp"))
        try store.set(Data("d".utf8), key: "d")
        try store.remove("d")
        try store.removeAll()
        _ = try? store.getData("missing")
        keychain.failing(.read, with: errSecInteractionNotAllowed, forAccount: "locked")
        _ = try? store.getData("locked")
        try recorder.itemStore(origin: .legacy, service: "legacy", accessGroup: nil).removeAll()

        XCTAssertEqual(recorder.queries, [
            "store | set | svc | grp | a -> ok",
            "store | getData | svc | grp | a -> ok",
            "store | addIfAbsent | svc | grp | b -> true",
            "store | replaceIfPresent | svc | grp | b -> true",
            "store | hasItems | svc | grp | - -> true",
            "store | allAccounts | svc | grp | - -> 2 accounts",
            "store | allEntries | svc | grp | - -> 2 entries",
            "store | move(to: dst / dgrp) | svc | grp | a -> moved",
            "store | moveEntry(group: grp, to: dst / dgrp) | svc | grp | b -> moved",
            "store | set | svc | grp | c -> ok",
            "store | removeEntry(group: grp) | svc | grp | c -> ok",
            "store | set | svc | grp | d -> ok",
            "store | remove | svc | grp | d -> ok",
            "store | removeAll | svc | grp | - -> ok",
            "store | getData | svc | grp | missing -> itemNotFound",
            "store | getData | svc | grp | locked -> error(securityError(-25308))",
            "legacy | removeAll | legacy | - | - -> ok"
        ])
    }

    /// Test that the production factories build exactly the stores the baseline records queries against
    ///
    /// The scenarios inject recording factories, so they cannot see the production ones, which the move of
    /// the credential store into the engine rewrote. This pins them: the plugin's `makeCredentialStore()`
    /// (including the `secureStoragePreferences` mapping), the credential store's default
    /// `makeKeychainStore`, and `makeLegacyKeychainStore(service:)`, all taken from a plugin configured through `configure(using:)`.
    /// The default `makeKeychainStore` is reached through the store it builds in the production init.
    ///
    /// The attributes are read from the `KeychainItemStore`s the re-typed factories return.
    ///
    /// - Given: Plugins configured through `configure(using:)` without an access group and with each group
    ///   the baseline uses
    /// - When:
    ///    - Their production factories build the store for every (origin, service, access group) in the baseline
    /// - Then:
    ///    - Each store's item attributes have that service and group and the generic-password class; a
    ///      legacy store never has a group, whatever the plugin's group
    ///    - The add query is AfterFirstUnlockThisDeviceOnly, in the data-protection keychain, not synchronizable
    ///
    func testProductionFactoriesBuildTheRecordedStores() async throws {
        let bundle = try XCTUnwrap(Bundle.main.bundleIdentifier)
        let recorded = try JSONDecoder().decode(Baseline.self, from: Data(contentsOf: Self.baselineURL))
        struct RecordedStore: Hashable, Comparable {
            let origin: String
            let service: String
            let accessGroup: String?
            static func < (lhs: Self, rhs: Self) -> Bool {
                (lhs.origin, lhs.service, lhs.accessGroup ?? "") < (rhs.origin, rhs.service, rhs.accessGroup ?? "")
            }
        }
        let stores = Set(recorded.scenarios.flatMap(\.queries).map { line in
            let fields = line.components(separatedBy: " | ")
            return RecordedStore(
                origin: fields[0],
                service: fields[2].replacingOccurrences(of: Self.bundlePlaceholder, with: bundle),
                accessGroup: fields[3] == "-" ? nil : fields[3]
            )
        })
        XCTAssertEqual(
            Set(stores.filter { $0.origin == "store" }.map { "\($0.service) / \($0.accessGroup ?? "-")" }),
            [
                "\(Self.service) / -",
                "\(Self.sharedService) / \(Self.accessGroup)",
                "\(Self.sharedService) / \(Self.otherAccessGroup)"
            ]
        )

        // Configuring writes the stored access group to `UserDefaults.standard`; put it back afterwards.
        let accessGroupKey = "amplify_secure_storage_scopes.awsCognitoAuthPlugin.accessGroup"
        let savedAccessGroup = UserDefaults.standard.object(forKey: accessGroupKey)
        defer { UserDefaults.standard.set(savedAccessGroup, forKey: accessGroupKey) }
        // One production plugin per access group the baseline uses, and one without.
        var environments: [String?: CredentialEnvironment] = [:]
        for accessGroup in [nil, Self.accessGroup, Self.otherAccessGroup] {
            environments[accessGroup] = try await Self.productionCredentialEnvironment(AWSCognitoSecureStoragePreferences(
                accessGroup: accessGroup.map { AccessGroup(name: $0, migrateKeychainItemsOfUserSession: true) }
            ))
        }

        for store in stores.sorted() {
            let expected = KeychainItemAttributes(service: store.service, accessGroup: store.accessGroup)
            XCTAssertEqual(expected.itemClass, kSecClassGenericPassword as String)
            switch store.origin {
            case "store":
                // `makeCredentialStore()`, its `secureStoragePreferences` mapping and the store's default
                // `makeKeychainStore`: the store the plugin builds for that group.
                let environment = try XCTUnwrap(environments[store.accessGroup], "No plugin for \(store)")
                let credentialStore = try XCTUnwrap(
                    environment.credentialStoreEnvironment.amplifyCredentialStoreFactory() as? AWSCognitoAuthCredentialStore
                )
                XCTAssertEqual(try Self.keychainAttributes(of: credentialStore), expected, "\(store)")
            case "legacy":
                // `makeLegacyKeychainStore(service:)`, whatever the plugin's access group.
                XCTAssertNil(store.accessGroup, "A legacy store never has an access group")
                for environment in environments.values {
                    let legacy = try XCTUnwrap(environment.credentialStoreEnvironment.legacyKeychainStoreFactory(store.service) as? KeychainItemStore)
                    XCTAssertEqual(legacy.attributes, expected, "\(store)")
                }
            default:
                XCTFail("Unknown origin \(store.origin)")
            }
        }

        // The attributes every add carries.
        let groupedEnvironment = try XCTUnwrap(environments[Self.accessGroup])
        let groupedStore = try XCTUnwrap(
            groupedEnvironment.credentialStoreEnvironment.amplifyCredentialStoreFactory() as? AWSCognitoAuthCredentialStore
        )
        let query = try Self.keychainAttributes(of: groupedStore).defaultSetQuery()
        XCTAssertEqual(query[kSecClass as String] as? String, kSecClassGenericPassword as String)
        XCTAssertEqual(query[kSecAttrAccessible as String] as? String, kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String)
        XCTAssertEqual(query[kSecUseDataProtectionKeychain as String] as? Bool, true)
        XCTAssertNil(query[kSecAttrSynchronizable as String])
    }

    /// A plugin configured through `Amplify.configure`, and so `configure(using:)`, so its credential
    /// environment is the production one. Waits for the plugin's own first launch (over the real keychain,
    /// which fails harmlessly unsigned) to dispatch its Hub event, then resets Amplify: resetting earlier
    /// traps in that dispatch.
    static func productionCredentialEnvironment(
        _ preferences: AWSCognitoSecureStoragePreferences
    ) async throws -> CredentialEnvironment {
        let configureEvent = AuthConfigureEventWaiter()
        let plugin = AWSCognitoAuthPlugin(secureStoragePreferences: preferences)
        try Amplify.add(plugin: plugin)
        try Amplify.configure(AmplifyConfiguration(auth: AuthCategoryConfiguration(plugins: [
            "awsCognitoAuthPlugin": productionConfiguration
        ])))
        await configureEvent.waitIfConfigureStarted()
        let machine: CredentialStoreStateMachine = try XCTUnwrap(plugin.credentialStoreStateMachine)
        let environment = try XCTUnwrap(storedProperty("environment", of: machine) as? CredentialEnvironment)
        await Amplify.reset()
        return environment
    }

    static var productionConfiguration: JSONValue {
        [
            "CredentialsProvider": [
                "CognitoIdentity": ["Default": ["PoolId": .string(StoredFormatFixtures.identityPool.poolId), "Region": "us-east-1"]]
            ],
            "CognitoUserPool": [
                "Default": [
                    "PoolId": .string(StoredFormatFixtures.minimalUserPool.poolId),
                    "AppClientId": .string(StoredFormatFixtures.minimalUserPool.clientId),
                    "Region": "us-east-1"
                ]
            ]
        ]
    }

    /// A stored property read by reflection, for production state that is `private`.
    static func storedProperty(_ label: String, of value: Any) -> Any? {
        Mirror(reflecting: value).children.first { $0.label == label }?.value
    }

    /// The attributes of the `KeychainItemStore` the store's private `keychain` operates on: the item store
    /// the default `makeKeychainStore` built for it.
    static func keychainAttributes(of store: AWSCognitoAuthCredentialStore) throws -> KeychainItemAttributes {
        let keychain = try XCTUnwrap(storedProperty("keychain", of: store))
        return try XCTUnwrap(itemStore(in: keychain), "No KeychainItemStore behind \(keychain)").attributes
    }

    /// The first `KeychainItemStore` in `value` or its stored properties, searched depth first by reflection.
    static func itemStore(in value: Any) -> KeychainItemStore? {
        if let itemStore = value as? KeychainItemStore {
            return itemStore
        }
        return Mirror(reflecting: value).children.lazy.compactMap { itemStore(in: $0.value) }.first
    }

    // MARK: Scenarios

    static func recordAll(bundle: String) async throws -> [Baseline.Scenario] {
        var scenarios: [Baseline.Scenario] = []
        func run(_ name: String, _ summary: String, _ body: (Harness) async throws -> Void) async throws {
            let harness = Harness()
            defer { harness.tearDown() }
            harness.recorder.substitute(bundle, with: bundlePlaceholder)
            try await body(harness)
            assertBundleOnlyPrefixesLegacyServices(harness.recorder.rawQueries, bundle: bundle, scenario: name)
            scenarios.append(.init(name: name, summary: summary, queries: harness.recorder.queries))
        }

        // The whole plugin.
        try await run("firstConfigure", "First configuration of the plugin over an empty keychain") { harness in
            _ = await harness.configuredPlugin()
        }
        try await run("signIn", "SRP sign-in of a configured, signed-out plugin; saves the session") { harness in
            let plugin = await harness.configuredPlugin(userPool: signInUserPool())
            harness.recorder.reset()
            let result = try await plugin.signIn(username: "alice", password: "password", options: .init())
            XCTAssertTrue(result.isSignedIn)
        }
        try await run("refresh", "fetchAuthSession refreshes an expired session and saves it") { harness in
            try harness.seedPluginSession(expiredSession)
            let plugin = await harness.configuredPlugin(userPool: refreshUserPool())
            harness.recorder.reset()
            let session = try await plugin.fetchAuthSession(options: .init())
            XCTAssertTrue(session.isSignedIn)
        }
        try await run("signOut", "Sign-out with no Cognito client default-session record") { harness in
            try harness.seedPluginSession(LongLivedCredentials.userPoolAndIdentityPool())
            let plugin = await harness.configuredPlugin(userPool: MockIdentityProvider(mockRevokeTokenResponse: { _ in .testData }))
            harness.recorder.reset()
            let result = await plugin.signOut(options: .init())
            XCTAssertTrue((result as? AWSCognitoSignOutResult)?.signedOutLocally ?? false)
        }
        try await run("deleteUser", "Delete user of a signed-in plugin") { harness in
            try harness.seedPluginSession(LongLivedCredentials.userPoolAndIdentityPool())
            let plugin = await harness.configuredPlugin(userPool: MockIdentityProvider(
                mockRevokeTokenResponse: { _ in .testData },
                mockGlobalSignOutResponse: { _ in .testData },
                mockDeleteUserOutput: { _ in DeleteUserOutput() }
            ))
            harness.recorder.reset()
            try await plugin.deleteUser()
        }
        try await run(
            "deviceMetadataAndASF",
            "ASF device ID created then read, device metadata saved, read and removed; mixed-case username"
        ) { harness in
            _ = await harness.configuredPlugin()
            harness.recorder.reset()
            let environment = try XCTUnwrap(harness.authEnvironment)
            let client = try XCTUnwrap(environment.credentialsClient)
            let username = "Alice.Example"
            _ = try await CognitoUserPoolASF.asfDeviceID(for: username, credentialStoreClient: client)
            _ = try await CognitoUserPoolASF.asfDeviceID(for: username, credentialStoreClient: client)
            _ = await DeviceMetadataHelper.getDeviceMetadata(for: username, with: environment)
            try await client.storeData(data: .deviceMetadata(
                .metadata(.init(deviceKey: "device-key", deviceGroupKey: "device-group", deviceSecret: "device-secret")),
                username
            ))
            _ = await DeviceMetadataHelper.getDeviceMetadata(for: username, with: environment)
            _ = try await CognitoUserPoolASF.asfDeviceID(for: username, credentialStoreClient: client)
            await DeviceMetadataHelper.removeDeviceMetaData(for: username, with: environment)
        }

        // Configuration changes: the three branches of `restoreCredentialsOnConfigurationChanges`.
        try await run(
            "configurationChangeIdentityPoolToUserPoolAndIdentityPool",
            "Identity pool only, then the same identity pool with a user pool: the session is copied forward"
        ) { harness in
            try await harness.launch(.identityPools(StoredFormatFixtures.identityPool), storing: identityPoolSession)
            harness.recorder.reset()
            try await harness.launch(.userPoolsAndIdentityPools(StoredFormatFixtures.minimalUserPool, StoredFormatFixtures.identityPool))
        }
        try await run(
            "configurationChangeSameUserPoolNamespace",
            "The user pool configuration changes but its pool, client and region do not: the session is copied"
        ) { harness in
            try await harness.launch(.userPools(StoredFormatFixtures.minimalUserPool), storing: LongLivedCredentials.userPoolAndIdentityPool())
            harness.recorder.reset()
            try await harness.launch(.userPools(StoredFormatFixtures.fullUserPool))
        }
        try await run(
            "configurationChangeDifferentUserPool",
            "A different user pool: the old namespace's session is removed"
        ) { harness in
            try await harness.launch(.userPools(StoredFormatFixtures.minimalUserPool), storing: LongLivedCredentials.userPoolAndIdentityPool())
            harness.recorder.reset()
            try await harness.launch(.userPools(otherUserPool))
        }
        // A development build's leftover `$default` session record of the Cognito client, which this plugin
        // never reads.
        try await run(
            "firstConfigureBesideALeftoverClientDefaultRecord",
            "First configuration beside a leftover client $default session record: no query names it"
        ) { harness in
            try harness.keychain.store(service: service)
                .set(Data("leftover".utf8), key: leftoverClientDefaultSessionAccount)
            _ = await harness.configuredPlugin()
            XCTAssertFalse(
                harness.recorder.rawQueries.contains { $0.contains("$default") },
                "A query names the leftover client record"
            )
            XCTAssertEqual(
                harness.keychain.value(service: service, account: leftoverClientDefaultSessionAccount),
                Data("leftover".utf8)
            )
        }

        // Access groups.
        try await run(
            "accessGroupTransitionClear",
            "First configuration with an access group, without migration: the unshared service is cleared, sparing client records"
        ) { harness in
            try await harness.populateUnsharedService()
            harness.recorder.reset()
            try await harness.launch(userPoolAndIdentityPool, accessGroup: accessGroup)
        }
        try await run(
            "migrateKeychainItems",
            "First configuration with an access group and migrateKeychainItems: true: items move to the shared service"
        ) { harness in
            try await harness.populateUnsharedService()
            harness.recorder.reset()
            try await harness.launch(userPoolAndIdentityPool, accessGroup: accessGroup, migrate: true)
        }
        try await run(
            "relaunchWithAccessGroup",
            "A later launch with the same access group and migrateKeychainItems: true: no migration, no clear"
        ) { harness in
            try await harness.populateUnsharedService()
            try await harness.launch(userPoolAndIdentityPool, accessGroup: accessGroup, migrate: true)
            harness.recorder.reset()
            try await harness.launch(userPoolAndIdentityPool, accessGroup: accessGroup, migrate: true)
        }
        try await run(
            "accessGroupChange",
            "Group A, then group B, migrateKeychainItems: true: items move from one shared group to the other"
        ) { harness in
            try await harness.populateUnsharedService()
            try await harness.launch(userPoolAndIdentityPool, accessGroup: accessGroup, migrate: true)
            harness.recorder.reset()
            try await harness.launch(userPoolAndIdentityPool, accessGroup: otherAccessGroup, migrate: true)
        }
        try await run(
            "accessGroupRemoved",
            "A group, then no group, migrateKeychainItems: true: items move back to the unshared service"
        ) { harness in
            try await harness.populateUnsharedService()
            try await harness.launch(userPoolAndIdentityPool, accessGroup: accessGroup, migrate: true)
            harness.recorder.reset()
            try await harness.launch(userPoolAndIdentityPool, migrate: true)
        }
        try await run(
            "accessGroupRemovedWithoutMigration",
            "A group, then no group, without migration: nothing is moved or cleared"
        ) { harness in
            try await harness.populateUnsharedService()
            try await harness.launch(userPoolAndIdentityPool, accessGroup: accessGroup, migrate: true)
            harness.recorder.reset()
            try await harness.launch(userPoolAndIdentityPool)
        }
        try await run(
            "accessGroupTransitionSkippedWhenSharedHasItems",
            "An app extension's first launch with the group and its own UserDefaults, without migration, after the app migrated: no clear"
        ) { harness in
            try await harness.populateUnsharedService()
            try await harness.launch(userPoolAndIdentityPool, accessGroup: accessGroup, migrate: true)
            harness.forgetStoredAccessGroup()
            harness.recorder.reset()
            try await harness.launch(userPoolAndIdentityPool, accessGroup: accessGroup)
        }
        try await run(
            "migrateKeychainItemsWhenSharedHasItems",
            "An app extension's first launch with migrateKeychainItems: true after the app migrated: the migration is skipped"
        ) { harness in
            try await harness.populateUnsharedService()
            try await harness.launch(userPoolAndIdentityPool, accessGroup: accessGroup, migrate: true)
            harness.forgetStoredAccessGroup()
            harness.recorder.reset()
            try await harness.launch(userPoolAndIdentityPool, accessGroup: accessGroup, migrate: true)
        }
        try await run(
            "migrateKeychainItemsIntoSharedHoldingOnlyClientRecord",
            "migrateKeychainItems: true while the shared service holds only a client record: the destination clear spares it, then items move"
        ) { harness in
            try await harness.populateUnsharedService()
            try harness.keychain.store(service: sharedService, accessGroup: accessGroup)
                .set(Data("client".utf8), key: clientSessionAccount)
            harness.recorder.reset()
            try await harness.launch(userPoolAndIdentityPool, accessGroup: accessGroup, migrate: true)
        }
        try await run(
            "migrationDestinationOccupied",
            "A group, then no group, migrateKeychainItems: true, over a stale authConfiguration already in the unshared service under the group: its move is destinationOccupied, the rest move"
        ) { harness in
            try await harness.populateUnsharedService()
            try await harness.launch(userPoolAndIdentityPool, accessGroup: accessGroup, migrate: true)
            // A move to a destination without a group keeps the item's own group, so this is where it lands.
            try harness.keychain.store(service: service, accessGroup: accessGroup)
                .set(Data("stale".utf8), key: "authConfiguration")
            harness.recorder.reset()
            try await harness.launch(userPoolAndIdentityPool, migrate: true)
        }
        // The Cognito client's default-session sidecar and challenge items belong to the plugin's session:
        // they move with it, and the transition wipe and the destination clear remove
        // them. They never count as the plugin's items in the shared service. Named sessions stay.
        try await run(
            "migrateKeychainItemsMovesTheDefaultSessionsSidecarAndChallenge",
            "Access group, migrateKeychainItems: true, with the client's $default.meta and .challenge: both move; the named session's record stays"
        ) { harness in
            try await harness.populateUnsharedService()
            try harness.seedDefaultSessionItems()
            harness.recorder.reset()
            try await harness.launch(userPoolAndIdentityPool, accessGroup: accessGroup, migrate: true)
        }
        try await run(
            "accessGroupTransitionClearRemovesTheDefaultSessionsSidecarAndChallenge",
            "Access group without migration, with the client's $default.meta and .challenge: both are removed; the named session's record is spared"
        ) { harness in
            try await harness.populateUnsharedService()
            try harness.seedDefaultSessionItems()
            harness.recorder.reset()
            try await harness.launch(userPoolAndIdentityPool, accessGroup: accessGroup)
        }
        try await run(
            "migrateKeychainItemsIntoSharedHoldingTheDefaultSessionsSidecarAndChallenge",
            "migrateKeychainItems: true while the shared service holds only the client's $default.meta, .challenge and a named session's record: the migration still runs, the destination clear removes the two $default items and spares the named record, then the unshared service's items move"
        ) { harness in
            try await harness.populateUnsharedService()
            try harness.seedDefaultSessionItems()
            let shared = harness.keychain.store(service: sharedService, accessGroup: accessGroup)
            for account in defaultSessionItemAccounts {
                try shared.set(Data("stale".utf8), key: account)
            }
            try shared.set(Data("client".utf8), key: clientSessionAccount)
            harness.recorder.reset()
            try await harness.launch(userPoolAndIdentityPool, accessGroup: accessGroup, migrate: true)
        }

        // The legacy AWSMobileClient migration: every seed set.
        for seed in try legacySeedNames() {
            try await run("legacyMigration-\(seed)", "AWSMobileClient records of GoldenStoredFormat/AWSMobileClient/\(seed).seed.json migrate on first configuration") { harness in
                let configuration = try harness.seedLegacyRecords(seed, bundle: bundle)
                harness.recorder.reset()
                try await harness.launch(configuration)
            }
        }

        // The third consumer of `legacyKeychainStoreFactory`: the Pinpoint endpoint ID.
        try await run(
            "userPoolAnalyticsPinpointEndpoint",
            "UserPoolAnalytics reads the Pinpoint endpoint ID on two launches; it writes under the generated ID as the key, so each launch generates a new one"
        ) { harness in
            let environment = harness.credentialEnvironment(.userPools(StoredFormatFixtures.fullUserPool)).credentialStoreEnvironment
            for launch in 1 ... 2 {
                let analytics = try UserPoolAnalytics(
                    StoredFormatFixtures.fullUserPool,
                    credentialStoreEnvironment: environment,
                    logger: AmplifyEngineLogRouter()
                )
                let endpoint = try XCTUnwrap(analytics.pinpointEndpoint)
                harness.recorder.substitute(endpoint, with: "<generated ID \(launch)>")
            }
        }
        return scenarios
    }

    static func firstDifference(_ lhs: [String], _ rhs: [String]) -> String {
        for index in 0 ..< max(lhs.count, rhs.count) {
            let left = index < lhs.count ? lhs[index] : "<none>"
            let right = index < rhs.count ? rhs[index] : "<none>"
            if left != right {
                return "#\(index): now \(left), baseline \(right)"
            }
        }
        return "none"
    }

    /// Every AWSMobileClient seed set, by name.
    static func legacySeedNames() throws -> [String] {
        try FileManager.default.contentsOfDirectory(atPath: legacySeedDirectory.path)
            .filter { $0.hasSuffix(".seed.json") }
            .map { String($0.dropLast(".seed.json".count)) }
            .sorted()
    }

    static var legacySeedDirectory: URL {
        GoldenFiles.directory("GoldenStoredFormat").appendingPathComponent("AWSMobileClient", isDirectory: true)
    }

    /// The `<bundle>` placeholder is a plain substring replacement, so it is only sound if the bundle
    /// identifier occurs nowhere but at the start of a legacy service name. Checked on every raw query,
    /// before substitution: a fixture string that contained the host's bundle identifier would fail here
    /// rather than be silently rewritten.
    static func assertBundleOnlyPrefixesLegacyServices(_ queries: [String], bundle: String, scenario: String) {
        for query in queries where query.contains(bundle) {
            let fields = query.components(separatedBy: " | ")
            XCTAssertEqual(fields.count, 5, "\(scenario): unexpected query shape: \(query)")
            guard fields.count == 5 else { continue }
            let service = fields[2]
            let others = fields.enumerated().filter { $0.offset != 2 }.map(\.element)
            XCTAssertFalse(others.contains { $0.contains(bundle) }, "\(scenario): the bundle ID occurs outside the service: \(query)")
            XCTAssertTrue(
                fields[0] == "legacy" && (service.hasPrefix("\(bundle).") || service.hasPrefix("Optional(\"\(bundle)\").")),
                "\(scenario): the bundle ID occurs other than as a legacy service prefix: \(query)"
            )
            XCTAssertEqual(
                service.components(separatedBy: bundle).count, 2,
                "\(scenario): the bundle ID occurs more than once: \(query)"
            )
        }
    }

    // MARK: Fixtures

    static let accessGroup = "fixture.access.group"
    static let otherAccessGroup = "fixture.other.access.group"
    static let service = "com.amplify.awsCognitoAuthPlugin"
    static let sharedService = "com.amplify.awsCognitoAuthPluginShared"

    /// A Cognito client session record for `userPoolAndIdentityPool`.
    static let clientSessionAccount = "amplify.1.us-east-1_FixturePool.us-east-1:00000000-0000-4000-8000-00000000ffff.work.session"

    /// The Cognito client's default-session sidecar and challenge items for `userPoolAndIdentityPool`.
    static let defaultSessionItemAccounts = [
        "amplify.1.us-east-1_FixturePool.us-east-1:00000000-0000-4000-8000-00000000ffff.$default.meta",
        "amplify.1.us-east-1_FixturePool.us-east-1:00000000-0000-4000-8000-00000000ffff.$default.challenge"
    ]

    /// A development build's leftover Cognito client `$default` session record, in the namespace of
    /// `Defaults.makeDefaultAuthConfigData()`.
    static let leftoverClientDefaultSessionAccount = "amplify.1.\(Defaults.userPoolId).\(Defaults.identityPoolId).$default.session"

    /// The plugin's session record for `userPoolAndIdentityPool`.
    static let userPoolAndIdentityPoolSessionKey = "amplify.us-east-1_FixturePool.us-east-1:00000000-0000-4000-8000-00000000ffff.session"

    static var userPoolConfiguration: AuthConfiguration { .userPools(StoredFormatFixtures.minimalUserPool) }

    static var userPoolAndIdentityPool: AuthConfiguration {
        .userPoolsAndIdentityPools(StoredFormatFixtures.minimalUserPool, StoredFormatFixtures.identityPool)
    }

    static var otherUserPool: UserPoolConfigurationData {
        UserPoolConfigurationData(poolId: "us-east-1_OtherPool", clientId: "other-client-id", region: "us-east-1")
    }

    static var legacyConfigurations: [String: AuthConfiguration] {
        let fixtures = StoredFormatFixtures.self
        return [
            "userPools-minimal": .userPools(fixtures.minimalUserPool),
            "identityPools": .identityPools(fixtures.identityPool),
            "userPoolsAndIdentityPools-minimal": .userPoolsAndIdentityPools(fixtures.minimalUserPool, fixtures.identityPool),
            "userPoolsAndIdentityPools-full": .userPoolsAndIdentityPools(fixtures.fullUserPool, fixtures.identityPool)
        ]
    }

    static var expiredSession: AmplifyCredentials {
        .userPoolAndIdentityPool(
            signedInData: .expiredTestData,
            identityID: "client-identity-id",
            credentials: EngineAWSCredentials.expiredTestData
        )
    }

    static var identityPoolSession: AmplifyCredentials {
        .identityPoolOnly(identityID: "client-identity-id", credentials: LongLivedCredentials.awsCredentials())
    }

    static func signInUserPool() -> MockIdentityProvider {
        MockIdentityProvider(
            mockInitiateAuthResponse: { _ in
                InitiateAuthOutput(
                    authenticationResult: .none,
                    challengeName: .passwordVerifier,
                    challengeParameters: InitiateAuthOutput.validChalengeParams,
                    session: "someSession"
                )
            },
            mockRespondToAuthChallengeResponse: { _ in
                RespondToAuthChallengeOutput(
                    authenticationResult: .init(
                        accessToken: Defaults.validAccessToken,
                        expiresIn: 300,
                        idToken: "idToken",
                        newDeviceMetadata: nil,
                        refreshToken: "refreshToken",
                        tokenType: ""
                    ),
                    challengeName: .none,
                    challengeParameters: [:],
                    session: "session"
                )
            }
        )
    }

    static func refreshUserPool() -> MockIdentityProvider {
        let refreshed = LongLivedCredentials.tokens(username: "alice")
        return MockIdentityProvider(
            mockGetTokensFromRefreshTokenResponse: { _ in
                GetTokensFromRefreshTokenOutput(authenticationResult: .init(
                    accessToken: refreshed.accessToken,
                    expiresIn: 3_600,
                    idToken: refreshed.idToken,
                    refreshToken: refreshed.refreshToken
                ))
            }
        )
    }
}

// MARK: - Harness

/// One scenario's keychain, `UserDefaults` suite and recorder, and the plugin paths that run over them.
private final class Harness: @unchecked Sendable {
    let keychain = InMemoryKeychain()
    let recorder: KeychainQueryRecorder
    let userDefaults: UserDefaults
    private let suiteName = "KeychainQueryParityTests.\(UUID().uuidString)"
    private(set) var authEnvironment: AuthEnvironment?

    init() {
        self.recorder = KeychainQueryRecorder(keychain: keychain)
        self.userDefaults = UserDefaults(suiteName: suiteName)!
    }

    func tearDown() {
        userDefaults.removePersistentDomain(forName: suiteName)
    }

    /// A credential store exactly as the plugin's `makeCredentialStore` builds one, over the recorder.
    func credentialStore(
        _ authConfiguration: AuthConfiguration,
        accessGroup: String? = nil,
        migrate: Bool = false
    ) -> AWSCognitoAuthCredentialStore {
        AWSCognitoAuthCredentialStore(
            authConfiguration: authConfiguration,
            accessGroup: accessGroup,
            migrateKeychainItemsOfUserSession: migrate,
            userDefaults: userDefaults,
            makeKeychainStore: recorder.makeKeychainStore,
            logger: AmplifyEngineLogRouter()
        )
    }

    /// The plugin's credential environment: a new store per operation, as `makeCredentialStore` does.
    func credentialEnvironment(
        _ authConfiguration: AuthConfiguration,
        accessGroup: String? = nil,
        migrate: Bool = false
    ) -> CredentialEnvironment {
        CredentialEnvironment(
            authConfiguration: authConfiguration,
            credentialStoreEnvironment: BasicCredentialStoreEnvironment(
                amplifyCredentialStoreFactory: { [self] in
                    credentialStore(authConfiguration, accessGroup: accessGroup, migrate: migrate)
                },
                legacyKeychainStoreFactory: recorder.legacyKeychainStoreFactory
            ),
            logger: AmplifyEngineLogRouter(scope: .category("awsCognitoAuthPluginTest"))
        )
    }

    /// A new credential-store state machine, in its production initial state (`.notConfigured`).
    func credentialsClient(
        _ authConfiguration: AuthConfiguration,
        accessGroup: String? = nil,
        migrate: Bool = false
    ) -> CredentialStoreOperationClient {
        CredentialStoreOperationClient(credentialStoreStateMachine: CredentialStoreStateMachine(
            resolver: CredentialStoreState.Resolver(),
            environment: credentialEnvironment(authConfiguration, accessGroup: accessGroup, migrate: migrate)
        ))
    }

    /// What one app launch does to the credential store before any API call: the first fetch of
    /// `InitializeAuthConfiguration`, which runs the legacy migration first. Then optionally a save.
    @discardableResult
    func launch(
        _ authConfiguration: AuthConfiguration,
        accessGroup: String? = nil,
        migrate: Bool = false,
        storing credentials: AmplifyCredentials? = nil
    ) async throws -> CredentialStoreOperationClient {
        let client = credentialsClient(authConfiguration, accessGroup: accessGroup, migrate: migrate)
        _ = try? await client.fetchData(type: .amplifyCredentials)
        if let credentials {
            try await client.storeData(data: .amplifyCredentials(credentials))
        }
        return client
    }

    /// Gives the next launch empty `UserDefaults`, as an app extension has: it does not share the app's.
    func forgetStoredAccessGroup() {
        userDefaults.removePersistentDomain(forName: suiteName)
    }

    /// Stores a session in the plugin's record for `Defaults.makeDefaultAuthConfigData()`.
    func seedPluginSession(_ credentials: AmplifyCredentials) throws {
        try credentialStore(Defaults.makeDefaultAuthConfigData()).saveCredential(credentials)
    }

    /// A plugin configured without an access group has stored a session, device metadata and an ASF
    /// device ID, and a Cognito client has stored a session record in the same unshared service.
    func populateUnsharedService() async throws {
        let configuration = KeychainQueryParityTests.userPoolAndIdentityPool
        let client = credentialsClient(configuration)
        _ = try? await client.fetchData(type: .amplifyCredentials)
        try await client.storeData(data: .amplifyCredentials(LongLivedCredentials.userPoolAndIdentityPool()))
        try await client.storeData(data: .deviceMetadata(
            .metadata(.init(deviceKey: "device-key", deviceGroupKey: "device-group", deviceSecret: "device-secret")),
            "Alice.Example"
        ))
        try await client.storeData(data: .asfDeviceId("asf-device-id", "Alice.Example"))
        try keychain.store(service: KeychainQueryParityTests.service)
            .set(Data("client".utf8), key: KeychainQueryParityTests.clientSessionAccount)
    }

    /// The Cognito client has stored its default session's sidecar and challenge items for
    /// `userPoolAndIdentityPool` in the unshared service.
    func seedDefaultSessionItems() throws {
        let store = keychain.store(service: KeychainQueryParityTests.service)
        for account in KeychainQueryParityTests.defaultSessionItemAccounts {
            try store.set(Data("client".utf8), key: account)
        }
    }

    /// Writes a legacy seed set into the keychain, as `LegacyMigrationGoldenTests` serves it, and returns
    /// its configuration.
    /// - A value with an `error` is written, and its reads fail with that `OSStatus`.
    /// - `existingSession: present` stores `StoredFormatFixtures.presentSession` in the plugin's store;
    ///   `securityError` makes the plugin's session read fail as a locked keychain does.
    func seedLegacyRecords(_ name: String, bundle: String) throws -> AuthConfiguration {
        struct Seed: Decodable {
            struct Value: Decodable {
                let string: String?
                let data: String?
                let error: Int32?
            }

            let authConfiguration: String
            let existingSession: String
            let services: [String: [String: Value]]
        }
        let url = KeychainQueryParityTests.legacySeedDirectory.appendingPathComponent("\(name).seed.json")
        let seed = try JSONDecoder().decode(Seed.self, from: Data(contentsOf: url))
        let configuration = try XCTUnwrap(
            KeychainQueryParityTests.legacyConfigurations[seed.authConfiguration],
            seed.authConfiguration
        )
        for (service, values) in seed.services {
            let store = keychain.store(service: service.replacingOccurrences(of: "<bundle>", with: bundle))
            for (key, value) in values {
                try store.set(Data((value.string ?? value.data ?? "").utf8), key: key)
                if let status = value.error {
                    keychain.failing(.read, with: status, forAccount: key)
                }
            }
        }
        switch seed.existingSession {
        case "absent":
            break
        case "present":
            try credentialStore(configuration).saveCredential(StoredFormatFixtures.presentSession)
        case "securityError":
            keychain.failing(.read, with: errSecInteractionNotAllowed, forAccount: "amplify.\(sessionNamespace(configuration)).session")
        default:
            XCTFail("\(name): unknown existingSession \(seed.existingSession)")
        }
        return configuration
    }

    private func sessionNamespace(_ configuration: AuthConfiguration) -> String {
        switch configuration {
        case .userPools(let userPool): userPool.poolId
        case .identityPools(let identityPool): identityPool.poolId
        case .userPoolsAndIdentityPools(let userPool, let identityPool): "\(userPool.poolId).\(identityPool.poolId)"
        }
    }

    /// A plugin as `configure(using:)` builds it, with its credential store over the recorder and
    /// only the Cognito service calls mocked, once it has finished configuring.
    func configuredPlugin(userPool: CognitoUserPoolBehavior = MockIdentityProvider()) async -> AWSCognitoAuthPlugin {
        let authConfiguration = Defaults.makeDefaultAuthConfigData()
        let credentialStoreMachine = CredentialStoreStateMachine(
            resolver: CredentialStoreState.Resolver(),
            environment: credentialEnvironment(authConfiguration)
        )
        let identity = MockIdentity(
            mockGetIdResponse: { _ in .init(identityId: "client-identity-id") },
            mockGetCredentialsResponse: { _ in
                .init(
                    credentials: CognitoIdentityClientTypes.Credentials(
                        accessKeyId: "refreshedAccessKey",
                        expiration: Date(timeIntervalSinceNow: 3_600),
                        secretKey: "refreshedSecret",
                        sessionToken: "refreshedSession"
                    ),
                    identityId: "client-identity-id"
                )
            }
        )
        let defaults = Defaults.makeDefaultAuthEnvironment(identityPoolFactory: { identity }, userPoolFactory: { userPool })
        let authEnvironment = AuthEnvironment(
            configuration: defaults.configuration,
            userPoolConfigData: defaults.userPoolConfigData,
            identityPoolConfigData: defaults.identityPoolConfigData,
            authenticationEnvironment: defaults.authenticationEnvironment,
            authorizationEnvironment: defaults.authorizationEnvironment,
            credentialsClient: CredentialStoreOperationClient(credentialStoreStateMachine: credentialStoreMachine),
            logger: defaults.logger
        )
        self.authEnvironment = authEnvironment
        let plugin = AWSCognitoAuthPlugin()
        plugin.configure(
            authConfiguration: authConfiguration,
            authEnvironment: authEnvironment,
            authStateMachine: AuthStateMachine(resolver: AuthState.Resolver(logger: AmplifyEngineLogRouter()), environment: authEnvironment),
            credentialStoreStateMachine: credentialStoreMachine,
            hubEventHandler: MockAuthHubEventBehavior(),
            analyticsHandler: MockAnalyticsHandler()
        )
        // Polled, so a configuration that never completes fails the scenario instead of hanging the run.
        let deadline = Date(timeIntervalSinceNow: 10)
        while Date() < deadline {
            if case .configured = await plugin.authStateMachine.currentState {
                await plugin.waitForConfigureOperation()
                return plugin
            }
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
        XCTFail("The plugin did not finish configuring: \(await plugin.authStateMachine.currentState)")
        return plugin
    }
}
