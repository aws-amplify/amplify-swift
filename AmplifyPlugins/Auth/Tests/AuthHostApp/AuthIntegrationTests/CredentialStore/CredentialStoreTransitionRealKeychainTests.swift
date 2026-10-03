//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import Amplify
import AWSCognitoAuthPlugin
import Foundation
@testable import InternalAmplifyKeychain
import Security
import XCTest

/// Q7, one of the real-keychain questions of the scoped wipe: the Auth plugin's access-group transition
/// on the real keychain, end to end.
///
/// Goes through the public surface only: `AWSCognitoAuthPlugin(secureStoragePreferences:)` and
/// `configure(using:)`, which builds `AWSCognitoAuthCredentialStore` on its first credential-store
/// action. Its `init` runs the transition clear or the migration. No network call is made: the
/// configuration has a user pool only, and nothing signs in.
///
/// Uses the plugin's real services, `com.amplify.awsCognitoAuthPlugin` and `…Shared`, and its
/// `UserDefaults` access-group record. All three are cleared before and after each test, as
/// `CredentialStoreConfigurationTests` does. Unlike that suite, this one needs no backend configuration:
/// it does not derive from `AWSAuthBaseTest` and never calls `Amplify.configure`.
///
/// The Cognito client's default session uses the plugin's own record, so its two items beside it, the sidecar
/// `amplify.1.<ns>.$default.meta` and the interrupted sign-in `amplify.1.<ns>.$default.challenge`, belong to the
/// plugin's session: the transition clear removes them, the migration moves them with the plugin's record,
/// and the migration's clear of a non-empty destination removes them there. Every other client
/// record, a development build's leftover `$default.session` included, stays where the client put it.
final class CredentialStoreTransitionRealKeychainTests: XCTestCase {

    private let unsharedService = "com.amplify.awsCognitoAuthPlugin"
    private let sharedService = "com.amplify.awsCognitoAuthPluginShared"
    private let accessGroupDefaultsKey = "amplify_secure_storage_scopes.awsCognitoAuthPlugin.accessGroup"

    private let pluginAccounts = [
        "amplify.us-east-1_KcWipeOld.Alice.deviceASF",
        "amplify.us-east-1_KcWipeOld.alice.deviceMetadata",
        "amplify.us-east-1_KcWipeOld.session",
        "authConfiguration"
    ]
    /// The Cognito client's default-session items: client records that belong to the plugin's session.
    private let defaultSessionItems = [
        "amplify.1.us-east-1_KcWipeOld.$default.challenge",
        "amplify.1.us-east-1_KcWipeOld.$default.meta"
    ]
    /// Client records that stay with the client, whatever the plugin does: named sessions' records of any schema
    /// version, and a development build's leftover `$default.session`.
    private let clientAccounts = [
        "amplify.1.us-east-1_KcWipeOld.$default.session",
        "amplify.1.us-east-1_KcWipeOld.work.challenge",
        "amplify.1.us-east-1_KcWipeOld.work.session",
        "amplify.2.us-east-1_KcWipeOld.work.session"
    ]

    private var defaultGroup = ""
    private var sharedGroup = ""
    private var plugin: AWSCognitoAuthPlugin?

    override func setUpWithError() throws {
        try super.setUpWithError()
        defaultGroup = try RealKeychain.defaultGroup()
        sharedGroup = RealKeychain.sharedGroup(defaultGroup: defaultGroup)
        resetPluginState()
    }

    override func tearDown() async throws {
        plugin = nil
        // A configured plugin is never released (its environment's factories capture it), and its
        // `AuthHubEventHandler` keeps listening on the global Hub. This suite never registers it with
        // Amplify, so nothing resets it: left alone, each one re-sends the next suite's sign-in as another
        // `signedIn` event. Resetting Amplify removes every Hub listener, as `AWSAuthBaseTest` does.
        await Amplify.reset()
        resetPluginState()
        try await super.tearDown()
    }

