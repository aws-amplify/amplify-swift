//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import Amplify
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient
@_spi(AmplifyExperimental) import AmplifyFoundation
import AWSCognitoAuthPlugin
import AWSPluginsCore
import Foundation
import Security
import XCTest

/// The plugin and the client's `.default` share one saved login (AD-1 …
/// AD-8): a sign-in, a refresh and a sign-out on either side is what the other reads next.
///
/// `.default`'s session record is the plugin's own `amplify.<ns>.session`, read and written in place, with the
/// client's sidecar (`amplify.1.<ns>.$default.meta`: label and last user) beside it. So whatever one side signs
/// in or out, the other sees on its next load: a new client, or a new plugin `configure`. The two are never run
/// side by side over `.default` (the plugin keeps its tokens in memory, so that stays unsupported), and each test
/// hands the login over at a "relaunch": the client is released before the plugin acts, and the plugin is reset
/// and configured again before it reads what the client wrote. No named session ever reads the plugin's record
/// (AD-2).
///
/// Signs `alice`, a fresh user each test signs up, in against the default backend. Tokens, subs and pool
/// identifiers are compared with booleans and never printed; keychain rows are described by role (`plugin`,
/// `sidecar`, `leftover`), never by account name, because account names carry the pool identifiers.
final class PluginSharedLoginTests: XCTestCase {

    private var configuration: AuthClientConfiguration!
    /// The plugin's record, `amplify.<ns>.session`: `.default`'s session record.
    private var pluginAccount = ""
    /// `.default`'s sidecar, `amplify.1.<ns>.$default.meta`, which only the client writes.
    private var sidecarAccount = ""
    /// `amplify.1.<ns>.$default.session`, the development builds' leftover: no build writes it any more.
    private var leftoverAccount = ""
    /// Named sessions a test created, purged at teardown.
    private var namedSessions: [SessionID] = []
    /// The test's own user (alice), signed up in `setUp` and deleted at teardown.
    private var alice: InteropUser!

    override func setUp() async throws {
        try await super.setUp()
        try InteropEnvironment.requireProvisioned()
        configuration = try AuthClientConfiguration(
            from: InteropEnvironment.outputsResource,
            bundle: InteropEnvironment.outputsBundle()
        )
        pluginAccount = SessionRecordKey.pluginSessionAccount(in: configuration.poolNamespace)
        sidecarAccount = SessionRecordKey.metaAccount(in: configuration.poolNamespace)
        leftoverAccount = SessionRecordKey.account(for: .default, in: configuration.poolNamespace, kind: .session)
        // A run that stopped early may have left the shared login or its sidecar; this test must start from
        // neither. The purge never touches a development leftover, so that is deleted directly.
        try await AmplifyCognitoClient.purgeStoredSession(sessionId: .default, configuration: configuration)
        try InteropEnvironment.deleteSessionAccount(leftoverAccount)
        XCTAssertEqual(records(), "plugin: absent, sidecar: absent, leftover: absent", "setUp left a record")
        alice = try await InteropEnvironment.signUpFreshUser()
        try configurePlugin()
    }

    /// Signs the plugin out first (which revokes the refresh token it holds, if any), then purges every session
    /// the test touched, whatever failed, and deletes the test's user, its device and advanced-security records
    /// on this device (which neither side removes), and the plugin's `authConfiguration`, so no later suite reads
    /// this one's configuration. Signs out only when Auth is configured: a
    /// throwing `setUp` or a failed relaunch leaves it unconfigured, and an unconfigured `Amplify.Auth` aborts
    /// the process.
    ///
    /// Each session is purged on its own, even if waiting for another's release, or its own, failed: a
    /// purge while a handle is still live goes through that handle, so it still deletes the records.
    override func tearDown() async throws {
        if Amplify.Auth.isConfigured {
            _ = await Amplify.Auth.signOut()
        }
        await Amplify.reset()
        if let configuration {
            for sessionId in [SessionID.default] + namedSessions {
                do {
                    try await InteropEnvironment.waitUntilReleased(sessionId)
                } catch {
                    XCTFail("tearDown: \(error)")
                }
                do {
                    try await AmplifyCognitoClient.purgeStoredSession(sessionId: sessionId, configuration: configuration)
                } catch {
                    XCTFail("tearDown could not purge \(sessionId): \(type(of: error))")
                }
            }
            XCTAssertEqual(records(), "plugin: absent, sidecar: absent, leftover: absent", "tearDown left a record")
        }
        if let alice {
            await InteropEnvironment.deleteFreshUser(alice)
            if let configuration {
                try InteropEnvironment.removeDeviceRecords(of: alice, under: configuration)
            }
        }
        try InteropEnvironment.deleteSessionAccount(SessionRecordStore.pluginConfigurationAccount)
        namedSessions = []
        try await super.tearDown()
    }

