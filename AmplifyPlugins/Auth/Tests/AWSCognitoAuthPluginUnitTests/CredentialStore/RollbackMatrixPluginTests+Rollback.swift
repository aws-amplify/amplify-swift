//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyKeychainTestCommon
import AWSCognitoIdentityProvider
import AWSPluginsCore
import Foundation
import InternalAmplifyKeychain
import XCTest
@testable import Amplify
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient
@testable import AWSCognitoAuthPlugin
@testable import InternalAWSCognitoAuth

/// The rollback rows, the plugin's side: rotation, roll-forward, mixed binaries, named sessions and a
/// newer sidecar, each across the `.released` and `.current` plugin binaries. The sign-out rows are in
/// `RollbackMatrixPluginTests+SignOut.swift`.
///
/// Where a row runs the client as an app does, it is `ClientOverKeychain`: a real `AmplifyCognitoClient` over the
/// row's keychain, and the plugin build of the same app is configured with `AuthConfiguration(client:)` of the
/// client's configuration. Cognito's refresh-token rotation is one `RotatingRefreshTokens` shared by every binary
/// of the row, so a binary that refreshed with a token another binary rotated away is refused, as on the service.
extension RollbackMatrixPluginTests {

    // MARK: - Refresh-token rotation

    /// Rotation rollback: the plugin is now signed in on the token the client rotated (the checklist's row 1)
    ///
    /// - Given: Refresh-token rotation on; alice signs in through the client on `.default`, and the client refreshes,
    ///   rotating her refresh token
    /// - When:
    ///    - The app rolls back to each plugin binary, which reads the keychain and then refreshes
    /// - Then:
    ///    - Each reads the rotated token; its refresh sends it and succeeds, signed in with tokens, and no refresh is
    ///      refused with `RefreshTokenReuseException`
    ///    - No plugin reads a client record
    ///
    func testMatrix_rotationRollback_isNowSignedIn() async throws {
        for binary in RollbackPluginBinary.allCases {
            resetKeychain()
            let cognito = RotatingRefreshTokens(live: "refresh-alice")
            let clients = ClientOverKeychain(keychain: keychain)
            clients.script(userPool: ClientOverKeychain.userPool(signingIn: "alice", refresh: { input in
                try cognito.refresh(input, username: "alice", rotatingTo: "rotated-by-the-client")
            }))
            var client: AmplifyCognitoClient? = try clients.client()
            try await signInThroughTheClient(XCTUnwrap(client))
            _ = try await client?.fetchAuthSession(options: .init(forceRefresh: true))
            client = nil
            await clients.waitForBaseline()

            XCTAssertEqual(try pluginStore(binary, clientPluginConfiguration).retrieveCredential().refreshToken, "rotated-by-the-client", "\(binary)")
            let plugin = makePluginOverKeychain(
                binary.keychainStore(over: pluginKeychain),
                authConfiguration: clientPluginConfiguration,
                userPool: MockIdentityProvider(mockGetTokensFromRefreshTokenResponse: { input in
                    try cognito.refresh(input, username: "alice", rotatingTo: "rotated-by-the-plugin")
                })
            )
            let session = try await plugin.fetchAuthSession(options: AuthFetchSessionRequest.Options(forceRefresh: true))

            XCTAssertTrue(session.isSignedIn, "\(binary)")
            let tokens = try XCTUnwrap(session as? AuthCognitoTokensProvider, "\(binary)").getCognitoTokens()
            XCTAssertEqual(try tokens.get().refreshToken, "rotated-by-the-plugin", "\(binary)")
            XCTAssertEqual(cognito.sent, ["refresh-alice", "rotated-by-the-client"], "\(binary)")
            XCTAssertEqual(cognito.refused, [], "\(binary)")
            XCTAssertEqual(pluginKeychain.hiddenReadAccounts, [], "\(binary)")
        }
    }

