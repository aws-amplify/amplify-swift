//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient
import XCTest

/// The plugin's remaining `AuthSRPSignInTests` cases, with their names: validation, client metadata, an
/// unknown user, and a sign-in racing a session fetch.
extension SignInFlowTests {

    /// An empty username and password fail validation, twice, without reaching Cognito (SV-1;
    /// the plugin's `testSignInFailWithEmptyUsername`).
    ///
    /// - Given: a client on a fresh session, the recorder installed
    /// - When:
    ///    - it signs in with an empty username and an empty password, then does it again
    /// - Then:
    ///    - each attempt throws `.validation(field: "username")`: the first failure left the session able
    ///      to validate the second
    ///    - the recorder saw no request, the state is `.signedOut`, and no row was stored
    ///
    func testSignInFailWithEmptyUsername() async throws {
        let configuration = try IntegrationTestEnvironment.configuration()
        let recorder = RecordingHTTPClient()
        let client = try makeClient("empty", configureUserPoolClient: recorder.configureUserPoolClient)

        for attempt in 1 ... 2 {
            let error = await Expect.authClientError("sign-in attempt \(attempt) with an empty username") {
                try await client.signIn(username: "", password: "")
            }
            XCTAssertEqual(error?.kind, .validation(field: "username"), "attempt \(attempt)")
        }

        XCTAssertEqual(recorder.operations, [], "validation fails before any request")
        let state = await client.currentSessionState()
        XCTAssertState(state, .signedOut)
        let listed = try await AmplifyCognitoClient.storedSessions(configuration: configuration, includingSignedOut: true)
        XCTAssertFalse(listed.contains { $0.sessionId == client.sessionId }, "a failed validation stores no row")
    }

    /// An empty username with a password fails validation without reaching Cognito (SV-2; the
    /// plugin's `testSignInValidation`).
    ///
    /// - Given: a client on a fresh session, the recorder installed
    /// - When:
    ///    - it signs in with an empty username and a non-empty password
    /// - Then:
    ///    - it throws `.validation(field: "username")`, the recorder saw no request, and the state is
    ///      `.signedOut`
    ///
    func testSignInValidation() async throws {
        let recorder = RecordingHTTPClient()
        let client = try makeClient("validation", configureUserPoolClient: recorder.configureUserPoolClient)

        let error = await Expect.authClientError("a sign-in with an empty username") {
            try await client.signIn(username: "", password: "password")
        }

        XCTAssertEqual(error?.kind, .validation(field: "username"))
        XCTAssertEqual(recorder.operations, [], "validation fails before any request")
        let state = await client.currentSessionState()
        XCTAssertState(state, .signedOut)
    }

    /// Client metadata reaches Cognito on every request of an SRP sign-in (SI-5; the plugin's
    /// `testSignInWithSignInOptions`, whose `AWSAuthSignInOptions(metadata:)` is the client's
    /// `AuthClientSignInOptions.clientMetadata`).
    ///
    /// - Given: a client on a fresh session, the recorder installed
    /// - When:
    ///    - alice signs in with `clientMetadata: ["mySignInData": "myvalue"]`, the plugin test's metadata
    /// - Then:
    ///    - the result is `.done`, and the state is `.signedIn(alice)`
    ///    - the sign-in's `InitiateAuth` and `RespondToAuthChallenge` both carry exactly that metadata
    ///
    func testSignInWithSignInOptions() async throws {
        let alice = try IntegrationTestEnvironment.users().alice
        let recorder = RecordingHTTPClient()
        let client = try makeClient("alice-metadata", configureUserPoolClient: recorder.configureUserPoolClient)
        let metadata = ["mySignInData": "myvalue"]

        let result = try await client.signIn(
            username: alice.username,
            password: alice.password,
            options: AuthClientSignInOptions(clientMetadata: metadata)
        )

        XCTAssertStep(result.nextStep, .done)
        let user = try await client.getCurrentUser()
        XCTAssertEqual(user.username, "alice")
        let state = await client.currentSessionState()
        XCTAssertState(state, .signedIn(user))
        let signIn = Array(recorder.requests.prefix(2))
        XCTAssertEqual(signIn.map(\.operation), ["InitiateAuth", "RespondToAuthChallenge"])
        for request in signIn {
            XCTAssertEqual(request.clientMetadata, metadata, "\(request.operation ?? "a request") carries the metadata")
        }
    }