    /// AD-1. The plugin signs alice in, and the client's `.default` restores her from the plugin's record, in
    /// place; a later plugin write is `.default`'s too.
    ///
    /// - Given: the plugin configured from the default backend's outputs and `alice` (a fresh user of the
    ///   test's own) signed in through it, so the plugin's record exists and the sidecar does not
    /// - When:
    ///    - a client on `.default` is created, with a request recorder on its user pool client, and reads its
    ///      state and both providers
    ///    - the client is released, the plugin force-refreshes (writing its record again), and a new client on
    ///      `.default` is created
    /// - Then:
    ///    - the first client reads `.signedIn(alice)` with **0** user pool requests, its access token is the
    ///      plugin's, and its credentials provider resolves
    ///    - restoring wrote nothing: the plugin's record is byte-for-byte unchanged, and neither the sidecar nor
    ///      a `$default.session` record exists
    ///    - the saved-session listing shows `.default` as alice
    ///    - after the plugin's refresh, the new client reads `.signedIn(alice)` with the plugin's **new** access
    ///      token, with 0 requests: there is one saved login, and it is the plugin's
    ///
    func testClientRestoresTheUserThePluginSignedIn() async throws {
        let signIn = try await Amplify.Auth.signIn(username: alice.username, password: alice.password)
        XCTAssertTrue(signIn.isSignedIn, "alice did not sign in through the plugin")
        let pluginToken = try await pluginAccessToken()
        XCTAssertEqual(records(), "plugin: present, sidecar: absent, leftover: absent", "the plugin's sign-in")
        let pluginRecord = try XCTUnwrap(row(pluginAccount), "the plugin wrote no record")

        do {
            let recorder = UserPoolRequestRecorder()
            let client = try makeDefaultClient(recorder)
            try await assertSignedInAsAlice(client)
            let restored = try await client.userPoolTokenProvider.accessToken()
            XCTAssertTrue(restored == pluginToken, "`.default` did not read the plugin's tokens")
            let credentials = try await client.credentialsProvider.resolve()
            XCTAssertFalse(credentials.accessKeyId.isEmpty, "the credentials provider resolved empty credentials")
            XCTAssertEqual(recorder.operations, [], "restoring the plugin's login made user pool requests")
        }
        XCTAssertEqual(records(), "plugin: present, sidecar: absent, leftover: absent", "restoring wrote a record")
        XCTAssertTrue(row(pluginAccount) == pluginRecord, "restoring changed the plugin's record")
        let listed = try await AmplifyCognitoClient.storedSessions(configuration: configuration)
        XCTAssertTrue(listed.first { $0.sessionId == .default }?.username == alice.username, "`.default` is not listed as alice")
        try await InteropEnvironment.waitUntilReleased(.default)

        // A later plugin write, a forced refresh, is read by the next `.default` load.
        let refreshed = try await pluginAccessToken(forceRefresh: true)
        XCTAssertTrue(refreshed != pluginToken, "the plugin's forced refresh did not mint a new token")
        do {
            let recorder = UserPoolRequestRecorder()
            let client = try makeDefaultClient(recorder)
            try await assertSignedInAsAlice(client)
            let token = try await client.userPoolTokenProvider.accessToken()
            XCTAssertTrue(token == refreshed, "the re-created `.default` did not read the plugin's refreshed tokens")
            XCTAssertEqual(recorder.operations, [], "the re-created `.default` made user pool requests")
        }
        XCTAssertEqual(records(), "plugin: present, sidecar: absent, leftover: absent", "the second restore")
    }