    /// Roll-forward after a plugin rotation: the client resumes on the newest token
    ///
    /// - Given: Rotation on; alice signed in through the client; then each plugin binary in turn refreshes, rotating
    ///   her refresh token, so the plugin rotated last
    /// - When:
    ///    - The app rolls forward to the client, which restores `.default` and refreshes
    /// - Then:
    ///    - The client is signed in as alice and refreshes with the token the plugin rotated last; the refresh
    ///      succeeds, so no `sessionExpired`, and no refresh is ever refused
    ///    - The shared record holds the client's newest token
    ///
    func testMatrix_rollForwardAfterAPluginRotation_resumesOnTheNewestToken() async throws {
        let cognito = RotatingRefreshTokens(live: "refresh-alice")
        let clients = ClientOverKeychain(keychain: keychain)
        clients.script(userPool: ClientOverKeychain.userPool(signingIn: "alice"))
        var client: AmplifyCognitoClient? = try clients.client()
        try await signInThroughTheClient(XCTUnwrap(client))
        client = nil
        await clients.waitForBaseline()

        for binary in RollbackPluginBinary.allCases {
            let plugin = makePluginOverKeychain(
                binary.keychainStore(over: pluginKeychain),
                authConfiguration: clientPluginConfiguration,
                userPool: MockIdentityProvider(mockGetTokensFromRefreshTokenResponse: { input in
                    try cognito.refresh(input, username: "alice", rotatingTo: "rotated-by-the-\(binary)-plugin")
                })
            )
            let session = try await plugin.fetchAuthSession(options: AuthFetchSessionRequest.Options(forceRefresh: true))
            XCTAssertTrue(session.isSignedIn, "\(binary)")
        }
        XCTAssertEqual(try storedRefreshToken(), "rotated-by-the-current-plugin")

        clients.script(userPool: ClientOverKeychain.userPool(refresh: { input in
            try cognito.refresh(input, username: "alice", rotatingTo: "rotated-by-the-client")
        }))
        let rolledForward = try clients.client()
        let state = await rolledForward.currentSessionState()
        let session = try await rolledForward.fetchAuthSession(options: .init(forceRefresh: true))

        XCTAssertEqual(state, .signedIn(AuthClientUser(username: "alice", userId: "alice-sub")))
        XCTAssertEqual(try session.userPoolTokensResult.get().refreshToken, "rotated-by-the-client")
        XCTAssertEqual(cognito.sent, ["refresh-alice", "rotated-by-the-released-plugin", "rotated-by-the-current-plugin"])
        XCTAssertEqual(cognito.refused, [])
        XCTAssertEqual(try storedRefreshToken(), "rotated-by-the-client")
        XCTAssertEqual(pluginKeychain.hiddenReadAccounts, [])
    }

    // MARK: - Mixed binaries

    /// Mixed binaries at rest: an extension on a plugin binary, the app on the client
    ///
    /// - Given: One keychain under an app that runs the client's `.default` and an extension that runs a plugin binary
    /// - When:
    ///    - The app signs alice in and quits; the extension launches, then refreshes, rotating her token, and quits;
    ///      the app relaunches and refreshes, then signs out; the extension relaunches
    /// - Then:
    ///    - Each launch sees the other side's latest login: the extension reads the app's alice; the app restores
    ///      alice with the extension's rotated token, which its refresh sends and Cognito accepts; the extension
    ///      then reads the app's sign-out
    ///
    func testMatrix_mixedBinaries_extensionOnThePluginAppOnTheClient_atRest() async throws {
        for binary in RollbackPluginBinary.allCases {
            resetKeychain()
            let cognito = RotatingRefreshTokens(live: "refresh-alice")
            let app = ClientOverKeychain(keychain: keychain)
            app.script(userPool: ClientOverKeychain.userPool(signingIn: "alice"))
            var client: AmplifyCognitoClient? = try app.client()
            try await signInThroughTheClient(XCTUnwrap(client))
            client = nil
            await app.waitForBaseline()
            let appLogin = try XCTUnwrap(keychain.value(service: pluginKeychainService, account: clientPluginAccount))

            XCTAssertEqual(try pluginStore(binary, clientPluginConfiguration).retrieveCredential(), try decoded(appLogin), "\(binary)")
            let fetched = try await makePluginOverKeychain(
                binary.keychainStore(over: pluginKeychain),
                authConfiguration: clientPluginConfiguration,
                userPool: MockIdentityProvider(mockGetTokensFromRefreshTokenResponse: { input in
                    try cognito.refresh(input, username: "alice", rotatingTo: "rotated-by-the-extension")
                })
            ).fetchAuthSession(options: AuthFetchSessionRequest.Options(forceRefresh: true))
            XCTAssertTrue(fetched.isSignedIn, "\(binary)")

            app.script(userPool: ClientOverKeychain.userPool(refresh: { input in
                try cognito.refresh(input, username: "alice", rotatingTo: "rotated-by-the-app")
            }))
            client = try app.client()
            let relaunched = await client?.currentSessionState()
            let session = try await client?.fetchAuthSession(options: .init(forceRefresh: true))
            let signedOut = await client?.signOut()
            client = nil
            await app.waitForBaseline()

            XCTAssertEqual(relaunched, .signedIn(AuthClientUser(username: "alice", userId: "alice-sub")), "\(binary)")
            XCTAssertEqual(try session?.userPoolTokensResult.get().refreshToken, "rotated-by-the-app", "\(binary)")
            XCTAssertEqual(cognito.sent, ["refresh-alice", "rotated-by-the-extension"], "\(binary)")
            XCTAssertEqual(cognito.refused, [], "\(binary)")
            XCTAssertEqual(signedOut, .complete, "\(binary)")
            XCTAssertEqual(try pluginStore(binary, clientPluginConfiguration).retrieveCredential(), .noCredentials, "\(binary)")
            XCTAssertEqual(pluginKeychain.hiddenReadAccounts, [], "\(binary)")
        }
    }

