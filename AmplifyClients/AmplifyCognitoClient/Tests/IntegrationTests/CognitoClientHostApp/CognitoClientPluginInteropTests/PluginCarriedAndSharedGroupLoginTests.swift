//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import Amplify
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient
import AWSCognitoAuthPlugin
import AWSPluginsCore
import Foundation
import Security
import XCTest

/// The shared saved login of `PluginSharedLoginTests` across a configuration change, and on a keychain access
/// group (AD-9, AD-10), live, on the real keychain.
///
/// - AD-9: the client signs a user in on `.default` under a user-pool-only configuration; the plugin, configured with
///   the same user pool plus the identity pool, carries that login and is signed in from it; then, configured under
///   another user pool, it deletes the carried login with `.default`'s sidecar and interrupted sign-in. That is the
///   plugin applying its configuration-change rule to an `authConfiguration` the client wrote, and to the client's two
///   `.default` items.
/// - AD-10: AD-3 and AD-5 of `PluginSharedLoginTests` with the plugin on the host app's shared access group S and a
///   `.default` client with `accessGroup: S`, and a `.default` client with no access group, which reads signed out.
///
/// As in `PluginSharedLoginTests`, the plugin and the client never act side by side over `.default`: the client is
/// released before the plugin is configured again, as at a relaunch. Signs `alice`, a fresh user each test signs up, in
/// against the default backend. Tokens, records and pool identifiers are compared with booleans and never printed.
///
/// Uses the plugin's real services, `com.amplify.awsCognitoAuthPlugin` and `…Shared`, which are also the client's, and
/// the plugin's `UserDefaults` access-group record. All three are cleared before and after each test, which also
/// removes alice's device records under every configuration the test used.
final class PluginCarriedAndSharedGroupLoginTests: XCTestCase {

    private let unsharedService = SessionRecordStore.unsharedService
    private let sharedService = SessionRecordStore.sharedService
    private let accessGroupDefaultsKey = "amplify_secure_storage_scopes.awsCognitoAuthPlugin.accessGroup"

    /// The default backend's outputs: its user pool and its identity pool.
    private var configuration: AuthClientConfiguration!
    /// The host app's second keychain access group, S.
    private var sharedGroup = ""
    /// The test's own user, signed up in `setUp` and deleted at teardown.
    private var alice: InteropUser?
    /// A plugin configured outside `Amplify` (AD-9's last step), held until teardown.
    private var plugin: AWSCognitoAuthPlugin?

    override func setUp() async throws {
        try await super.setUp()
        try InteropEnvironment.requireProvisioned()
        sharedGroup = try RealKeychain.sharedGroup(defaultGroup: RealKeychain.defaultGroup())
        configuration = try AuthClientConfiguration(
            from: InteropEnvironment.outputsResource,
            bundle: InteropEnvironment.outputsBundle()
        )
        resetPluginState()
        alice = try await InteropEnvironment.signUpFreshUser()
    }

    /// Signs the plugin out first when Auth is configured (which revokes the refresh token it holds; an unconfigured
    /// `Amplify.Auth` aborts the process), then deletes the test's user, whose deletion also invalidates every token a
    /// record left behind holds, and clears both services and the access-group record.
    override func tearDown() async throws {
        plugin = nil
        if Amplify.Auth.isConfigured {
            _ = await Amplify.Auth.signOut()
        }
        await Amplify.reset()
        do {
            try await InteropEnvironment.waitUntilReleased(.default)
        } catch {
            XCTFail("tearDown: \(error)")
        }
        if let alice {
            await InteropEnvironment.deleteFreshUser(alice)
        }
        resetPluginState()
        try await super.tearDown()
    }