    /// AD-2. A named session never reads the plugin's record.
    ///
    /// - Given: `alice` signed in through the plugin, as in AD-1, so the plugin's record exists
    /// - When:
    ///    - a client on a new named session is created, and reads its state and both providers
    /// - Then:
    ///    - it reads `.signedOut`, with 0 user pool requests
    ///    - its credentials provider and its user pool token provider throw `CredentialsError.notSignedIn`
    ///    - the plugin's record is byte-for-byte unchanged, no record exists for the named session, and
    ///      `.default` has neither a sidecar nor a `$default.session` record
    ///    - the saved-session listing does not show the named session; it shows `.default` as `alice`, from the
    ///      plugin's record, which is `.default`'s own
    ///
    func testNamedSessionNeverReadsThePluginRecord() async throws {
        let signIn = try await Amplify.Auth.signIn(username: alice.username, password: alice.password)
        XCTAssertTrue(signIn.isSignedIn, "alice did not sign in through the plugin")
        let pluginRecord = try XCTUnwrap(row(pluginAccount), "the plugin wrote no record")
        let sessionId = try SessionID.named("ad2-\(UUID().uuidString.prefix(8).lowercased())")
        namedSessions.append(sessionId)
        let namedAccount = SessionRecordKey.account(for: sessionId, in: configuration.poolNamespace, kind: .session)

        do {
            let recorder = UserPoolRequestRecorder()
            let client = try AmplifyCognitoClient(
                configuration: configuration,
                options: .init(sessionId: sessionId, configureUserPoolClient: recorder.configureUserPoolClient)
            )

            let state = await client.currentSessionState()
            XCTAssertTrue(state == .signedOut, "the named session is not signed out")
            let resolveError = await credentialsError("credentialsProvider.resolve()") {
                try await client.credentialsProvider.resolve()
            }
            let tokenError = await credentialsError("userPoolTokenProvider.accessToken()") {
                try await client.userPoolTokenProvider.accessToken()
            }
            XCTAssertEqual(resolveError, "notSignedIn")
            XCTAssertEqual(tokenError, "notSignedIn")
            XCTAssertEqual(recorder.operations, [], "the named session made user pool requests")
        }

        XCTAssertTrue(row(pluginAccount) == pluginRecord, "the plugin's record changed")
        XCTAssertTrue(row(namedAccount) == nil, "the named session wrote a record")
        XCTAssertEqual(records(), "plugin: present, sidecar: absent, leftover: absent")
        let listed = try await AmplifyCognitoClient.storedSessions(configuration: configuration, includingSignedOut: true)
        XCTAssertFalse(listed.contains { $0.sessionId == sessionId }, "the named session is listed")
        let defaultRow = listed.first { $0.sessionId == .default }
        XCTAssertTrue(defaultRow?.username == alice.username, "`.default` is not listed as alice from the plugin's record")
    }

