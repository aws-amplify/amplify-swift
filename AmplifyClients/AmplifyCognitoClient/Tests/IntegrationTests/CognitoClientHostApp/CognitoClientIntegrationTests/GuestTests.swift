//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient
@_spi(AmplifyExperimental) import AmplifyFoundation
import XCTest

/// A session with no user, over R-IP's guest access: the plugin's `SignedOutAuthSessionTests` that the
/// base suites do not already cover.
///
/// The recorder sees only user pool requests; the identity client has no configure hook.
/// An identity pool issues a new identity for every unauthenticated `GetId`, and new credentials for every
/// `GetCredentialsForIdentity`, so an unchanged identity ID and access key ID are the evidence that no
/// second call was made.
final class GuestTests: ClientIntegrationTestCase {

    /// Signing a guest out replaces its identity (GU-1; the plugin's
    /// `testSuccessfulSessionFetchAfterSignOut`).
    ///
    /// - Given: a fresh session whose `fetchAuthSession()` made it a guest
    /// - When:
    ///    - `signOut()`, then `fetchAuthSession()` again
    /// - Then:
    ///    - the sign-out is `.complete` and leaves the session `.signedOut`
    ///    - the second fetch is a guest again, with a different identity ID
    ///
    func testGuestIdentityIsReplacedAfterSignOut() async throws {
        let client = try makeClient("guest-replaced")
        let first = try await client.fetchAuthSession().identityIdResult.get()
        let guestState = await client.currentSessionState()
        XCTAssertState(guestState, .guest)

        let signOut = try await client.signOut()

        XCTAssertEqual(signOut, .complete)
        let signedOut = await client.currentSessionState()
        XCTAssertState(signedOut, .signedOut)
        let second = try await client.fetchAuthSession().identityIdResult.get()
        XCTAssertFalse(first == second, "a guest signed out gets a new identity on its next fetch")
        let state = await client.currentSessionState()
        XCTAssertState(state, .guest)
    }

    /// Repeated guest fetches reuse the one identity and its credentials (GU-2; the plugin's
    /// `testMultipleSuccessfulSessionFetchWithCredentials`).
    ///
    /// - Given: a fresh session whose first `fetchAuthSession()` made it a guest
    /// - When:
    ///    - two more fetches
    /// - Then:
    ///    - each has the first fetch's identity ID and access key ID: one `GetId`, one
    ///      `GetCredentialsForIdentity`
    ///    - the state is `.guest`, and the stored row's kind is `.guest`
    ///
    func testRepeatedGuestFetchesReuseOneIdentity() async throws {
        let configuration = try IntegrationTestEnvironment.configuration()
        let client = try makeClient("guest-repeated")
        let first = try await client.fetchAuthSession()
        let identity = try first.identityIdResult.get()
        let accessKey = try first.awsCredentialsResult.get().accessKeyId

        for fetch in 1 ... 2 {
            let session = try await client.fetchAuthSession()
            XCTAssertTrue(try session.identityIdResult.get() == identity, "fetch \(fetch) reuses the identity")
            XCTAssertTrue(try session.awsCredentialsResult.get().accessKeyId == accessKey, "fetch \(fetch) reuses the credentials")
        }

        let state = await client.currentSessionState()
        XCTAssertState(state, .guest)
        let stored = try await AmplifyCognitoClient.storedSessions(configuration: configuration)
        XCTAssertEqual(stored.first { $0.sessionId == client.sessionId }?.kind, .guest)
    }

    /// A guest session has no user pool tokens (GU-3; the plugin's
    /// `testCognitoTokenSignedOutError`, whose `AuthError.signedOut` is the client's `.notSignedIn`).
    ///
    /// - Given: a fresh session whose `fetchAuthSession()` made it a guest
    /// - When:
    ///    - the session's fields are read, and `userPoolTokenProvider.accessToken()` is called
    /// - Then:
    ///    - the user pool tokens and the sub are `.notSignedIn`, while the identity and AWS credentials succeed
    ///    - the token provider throws `CredentialsError.notSignedIn`
    ///
    func testGuestSessionHasNoUserPoolTokens() async throws {
        let client = try makeClient("guest-tokens")

        let session = try await client.fetchAuthSession()

        guard case .failure(let tokensError) = session.userPoolTokensResult else {
            return XCTFail("a guest session should hold no user pool tokens")
        }
        XCTAssertEqual(tokensError.kind, .notSignedIn)
        guard case .failure(let subError) = session.userSubResult else {
            return XCTFail("a guest session should have no user sub")
        }
        XCTAssertEqual(subError.kind, .notSignedIn)
        XCTAssertNoThrow(try session.identityIdResult.get())
        XCTAssertNoThrow(try session.awsCredentialsResult.get())
        let providerError = await Expect.credentialsError("a guest session's token provider") {
            try await client.userPoolTokenProvider.accessToken()
        }
        XCTAssertEqual(providerError?.caseName, "notSignedIn")
    }
}
