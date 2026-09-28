//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient
import AWSCognitoIdentityProvider
import XCTest

/// Signing out a saved session nobody holds, over the live revoker. Each test checks
/// what Cognito itself thinks of the refresh token afterwards, through a plain SDK client.
final class SignOutTests: ClientIntegrationTestCase {

    private var configuration: AuthClientConfiguration!
    private var users: SandboxUsers!

    override func setUp() async throws {
        try await super.setUp()
        configuration = try IntegrationTestEnvironment.configuration()
        users = try IntegrationTestEnvironment.users()
    }

    /// Signing out revokes the refresh token at Cognito, not only on this device (SO-1).
    ///
    /// - Given: alice signed in, her refresh token captured from the session
    /// - When:
    ///    - `signOut()`
    /// - Then:
    ///    - it returns `.complete`, and the session is `.signedOut`
    ///    - a raw `GetTokensFromRefreshToken` with the captured token, sent through the client's own
    ///      `getUserPoolClient()`, fails with `NotAuthorizedException`
    ///
    func testSignOutRevokesTheRefreshTokenServerSide() async throws {
        let sessionId = try makeSessionID("alice")
        let client = try AmplifyCognitoClient(configuration: configuration, options: .init(sessionId: sessionId))
        _ = try await client.signIn(username: users.alice.username, password: users.alice.password)
        let refreshToken = try await client.fetchAuthSession().userPoolTokensResult.get().refreshToken

        let result = try await client.signOut()

        XCTAssertEqual(result, .complete)
        let state = await client.currentSessionState()
        XCTAssertState(state, .signedOut)
        let userPool = try XCTUnwrap(client.getUserPoolClient())
        let appClientId = try XCTUnwrap(configuration.userPool).appClientId
        do {
            _ = try await userPool.getTokensFromRefreshToken(input: GetTokensFromRefreshTokenInput(
                clientId: appClientId,
                refreshToken: refreshToken
            ))
            XCTFail("Cognito accepted the refresh token of a signed-out session")
        } catch {
            XCTAssertTrue(error is NotAuthorizedException, "expected NotAuthorizedException, got \(type(of: error))")
        }
    }

    /// `signOutStoredSession` revokes a saved session's refresh token with no client live, and keeps
    /// its row (SO-2; design §14.3).
    ///
    /// - Given: alice signed in on a session, its refresh token captured, then every handle dropped
    /// - When:
    ///    - `signOutStoredSession(sessionId:configuration:)`
    /// - Then:
    ///    - it returns `.complete`
    ///    - the row is kept, signed out (`kind == .signedOut`, still naming alice), and hidden by default
    ///    - Cognito rejects the captured refresh token with `NotAuthorizedException`
    ///    - the keychain holds the same items as before, in every service and group, and every item but
    ///      the session's own record has the modification date and data it had before
    ///
    func testSignOutStoredSessionRevokesWithoutALiveClient() async throws {
        let raw = try RawUserPool()
        let sessionId = try makeSessionID("alice")
        let refreshToken = try await signInAndDrop(sessionId)
        try await SessionCleanup.waitUntilReleased([sessionId])
        let before = try KeychainSnapshot.versions()

        let result = try await AmplifyCognitoClient.signOutStoredSession(sessionId: sessionId, configuration: configuration)

        XCTAssertEqual(result, .complete)
        let listed = try await AmplifyCognitoClient.storedSessions(configuration: configuration, includingSignedOut: true)
        let row = try XCTUnwrap(listed.first { $0.sessionId == sessionId }, "the signed-out row is kept")
        XCTAssertEqual(row.kind, SessionKind.signedOut)
        XCTAssertEqual(row.username, "alice")
        let visible = try await AmplifyCognitoClient.storedSessions(configuration: configuration)
        XCTAssertFalse(visible.contains { $0.sessionId == sessionId }, "a signed-out row is hidden by default")
        assertNotAuthorized(await raw.refresh(refreshToken))
        let after = try KeychainSnapshot.versions()
        let added = Set(after.keys).subtracting(before.keys)
        let removed = Set(before.keys).subtracting(after.keys)
        XCTAssertTrue(added.isEmpty, "the sign-out added \(added)")
        XCTAssertTrue(removed.isEmpty, "the sign-out removed \(removed)")
        let sessionRecord = SessionRecordKey.account(for: sessionId, in: configuration.poolNamespace, kind: .session)
        XCTAssertTrue(after.keys.contains { $0.account == sessionRecord }, "the session's record is kept")
        let rewritten = before.filter { item, version in item.account != sessionRecord && after[item] != version }.keys
        XCTAssertTrue(rewritten.isEmpty, "the sign-out rewrote \(Array(rewritten)), not only the session's record")
    }

    /// `purgeStoredSession` is local only: the row goes, and the refresh token still works server-side
    /// (SO-3; design §14.3).
    ///
    /// - Given: alice signed in on a session, its refresh token captured, then every handle dropped
    /// - When:
    ///    - `purgeStoredSession(sessionId:configuration:)`
    /// - Then:
    ///    - the row is gone from both listings, and the keychain holds no account for the session
    ///    - Cognito still refreshes with the captured token (documented: purging does not revoke). The
    ///      test revokes it afterwards
    ///
    func testPurgeStoredSessionIsLocalOnly() async throws {
        let raw = try RawUserPool()
        let sessionId = try makeSessionID("alice")
        let refreshToken = try await signInAndDrop(sessionId)
        addTeardownBlock { try await raw.revoke(refreshToken) }
        try await SessionCleanup.waitUntilReleased([sessionId])

        try await AmplifyCognitoClient.purgeStoredSession(sessionId: sessionId, configuration: configuration)

        let listed = try await AmplifyCognitoClient.storedSessions(configuration: configuration, includingSignedOut: true)
        XCTAssertFalse(listed.contains { $0.sessionId == sessionId }, "the purged row is gone")
        let accounts = try IntegrationTestEnvironment.rawKeychainAccounts()
        XCTAssertFalse(accounts.contains { $0.contains(".\(sessionId.stringValue).") }, "no keychain account is left for the session")
        let refreshed = await raw.refresh(refreshToken)
        if case .failure(let error) = refreshed {
            XCTFail("a purged session's refresh token should still refresh: \(type(of: error))")
        }
    }

    /// Signs alice in on `sessionId` through a client that is released when this returns, and returns
    /// the session's refresh token.
    private func signInAndDrop(_ sessionId: SessionID) async throws -> String {
        let client = try AmplifyCognitoClient(configuration: configuration, options: .init(sessionId: sessionId))
        _ = try await client.signIn(username: users.alice.username, password: users.alice.password)
        return try await client.fetchAuthSession().userPoolTokensResult.get().refreshToken
    }

    private func assertNotAuthorized(
        _ result: Result<String, Error>,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        switch result {
        case .success:
            XCTFail("Cognito accepted a refresh token that should be revoked", file: file, line: line)
        case .failure(let error):
            XCTAssertTrue(error is NotAuthorizedException, "expected NotAuthorizedException, got \(type(of: error))", file: file, line: line)
        }
    }
}