    // MARK: - Named sessions

    /// Named sessions disappear on a rollback to a plugin-only release and return on roll-forward, unless a
    /// released plugin's access-group transition wipes them
    ///
    /// - Given: Two named client sessions, work and home, and no `.default` login
    /// - When:
    ///    - The app rolls back to each plugin binary, which retrieves, signs bob in and out; then rolls forward to the
    ///      client
    ///    - Then each binary's access-group transition without migration runs over the same items: the released
    ///      one's service-wide `_removeAll()`, emulated by `removeAll()` on its view, and the current one's own
    /// - Then:
    ///    - Each plugin is signed out, reads no client record, and never writes or deletes one
    ///    - Rolled forward, the client lists work and home again, with their bytes unchanged
    ///    - After the transition, the current plugin's scoped wipe has kept them, and the released one has
    ///      deleted them: the client lists neither (a documented caveat)
    ///
    func testMatrix_namedSessionsDisappearOnRollbackAndReturnOnRollForward() async throws {
        for binary in RollbackPluginBinary.allCases {
            resetKeychain()
            let work = try SessionID.named("work")
            let home = try SessionID.named("home")
            try RollbackMatrixBytes.writeClientRecord(RollbackMatrixBytes.pluginPayload("userPoolOnly"), for: work, in: keychain, pools: pools)
            try RollbackMatrixBytes.writeClientRecord(RollbackMatrixBytes.pluginPayload("identityPoolOnly"), for: home, in: keychain, pools: pools)
            let namedAccounts = [work, home].map { SessionRecordKey.account(for: $0, in: pools, kind: .session) }
            let namedBytes = namedAccounts.map { keychain.value(service: pluginKeychainService, account: $0) }

            let store = makeStore(binary)
            XCTAssertThrowsError(try store.retrieveCredential(), "\(binary)") { error in
                XCTAssertEqual(error as? EngineCredentialStoreError, .itemNotFound)
            }
            try store.saveCredential(LongLivedCredentials.userPoolAndIdentityPool(username: "bob"))
            try store.deleteCredential()
            XCTAssertEqual(pluginKeychain.hiddenReadAccounts, [], "\(binary)")
            XCTAssertEqual(keychain.mutatedClientAccounts, [], "\(binary)")

            let client = RollbackMatrixBytes.clientStore(in: keychain, pools: pools)
            XCTAssertEqual(try Set(client.storedSessions().map(\.sessionId)), [home, work], "\(binary)")
            XCTAssertEqual(namedAccounts.map { keychain.value(service: pluginKeychainService, account: $0) }, namedBytes, "\(binary)")

            try accessGroupTransitionWithoutMigration(binary)
            switch binary {
            case .released:
                XCTAssertEqual(try client.storedSessions(includingSignedOut: true), [], "\(binary)")
                XCTAssertEqual(try client.read(work), .absent, "\(binary)")
            case .current:
                XCTAssertEqual(try Set(client.storedSessions().map(\.sessionId)), [home, work], "\(binary)")
            }
        }
    }

