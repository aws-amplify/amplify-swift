//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient
import AWSCognitoAuthPlugin
import Foundation
@testable import InternalAmplifyKeychain
import Security
import XCTest

/// `IO-1` … `IO-3` and `IO-5`: the plugin's `CredentialStoreTransitionRealKeychainTests` (Q7),
/// ported into the interop target, the one that links the plugin. Each test keeps
/// the plugin's method name.
///
/// The plugin's access-group transition runs on the real keychain, end to end, through its public
/// surface: `AWSCognitoAuthPlugin(secureStoragePreferences:)` and `configure(using:)`, which builds
/// `AWSCognitoAuthCredentialStore` on its first credential-store action. Its `init` runs the transition
/// clear or the migration. No network call is made: the plugin's configuration has a user pool only,
/// and nothing signs in.
///
/// Uses the plugin's real services, `com.amplify.awsCognitoAuthPlugin` and `…Shared`, which are also
/// the client's, and the plugin's `UserDefaults` access-group record. All three are cleared before and
/// after each test.
///
/// `.default`'s two client items, the sidecar `$default.meta` and the interrupted sign-in `$default.challenge`,
/// belong to the plugin's session, since `.default`'s login is the plugin's own record. So the
/// plugin treats them as its own items: the transition wipe removes them, the migration moves them with the
/// plugin's record, and the migration's clear of a non-empty destination removes them there. Every
/// other client record, a development build's leftover `$default.session` included, stays where the client put it.
///
/// Beyond the plugin's version, the Q7 tests also hold two records **the client wrote**: a labelled, signed-out
/// row for a named session in the sandbox namespace, and a label on `.default` there, which writes only its
/// sidecar, both through `setSessionLabel`. The plugin's `amplify.1.`/`amplify.2.` fixtures only prove that raw
/// rows survive or move; these prove what the client then lists through `storedSessions`: the named session where
/// it was, and `.default`'s label wherever the plugin's session went.
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
    /// `.default`'s sidecar and interrupted sign-in: client records that belong to the plugin's session.
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
    private var clientConfiguration: AuthClientConfiguration?

    override func setUpWithError() throws {
        try super.setUpWithError()
        defaultGroup = try RealKeychain.defaultGroup()
        sharedGroup = RealKeychain.sharedGroup(defaultGroup: defaultGroup)
        try InteropEnvironment.requireProvisioned()
        clientConfiguration = try AuthClientConfiguration(
            from: InteropEnvironment.outputsResource,
            bundle: InteropEnvironment.outputsBundle()
        )
        resetPluginState()
    }

    override func tearDown() {
        plugin = nil
        resetPluginState()
        super.tearDown()
    }

    /// IO-1. Q7: the transition clear removes the plugin's items, and `.default`'s, from every group and keeps
    /// the other client records.
    ///
    /// - Given: the unshared service holding plugin items, `.default`'s sidecar and challenge items, and
    ///   `amplify.1.` and `amplify.2.` client records (a `$default.session` leftover included) in the default
    ///   group, plus a copy of one plugin account, of `.default`'s sidecar and of one client record under the
    ///   second (shared) group; a labelled named row and a `.default` label the client wrote; no stored access
    ///   group, and an empty shared service
    /// - When:
    ///    - the plugin is configured with the shared group and `migrateKeychainItems: false`
    /// - Then:
    ///    - no plugin account and no `.default` sidecar or challenge item is left in the unshared service, in
    ///      either group, the one the client wrote included
    ///    - every other client record is left, in its own group, with its own data
    ///    - the shared service holds only the plugin's newly written `authConfiguration`
    ///    - the client still lists its named session, with its label, and no longer lists `.default`
    ///
    func testQ7TransitionClearRemovesPluginItemsInEveryGroupAndKeepsClientRecords() async throws {
        seedUnsharedService()
        XCTAssertEqual(RealKeychain.add("shared", account: "amplify.us-east-1_KcWipeOld.session", service: unsharedService, group: sharedGroup), errSecSuccess)
        XCTAssertEqual(RealKeychain.add("shared", account: "amplify.1.us-east-1_KcWipeOld.$default.meta", service: unsharedService, group: sharedGroup), errSecSuccess)
        XCTAssertEqual(RealKeychain.add("shared", account: "amplify.1.us-east-1_KcWipeOld.work.session", service: unsharedService, group: sharedGroup), errSecSuccess)
        let clientSession = try await writeClientRow()
        try await writeClientDefaultLabel()
        let expectedClientRows = RealKeychain.rows(service: unsharedService).filter { staysWithTheClient($0.account) }
        RealKeychain.report(self, "seeded unshared service: \(RealKeychain.rows(service: unsharedService))")

        try await configurePlugin(migrateKeychainItems: false)

        let unshared = RealKeychain.rows(service: unsharedService)
        let shared = RealKeychain.rows(service: sharedService)
        let observed = "unshared service \(unshared); shared service \(shared)"
        RealKeychain.report(self, "after transition clear: \(observed)")
        XCTAssertEqual(unshared.filter { !staysWithTheClient($0.account) }, [], "Q7 clear left plugin or `.default` items: \(observed)")
        XCTAssertEqual(unshared, expectedClientRows, "Q7 clear changed client records: \(observed)")
        XCTAssertEqual(shared.map(\.account), ["authConfiguration"], "Q7 clear: \(observed)")
        XCTAssertTrue(Set(shared.map(\.group)) == [sharedGroup], "Q7 clear: \(observed)")
        try await assertClientStillLists(clientSession, observed: observed)
        try await assertClientListsTheDefaultLabel(nil, accessGroup: nil, observed: observed)
    }

    /// IO-2. Q7: with `migrateKeychainItems: true` the plugin's items move with `.default`'s, and the other client
    /// records stay.
    ///
    /// - Given: the unshared service holding plugin items, `.default`'s sidecar and challenge items, and client
    ///   records in the default group, plus a client record under the shared group; a labelled named row and a
    ///   `.default` label the client wrote; no stored access group, and an empty shared service
    /// - When:
    ///    - the plugin is configured with the shared group and `migrateKeychainItems: true`
    /// - Then:
    ///    - every plugin account and every `.default` sidecar and challenge item, the one the client wrote
    ///      included, is in the shared service, under the shared group, with its own data, and none is left in
    ///      the unshared service
    ///    - every other client record is still in the unshared service, in its own group, with its own data,
    ///      and none is in the shared service
    ///    - the client still lists its named session, with its label, without an access group; it lists
    ///      `.default`'s label with the shared group, where the plugin's session now is, and not without
    ///
    func testQ7MigrationMovesPluginItemsAndLeavesClientRecords() async throws {
        seedUnsharedService()
        XCTAssertEqual(RealKeychain.add("shared", account: "amplify.1.us-east-1_KcWipeOld.work.session", service: unsharedService, group: sharedGroup), errSecSuccess)
        let clientSession = try await writeClientRow()
        let clientSidecar = try await writeClientDefaultLabel()
        let expectedClientRows = RealKeychain.rows(service: unsharedService).filter { staysWithTheClient($0.account) }
        let clientSidecarData = RealKeychain.rows(service: unsharedService).first { $0.account == clientSidecar }?.value

        try await configurePlugin(migrateKeychainItems: true)

        let unshared = RealKeychain.rows(service: unsharedService)
        let shared = RealKeychain.rows(service: sharedService)
        let observed = "unshared service \(unshared); shared service \(shared)"
        RealKeychain.report(self, "after migration: \(observed)")
        XCTAssertEqual(unshared, expectedClientRows, "Q7 migration: \(observed)")
        // Booleans: the client's sidecar account holds the sandbox's pool IDs. `observed` is redacted.
        XCTAssertTrue(shared.map(\.account) == (pluginAccounts + defaultSessionItems + [clientSidecar]).sorted(), "Q7 migration: \(observed)")
        XCTAssertTrue(Set(shared.map(\.group)) == [sharedGroup], "Q7 migration: \(observed)")
        // Moved items keep their data; `authConfiguration` is rewritten by the plugin after the move.
        for row in shared where row.account != "authConfiguration" && row.account != clientSidecar {
            XCTAssertEqual(row.value, "default", "Q7 migration changed \(row.description)'s data: \(observed)")
        }
        XCTAssertTrue(
            clientSidecarData != nil && shared.first { $0.account == clientSidecar }?.value == clientSidecarData,
            "Q7 migration changed the client's sidecar: \(observed)"
        )
        try await assertClientStillLists(clientSession, observed: observed)
        try await assertClientListsTheDefaultLabel(nil, accessGroup: nil, observed: observed)
        try await assertClientListsTheDefaultLabel(Self.clientLabel, accessGroup: sharedGroup, observed: observed)
    }

    /// IO-3. Q7 with Q2's fixture: migration when one plugin account is in two groups of the unshared service.
    ///
    /// Before the move-by-group fix, the unscoped move of that account moved neither copy (Q2), so the
    /// session never reached the shared service. The migrator now moves each listed entry scoped to its
    /// group: the first copy moves and the second collides and is skipped.
    ///
    /// - Given: the unshared service holding plugin items, `.default`'s sidecar and challenge items, and client
    ///   records in the default group, plus a copy of the plugin's session record under the shared group; a
    ///   labelled named row and a `.default` label the client wrote; no stored access group
    /// - When:
    ///    - the plugin is configured with the shared group and `migrateKeychainItems: true`
    /// - Then:
    ///    - every plugin account, the session record included, and every `.default` sidecar and challenge item
    ///      is in the shared service, under the shared group
    ///    - the unshared service keeps every other client record and exactly one stale copy of the session
    ///      record, the one that collided
    ///    - the client still lists its named session, with its label, and lists `.default`'s label with the
    ///      shared group
    ///
    func testQ7MigrationWithPluginAccountInTwoGroups() async throws {
        let session = "amplify.us-east-1_KcWipeOld.session"
        seedUnsharedService()
        XCTAssertEqual(RealKeychain.add("shared", account: session, service: unsharedService, group: sharedGroup), errSecSuccess)
        let clientSession = try await writeClientRow()
        let clientSidecar = try await writeClientDefaultLabel()
        let expectedClientRows = RealKeychain.rows(service: unsharedService).filter { staysWithTheClient($0.account) }

        try await configurePlugin(migrateKeychainItems: true)

        let unshared = RealKeychain.rows(service: unsharedService)
        let shared = RealKeychain.rows(service: sharedService)
        let observed = "unshared service \(unshared); shared service \(shared)"
        RealKeychain.report(self, "after migration, session in two groups: \(observed)")
        // Booleans: the client's sidecar account holds the sandbox's pool IDs. `observed` is redacted.
        XCTAssertTrue(
            shared.map(\.account) == (pluginAccounts + defaultSessionItems + [clientSidecar]).sorted(),
            "Q7 migration, two-group account: \(observed)"
        )
        XCTAssertTrue(Set(shared.map(\.group)) == [sharedGroup], "Q7 migration, two-group account: \(observed)")
        XCTAssertEqual(unshared.filter { staysWithTheClient($0.account) }, expectedClientRows, "Q7 migration, two-group account: \(observed)")
        XCTAssertEqual(unshared.filter { !staysWithTheClient($0.account) }.map(\.account), [session], "Q7 migration, two-group account: \(observed)")
        try await assertClientStillLists(clientSession, observed: observed)
        try await assertClientListsTheDefaultLabel(Self.clientLabel, accessGroup: sharedGroup, observed: observed)
    }

    /// IO-5. The migration's clear of a non-empty destination removes `.default`'s items there, keeps named
    /// sessions' records, and is not blocked by them.
    ///
    /// - Given: the unshared service holding plugin items, `.default`'s sidecar and challenge items and client
    ///   records in the default group; the shared service, under the shared group, already holding a stale copy
    ///   of `.default`'s two items and a named session's record, and nothing of the plugin's own; no stored access
    ///   group
    /// - When:
    ///    - the plugin is configured with the shared group and `migrateKeychainItems: true`
    /// - Then:
    ///    - the migration ran: a shared service holding only client records does not count as "already migrated"
    ///      (the has-items check ignores `.default`'s items too), so every plugin account reached it
    ///    - the stale `.default` items were removed by the clear and replaced by the moved ones, with the moved
    ///      data; the shared service's named record is kept, with its own data
    ///    - the unshared service keeps every other client record, in its own group, with its own data
    ///
    func testDestinationClearRemovesDefaultItemsAndKeepsNamedRecords() async throws {
        let sharedNamed = "amplify.1.us-east-1_KcWipeOld.work.session"
        seedUnsharedService()
        for account in defaultSessionItems + [sharedNamed] {
            let status = RealKeychain.add("stale", account: account, service: sharedService, group: sharedGroup)
            XCTAssertEqual(status, errSecSuccess, "seed the shared service: \(RealKeychain.describe(status))")
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
        XCTAssertTrue(Set(shared.map(\.group)) == [sharedGroup], "the shared service's group after the destination clear: \(observed)")
        for row in shared where row.account != "authConfiguration" {
            XCTAssertEqual(
                row.value,
                row.account == sharedNamed ? "stale" : "default",
                "the shared service's \(row.description) data after the destination clear: \(observed)"
            )
        }
        XCTAssertEqual(unshared, expectedClientRows, "the unshared service's client records after the destination clear: \(observed)")
    }

    // MARK: - Helpers

    private static let clientLabel = "W3 keychain port"

    /// Writes a labelled, signed-out row for a new named session through the client's API, then drops
    /// the client and waits until the registry has released it.
    private func writeClientRow() async throws -> SessionID {
        let configuration = try XCTUnwrap(clientConfiguration)
        let suffix = UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(8).lowercased()
        let sessionId = try SessionID.named("io-\(suffix)")
        try await AmplifyCognitoClient(configuration: configuration, options: .init(sessionId: sessionId))
            .setSessionLabel(Self.clientLabel)
        try await InteropEnvironment.waitUntilReleased(sessionId)
        let account = SessionRecordKey.account(for: sessionId, in: configuration.poolNamespace, kind: .session)
        XCTAssertTrue(
            RealKeychain.rows(service: unsharedService).contains { $0.account == account },
            "the client's row \(account) is not in \(RealKeychain.rows(service: unsharedService))"
        )
        return sessionId
    }

    /// Labels `.default` in the sandbox namespace through the client's API, which writes only its sidecar
    /// (`$default.meta`: nobody has signed in), then drops the client and waits until the registry has released
    /// it. Returns the sidecar's account. Called after the plugin's items are seeded, so a client that writes the
    /// plugin's `authConfiguration` for `.default` never collides with the seeded one.
    @discardableResult
    private func writeClientDefaultLabel() async throws -> String {
        let configuration = try XCTUnwrap(clientConfiguration)
        try await AmplifyCognitoClient(configuration: configuration, options: .init(sessionId: .default))
            .setSessionLabel(Self.clientLabel)
        try await InteropEnvironment.waitUntilReleased(.default)
        let account = SessionRecordKey.metaAccount(in: configuration.poolNamespace)
        XCTAssertTrue(
            RealKeychain.rows(service: unsharedService).contains { $0.account == account },
            "the client's sidecar \(RealKeychain.redact(account)) is not in \(RealKeychain.rows(service: unsharedService))"
        )
        XCTAssertFalse(
            RealKeychain.rows(service: unsharedService).contains { $0.account == SessionRecordKey.pluginSessionAccount(in: configuration.poolNamespace) },
            "labelling `.default` wrote the plugin's record"
        )
        return account
    }

    /// The client's listing under `accessGroup` shows `.default` as a signed-out row with `label`, or, for `nil`,
    /// shows no `.default` row.
    private func assertClientListsTheDefaultLabel(_ label: String?, accessGroup: String?, observed: String) async throws {
        let listed = try await AmplifyCognitoClient.storedSessions(
            configuration: XCTUnwrap(clientConfiguration),
            accessGroup: accessGroup,
            includingSignedOut: true
        )
        let row = listed.first { $0.sessionId == .default }
        let scope = accessGroup == nil ? "without an access group" : "with the shared group"
        guard let label else {
            XCTAssertTrue(row == nil, "the client lists `.default` \(scope): \(listed); \(observed)")
            return
        }
        XCTAssertEqual(row?.label, label, "the client lists \(listed) \(scope); \(observed)")
        XCTAssertEqual(row?.kind, SessionKind.signedOut, "the client lists \(listed) \(scope); \(observed)")
    }

    /// The client lists `sessionId` from storage, with its label, as a signed-out row.
    private func assertClientStillLists(_ sessionId: SessionID, observed: String) async throws {
        let listed = try await AmplifyCognitoClient.storedSessions(
            configuration: XCTUnwrap(clientConfiguration),
            includingSignedOut: true
        )
        let row = listed.first { $0.sessionId == sessionId }
        XCTAssertEqual(row?.label, Self.clientLabel, "the client lists \(listed); \(observed)")
        XCTAssertEqual(row?.kind, SessionKind.signedOut, "the client lists \(listed); \(observed)")
    }

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

    /// Whether the plugin leaves `account` where it is: a client record that is not one of `.default`'s two items.
    private func staysWithTheClient(_ account: String) -> Bool {
        SessionRecordAccount.isClientSessionRecord(account) && !SessionRecordAccount.isDefaultSessionItem(account)
    }

    private func resetPluginState() {
        RealKeychain.wipe(unsharedService)
        RealKeychain.wipe(sharedService)
        UserDefaults.standard.removeObject(forKey: accessGroupDefaultsKey)
    }
}