    /// AD-9. The plugin carries the login the client signed in under a user-pool-only configuration when the identity
    /// pool is added, is signed in from it, and deletes it, with `.default`'s sidecar and interrupted sign-in, when it
    /// is then configured under another user pool.
    ///
    /// - Given: `alice` signed in through a client on `.default` over the default backend's user pool alone, then
    ///   released: the plugin's record and the sidecar are under that configuration's namespace, and
    ///   `authConfiguration` records it
    /// - When:
    ///    - the plugin is configured with the default backend's outputs (the same user pool, plus its identity pool),
    ///      settles, and fetches its session
    ///    - the plugin is reset; a client on `.default` over the same outputs restores alice and labels the session,
    ///      which writes that namespace's sidecar, and is released; a `$default.challenge` item is seeded beside them
    ///    - a plugin with no access group is configured under another user pool
    /// - Then:
    ///    - before its fetch, the plugin had carried the record to the identity pool's namespace as its bytes were,
    ///      and kept the old one
    ///    - the plugin is signed in as alice, with the access token the client's sign-in received
    ///    - the restored `.default` is signed in as alice, with no user pool request
    ///    - under another user pool, the plugin deleted the carried login, its sidecar and its challenge item; the
    ///      user-pool-only namespace it carried from keeps its record and sidecar, as a carry keeps them
    ///
    func testPluginCarriesTheClientsLoginAndDeletesItOnAUserPoolChange() async throws {
        let alice = try XCTUnwrap(alice)
        let full = try XCTUnwrap(configuration)
        guard full.identityPool != nil else {
            throw InteropError("""
            \(InteropEnvironment.outputsResource).json names no identity pool: this test needs the default backend's, \
            which federates its user pool.
            """)
        }
        let userPoolOnly = try AuthClientConfiguration(userPool: full.userPool)
        let oldLogin = SessionRecordKey.pluginSessionAccount(in: userPoolOnly.poolNamespace)
        let oldSidecar = SessionRecordKey.metaAccount(in: userPoolOnly.poolNamespace)
        let newLogin = SessionRecordKey.pluginSessionAccount(in: full.poolNamespace)
        let newSidecar = SessionRecordKey.metaAccount(in: full.poolNamespace)
        let newChallenge = SessionRecordKey.account(for: .default, in: full.poolNamespace, kind: .challenge)

        let clientToken: String
        do {
            let client = try AmplifyCognitoClient(configuration: userPoolOnly, options: .init(sessionId: .default))
            let signIn = try await client.signIn(username: alice.username, password: alice.password)
            guard case .done = signIn.nextStep else {
                return XCTFail("alice did not sign in through the client")
            }
            clientToken = try await client.userPoolTokenProvider.accessToken()
        }
        try await InteropEnvironment.waitUntilReleased(.default)
        let signedIn = try XCTUnwrap(value(oldLogin), "the client's sign-in wrote no plugin record")
        XCTAssertNotNil(value(oldSidecar), "the client's sign-in wrote no sidecar")
        XCTAssertNil(value(newLogin), "the identity pool's namespace already holds a login")
        XCTAssertNotNil(
            value(SessionRecordStore.pluginConfigurationAccount),
            "the client recorded no configuration for the plugin"
        )

        // The identity pool is added: the plugin carries the client's login.
        try await configurePlugin(accessGroup: nil)
        XCTAssertTrue(value(newLogin) == signedIn, "the plugin did not carry the client's login as its bytes were")
        XCTAssertTrue(value(oldLogin) == signedIn, "the plugin's carry did not keep the user-pool-only login")
        let session = try await Amplify.Auth.fetchAuthSession()
        XCTAssertTrue(session.isSignedIn, "the plugin is not signed in from the carried login")
        let user = try await Amplify.Auth.getCurrentUser()
        XCTAssertTrue(user.username == alice.username, "the plugin is signed in as another user")
        let pluginToken = try await pluginAccessToken()
        XCTAssertTrue(pluginToken == clientToken, "the plugin does not hold the client's tokens")

        // The client's `.default` reads the carried login, and writes its sidecar beside it.
        await Amplify.reset()
        do {
            let recorder = UserPoolRequestRecorder()
            let client = try AmplifyCognitoClient(
                configuration: full,
                options: .init(sessionId: .default, configureUserPoolClient: recorder.configureUserPoolClient)
            )
            let state = await client.currentSessionState()
            guard case .signedIn(let restored) = state else {
                return XCTFail("`.default` did not restore the carried login")
            }
            XCTAssertTrue(restored.username == alice.username, "`.default` restored another user")
            XCTAssertEqual(recorder.operations, [], "restoring the carried login made user pool requests")
            try await client.setSessionLabel("Carried login")
        }
        try await InteropEnvironment.waitUntilReleased(.default)
        XCTAssertNotNil(value(newSidecar), "labelling `.default` wrote no sidecar")
        let seeded = RealKeychain.add("default", account: newChallenge, service: unsharedService)
        XCTAssertEqual(seeded, errSecSuccess, "seed `.default`'s challenge item: \(RealKeychain.describe(seeded))")

        // Another user pool: the plugin deletes the login it last ran, with `.default`'s two items.
        try await configurePluginUnderAnotherUserPool(changedFrom: value(SessionRecordStore.pluginConfigurationAccount))

        let observed = RealKeychain.rows(service: unsharedService).map(\.description).joined(separator: ", ")
        RealKeychain.report(self, "after the plugin's configuration change: \(observed)")
        XCTAssertNil(value(newLogin), "the plugin kept the carried login: \(observed)")
        XCTAssertNil(value(newSidecar), "the plugin kept `.default`'s sidecar: \(observed)")
        XCTAssertNil(value(newChallenge), "the plugin kept `.default`'s interrupted sign-in: \(observed)")
        XCTAssertTrue(value(oldLogin) == signedIn, "the plugin changed the user-pool-only login it carried from: \(observed)")
        XCTAssertNotNil(value(oldSidecar), "the plugin deleted the user-pool-only namespace's sidecar: \(observed)")
    }

