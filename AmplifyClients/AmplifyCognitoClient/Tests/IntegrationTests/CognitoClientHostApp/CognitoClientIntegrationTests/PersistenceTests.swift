//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient
@_spi(AmplifyExperimental) import AmplifyFoundation
import XCTest

/// Storage behaviour over the real keychain and the live engine: unreadable storage
/// is never "signed out", and a session in a shared access group is scoped to that group.
final class PersistenceTests: ClientIntegrationTestCase {

    private var configuration: AuthClientConfiguration!

    override func setUp() async throws {
        try await super.setUp()
        configuration = try IntegrationTestEnvironment.configuration()
    }

    /// A session whose storage cannot be read is `.unavailable`, never `.signedOut`, and nothing is sent
    /// to Cognito for it (PS-2; design §12, decision 7).
    ///
    /// - Given: alice signed in under the default access group, and a second client on another session
    ///   ID in an access group the app is not entitled to, with the recorder installed
    /// - When:
    ///    - the second client reads its state, resolves credentials, and signs in
    /// - Then:
    ///    - its state is `.unavailable(.denied)`, which is not `.signedOut`
    ///    - its provider throws `CredentialsError.storageUnavailable(.denied)`
    ///    - its sign-in throws `.storageUnavailable(.denied)` and the recorder saw no request
    ///    - alice's session is untouched: still signed in, and its tokens still resolve
    ///
    func testStorageUnavailableIsNotSignedOut() async throws {
        let aliceCredentials = try await makeSignInUser()
        let aliceId = try makeSessionID("alice")
        let alice = try AmplifyCognitoClient(configuration: configuration, options: .init(sessionId: aliceId))
        _ = try await alice.signIn(username: aliceCredentials.username, password: aliceCredentials.password)
        let aliceUser = try await alice.getCurrentUser()
        let notEntitled = try IntegrationTestEnvironment.defaultAccessGroup()
            .replacingOccurrences(of: "CognitoClientHostApp", with: "NotEntitled")
        // Not minted through makeSessionID: its cleanup could only fail the same way. It never holds a
        // row, and the handle is released when this block ends.
        let deniedId = try IntegrationTestEnvironment.uniqueSessionID("denied")
        do {
            let recorder = RecordingHTTPClient()
            let denied = try AmplifyCognitoClient(
                configuration: configuration,
                options: .init(
                    sessionId: deniedId,
                    accessGroup: notEntitled,
                    configureUserPoolClient: recorder.configureUserPoolClient
                )
            )

            let state = await denied.currentSessionState()

            XCTAssertState(state, .unavailable(.denied))
            XCTAssertTrue(state != .signedOut, "unreadable storage must not read as signed out")
            let providerError = await Expect.credentialsError("resolving credentials from unreadable storage") {
                try await denied.credentialsProvider.resolve()
            }
            XCTAssertEqual(providerError?.caseName, "storageUnavailable(denied)")
            let signInError = await Expect.authClientError("signing in over unreadable storage") {
                try await denied.signIn(username: aliceCredentials.username, password: aliceCredentials.password)
            }
            XCTAssertEqual(signInError?.kind, .storageUnavailable(.denied))
            XCTAssertEqual(recorder.operations, [], "nothing is sent for a session whose storage cannot be read")
        }
        try await SessionCleanup.waitUntilReleased([deniedId])

        let aliceState = await alice.currentSessionState()
        XCTAssertState(aliceState, .signedIn(aliceUser))
        _ = try await alice.fetchAuthSession().userPoolTokensResult.get()
    }

    /// A session stored in a shared access group is listed, and restored, only through that group
    /// (PS-3; the plugin's `testSharedKeychainCredentialsNotClearedOnFreshInstall`).
    ///
    /// - Given: bob signed in on a session in the `…Shared` access group
    /// - When:
    ///    - the stored sessions are listed for the shared group and for the default group
    ///    - every handle is dropped, and a new client over the same ID and group reads the session
    /// - Then:
    ///    - the shared-group listing has the session, naming bob; the default-group listing does not
    ///    - the new client reads `.signedIn(bob)` without a request, and a forced refresh succeeds
    ///
    func testSharedAccessGroupSessionIsScopedToItsGroup() async throws {
        let bobCredentials = try await makeSignInUser()
        let shared = try IntegrationTestEnvironment.sharedAccessGroup()
        let sessionId = try makeSessionID("bob-shared", accessGroup: shared)
        let bob: AuthClientUser
        do {
            let client = try AmplifyCognitoClient(
                configuration: configuration,
                options: .init(sessionId: sessionId, accessGroup: shared)
            )
            _ = try await client.signIn(username: bobCredentials.username, password: bobCredentials.password)
            bob = try await client.getCurrentUser()
        }
        try await SessionCleanup.waitUntilReleased([sessionId])

        let sharedListing = try await AmplifyCognitoClient.storedSessions(configuration: configuration, accessGroup: shared)
        let defaultListing = try await AmplifyCognitoClient.storedSessions(configuration: configuration, includingSignedOut: true)

        XCTAssertTrue(sharedListing.first { $0.sessionId == sessionId }?.username == bob.username, "the shared listing names bob")
        XCTAssertFalse(defaultListing.contains { $0.sessionId == sessionId }, "the default group does not list a shared-group session")

        let recorder = RecordingHTTPClient()
        let restored = try AmplifyCognitoClient(
            configuration: configuration,
            options: .init(sessionId: sessionId, accessGroup: shared, configureUserPoolClient: recorder.configureUserPoolClient)
        )
        let state = await restored.currentSessionState()
        XCTAssertState(state, .signedIn(bob))
        XCTAssertEqual(recorder.operations, [], "restoring makes no request")
        _ = try await restored.fetchAuthSession(options: .init(forceRefresh: true)).userPoolTokensResult.get()
        XCTAssertEqual(recorder.operations, ["GetTokensFromRefreshToken"])
    }
}
