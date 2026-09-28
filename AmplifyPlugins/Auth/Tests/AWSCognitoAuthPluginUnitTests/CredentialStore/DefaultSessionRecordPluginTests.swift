//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyKeychainTestCommon
import AWSCognitoIdentity
import AWSCognitoIdentityProvider
import AWSPluginsCore
import Foundation
import XCTest
@testable import Amplify
@testable import AWSCognitoAuthPlugin
@testable import InternalAWSCognitoAuth

/// The whole plugin, configured over a keychain holding a record written by the Cognito client's own
/// storage code: it signs the user in from that record, and never writes or deletes any `amplify.1.`
/// record while signing in, refreshing and signing out.
///
/// The plugin runs its real credential store over the in-memory keychain fake, through the real
/// credential-store state machine; only the Cognito service calls are mocked.
///
/// - Note: `@unchecked Sendable` so the test body can be captured by the `@Sendable` closures the
///   production API takes. `XCTestCase` is not `Sendable`, and each test runs alone.
class DefaultSessionRecordPluginTests: XCTestCase, @unchecked Sendable {

    private let authConfiguration = Defaults.makeDefaultAuthConfigData()
    private let legacyAccount = "amplify.\(Defaults.userPoolId).\(Defaults.identityPoolId).session"

    private var keychain: InMemoryKeychain!

    override func setUp() {
        super.setUp()
        keychain = InMemoryKeychain()
    }

    override func tearDown() async throws {
        keychain = nil
        await Amplify.reset()
    }

    /// Test that the plugin signs a user in from a record only the client wrote
    ///
    /// - Given: A keychain holding nothing but the client's default-session record for a signed-in user,
    ///   written by the client's record store
    /// - When:
    ///    - The plugin is configured and I invoke fetchAuthSession
    /// - Then:
    ///    - The session is signed in with exactly the stored tokens, identity ID and AWS credentials, and
    ///      nothing is written or deleted
    ///
    func testFetchAuthSession_fromOnlyAClientRecord_isSignedInWithItsTokens() async throws {
        let credentials = LongLivedCredentials.userPoolAndIdentityPool()
        let written = try CognitoClientRecords.writeDefaultSession(credentials, in: keychain, for: authConfiguration)
        keychain.resetMutations()
        guard case .userPoolAndIdentityPool(let signedInData, let identityID, let awsCredentials) = credentials else {
            return XCTFail("Unexpected fixture")
        }

        let plugin = makePlugin(userPool: MockIdentityProvider())
        let session = try await plugin.fetchAuthSession(options: AuthFetchSessionRequest.Options())

        XCTAssertTrue(session.isSignedIn)
        let tokens = try (session as? AuthCognitoTokensProvider)?.getCognitoTokens().get()
        XCTAssertEqual(tokens?.idToken, signedInData.cognitoUserPoolTokens.idToken)
        XCTAssertEqual(tokens?.accessToken, signedInData.cognitoUserPoolTokens.accessToken)
        XCTAssertEqual(tokens?.refreshToken, signedInData.cognitoUserPoolTokens.refreshToken)
        XCTAssertEqual(try (session as? AuthCognitoIdentityProvider)?.getIdentityId().get(), identityID)
        let sessionCredentials = try (session as? AuthAWSCredentialsProvider)?.getAWSCredentials().get()
        XCTAssertEqual(sessionCredentials?.accessKeyId, awsCredentials.accessKeyId)
        XCTAssertEqual(try CognitoClientRecords.storedBytes(in: keychain, for: authConfiguration), written)
        XCTAssertFalse(keychain.mutatedAccounts.contains(legacyAccount))
        XCTAssertEqual(keychain.mutatedClientAccounts, [])
    }