    /// AD-10, a sign-in: the client's `.default` on the plugin's access group signs alice in, a relaunched plugin on
    /// that group sees her (AD-3 on S), and a `.default` client with no access group does not.
    ///
    /// - Given: the plugin configured on the shared access group S (`migrateKeychainItems: false`), with nothing stored
    /// - When:
    ///    - a client on `.default` with `accessGroup: S` signs `alice` in (SRP, its default), and is released
    ///    - a client on `.default` with no access group reads its state, and is released
    ///    - the plugin, on S, is reset and configured again, as at a relaunch, and fetches its session
    /// - Then:
    ///    - the client's sign-in wrote the plugin's record, in the plugin's format and naming alice, and the sidecar,
    ///      both in (the shared service, S), and no login to the unshared service
    ///    - the client's listing on S shows `.default` as alice; its listing with no access group shows no `.default`
    ///    - the group-less `.default` reads `.signedOut`, with no user pool request
    ///    - the relaunched plugin reports alice signed in, with the access token the client's sign-in received
    ///
    func testPluginOnTheAccessGroupSeesTheUserTheClientSignedIn() async throws {
        let alice = try XCTUnwrap(alice)
        let login = SessionRecordKey.pluginSessionAccount(in: configuration.poolNamespace)
        let sidecar = SessionRecordKey.metaAccount(in: configuration.poolNamespace)
        try await configurePlugin(accessGroup: sharedGroup)

        let clientToken: String
        do {
            let client = try makeDefaultClient(accessGroup: sharedGroup, UserPoolRequestRecorder())
            let signIn = try await client.signIn(username: alice.username, password: alice.password)
            guard case .done = signIn.nextStep else {
                return XCTFail("alice did not sign in through the client")
            }
            clientToken = try await client.userPoolTokenProvider.accessToken()
        }
        try await InteropEnvironment.waitUntilReleased(.default)
        let record = try XCTUnwrap(value(login, service: sharedService, group: sharedGroup), "the client wrote no plugin record on S")
        let summary = PluginRecordSummary.peek(Data(record.utf8))
        XCTAssertTrue(summary.isRecognised, "the client's record is not in the plugin's format")
        XCTAssertTrue(summary.username == alice.username, "the client's record does not name alice")
        XCTAssertNotNil(value(sidecar, service: sharedService, group: sharedGroup), "the client wrote no sidecar on S")
        XCTAssertNil(value(login), "the client wrote a login to the unshared service")
        let onTheGroup = try await AmplifyCognitoClient.storedSessions(configuration: configuration, accessGroup: sharedGroup)
        XCTAssertTrue(onTheGroup.first { $0.sessionId == .default }?.username == alice.username, "`.default` is not listed as alice on S")
        let groupLess = try await AmplifyCognitoClient.storedSessions(configuration: configuration, includingSignedOut: true)
        XCTAssertFalse(groupLess.contains { $0.sessionId == .default }, "`.default` is listed with no access group")

        do {
            let recorder = UserPoolRequestRecorder()
            let client = try makeDefaultClient(accessGroup: nil, recorder)
            let state = await client.currentSessionState()
            XCTAssertTrue(state == .signedOut, "the group-less `.default` read the login on S")
            XCTAssertEqual(recorder.operations, [], "the group-less `.default` made user pool requests")
        }
        try await InteropEnvironment.waitUntilReleased(.default)

        try await relaunchPlugin(accessGroup: sharedGroup)

        let session = try await Amplify.Auth.fetchAuthSession()
        XCTAssertTrue(session.isSignedIn, "the plugin on S does not see the client's sign-in")
        let user = try await Amplify.Auth.getCurrentUser()
        XCTAssertTrue(user.username == alice.username, "the plugin is signed in as another user")
        let pluginToken = try await pluginAccessToken()
        XCTAssertTrue(pluginToken == clientToken, "the plugin does not hold the client's tokens")
    }

