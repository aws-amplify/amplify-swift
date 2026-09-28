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

/// Parity `IO-1` … `IO-3`: the plugin's `CredentialStoreTransitionRealKeychainTests` (its real-keychain
/// question Q7), ported into the interop target, the one that links the plugin. Each test keeps
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
/// Beyond the plugin's version, each test also holds a record **the client wrote**: a labelled,
/// signed-out row for a named session in the sandbox namespace, written with `setSessionLabel`. The
/// plugin's `amplify.1.`/`amplify.2.` fixtures only prove that raw rows survive; this row proves the
/// client still lists its session through `storedSessions` after the plugin's transition.
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
    private let clientAccounts = [
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
            bundle: InteropEnvironment.bundle
        )
        resetPluginState()
    }

    override func tearDown() {
        plugin = nil
        resetPluginState()
        super.tearDown()
    }

    /// IO-1. Q7: the transition clear removes the plugin's items from every group and keeps client records.
    ///
    /// - Given: the unshared service holding plugin items, `amplify.1.` and `amplify.2.` client records
    ///   in the default group, plus a copy of one plugin account and one client record under the second
    ///   (shared) group; a labelled row the client wrote; no stored access group, and an empty shared
    ///   service
    /// - When:
    ///    - the plugin is configured with the shared group and `migrateKeychainItems: false`
    /// - Then:
    ///    - no plugin account is left in the unshared service, in either group
    ///    - every client record is left, in its own group, with its own data
    ///    - the shared service holds only the plugin's newly written `authConfiguration`
    ///    - the client still lists its session, with its label
    ///
    func testQ7TransitionClearRemovesPluginItemsInEveryGroupAndKeepsClientRecords() async throws {
        let clientSession = try await writeClientRow()
        seedUnsharedService()
        XCTAssertEqual(RealKeychain.add("shared", account: "amplify.us-east-1_KcWipeOld.session", service: unsharedService, group: sharedGroup), errSecSuccess)
        XCTAssertEqual(RealKeychain.add("shared", account: "amplify.1.us-east-1_KcWipeOld.work.session", service: unsharedService, group: sharedGroup), errSecSuccess)
        let expectedClientRows = RealKeychain.rows(service: unsharedService).filter { isClientRecord($0.account) }
        RealKeychain.report(self, "seeded unshared service: \(RealKeychain.rows(service: unsharedService))")

        try await configurePlugin(migrateKeychainItems: false)

        let unshared = RealKeychain.rows(service: unsharedService)
        let shared = RealKeychain.rows(service: sharedService)
        let observed = "unshared service \(unshared); shared service \(shared)"
        RealKeychain.report(self, "after transition clear: \(observed)")
        XCTAssertEqual(unshared.filter { !isClientRecord($0.account) }, [], "Q7 clear left plugin items: \(observed)")
        XCTAssertEqual(unshared, expectedClientRows, "Q7 clear changed client records: \(observed)")
        XCTAssertEqual(shared.map(\.account), ["authConfiguration"], "Q7 clear: \(observed)")
        XCTAssertEqual(Set(shared.map(\.group)), [sharedGroup], "Q7 clear: \(observed)")
        try await assertClientStillLists(clientSession, observed: observed)
    }

    /// IO-2. Q7: with `migrateKeychainItems: true` the plugin's items move and client records stay.
    ///
    /// - Given: the unshared service holding plugin items and client records in the default group,
    ///   plus a client record under the shared group; a labelled row the client wrote; no stored access
    ///   group, and an empty shared service
    /// - When:
    ///    - the plugin is configured with the shared group and `migrateKeychainItems: true`
    /// - Then:
    ///    - every plugin account is in the shared service, under the shared group, and none is left
    ///      in the unshared service
    ///    - every client record is still in the unshared service, in its own group, with its own data,
    ///      and none is in the shared service
    ///    - the client still lists its session, with its label
    ///
    func testQ7MigrationMovesPluginItemsAndLeavesClientRecords() async throws {
        let clientSession = try await writeClientRow()
        seedUnsharedService()
        XCTAssertEqual(RealKeychain.add("shared", account: "amplify.1.us-east-1_KcWipeOld.work.session", service: unsharedService, group: sharedGroup), errSecSuccess)
        let expectedClientRows = RealKeychain.rows(service: unsharedService).filter { isClientRecord($0.account) }

        try await configurePlugin(migrateKeychainItems: true)

        let unshared = RealKeychain.rows(service: unsharedService)
        let shared = RealKeychain.rows(service: sharedService)
        let observed = "unshared service \(unshared); shared service \(shared)"
        RealKeychain.report(self, "after migration: \(observed)")
        XCTAssertEqual(unshared, expectedClientRows, "Q7 migration: \(observed)")
        XCTAssertEqual(shared.map(\.account), pluginAccounts.sorted(), "Q7 migration: \(observed)")
        XCTAssertEqual(Set(shared.map(\.group)), [sharedGroup], "Q7 migration: \(observed)")
        // Moved items keep their data; `authConfiguration` is rewritten by the plugin after the move.
        for row in shared where row.account != "authConfiguration" {
            XCTAssertEqual(row.value, "default", "Q7 migration changed \(row.account)'s data: \(observed)")
        }
        try await assertClientStillLists(clientSession, observed: observed)
    }

    /// IO-3. Q7 with Q2's fixture: migration when one plugin account is in two groups of the unshared service.
    ///
    /// Before the move-by-group fix, the unscoped move of that account moved neither copy (Q2), so the
    /// session never reached the shared service. The migrator now moves each listed entry scoped to its
    /// group: the first copy moves and the second collides and is skipped.
    ///
    /// - Given: the unshared service holding plugin items and client records in the default group, plus a
    ///   copy of the plugin's session record under the shared group; a labelled row the client wrote;
    ///   no stored access group
    /// - When:
    ///    - the plugin is configured with the shared group and `migrateKeychainItems: true`
    /// - Then:
    ///    - every plugin account, the session record included, is in the shared service, under the
    ///      shared group
    ///    - the unshared service keeps every client record and exactly one stale copy of the session
    ///      record, the one that collided
    ///    - the client still lists its session, with its label
    ///
    func testQ7MigrationWithPluginAccountInTwoGroups() async throws {
        let session = "amplify.us-east-1_KcWipeOld.session"
        let clientSession = try await writeClientRow()
        seedUnsharedService()
        XCTAssertEqual(RealKeychain.add("shared", account: session, service: unsharedService, group: sharedGroup), errSecSuccess)
        let expectedClientRows = RealKeychain.rows(service: unsharedService).filter { isClientRecord($0.account) }

        try await configurePlugin(migrateKeychainItems: true)

        let unshared = RealKeychain.rows(service: unsharedService)
        let shared = RealKeychain.rows(service: sharedService)
        let observed = "unshared service \(unshared); shared service \(shared)"
        RealKeychain.report(self, "after migration, session in two groups: \(observed)")
        XCTAssertEqual(shared.map(\.account), pluginAccounts.sorted(), "Q7 migration, two-group account: \(observed)")
        XCTAssertEqual(Set(shared.map(\.group)), [sharedGroup], "Q7 migration, two-group account: \(observed)")
        XCTAssertEqual(unshared.filter { isClientRecord($0.account) }, expectedClientRows, "Q7 migration, two-group account: \(observed)")
        XCTAssertEqual(unshared.filter { !isClientRecord($0.account) }.map(\.account), [session], "Q7 migration, two-group account: \(observed)")
        try await assertClientStillLists(clientSession, observed: observed)
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
        for account in pluginAccounts + clientAccounts {
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

    private func isClientRecord(_ account: String) -> Bool {
        SessionRecordAccount.isClientSessionRecord(account)
    }

    private func resetPluginState() {
        RealKeychain.wipe(unsharedService)
        RealKeychain.wipe(sharedService)
        UserDefaults.standard.removeObject(forKey: accessGroupDefaultsKey)
    }
}