    /// Test that the plugin never writes or deletes a client record across sign-in, refresh and sign-out
    ///
    /// - Given: A keychain holding only the client's default-session record, with expired tokens
    /// - When:
    ///    - The plugin is configured, refreshes the session in fetchAuthSession, signs out, signs in again
    ///      and signs out again
    /// - Then:
    ///    - The refreshed tokens land in the plugin's own record, no write or removal ever touches an
    ///      `amplify.1.` account, nothing is removed service-wide, and the client's record is
    ///      byte-identical at the end
    ///
    func testSignInRefreshAndSignOut_neverWriteOrDeleteAClientRecord() async throws {
        let expired = AmplifyCredentials.userPoolAndIdentityPool(
            signedInData: .expiredTestData,
            identityID: "client-identity-id",
            credentials: EngineAWSCredentials.expiredTestData
        )
        let written = try CognitoClientRecords.writeDefaultSession(expired, in: keychain, for: authConfiguration)
        keychain.resetMutations()
        let refreshed = LongLivedCredentials.tokens(username: "alice")
        let userPool = MockIdentityProvider(
            mockRevokeTokenResponse: { _ in .testData },
            mockInitiateAuthResponse: { _ in
                InitiateAuthOutput(
                    authenticationResult: .none,
                    challengeName: .passwordVerifier,
                    challengeParameters: InitiateAuthOutput.validChalengeParams,
                    session: "someSession"
                )
            },
            mockGetTokensFromRefreshTokenResponse: { _ in
                GetTokensFromRefreshTokenOutput(authenticationResult: .init(
                    accessToken: refreshed.accessToken,
                    expiresIn: 3_600,
                    idToken: refreshed.idToken,
                    refreshToken: refreshed.refreshToken
                ))
            },
            mockGlobalSignOutResponse: { _ in .testData },
            mockRespondToAuthChallengeResponse: { _ in
                RespondToAuthChallengeOutput(
                    authenticationResult: .init(
                        accessToken: Defaults.validAccessToken,
                        expiresIn: 300,
                        idToken: "idToken",
                        newDeviceMetadata: nil,
                        refreshToken: "refreshToken",
                        tokenType: ""
                    ),
                    challengeName: .none,
                    challengeParameters: [:],
                    session: "session"
                )
            }
        )
        let plugin = makePlugin(userPool: userPool)

        // Refresh.
        let session = try await plugin.fetchAuthSession(options: AuthFetchSessionRequest.Options())
        XCTAssertTrue(session.isSignedIn)
        XCTAssertEqual(try (session as? AuthCognitoTokensProvider)?.getCognitoTokens().get().idToken, refreshed.idToken)
        XCTAssertTrue(keychain.mutatedAccounts.contains(legacyAccount), "The refresh should be stored in the plugin's record")

        // Sign out.
        let firstSignOut = await plugin.signOut(options: AuthSignOutRequest.Options())
        XCTAssertTrue((firstSignOut as? AWSCognitoSignOutResult)?.signedOutLocally ?? false)

        // Sign in.
        let signIn = try await plugin.signIn(username: "alice", password: "password", options: AuthSignInRequest.Options())
        XCTAssertTrue(signIn.isSignedIn)

        // Sign out.
        let secondSignOut = await plugin.signOut(options: AuthSignOutRequest.Options())
        XCTAssertTrue((secondSignOut as? AWSCognitoSignOutResult)?.signedOutLocally ?? false)

        XCTAssertEqual(keychain.mutatedClientAccounts, [])
        XCTAssertFalse(keychain.hasRemovedAll)
        XCTAssertEqual(try CognitoClientRecords.storedBytes(in: keychain, for: authConfiguration), written)
    }

    /// Test that signing out of a session read from the client's record keeps the user signed out
    ///
    /// - Given: A plugin signed in from the client's default-session record alone
    /// - When:
    ///    - The user signs out, and the app is launched again over the same keychain
    /// - Then:
    ///    - The new launch is signed out, although the client's record is still there, unchanged
    ///
    func testSignOut_ofASessionReadFromAClientRecord_staysSignedOutOnTheNextLaunch() async throws {
        let written = try CognitoClientRecords.writeDefaultSession(
            LongLivedCredentials.userPoolAndIdentityPool(),
            in: keychain,
            for: authConfiguration
        )
        let userPool = MockIdentityProvider(mockRevokeTokenResponse: { _ in .testData })
        let firstLaunch = makePlugin(userPool: userPool)
        let signedIn = try await firstLaunch.fetchAuthSession(options: AuthFetchSessionRequest.Options())
        XCTAssertTrue(signedIn.isSignedIn)

        let signOut = await firstLaunch.signOut(options: AuthSignOutRequest.Options())
        XCTAssertTrue((signOut as? AWSCognitoSignOutResult)?.signedOutLocally ?? false)

        let nextLaunch = makePlugin(userPool: userPool)
        let session = try await nextLaunch.fetchAuthSession(options: AuthFetchSessionRequest.Options())
        XCTAssertFalse(session.isSignedIn, "The ended session came back from the client's record")
        XCTAssertEqual(try CognitoClientRecords.storedBytes(in: keychain, for: authConfiguration), written)
        XCTAssertEqual(keychain.mutatedClientAccounts, [])
    }

    // MARK: - Helpers

    /// A plugin as `configure(using:)` builds it, except that its credential store runs over `keychain`
    /// and the Cognito service calls are mocked.
    private func makePlugin(userPool: CognitoUserPoolBehavior) -> AWSCognitoAuthPlugin {
        makePluginOverKeychain(
            InMemoryPluginKeychainStore(keychain: keychain),
            authConfiguration: authConfiguration,
            userPool: userPool
        )
    }
}