    /// AD-10, a sign-out: the client's `.default` on the plugin's access group signs alice out, and a relaunched plugin
    /// on that group is signed out (AD-5 on S).
    ///
    /// - Given: the plugin configured on the shared access group S (`migrateKeychainItems: false`), and `alice` signed
    ///   in through a client on `.default` with `accessGroup: S`
    /// - When:
    ///    - the client signs out, and is released
    ///    - the plugin, on S, is reset and configured again, as at a relaunch, and fetches its session
    /// - Then:
    ///    - the client's sign-out is `.complete`, and signed out locally
    ///    - the plugin's record on S is the signed-out record, `{"noCredentials":{}}`, and the sidecar is kept there
    ///    - the client's listing on S, with signed-out rows, shows `.default` as a signed-out row naming alice
    ///    - the relaunched plugin reports signed out
    ///
    func testClientSignOutOnTheAccessGroupIsSeenByThePlugin() async throws {
        let alice = try XCTUnwrap(alice)
        let login = SessionRecordKey.pluginSessionAccount(in: configuration.poolNamespace)
        let sidecar = SessionRecordKey.metaAccount(in: configuration.poolNamespace)
        try await configurePlugin(accessGroup: sharedGroup)

        do {
            let client = try makeDefaultClient(accessGroup: sharedGroup, UserPoolRequestRecorder())
            let signIn = try await client.signIn(username: alice.username, password: alice.password)
            guard case .done = signIn.nextStep else {
                return XCTFail("alice did not sign in through the client")
            }

            let signOut = await client.signOut()

            XCTAssertTrue(signOut == .complete, "the client's sign-out did not complete")
            XCTAssertTrue(signOut.signedOutLocally, "the client's sign-out left alice signed in")
        }
        try await InteropEnvironment.waitUntilReleased(.default)
        let record = try XCTUnwrap(
            value(login, service: sharedService, group: sharedGroup),
            "the client's sign-out deleted the plugin's record on S"
        )
        XCTAssertTrue(PluginRecordSummary.isSignedOut(Data(record.utf8)), "the client's sign-out did not write the signed-out record")
        XCTAssertNotNil(value(sidecar, service: sharedService, group: sharedGroup), "the client's sign-out removed the sidecar on S")
        let listed = try await AmplifyCognitoClient.storedSessions(
            configuration: configuration,
            accessGroup: sharedGroup,
            includingSignedOut: true
        )
        let defaultRow = try XCTUnwrap(listed.first { $0.sessionId == .default }, "`.default`'s signed-out row is not listed on S")
        XCTAssertEqual(defaultRow.kind, SessionKind.signedOut)
        XCTAssertTrue(defaultRow.username == alice.username, "`.default`'s signed-out row does not name alice")

        try await relaunchPlugin(accessGroup: sharedGroup)

        let session = try await Amplify.Auth.fetchAuthSession()
        XCTAssertFalse(session.isSignedIn, "the plugin on S is still signed in after the client's sign-out")
    }