    // MARK: - A newer schema

    /// A newer schema's `.default` sidecar is shown as absent and never overwritten (replaces matrix 03 row 10)
    ///
    /// - Given: The plugin's record for alice; beside it a schema-2 `$default.meta` holding a label, and a named
    ///   session's record under an `amplify.2.` account
    /// - When:
    ///    - The client reads and lists `.default`, tries to label it, commits a refresh over it and signs it out;
    ///      then each plugin binary retrieves, saves and deletes its record
    /// - Then:
    ///    - The client shows no label, refuses to label it (`.unreadableSidecar`), and both writes commit, the
    ///      sign-out writing `{"noCredentials":{}}`
    ///    - Neither item is ever written or deleted, and no plugin reads a client record
    ///
    func testMatrix_newerSchemaSidecar_isLeftAlone() throws {
        let alice = try RollbackMatrixBytes.pluginPayload("userPoolAndIdentityPool")
        try RollbackMatrixBytes.put(alice, pluginAccount, in: keychain)
        let newerSidecar = Data(#"{"label":"Future","lastWriteTimestamp":1,"schemaVersion":2,"userId":"fixture-sub","username":"fixture-user"}"#.utf8)
        try RollbackMatrixBytes.put(newerSidecar, sidecarAccount, in: keychain)
        let versionTwo = Data(#"{"schemaVersion":2,"generation":1,"lastWriteTimestamp":0,"kind":"passkey","credentials":"e30="}"#.utf8)
        let futureAccount = "amplify.2.\(Defaults.userPoolId).\(Defaults.identityPoolId).work.session"
        try RollbackMatrixBytes.put(versionTwo, futureAccount, in: keychain)
        let client = RollbackMatrixBytes.clientStore(in: keychain, pools: pools)

        guard case .record(let held) = try client.read(.default) else {
            return XCTFail("The client should read alice")
        }
        XCTAssertNil(held.record.label)
        XCTAssertEqual(try client.storedSessions(), [
            StoredSession(sessionId: .default, label: nil, username: "fixture-user", kind: .userPoolAndIdentityPool)
        ])
        guard case .unreadableSidecar = try client.setDefaultLabel("Mine") else {
            return XCTFail("A newer sidecar must not be labelled over")
        }
        var refreshed = held.record
        refreshed.credentials = try RollbackMatrixBytes.replacingRefreshToken(in: alice, with: "rotated-by-the-client")
        XCTAssertTrue(try client.write(refreshed, for: .default, expecting: held.version).didCommit)
        _ = try client.signOut(.default)
        XCTAssertEqual(keychain.value(service: pluginKeychainService, account: pluginAccount), try JSONEncoder().encode(AmplifyCredentials.noCredentials))
        XCTAssertFalse(keychain.mutatedAccounts.contains(sidecarAccount))
        XCTAssertFalse(keychain.mutatedAccounts.contains(futureAccount))

        for binary in RollbackPluginBinary.allCases {
            try RollbackMatrixBytes.put(alice, pluginAccount, in: keychain)
            let store = makeStore(binary)
            XCTAssertEqual(try store.retrieveCredential(), try decoded(alice), "\(binary)")
            try store.saveCredential(LongLivedCredentials.userPoolAndIdentityPool())
            try store.deleteCredential()
            XCTAssertFalse(keychain.mutatedAccounts.contains(sidecarAccount), "\(binary)")
            XCTAssertFalse(keychain.mutatedAccounts.contains(futureAccount), "\(binary)")
        }

        XCTAssertEqual(keychain.value(service: pluginKeychainService, account: sidecarAccount), newerSidecar)
        XCTAssertEqual(keychain.value(service: pluginKeychainService, account: futureAccount), versionTwo)
        XCTAssertEqual(pluginKeychain.hiddenReadAccounts, [])
    }
}
