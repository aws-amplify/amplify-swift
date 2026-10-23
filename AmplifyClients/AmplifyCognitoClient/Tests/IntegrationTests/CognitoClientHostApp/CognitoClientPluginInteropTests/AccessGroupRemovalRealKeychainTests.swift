//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import Amplify
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient
import AWSCognitoAuthPlugin
import Foundation
@testable import InternalAmplifyKeychain
import Security
import XCTest

/// Parity `IO-4`, a characterisation: after an app **removes** its keychain access group, can a
/// group-less read still find the session the plugin moved back?
///
/// An open question of the keychain parity work. The plugin's
/// `accessGroupRemoved` path (a group, then no group, `migrateKeychainItems: true`) moves every item
/// from (shared service, group S) to the unshared service with no access group. A move to a
/// group-less destination keeps each item's own group (KM-9), so the moved session still sits in
/// group S. The in-memory fake's `.exactGroup` matching then reads nothing; on a device, a group-less
/// query matches every entitled group. This asserts what the simulator keychain does, end to end,
/// with a real plugin session.
///
/// Signs `alice`, a fresh user the test signs up, in through the plugin against the default backend, so
/// it needs the test configuration and the network. It uses the plugin's real services and its `UserDefaults` access-group record, which
/// are cleared before and after the test.
final class AccessGroupRemovalRealKeychainTests: XCTestCase {

    private let unsharedService = "com.amplify.awsCognitoAuthPlugin"
    private let sharedService = "com.amplify.awsCognitoAuthPluginShared"
    private let accessGroupDefaultsKey = "amplify_secure_storage_scopes.awsCognitoAuthPlugin.accessGroup"

    private var sharedGroup = ""
    private var configuration: AuthClientConfiguration?
    /// The test's own user, deleted at teardown.
    private var alice: InteropUser?

    override func setUp() async throws {
        try await super.setUp()
        try InteropEnvironment.requireProvisioned()
        sharedGroup = try RealKeychain.sharedGroup(defaultGroup: RealKeychain.defaultGroup())
        configuration = try AuthClientConfiguration(
            from: InteropEnvironment.outputsResource,
            bundle: InteropEnvironment.outputsBundle()
        )
        resetPluginState()
    }

    /// Clears the keychain and `UserDefaults` first, whatever failed, so alice's plugin record never
    /// outlives the test. Signs out only when Auth is configured: `setUp`, either `configurePlugin`, or
    /// the gap after `Amplify.reset()` can leave it unconfigured, and an unconfigured `Amplify.Auth`
    /// aborts the process. The sign-out revokes from the plugin's in-memory session, so it still works
    /// after the wipe; the second wipe removes anything it wrote.
    override func tearDown() async throws {
        resetPluginState()
        if Amplify.Auth.isConfigured {
            _ = await Amplify.Auth.signOut()
        }
        await Amplify.reset()
        if let alice {
            await InteropEnvironment.deleteFreshUser(alice)
        }
        resetPluginState()
        try await super.tearDown()
    }

