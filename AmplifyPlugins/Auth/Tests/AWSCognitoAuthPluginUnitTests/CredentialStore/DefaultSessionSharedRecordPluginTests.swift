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
import XCTest
@testable import Amplify
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient
@testable import AWSCognitoAuthPlugin
@testable import InternalAWSCognitoAuth

/// The Cognito client's `.default` and the whole plugin share one saved login: each
/// reads what the other last stored, over one keychain. The plugin runs as `configure(using:)` builds it
/// (`makePluginOverKeychain`); the client runs its real record store.
///
/// - Note: `@unchecked Sendable` so the test body can be captured by the `@Sendable` closures the
///   production API takes. `XCTestCase` is not `Sendable`, and each test runs alone.
final class DefaultSessionSharedRecordPluginTests: XCTestCase, @unchecked Sendable {

    private let pools = PoolNamespace.userPoolAndIdentityPool(userPoolId: Defaults.userPoolId, identityPoolId: Defaults.identityPoolId)
    private var pluginAccount: String { SessionRecordKey.pluginSessionAccount(in: pools) }

    private var keychain: InMemoryKeychain!
    private var pluginKeychain: InMemoryPluginKeychainStore!

    override func setUp() {
        super.setUp()
        keychain = InMemoryKeychain()
        pluginKeychain = InMemoryPluginKeychainStore(keychain: keychain)
    }

    override func tearDown() async throws {
        keychain = nil
        pluginKeychain = nil
        await Amplify.reset()
    }

    /// - Given: the client's `.default` signed in, with the plugin's frozen payload as its credentials
    /// - When:
    ///    - the plugin is configured over the same keychain and fetches its session
    /// - Then:
    ///    - it is signed in as that user, with that payload's tokens, and reads no client record
    ///
    func testPluginFetchAuthSession_afterAClientSignIn_isThatUser() async throws {
        let payload = try RollbackMatrixBytes.pluginPayload("userPoolAndIdentityPool")
        try RollbackMatrixBytes.writeClientRecord(payload, in: keychain, pools: pools)
        guard case .userPoolAndIdentityPool(let signedInData, _, _) = try JSONDecoder().decode(AmplifyCredentials.self, from: payload) else {
            return XCTFail("the fixture holds both pools")
        }
        let plugin = makePluginOverKeychain(pluginKeychain, userPool: MockIdentityProvider())

        let session = try await plugin.fetchAuthSession(options: AuthFetchSessionRequest.Options())

        XCTAssertTrue(session.isSignedIn)
        let tokens = try XCTUnwrap(session as? AuthCognitoTokensProvider).getCognitoTokens().get()
        XCTAssertEqual(tokens.idToken, signedInData.cognitoUserPoolTokens.idToken)
        XCTAssertEqual(try XCTUnwrap(session as? AuthCognitoIdentityProvider).getUserSub().get(), signedInData.userId)
        XCTAssertEqual(pluginKeychain.readAccounts.filter { $0.hasPrefix("amplify.1.") }, [])
    }

    /// - Given: the whole plugin over the keychain, signing bob in with `USER_PASSWORD_AUTH` against a mocked user pool
    /// - When:
    ///    - the client's `.default` reads its record
    /// - Then:
    ///    - it is bob's record, read in place, holding the credentials the plugin stored
    ///
    func testClientRestore_afterAPluginSignIn_isThatUser() async throws {
        let tokens = LongLivedCredentials.tokens(username: "bob", sub: "bob-sub")
        let plugin = makePluginOverKeychain(pluginKeychain, userPool: MockIdentityProvider(
            mockInitiateAuthResponse: { _ in
                InitiateAuthOutput(authenticationResult: .init(
                    accessToken: tokens.accessToken,
                    expiresIn: 3_600,
                    idToken: tokens.idToken,
                    refreshToken: tokens.refreshToken
                ))
            }
        ))

        let result = try await plugin.signIn(
            username: "bob",
            password: "password",
            options: AuthSignInRequest.Options(pluginOptions: AWSAuthSignInOptions(authFlowType: .userPassword))
        )

        XCTAssertTrue(result.isSignedIn)
        let stored = try XCTUnwrap(keychain.value(service: pluginKeychainService, account: pluginAccount))
        guard case .record(let read) = try RollbackMatrixBytes.clientStore(in: keychain, pools: pools).read(.default) else {
            return XCTFail("the client should read the plugin's record")
        }
        XCTAssertEqual(read.record.userId, "bob-sub")
        XCTAssertEqual(read.record.username, "bob")
        XCTAssertEqual(read.record.credentials, stored)
        XCTAssertEqual(read.version, .storedBytes(stored))
    }

    /// - Given: the client's `.default` signed in, and the whole plugin over the same keychain
    /// - When:
    ///    - the plugin signs out, and the client reads its record
    /// - Then:
    ///    - the plugin deleted its record, and the client reads `.default` as signed out, keeping its signed-out
    ///      row's last user from the sidecar
    ///
    func testClientRestore_afterAPluginSignOut_isSignedOut() async throws {
        let payload = try RollbackMatrixBytes.pluginPayload("userPoolAndIdentityPool")
        try RollbackMatrixBytes.writeClientRecord(payload, in: keychain, pools: pools)
        let plugin = makePluginOverKeychain(pluginKeychain, userPool: MockIdentityProvider(
            mockRevokeTokenResponse: { _ in RevokeTokenOutput() },
            mockGlobalSignOutResponse: { _ in GlobalSignOutOutput() }
        ))
        _ = try await plugin.fetchAuthSession(options: AuthFetchSessionRequest.Options())

        let result = await plugin.signOut()

        XCTAssertTrue(try XCTUnwrap(result as? AWSCognitoSignOutResult).signedOutLocally)
        XCTAssertNil(keychain.value(service: pluginKeychainService, account: pluginAccount))
        guard case .record(let read) = try RollbackMatrixBytes.clientStore(in: keychain, pools: pools).read(.default) else {
            return XCTFail("the sidecar keeps a signed-out row")
        }
        XCTAssertTrue(read.record.isSignedOut)
        XCTAssertEqual(read.record.username, "fixture-user")
        XCTAssertNil(read.version)
    }
}