    /// AD-3. The client's `.default` signs alice in, and the plugin's `fetchAuthSession` sees her after a relaunch.
    ///
    /// - Given: the plugin configured with nothing stored, so it loaded signed out
    /// - When:
    ///    - a client on `.default` signs `alice` in (SRP, its default) and is released
    ///    - the plugin is reset and configured again, as at a relaunch, and fetches its session
    /// - Then:
    ///    - the client's sign-in wrote the plugin's record and the sidecar, never a `$default.session` record
    ///    - the plugin's record is a signed-in record naming alice, in the plugin's own format
    ///    - the plugin reports alice signed in, its `getCurrentUser()` names her, and its access token is the one
    ///      the client's sign-in received
    ///
    func testPluginSeesTheUserTheClientSignedIn() async throws {
        let clientToken: String
        do {
            let client = try makeDefaultClient(UserPoolRequestRecorder())
            let signIn = try await client.signIn(username: alice.username, password: alice.password)
            guard case .done = signIn.nextStep else {
                return XCTFail("alice did not sign in through the client")
            }
            try await assertSignedInAsAlice(client)
            clientToken = try await client.userPoolTokenProvider.accessToken()
        }
        try await InteropEnvironment.waitUntilReleased(.default)
        XCTAssertEqual(records(), "plugin: present, sidecar: present, leftover: absent", "the client's sign-in")
        let summary = try PluginRecordSummary.peek(XCTUnwrap(row(pluginAccount), "the client wrote no plugin record"))
        XCTAssertTrue(summary.isRecognised, "the client's record is not in the plugin's format")
        XCTAssertTrue(summary.username == alice.username, "the client's record does not name alice")

        try await relaunchPlugin()

        let session = try await Amplify.Auth.fetchAuthSession()
        XCTAssertTrue(session.isSignedIn, "the plugin does not see the client's sign-in")
        let user = try await Amplify.Auth.getCurrentUser()
        XCTAssertTrue(user.username == alice.username, "the plugin is signed in as another user")
        let pluginToken = try await pluginAccessToken()
        XCTAssertTrue(pluginToken == clientToken, "the plugin does not hold the client's tokens")
    }

    /// AD-4. A sign-out through the plugin is seen by the client's next `.default`.
    ///
    /// - Given: `alice` signed in through the plugin, and a client on `.default` that restored her, then released
    /// - When:
    ///    - the plugin signs out
    ///    - a new client on `.default` is created
    /// - Then:
    ///    - the plugin's sign-out is `.complete`, and it deletes the plugin's record (no signed-out marker is
    ///      written any more)
    ///    - the new client reads `.signedOut`, with 0 user pool requests, and its user pool token provider throws
    ///      `CredentialsError.notSignedIn`
    ///    - the listing shows no `.default` row, even with signed-out rows: no client ever wrote a sidecar here
    ///
    func testPluginSignOutIsSeenByTheClient() async throws {
        let signIn = try await Amplify.Auth.signIn(username: alice.username, password: alice.password)
        XCTAssertTrue(signIn.isSignedIn, "alice did not sign in through the plugin")
        do {
            let client = try makeDefaultClient(UserPoolRequestRecorder())
            try await assertSignedInAsAlice(client)
        }
        try await InteropEnvironment.waitUntilReleased(.default)

        let signOut = await Amplify.Auth.signOut()

        guard let pluginSignOut = signOut as? AWSCognitoSignOutResult, case .complete = pluginSignOut else {
            return XCTFail("the plugin's sign-out did not complete")
        }
        XCTAssertEqual(records(), "plugin: absent, sidecar: absent, leftover: absent", "the plugin's sign-out")
        do {
            let recorder = UserPoolRequestRecorder()
            let client = try makeDefaultClient(recorder)
            let state = await client.currentSessionState()
            XCTAssertTrue(state == .signedOut, "`.default` did not see the plugin's sign-out")
            let tokenError = await credentialsError("userPoolTokenProvider.accessToken()") {
                try await client.userPoolTokenProvider.accessToken()
            }
            XCTAssertEqual(tokenError, "notSignedIn")
            XCTAssertEqual(recorder.operations, [], "the signed-out `.default` made user pool requests")
        }
        let listed = try await AmplifyCognitoClient.storedSessions(configuration: configuration, includingSignedOut: true)
        XCTAssertFalse(listed.contains { $0.sessionId == .default }, "`.default` is listed after the plugin's sign-out")
    }

