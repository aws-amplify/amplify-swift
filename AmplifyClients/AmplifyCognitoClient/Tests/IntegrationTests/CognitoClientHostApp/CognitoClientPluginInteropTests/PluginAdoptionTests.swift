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

/// Adoption of a session the plugin wrote (AD-1 and AD-2).
///
/// `.default` reads the plugin's record in place until the client has a record of its own, and
/// `completeAdoption()` migrates it. From then on the client's record is authoritative: later plugin
/// writes, which land on the plugin's own key again, are never read. No other session ever reads the
/// plugin's record.
///
/// Signs `alice`, a fresh user each test signs up, in through the plugin against the default backend.
/// Tokens, subs and pool identifiers are compared with booleans and never printed; keychain rows are
/// described by role (`plugin`, `own`), never by account name, because account names carry the pool
/// identifiers.
final class PluginAdoptionTests: XCTestCase {

    private var configuration: AuthClientConfiguration!
    /// The plugin's record, `amplify.<ns>.session`: the key `.default` reads through.
    private var pluginAccount = ""
    /// `.default`'s own record, `amplify.1.<ns>.$default.session`.
    private var ownAccount = ""
    /// Named sessions a test created, purged at teardown.
    private var namedSessions: [SessionID] = []
    /// The test's own user (alice), signed up in `setUp` and deleted at teardown.
    private var alice: InteropUser!

    override func setUp() async throws {
        try await super.setUp()
        try InteropEnvironment.requireProvisioned()
        configuration = try AuthClientConfiguration(
            from: InteropEnvironment.outputsResource,
            bundle: InteropEnvironment.bundle
        )
        pluginAccount = SessionRecordKey.legacySessionAccount(in: configuration.poolNamespace)
        ownAccount = SessionRecordKey.account(for: .default, in: configuration.poolNamespace, kind: .session)
        // A run that stopped early may have left either record; this test must start from neither.
        try await AmplifyCognitoClient.purgeStoredSession(sessionId: .default, configuration: configuration)
        XCTAssertEqual(records(), "plugin: absent, own: absent", "setUp left a record")
        alice = try await InteropEnvironment.signUpFreshUser()
        try Amplify.add(plugin: AWSCognitoAuthPlugin())
        try Amplify.configure(with: .data(InteropEnvironment.data(forResource: InteropEnvironment.outputsResource)))
    }