    // MARK: - Helpers

    /// Configures the plugin from the default backend's outputs, on `accessGroup` (no migration) or none, and waits
    /// until it has settled (`InteropEnvironment.settlePlugin()`): its credential store, which applies a configuration
    /// change and writes `authConfiguration`, is built.
    private func configurePlugin(accessGroup: String?) async throws {
        let plugin = accessGroup.map {
            AWSCognitoAuthPlugin(secureStoragePreferences: AWSCognitoSecureStoragePreferences(
                accessGroup: AccessGroup(name: $0, migrateKeychainItemsOfUserSession: false)
            ))
        } ?? AWSCognitoAuthPlugin()
        try Amplify.add(plugin: plugin)
        try Amplify.configure(with: .data(InteropEnvironment.outputsData()))
        try await InteropEnvironment.settlePlugin()
    }

    /// A new plugin over the same keychain, as at the app's next launch.
    private func relaunchPlugin(accessGroup: String?) async throws {
        await Amplify.reset()
        try await configurePlugin(accessGroup: accessGroup)
    }

    /// Configures a plugin with no access group under another user pool (one with no backend: nothing signs in, so no
    /// request is made), and waits until its credential store has applied the configuration change from `previous`,
    /// the bytes of `authConfiguration` before, and rewritten it.
    private func configurePluginUnderAnotherUserPool(changedFrom previous: String?) async throws {
        let plugin = AWSCognitoAuthPlugin()
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
        while value(SessionRecordStore.pluginConfigurationAccount) == previous {
            guard Date() < deadline else {
                XCTFail("The credential store was not built within 20 s")
                return
            }
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        // Let the credential-store state machine finish loading, so nothing writes after the asserts.
        _ = try? await plugin.fetchAuthSession(options: nil)
    }

    private func makeDefaultClient(accessGroup: String?, _ recorder: UserPoolRequestRecorder) throws -> AmplifyCognitoClient {
        try AmplifyCognitoClient(
            configuration: configuration,
            options: .init(sessionId: .default, accessGroup: accessGroup, configureUserPoolClient: recorder.configureUserPoolClient)
        )
    }

    /// The plugin's current access token. Never printed.
    private func pluginAccessToken() async throws -> String {
        let session = try await Amplify.Auth.fetchAuthSession()
        let provider = try XCTUnwrap(session as? AuthCognitoTokensProvider, "the plugin's session has no tokens")
        return try provider.getCognitoTokens().get().accessToken
    }

    /// The data of `account` in `service` (default: the unshared one), in `group` or any visible group, or nil if it is
    /// absent. Compared, never printed: a record holds real tokens.
    private func value(_ account: String, service: String? = nil, group: String? = nil) -> String? {
        RealKeychain.rows(service: service ?? unsharedService, group: group).first { $0.account == account }?.value
    }

    private func resetPluginState() {
        RealKeychain.wipe(unsharedService)
        RealKeychain.wipe(sharedService)
        UserDefaults.standard.removeObject(forKey: accessGroupDefaultsKey)
    }
}