    /// AD-5. A sign-out through the client's `.default` is seen by the plugin after a relaunch.
    ///
    /// - Given: the plugin configured with nothing stored, and `alice` signed in through a client on `.default`
    /// - When:
    ///    - the client signs out, and is released
    ///    - the plugin is reset and configured again, as at a relaunch, and fetches its session
    /// - Then:
    ///    - the client's sign-out is `.complete`, and signed out locally
    ///    - the plugin's record is kept as the signed-out record, `{"noCredentials":{}}`, which every plugin
    ///      release reads as signed out, and the sidecar is kept
    ///    - the listing with signed-out rows shows `.default` as a signed-out row naming alice, from the sidecar
    ///    - the plugin reports signed out
    ///
    func testClientSignOutIsSeenByThePlugin() async throws {
        do {
            let client = try makeDefaultClient(UserPoolRequestRecorder())
            let signIn = try await client.signIn(username: alice.username, password: alice.password)
            guard case .done = signIn.nextStep else {
                return XCTFail("alice did not sign in through the client")
            }

            let signOut = await client.signOut()

            XCTAssertTrue(signOut == .complete, "the client's sign-out did not complete")
            XCTAssertTrue(signOut.signedOutLocally, "the client's sign-out left alice signed in")
            let state = await client.currentSessionState()
            XCTAssertTrue(state == .signedOut, "`.default` is not signed out")
        }
        try await InteropEnvironment.waitUntilReleased(.default)
        XCTAssertEqual(records(), "plugin: present, sidecar: present, leftover: absent", "the client's sign-out")
        let record = try XCTUnwrap(row(pluginAccount), "the client's sign-out deleted the plugin's record")
        XCTAssertTrue(PluginRecordSummary.isSignedOut(record), "the client's sign-out did not write the signed-out record")
        let listed = try await AmplifyCognitoClient.storedSessions(configuration: configuration, includingSignedOut: true)
        let defaultRow = try XCTUnwrap(listed.first { $0.sessionId == .default }, "`.default`'s signed-out row is not listed")
        XCTAssertEqual(defaultRow.kind, SessionKind.signedOut)
        XCTAssertTrue(defaultRow.username == alice.username, "`.default`'s signed-out row does not name alice")

        try await relaunchPlugin()

        let session = try await Amplify.Auth.fetchAuthSession()
        XCTAssertFalse(session.isSignedIn, "the plugin is still signed in after the client's sign-out")
    }

    /// AD-6. A refresh through the client's `.default` is what a relaunched plugin holds.
    ///
    /// - Given: the plugin configured with nothing stored, and `alice` signed in through a client on `.default`
    /// - When:
    ///    - the client force-refreshes, and is released
    ///    - the plugin is reset and configured again, as at a relaunch, and fetches its session
    /// - Then:
    ///    - the client's refresh minted a new access token, and wrote it to the shared record
    ///    - the relaunched plugin is signed in as alice and holds the client's refreshed access token, not the
    ///      one the sign-in received
    ///
    func testClientRefreshIsSeenByARelaunchedPlugin() async throws {
        let signedInToken: String
        let refreshedToken: String
        do {
            let client = try makeDefaultClient(UserPoolRequestRecorder())
            let signIn = try await client.signIn(username: alice.username, password: alice.password)
            guard case .done = signIn.nextStep else {
                return XCTFail("alice did not sign in through the client")
            }
            signedInToken = try await client.userPoolTokenProvider.accessToken()
            refreshedToken = try await client.fetchAuthSession(options: .init(forceRefresh: true)).userPoolTokensResult.get().accessToken
            XCTAssertTrue(refreshedToken != signedInToken, "the client's forced refresh did not mint a new token")
        }
        try await InteropEnvironment.waitUntilReleased(.default)

        try await relaunchPlugin()

        let session = try await Amplify.Auth.fetchAuthSession()
        XCTAssertTrue(session.isSignedIn, "the relaunched plugin does not see the client's login")
        let pluginToken = try await pluginAccessToken()
        XCTAssertTrue(pluginToken == refreshedToken, "the relaunched plugin does not hold the client's refreshed tokens")
    }