    /// Signs the plugin out first (which revokes its refresh token), then purges every session the test
    /// touched, whatever failed, and deletes the test's user. Signs out only when Auth is configured: a throwing `setUp` leaves it
    /// unconfigured, and an unconfigured `Amplify.Auth` aborts the process.
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
            XCTAssertEqual(records(), "plugin: absent, own: absent", "tearDown left a record")
        }
        if let alice {
            await InteropEnvironment.deleteFreshUser(alice)
        }
        namedSessions = []
        try await super.tearDown()
    }

    /// AD-1. `.default` adopts the plugin's record at its first load only; later plugin writes are ignored.
    ///
    /// - Given: the plugin configured from the default backend's outputs and `alice` (a fresh user of the
    ///   test's own) signed in through it, so the plugin's record exists and `.default` has no record of its own
    /// - When:
    ///    - a client on `.default` is created, with a request recorder on its user pool client, and reads
    ///      its state and both providers
    ///    - `completeAdoption()` runs
    ///    - the client is released, the plugin force-refreshes (writing its record again), and a new
    ///      client on `.default` is created once the registry has released the first
    ///    - the plugin signs out and signs `alice` in again (writing a third record), and `.default` is
    ///      re-created once more
    /// - Then:
    ///    - the first client reads `.signedIn(alice)` with **0** user pool requests (read-through), its
    ///      access token is the plugin's, and its credentials provider resolves
    ///    - after `completeAdoption()`, `.default`'s own record exists and the plugin's is gone
    ///    - after the plugin's refresh, the plugin's record exists again, with new tokens; the re-created
    ///      client still reads `.signedIn(alice)` with the adopted token, not the plugin's new one, with
    ///      0 requests, and `.default`'s own record is byte-for-byte unchanged
    ///    - the same holds after the plugin's sign-out and second sign-in
    ///
    func testDefaultAdoptsThePluginRecordOnFirstLoadOnly() async throws {
        let signIn = try await Amplify.Auth.signIn(username: alice.username, password: alice.password)
        XCTAssertTrue(signIn.isSignedIn, "alice did not sign in through the plugin")
        let pluginToken = try await pluginAccessToken()
        XCTAssertEqual(records(), "plugin: present, own: absent", "the plugin's sign-in")
        let pluginRecord = try XCTUnwrap(row(pluginAccount), "the plugin wrote no record")

        // First load: read-through.
        let adopted: String
        do {
            let recorder = UserPoolRequestRecorder()
            let client = try makeDefaultClient(recorder)
            try await assertSignedInAsAlice(client)
            adopted = try await client.userPoolTokenProvider.accessToken()
            XCTAssertTrue(adopted == pluginToken, "`.default` did not read the plugin's tokens")
            let credentials = try await client.credentialsProvider.resolve()
            XCTAssertFalse(credentials.accessKeyId.isEmpty, "the credentials provider resolved empty credentials")
            XCTAssertEqual(recorder.operations, [], "the read-through made user pool requests")
            XCTAssertEqual(records(), "plugin: present, own: absent", "reading through wrote a record")
            XCTAssertTrue(row(pluginAccount) == pluginRecord, "reading through changed the plugin's record")

            try await client.completeAdoption()

            XCTAssertEqual(records(), "plugin: absent, own: present", "after completeAdoption()")
            try await assertSignedInAsAlice(client)
        }
        let ownRecord = try XCTUnwrap(row(ownAccount), "`.default` has no record of its own")
        try await InteropEnvironment.waitUntilReleased(.default)

        // A later plugin write: a forced refresh.
        let refreshed = try await pluginAccessToken(forceRefresh: true)
        XCTAssertTrue(refreshed != adopted, "the plugin's forced refresh did not mint a new token")
        XCTAssertEqual(records(), "plugin: present, own: present", "the plugin's refresh did not write its record again")
        try await assertDefaultKeepsItsOwnRecord(ownRecord, adopted: adopted, ignoring: refreshed)

        // Later plugin writes: a sign-out, then a new sign-in. With a client record present, the plugin's
        // sign-out writes its signed-out marker instead of deleting its record, and must leave
        // `.default`'s record alone.
        _ = await Amplify.Auth.signOut()
        let marker = try XCTUnwrap(row(pluginAccount), "the plugin's sign-out left no record")
        XCTAssertTrue(PluginRecordSummary.isSignedOutMarker(marker), "the plugin's sign-out did not write its signed-out marker")
        XCTAssertTrue(row(ownAccount) == ownRecord, "the plugin's sign-out changed `.default`'s record")
        let again = try await Amplify.Auth.signIn(username: alice.username, password: alice.password)
        XCTAssertTrue(again.isSignedIn, "alice did not sign in through the plugin again")
        let signedInAgain = try await pluginAccessToken()
        XCTAssertTrue(signedInAgain != adopted, "the plugin's second sign-in reused a token")
        XCTAssertEqual(records(), "plugin: present, own: present", "the plugin's second sign-in")
        try await assertDefaultKeepsItsOwnRecord(ownRecord, adopted: adopted, ignoring: signedInAgain)
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
    ///      `.default` has none of its own
    ///    - the saved-session listing does not show the named session; it shows `.default` as `alice`,
    ///      read through from the plugin's record
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
        XCTAssertNil(row(namedAccount), "the named session wrote a record")
        XCTAssertEqual(records(), "plugin: present, own: absent")
        let listed = try await AmplifyCognitoClient.storedSessions(configuration: configuration, includingSignedOut: true)
        XCTAssertFalse(listed.contains { $0.sessionId == sessionId }, "the named session is listed")
        let defaultRow = listed.first { $0.sessionId == .default }
        XCTAssertTrue(defaultRow?.username == alice.username, "`.default` is not listed as alice from the plugin's record")
    }

    // MARK: - Helpers

    private func makeDefaultClient(_ recorder: UserPoolRequestRecorder) throws -> AmplifyCognitoClient {
        try AmplifyCognitoClient(
            configuration: configuration,
            options: .init(sessionId: .default, configureUserPoolClient: recorder.configureUserPoolClient)
        )
    }

    /// Re-creates `.default` and checks it serves its own record: signed in as alice, with the adopted
    /// token and not `ignored`, no user pool request, and its record's bytes as `ownRecord`. Returns only
    /// once the registry has released it.
    private func assertDefaultKeepsItsOwnRecord(
        _ ownRecord: Data,
        adopted: String,
        ignoring ignored: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        do {
            let recorder = UserPoolRequestRecorder()
            let client = try makeDefaultClient(recorder)
            try await assertSignedInAsAlice(client, file: file, line: line)
            let token = try await client.userPoolTokenProvider.accessToken()
            XCTAssertTrue(token == adopted, "the re-created `.default` does not hold its own tokens", file: file, line: line)
            XCTAssertTrue(token != ignored, "the re-created `.default` read the plugin's later write", file: file, line: line)
            XCTAssertEqual(recorder.operations, [], "the re-created `.default` made user pool requests", file: file, line: line)
        }
        XCTAssertTrue(row(ownAccount) == ownRecord, "`.default`'s own record changed", file: file, line: line)
        try await InteropEnvironment.waitUntilReleased(.default)
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

    /// Which of the two records exist, by role.
    private func records() -> String {
        let accounts = Set(RealKeychain.rows(service: SessionRecordStore.unsharedService).map(\.account))
        func presence(_ account: String) -> String {
            accounts.contains(account) ? "present" : "absent"
        }
        return "plugin: \(presence(pluginAccount)), own: \(presence(ownAccount))"
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