    /// Q7: the transition clear removes the plugin's items, and the client's default-session items, from every
    /// group and keeps the other client records.
    ///
    /// - Given: the unshared service holding plugin items, the client's `$default.meta` and `$default.challenge`,
    ///   and `amplify.1.` and `amplify.2.` client records (a `$default.session` leftover included) in the default
    ///   group, plus a copy of one plugin account, of `$default.meta` and of one client record under the second
    ///   (shared) group; no stored access group, and an empty shared service
    /// - When:
    ///    - the plugin is configured with the shared group and `migrateKeychainItems: false`
    /// - Then:
    ///    - no plugin account and no default-session item is left in the unshared service, in either group
    ///    - every other client record is left, in its own group, with its own data
    ///    - the shared service holds only the plugin's newly written `authConfiguration`
    ///
    func testQ7TransitionClearRemovesPluginItemsInEveryGroupAndKeepsClientRecords() async throws {
        seedUnsharedService()
        XCTAssertEqual(RealKeychain.add("shared", account: "amplify.us-east-1_KcWipeOld.session", service: unsharedService, group: sharedGroup), errSecSuccess)
        XCTAssertEqual(RealKeychain.add("shared", account: "amplify.1.us-east-1_KcWipeOld.$default.meta", service: unsharedService, group: sharedGroup), errSecSuccess)
        XCTAssertEqual(RealKeychain.add("shared", account: "amplify.1.us-east-1_KcWipeOld.work.session", service: unsharedService, group: sharedGroup), errSecSuccess)
        let expectedClientRows = RealKeychain.rows(service: unsharedService).filter { staysWithTheClient($0.account) }
        RealKeychain.report(self, "seeded unshared service: \(RealKeychain.rows(service: unsharedService))")

        try await configurePlugin(migrateKeychainItems: false)

        let unshared = RealKeychain.rows(service: unsharedService)
        let shared = RealKeychain.rows(service: sharedService)
        let observed = "unshared service \(unshared); shared service \(shared)"
        RealKeychain.report(self, "after transition clear: \(observed)")
        XCTAssertEqual(unshared.filter { !staysWithTheClient($0.account) }, [], "Q7 clear left plugin or default-session items: \(observed)")
        XCTAssertEqual(unshared, expectedClientRows, "Q7 clear changed client records: \(observed)")
        XCTAssertEqual(shared.map(\.account), ["authConfiguration"], "Q7 clear: \(observed)")
        XCTAssertEqual(Set(shared.map(\.group)), [sharedGroup], "Q7 clear: \(observed)")
    }

    /// Q7: with `migrateKeychainItems: true` the plugin's items move with the client's default-session items,
    /// and the other client records stay.
    ///
    /// - Given: the unshared service holding plugin items, the client's `$default.meta` and `$default.challenge`,
    ///   and client records in the default group, plus a client record under the shared group; no stored access
    ///   group, and an empty shared service
    /// - When:
    ///    - the plugin is configured with the shared group and `migrateKeychainItems: true`
    /// - Then:
    ///    - every plugin account and both default-session items are in the shared service, under the shared
    ///      group, with their own data, and none is left in the unshared service
    ///    - every other client record is still in the unshared service, in its own group, with its own data,
    ///      and none is in the shared service
    ///
    func testQ7MigrationMovesPluginItemsAndLeavesClientRecords() async throws {
        seedUnsharedService()
        XCTAssertEqual(RealKeychain.add("shared", account: "amplify.1.us-east-1_KcWipeOld.work.session", service: unsharedService, group: sharedGroup), errSecSuccess)
        let expectedClientRows = RealKeychain.rows(service: unsharedService).filter { staysWithTheClient($0.account) }

        try await configurePlugin(migrateKeychainItems: true)

        let unshared = RealKeychain.rows(service: unsharedService)
        let shared = RealKeychain.rows(service: sharedService)
        let observed = "unshared service \(unshared); shared service \(shared)"
        RealKeychain.report(self, "after migration: \(observed)")
        XCTAssertEqual(unshared, expectedClientRows, "Q7 migration: \(observed)")
        XCTAssertEqual(shared.map(\.account), (pluginAccounts + defaultSessionItems).sorted(), "Q7 migration: \(observed)")
        XCTAssertEqual(Set(shared.map(\.group)), [sharedGroup], "Q7 migration: \(observed)")
        // Moved items keep their data; `authConfiguration` is rewritten by the plugin after the move.
        for row in shared where row.account != "authConfiguration" {
            XCTAssertEqual(row.value, "default", "Q7 migration changed \(row.account)'s data: \(observed)")
        }
    }

    /// Q7 with Q2's fixture: migration when one plugin account is in two groups of the unshared service.
    ///
    /// Before the move-by-group fix, the unscoped move of that account moved neither copy (Q2), so the
    /// session never reached the shared service. The migrator now moves each listed entry scoped to its
    /// group: the first copy moves and the second collides and is skipped.
    ///
    /// - Given: the unshared service holding plugin items, the client's default-session items and client records
    ///   in the default group, plus a copy of the plugin's session record under the shared group; no stored
    ///   access group
    /// - When:
    ///    - the plugin is configured with the shared group and `migrateKeychainItems: true`
    /// - Then:
    ///    - every plugin account, the session record included, and both default-session items are in the
    ///      shared service, under the shared group
    ///    - the unshared service keeps every other client record and exactly one stale copy of the session
    ///      record, the one that collided
    ///
    func testQ7MigrationWithPluginAccountInTwoGroups() async throws {
        let session = "amplify.us-east-1_KcWipeOld.session"
        seedUnsharedService()
        XCTAssertEqual(RealKeychain.add("shared", account: session, service: unsharedService, group: sharedGroup), errSecSuccess)
        let expectedClientRows = RealKeychain.rows(service: unsharedService).filter { staysWithTheClient($0.account) }

        try await configurePlugin(migrateKeychainItems: true)

        let unshared = RealKeychain.rows(service: unsharedService)
        let shared = RealKeychain.rows(service: sharedService)
        let observed = "unshared service \(unshared); shared service \(shared)"
        RealKeychain.report(self, "after migration, session in two groups: \(observed)")
        XCTAssertEqual(shared.map(\.account), (pluginAccounts + defaultSessionItems).sorted(), "Q7 migration, two-group account: \(observed)")
        XCTAssertEqual(Set(shared.map(\.group)), [sharedGroup], "Q7 migration, two-group account: \(observed)")
        XCTAssertEqual(unshared.filter { staysWithTheClient($0.account) }, expectedClientRows, "Q7 migration, two-group account: \(observed)")
        XCTAssertEqual(unshared.filter { !staysWithTheClient($0.account) }.map(\.account), [session], "Q7 migration, two-group account: \(observed)")
    }