    /// AD-7. The plugin signs out a login the client signed in, and the client's next `.default` is signed out, with
    /// a signed-out row that names the user.
    ///
    /// - Given: `alice` signed in through a client on `.default` (so the sidecar names her), then released, and the
    ///   plugin relaunched, so it holds her
    /// - When:
    ///    - the plugin signs out
    ///    - a new client on `.default` is created
    /// - Then:
    ///    - the plugin's sign-out is `.complete`, and deletes the shared record; the client's sidecar stays
    ///    - the new client reads `.signedOut`, with no request
    ///    - the listing with signed-out rows shows `.default` as a signed-out row naming alice, from the sidecar
    ///
    func testPluginSignOutOfTheClientsLoginIsSeenByTheClient() async throws {
        do {
            let client = try makeDefaultClient(UserPoolRequestRecorder())
            let signIn = try await client.signIn(username: alice.username, password: alice.password)
            guard case .done = signIn.nextStep else {
                return XCTFail("alice did not sign in through the client")
            }
        }
        try await InteropEnvironment.waitUntilReleased(.default)
        try await relaunchPlugin()
        let user = try await Amplify.Auth.getCurrentUser()
        XCTAssertTrue(user.username == alice.username, "the relaunched plugin does not hold alice")

        let signOut = await Amplify.Auth.signOut()

        guard let pluginSignOut = signOut as? AWSCognitoSignOutResult, case .complete = pluginSignOut else {
            return XCTFail("the plugin's sign-out did not complete")
        }
        XCTAssertEqual(records(), "plugin: absent, sidecar: present, leftover: absent", "the plugin's sign-out")
        do {
            let recorder = UserPoolRequestRecorder()
            let client = try makeDefaultClient(recorder)
            let state = await client.currentSessionState()
            XCTAssertTrue(state == .signedOut, "`.default` did not see the plugin's sign-out")
            XCTAssertEqual(recorder.operations, [], "the signed-out `.default` made user pool requests")
        }
        try await InteropEnvironment.waitUntilReleased(.default)
        let listed = try await AmplifyCognitoClient.storedSessions(configuration: configuration, includingSignedOut: true)
        let defaultRow = try XCTUnwrap(listed.first { $0.sessionId == .default }, "`.default`'s signed-out row is not listed")
        XCTAssertEqual(defaultRow.kind, SessionKind.signedOut)
        XCTAssertTrue(defaultRow.username == alice.username, "`.default`'s signed-out row does not name alice")
    }

    /// AD-8. The client's `.default` signs out a login the plugin signed in, and a relaunched plugin is signed out.
    ///
    /// - Given: `alice` signed in through the plugin, so the shared record is the plugin's and no sidecar exists
    /// - When:
    ///    - a client on `.default` restores her and signs out, and is released
    ///    - the plugin is reset and configured again, as at a relaunch, and fetches its session
    /// - Then:
    ///    - the client's sign-out is `.complete`, and signed out locally
    ///    - the shared record is the signed-out record, `{"noCredentials":{}}`, and the sidecar now names alice
    ///    - the relaunched plugin reports signed out
    ///
    func testClientSignOutOfThePluginsLoginIsSeenByThePlugin() async throws {
        let signIn = try await Amplify.Auth.signIn(username: alice.username, password: alice.password)
        XCTAssertTrue(signIn.isSignedIn, "alice did not sign in through the plugin")
        do {
            let client = try makeDefaultClient(UserPoolRequestRecorder())
            try await assertSignedInAsAlice(client)

            let signOut = await client.signOut()

            XCTAssertTrue(signOut == .complete, "the client's sign-out did not complete")
            XCTAssertTrue(signOut.signedOutLocally, "the client's sign-out left alice signed in")
        }
        try await InteropEnvironment.waitUntilReleased(.default)
        XCTAssertEqual(records(), "plugin: present, sidecar: present, leftover: absent", "the client's sign-out")
        let record = try XCTUnwrap(row(pluginAccount), "the client's sign-out deleted the plugin's record")
        XCTAssertTrue(PluginRecordSummary.isSignedOut(record), "the client's sign-out did not write the signed-out record")
        // The record holds no user now, so the signed-out row's username is the sidecar's.
        let listed = try await AmplifyCognitoClient.storedSessions(configuration: configuration, includingSignedOut: true)
        let defaultRow = listed.first { $0.sessionId == .default }
        XCTAssertTrue(defaultRow?.kind == .signedOut, "`.default` is not listed as a signed-out row")
        XCTAssertTrue(defaultRow?.username == alice.username, "the sidecar does not name alice")

        try await relaunchPlugin()

        let session = try await Amplify.Auth.fetchAuthSession()
        XCTAssertFalse(session.isSignedIn, "the relaunched plugin is still signed in after the client's sign-out")
    }