    /// An unknown user is refused as `.notAuthorized`, because the app client prevents user-existence
    /// errors (SI-6; the plugin's `testSignInWithInvalidUser`).
    ///
    /// - Given: a client on a fresh session, and a username no pool holds (R-UP is admin-create-only)
    /// - When:
    ///    - it signs in with that username
    /// - Then:
    ///    - it throws `.notAuthorized` (existence errors prevented), or `.service(.userNotFound)` or
    ///      `.service(.limitExceeded)`, the answers the plugin accepts; the state stays `.signedOut`
    ///
    func testSignInWithInvalidUser() async throws {
        let client = try makeClient("unknown")
        let unknown = "ccit-unknown-\(UUID().uuidString.lowercased())"

        let error = await Expect.authClientError("signing an unknown user in") {
            try await client.signIn(username: unknown, password: "password")
        }

        let kind = try XCTUnwrap(error?.kind)
        XCTAssertTrue(
            [.notAuthorized, .service(.userNotFound), .service(.limitExceeded)].contains(kind),
            "an unknown user is refused as the plugin expects, got \(kind)"
        )
        let state = await client.currentSessionState()
        XCTAssertState(state, .signedOut)
    }

    /// A sign-in and a session fetch on the same session, at the same time, both succeed (SI-7;
    /// the plugin's `testSignInWithFetchAuthSession`, with its 60-second limit).
    ///
    /// - Given: a client on a fresh session over R-UP and R-IP (guests allowed)
    /// - When:
    ///    - `fetchAuthSession()` and alice's `signIn` run concurrently, each in its own task, awaited for at
    ///      most 60 s
    /// - Then:
    ///    - the sign-in returns `.done`, and the final state is `.signedIn(alice)`
    ///    - the fetch does not throw, and returns a coherent session: an identity and AWS credentials, and
    ///      either no user pool tokens (`.notSignedIn`: it ran before the sign-in, as a guest) or alice's
    ///      (its sub is alice's)
    ///    - a fetch afterwards returns alice's tokens, an identity and credentials
    ///
    func testSignInWithFetchAuthSession() async throws {
        let alice = try IntegrationTestEnvironment.users().alice
        let client = try makeClient("alice-fetch")

        let fetchCall = ConcurrentCalls("the racing fetch", count: 1) { _ in try await client.fetchAuthSession() }
        let signInCall = ConcurrentCalls("the sign-in", count: 1) { _ in
            try await client.signIn(username: alice.username, password: alice.password)
        }
        await fulfillment(of: [fetchCall.expectation, signInCall.expectation], timeout: 60)
        let fetched = try XCTUnwrap(fetchCall.values().first)
        let result = try XCTUnwrap(signInCall.values().first)

        XCTAssertStep(result.nextStep, .done)
        let user = try await client.getCurrentUser()
        XCTAssertEqual(user.username, "alice")
        let state = await client.currentSessionState()
        XCTAssertState(state, .signedIn(user))
        XCTAssertNoThrow(try fetched.identityIdResult.get(), "the racing fetch has an identity")
        XCTAssertNoThrow(try fetched.awsCredentialsResult.get(), "the racing fetch has AWS credentials")
        switch fetched.userPoolTokensResult {
        case .success(let tokens):
            let sub = try IntegrationTestEnvironment.jwtClaims(tokens.idToken)["sub"] as? String
            XCTAssertTrue(sub == user.userId, "the racing fetch's tokens are alice's")
            XCTAssertTrue(try fetched.userSubResult.get() == user.userId, "the racing fetch's sub is alice's")
        case .failure(let error):
            XCTAssertEqual(error.kind, .notSignedIn, "a fetch before the sign-in is a guest's")
        }

        let after = try await client.fetchAuthSession()
        let afterSub = try IntegrationTestEnvironment.jwtClaims(after.userPoolTokensResult.get().idToken)["sub"] as? String
        XCTAssertTrue(afterSub == user.userId, "a fetch afterwards returns alice's tokens")
        XCTAssertNoThrow(try after.identityIdResult.get())
        XCTAssertNoThrow(try after.awsCredentialsResult.get())
    }
}