    /// IO-4. After the access group is removed, a group-less read finds the moved session.
    ///
    /// - Given: the plugin configured with the shared group S (`migrateKeychainItems: true`) and `alice`
    ///   signed in through it, so its session record is in (shared service, S)
    /// - When:
    ///    - the plugin is reset and configured again with no access group, `migrateKeychainItems: true`
    ///      (the plugin's `accessGroupRemoved` path), and fetches its session
    /// - Then (observed on the iOS 26.5 simulator, pinned):
    ///    - the session record is in the unshared service, still in group S, and no longer in the
    ///      shared service
    ///    - a group-less `KeychainItemStore` read of that account returns it
    ///    - the plugin reports `alice` signed in, from storage
    ///    - the client's group-less `storedSessions` lists `.default` from the plugin's moved record, which is
    ///      `.default`'s own session record, as `alice` with both pools
    ///    - a group-less client on `.default` restores the moved record as `.signedIn(alice)`, with no user pool
    ///      request, and released, leaves the record as the plugin moved it
    ///
    func testAccessGroupRemovedGroupLessReadFindsTheMovedSession() async throws {
        let configuration = try XCTUnwrap(configuration)
        let sessionAccount = SessionRecordKey.pluginSessionAccount(in: configuration.poolNamespace)

        let alice = try await InteropEnvironment.signUpFreshUser()
        self.alice = alice
        try await configurePlugin(accessGroup: AccessGroup(name: sharedGroup, migrateKeychainItemsOfUserSession: true))
        let signIn = try await Amplify.Auth.signIn(username: alice.username, password: alice.password)
        XCTAssertTrue(signIn.isSignedIn, "alice did not sign in through the plugin: \(signIn.nextStep)")
        let before = rows()
        RealKeychain.report(self, "signed in with group S: \(before)")
        XCTAssertTrue(
            RealKeychain.rows(service: sharedService).contains { $0.account == sessionAccount && $0.group == sharedGroup },
            "the plugin's session is not in (shared service, S): \(before)"
        )

        await Amplify.reset()
        try await configurePlugin(accessGroup: .none(migrateKeychainItemsOfUserSession: true))
        let session = try await Amplify.Auth.fetchAuthSession()

        let after = rows()
        RealKeychain.report(self, "after the access group was removed: \(after); plugin signed in: \(session.isSignedIn)")
        XCTAssertEqual(
            RealKeychain.rows(service: unsharedService).filter { $0.account == sessionAccount }.map(\.group),
            [sharedGroup],
            "the moved session is not in (unshared service, S): \(after)"
        )
        XCTAssertFalse(
            RealKeychain.rows(service: sharedService).contains { $0.account == sessionAccount },
            "the session is still in the shared service: \(after)"
        )
        let groupLessRead = try KeychainItemStore(service: unsharedService).getData(sessionAccount)
        XCTAssertFalse(groupLessRead.isEmpty, "a group-less read returned an empty record")
        XCTAssertTrue(session.isSignedIn, "the plugin lost alice after the access group was removed: \(after)")

        let listed = try await AmplifyCognitoClient.storedSessions(configuration: configuration)
        let defaultRow = listed.first { $0.sessionId == .default }
        RealKeychain.report(self, "the client lists \(listed)")
        XCTAssertTrue(defaultRow?.username == alice.username, "the client's listing is \(listed)")
        XCTAssertEqual(defaultRow?.kind, .userPoolAndIdentityPool, "the client's listing is \(listed)")

        do {
            let recorder = UserPoolRequestRecorder()
            let client = try AmplifyCognitoClient(
                configuration: configuration,
                options: .init(sessionId: .default, configureUserPoolClient: recorder.configureUserPoolClient)
            )
            let state = await client.currentSessionState()
            guard case .signedIn(let user) = state else {
                return XCTFail("the group-less `.default` did not restore the moved session: \(after)")
            }
            XCTAssertTrue(user.username == alice.username, "the group-less `.default` is signed in as another user")
            XCTAssertEqual(recorder.operations, [], "restoring the moved session made user pool requests")
        }
        try await InteropEnvironment.waitUntilReleased(.default)
        let restoredRead = try KeychainItemStore(service: unsharedService).getData(sessionAccount)
        XCTAssertTrue(restoredRead == groupLessRead, "restoring the moved session changed the record")
    }

    // MARK: - Helpers

    private func configurePlugin(accessGroup: AccessGroup) async throws {
        try Amplify.add(plugin: AWSCognitoAuthPlugin(
            secureStoragePreferences: AWSCognitoSecureStoragePreferences(accessGroup: accessGroup)
        ))
        try Amplify.configure(with: .data(InteropEnvironment.outputsData()))
        try await InteropEnvironment.settlePlugin()
    }

    /// Both services' accounts and groups, never their data: the session record holds real tokens. The
    /// accounts carry the sandbox pool ids, which `Row.description` redacts.
    private func rows() -> String {
        func redacted(_ service: String) -> String {
            RealKeychain.rows(service: service).map(\.description).joined(separator: ", ")
        }
        return "unshared service [\(redacted(unsharedService))]; shared service [\(redacted(sharedService))]"
    }

    private func resetPluginState() {
        RealKeychain.wipe(unsharedService)
        RealKeychain.wipe(sharedService)
        UserDefaults.standard.removeObject(forKey: accessGroupDefaultsKey)
    }
}