    /// the migration's clear of a non-empty destination removes the client's default-session items there,
    /// keeps named sessions' records, and is not blocked by either.
    ///
    /// - Given: the unshared service holding plugin items, the client's default-session items and client records
    ///   in the default group; the shared service, under the shared group, already holding a stale copy of the
    ///   two default-session items and a named session's record, and nothing of the plugin's own; no stored
    ///   access group
    /// - When:
    ///    - the plugin is configured with the shared group and `migrateKeychainItems: true`
    /// - Then:
    ///    - the migration ran: a shared service holding only client records does not count as "already migrated"
    ///      (the has-items check ignores the default-session items too), so every plugin account reached it
    ///    - the stale default-session items were removed by the clear and replaced by the moved ones, with the
    ///      moved data; the shared service's named record is kept, with its own data
    ///    - the unshared service keeps every other client record, in its own group, with its own data
    ///
    func testDestinationClearRemovesDefaultSessionItemsAndKeepsNamedRecords() async throws {
        let sharedNamed = "amplify.1.us-east-1_KcWipeOld.work.session"
        seedUnsharedService()
        for account in defaultSessionItems + [sharedNamed] {
            let status = RealKeychain.add("stale", account: account, service: sharedService, group: sharedGroup)
            XCTAssertEqual(status, errSecSuccess, "seed the shared service with \(account): \(RealKeychain.describe(status))")
        }
        let expectedClientRows = RealKeychain.rows(service: unsharedService).filter { staysWithTheClient($0.account) }

        try await configurePlugin(migrateKeychainItems: true)

        let unshared = RealKeychain.rows(service: unsharedService)
        let shared = RealKeychain.rows(service: sharedService)
        let observed = "unshared service \(unshared); shared service \(shared)"
        RealKeychain.report(self, "after migration onto a shared service holding client records: \(observed)")
        XCTAssertEqual(
            shared.map(\.account),
            (pluginAccounts + defaultSessionItems + [sharedNamed]).sorted(),
            "the shared service's accounts after the destination clear: \(observed)"
        )
        XCTAssertEqual(Set(shared.map(\.group)), [sharedGroup], "the shared service's group after the destination clear: \(observed)")
        for row in shared where row.account != "authConfiguration" {
            XCTAssertEqual(
                row.value,
                row.account == sharedNamed ? "stale" : "default",
                "the shared service's \(row.account) data after the destination clear: \(observed)"
            )
        }
        XCTAssertEqual(unshared, expectedClientRows, "the unshared service's client records after the destination clear: \(observed)")
    }

    // MARK: - Helpers

    private func seedUnsharedService() {
        for account in pluginAccounts + defaultSessionItems + clientAccounts {
            let status = RealKeychain.add("default", account: account, service: unsharedService)
            XCTAssertEqual(status, errSecSuccess, "seed \(account): \(RealKeychain.describe(status))")
        }
    }

    /// Configures a fresh plugin and waits until its credential store has been built: that is when
    /// `AWSCognitoAuthCredentialStore.init` clears or migrates, and it finishes by writing
    /// `authConfiguration` to the shared service.
    private func configurePlugin(migrateKeychainItems: Bool) async throws {
        let plugin = AWSCognitoAuthPlugin(
            secureStoragePreferences: AWSCognitoSecureStoragePreferences(
                accessGroup: AccessGroup(name: sharedGroup, migrateKeychainItemsOfUserSession: migrateKeychainItems)
            )
        )
        self.plugin = plugin
        let configuration: JSONValue = [
            "CognitoUserPool": [
                "Default": [
                    "PoolId": "us-east-1_KcWipeNew",
                    "AppClientId": "kcwipeappclient",
                    "Region": "us-east-1"
                ]
            ]
        ]
        try plugin.configure(using: configuration)

        let deadline = Date().addingTimeInterval(20)
        while !RealKeychain.rows(service: sharedService).contains(where: { $0.account == "authConfiguration" }) {
            guard Date() < deadline else {
                XCTFail("The credential store was not built within 20 s")
                return
            }
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        // Let the credential-store state machine finish loading, so nothing writes after the asserts.
        _ = try? await plugin.fetchAuthSession(options: nil)
    }

    /// Whether the plugin leaves `account` where it is: a client record that is not a default-session item.
    private func staysWithTheClient(_ account: String) -> Bool {
        SessionRecordAccount.isClientSessionRecord(account) && !SessionRecordAccount.isDefaultSessionItem(account)
    }

    private func resetPluginState() {
        RealKeychain.wipe(unsharedService)
        RealKeychain.wipe(sharedService)
        UserDefaults.standard.removeObject(forKey: accessGroupDefaultsKey)
    }
}