    // MARK: - Helpers

    private func configurePlugin() throws {
        try Amplify.add(plugin: AWSCognitoAuthPlugin())
        try Amplify.configure(with: .data(InteropEnvironment.outputsData()))
    }

    /// A new plugin over the same keychain, as at the app's next launch: the plugin reads its record when it is
    /// configured, and keeps its tokens in memory after that.
    private func relaunchPlugin() async throws {
        await Amplify.reset()
        try configurePlugin()
    }

    private func makeDefaultClient(_ recorder: UserPoolRequestRecorder) throws -> AmplifyCognitoClient {
        try AmplifyCognitoClient(
            configuration: configuration,
            options: .init(sessionId: .default, configureUserPoolClient: recorder.configureUserPoolClient)
        )
    }

    private func assertSignedInAsAlice(
        _ client: AmplifyCognitoClient,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        let state = await client.currentSessionState()
        guard case .signedIn(let user) = state else {
            XCTFail("`.default` is not signed in", file: file, line: line)
            return
        }
        XCTAssertTrue(user.username == alice.username, "`.default` is signed in as another user", file: file, line: line)
    }

    /// The plugin's current access token, optionally after a forced refresh. Never printed.
    private func pluginAccessToken(forceRefresh: Bool = false) async throws -> String {
        let session = try await Amplify.Auth.fetchAuthSession(options: .init(forceRefresh: forceRefresh))
        let provider = try XCTUnwrap(session as? AuthCognitoTokensProvider, "the plugin's session has no tokens")
        return try provider.getCognitoTokens().get().accessToken
    }

    /// Which of `.default`'s items exist, by role: the plugin's record (`.default`'s session record), the
    /// sidecar, and the development leftover no build writes.
    private func records() -> String {
        let accounts = Set(RealKeychain.rows(service: SessionRecordStore.unsharedService).map(\.account))
        func presence(_ account: String) -> String {
            accounts.contains(account) ? "present" : "absent"
        }
        return "plugin: \(presence(pluginAccount)), sidecar: \(presence(sidecarAccount)), leftover: \(presence(leftoverAccount))"
    }

    /// The raw `kSecValueData` of `account` in the session service, in any entitled group, or `nil` if it
    /// is absent. Fails the test if the account is in more than one group. Compared, never printed.
    private func row(_ account: String, file: StaticString = #filePath, line: UInt = #line) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: SessionRecordStore.unsharedService,
            kSecAttrAccount as String: account,
            kSecUseDataProtectionKeychain as String: true,
            kSecReturnAttributes as String: true,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let items = result as? [[String: Any]] else {
            XCTAssertEqual(status, errSecItemNotFound, "reading a record: \(RealKeychain.describe(status))", file: file, line: line)
            return nil
        }
        XCTAssertEqual(items.count, 1, "a record is stored in more than one group", file: file, line: line)
        return items.first?[kSecValueData as String] as? Data
    }

    /// The `CredentialsError` case `operation` throws, by name; fails the test if it returns or throws
    /// anything else.
    private func credentialsError(
        _ what: String,
        file: StaticString = #filePath,
        line: UInt = #line,
        _ operation: () async throws -> some Any
    ) async -> String? {
        do {
            _ = try await operation()
            XCTFail("\(what) should have thrown", file: file, line: line)
        } catch let error as CredentialsError {
            switch error {
            case .notSignedIn: return "notSignedIn"
            case .sessionExpired: return "sessionExpired"
            case .storageUnavailable: return "storageUnavailable"
            case .notConfigured: return "notConfigured"
            case .unknown: return "unknown"
            }
        } catch {
            XCTFail("\(what) should throw a CredentialsError, got \(type(of: error))", file: file, line: line)
        }
        return nil
    }
}
