//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
@testable import AWSCognitoAuthPlugin
@testable import InternalAWSCognitoAuth

/// The hosted UI's identity check, where it sits: `FetchHostedUISignInToken`
/// applies the flow's identity policy after the token exchange and before `finalizeSignIn`, so a refused
/// response never signs anyone in.
///
/// - Note: `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
///   `@Sendable` closures the API takes. XCTest runs one test at a time.
class FetchHostedUISignInTokenIdentityTests: XCTestCase, @unchecked Sendable {

    // `Defaults.makeDefaultAuthEnvironment` configures this pool; the issuer's region is the pool ID's prefix.
    private let issuer: String = {
        let region = HostedUIIdentityVerifier.issuerRegion(
            userPoolId: Defaults.userPoolId,
            configuredRegion: Defaults.regionString
        )
        return "https://cognito-idp.\(region).amazonaws.com/\(Defaults.userPoolId)"
    }()
    private let hostedUIClientId = "hostedUIClient"
    private let nonce = "flowNonce"

    override func setUpWithError() throws {
        try super.setUpWithError()
        // `MockURLProtocol` answers the token exchange. On watchOS the session does not route the request
        // through the configuration's `protocolClasses`: it goes to the network, and fails there with
        // NSURLErrorCannotFindHost.
        #if os(watchOS)
        throw XCTSkip("MockURLProtocol cannot answer URLSession requests on watchOS")
        #endif
    }

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    /// Test that a refused response is never signed in
    ///
    /// - Given: A token response for another user than the one the policy expects
    /// - When:
    ///    - `FetchHostedUISignInToken` runs
    /// - Then:
    ///    - It sends `HostedUIEvent.throwError` with `unexpectedIdentity(.notExpectedIdentity)`, and never
    ///      `SignInEvent.finalizeSignIn`, so nothing is stored
    ///
    func testMismatchThrowsAndNeverFinalizesTheSignIn() async throws {
        let policy = HostedUIIdentityPolicy(verifiesTokenClaims: true, expectedIdentity: "someoneElse")
        let events = await run(policy: policy, idToken: idToken(), accessToken: accessToken())

        XCTAssertFalse(events.contains { Self.isFinalizeSignIn($0) })
        let error = try XCTUnwrap(events.compactMap(Self.thrownError).first)
        guard case .hostedUI(.unexpectedIdentity(let mismatch)) = error else {
            return XCTFail("Expected hostedUI(.unexpectedIdentity), got \(error)")
        }
        XCTAssertEqual(mismatch.reason, .notExpectedIdentity)
        XCTAssertEqual(mismatch.returnedUserId, "user-sub")
    }

    /// Test that a response failing a claim check is never signed in
    ///
    /// - Given: A token response whose id token carries another flow's nonce
    /// - When:
    ///    - `FetchHostedUISignInToken` runs with claim checks on
    /// - Then:
    ///    - It sends `unexpectedIdentity(.nonce)` and never `finalizeSignIn`
    ///
    func testClaimFailureThrowsAndNeverFinalizesTheSignIn() async throws {
        let events = await run(
            policy: HostedUIIdentityPolicy(verifiesTokenClaims: true),
            idToken: idToken(nonce: "anotherFlow"),
            accessToken: accessToken()
        )

        XCTAssertFalse(events.contains { Self.isFinalizeSignIn($0) })
        let error = try XCTUnwrap(events.compactMap(Self.thrownError).first)
        guard case .hostedUI(.unexpectedIdentity(let mismatch)) = error else {
            return XCTFail("Expected hostedUI(.unexpectedIdentity), got \(error)")
        }
        XCTAssertEqual(mismatch.reason, .nonce)
    }

    /// Test that a user the sign-in could not store is never signed in
    ///
    /// - Given: A valid id token and an access token that cannot be read, so the sign-in would store the
    ///   `"unknown"` user
    /// - When:
    ///    - `FetchHostedUISignInToken` runs under an active policy
    /// - Then:
    ///    - It sends `unexpectedIdentity(.subject)` and never `finalizeSignIn`
    ///
    func testUnreadableAccessTokenIsNeverSignedIn() async throws {
        let events = await run(
            policy: HostedUIIdentityPolicy(verifiesTokenClaims: true),
            idToken: idToken(),
            accessToken: "opaque"
        )

        XCTAssertFalse(events.contains { Self.isFinalizeSignIn($0) })
        let error = try XCTUnwrap(events.compactMap(Self.thrownError).first)
        guard case .hostedUI(.unexpectedIdentity(let mismatch)) = error else {
            return XCTFail("Expected hostedUI(.unexpectedIdentity), got \(error)")
        }
        XCTAssertEqual(mismatch.reason, .subject)
    }

    /// Test that a response meeting the policy is signed in
    ///
    /// - Given: A token response for the expected user, from this client, pool and flow
    /// - When:
    ///    - `FetchHostedUISignInToken` runs
    /// - Then:
    ///    - It sends `finalizeSignIn` with the returned user, and no error
    ///
    func testMatchingResponseFinalizesTheSignIn() async throws {
        let policy = HostedUIIdentityPolicy(verifiesTokenClaims: true, expectedIdentity: "user-sub")
        let events = await run(policy: policy, idToken: idToken(), accessToken: accessToken())

        XCTAssertTrue(events.compactMap(Self.thrownError).isEmpty)
        let signedIn = try XCTUnwrap(events.compactMap(Self.finalizedSignIn).first)
        XCTAssertEqual(signedIn.userId, "user-sub")
    }

    /// Test that the plugin's flow is unchanged
    ///
    /// - Given: The `.none` policy, and tokens that would fail every check (not even JWTs)
    /// - When:
    ///    - `FetchHostedUISignInToken` runs
    /// - Then:
    ///    - It sends `finalizeSignIn`, as before the policy existed
    ///
    func testNonePolicyFinalizesAsBefore() async throws {
        let events = await run(policy: .none, idToken: "idToken", accessToken: "accessToken")

        XCTAssertTrue(events.compactMap(Self.thrownError).isEmpty)
        XCTAssertNotNil(events.compactMap(Self.finalizedSignIn).first)
    }

    /// Test that the issued refresh token is shown to the observer, whatever the checks decide
    ///
    /// - Given: An observer, and a token response for another user than the policy expects
    /// - When:
    ///    - `FetchHostedUISignInToken` runs, refusing it, and again with the plugin's `.none` policy
    /// - Then:
    ///    - The observer is told the response's refresh token each time, and an environment without one (the
    ///      plugin's) is unchanged
    ///
    func testTheIssuedRefreshTokenReachesTheObserver() async throws {
        let seen = SeenTokens()
        let refused = await run(
            policy: HostedUIIdentityPolicy(verifiesTokenClaims: true, expectedIdentity: "someoneElse"),
            idToken: idToken(),
            accessToken: accessToken(),
            observer: { seen.append($0) }
        )
        let accepted = await run(policy: .none, idToken: "idToken", accessToken: "accessToken", observer: { seen.append($0) })

        XCTAssertFalse(refused.contains { Self.isFinalizeSignIn($0) })
        XCTAssertTrue(accepted.contains { Self.isFinalizeSignIn($0) })
        XCTAssertEqual(seen.tokens, ["refreshToken", "refreshToken"])
    }

    // MARK: - Helpers

    private func run(
        policy: HostedUIIdentityPolicy,
        idToken: String,
        accessToken: String,
        observer: HostedUIEnvironment.IssuedRefreshTokenObserver? = nil
    ) async -> [StateMachineEvent] {
        let response: [String: Any] = [
            "id_token": idToken,
            "access_token": accessToken,
            "refresh_token": "refreshToken",
            "expires_in": 3_600
        ]
        let body = (try? JSONSerialization.data(withJSONObject: response)) ?? Data()
        MockURLProtocol.requestHandler = { _ in (HTTPURLResponse(), body) }

        let options = HostedUIOptions(
            scopes: ["openid"],
            providerInfo: HostedUIProviderInfo(authProvider: nil, idpIdentifier: nil),
            presentationAnchor: nil,
            preferPrivateSession: true,
            nonce: nonce,
            language: nil,
            loginHint: nil,
            prompt: nil,
            resource: nil
        )
        let action = FetchHostedUISignInToken(result: HostedUIResult(
            code: "code",
            state: "state",
            codeVerifier: "verifier",
            options: options
        ))
        let events = EventRecorder()
        await action.execute(
            withDispatcher: MockDispatcher { events.append($0) },
            environment: Defaults.makeDefaultAuthEnvironment(
                hostedUIEnvironment: hostedUIEnvironment(policy: policy, observer: observer)
            )
        )
        return events.events
    }

    private func hostedUIEnvironment(
        policy: HostedUIIdentityPolicy,
        observer: HostedUIEnvironment.IssuedRefreshTokenObserver?
    ) -> HostedUIEnvironment {
        BasicHostedUIEnvironment(
            configuration: HostedUIConfigurationData(
                clientId: hostedUIClientId,
                oauth: OAuthConfigurationData(
                    domain: "cognitodomain",
                    scopes: ["openid"],
                    signInRedirectURI: "myapp://",
                    signOutRedirectURI: "myapp://"
                )
            ),
            hostedUISessionFactory: { MockHostedUISession(result: .success([])) },
            urlSessionFactory: {
                let configuration = URLSessionConfiguration.ephemeral
                configuration.protocolClasses = [MockURLProtocol.self]
                return URLSession(configuration: configuration)
            },
            randomStringFactory: { MockRandomStringGenerator(mockString: "mockString", mockUUID: "mockUUID") },
            identityPolicy: policy,
            issuedRefreshTokenObserver: observer
        )
    }

    private func idToken(nonce: String? = nil) -> String {
        UnsignedJWT.make([
            "sub": "user-sub",
            "cognito:username": "user",
            "aud": hostedUIClientId,
            "iss": issuer,
            "token_use": "id",
            "nonce": nonce ?? self.nonce
        ])
    }

    private func accessToken() -> String {
        UnsignedJWT.make([
            "sub": "user-sub",
            "username": "user",
            "token_use": "access"
        ])
    }

    private static func isFinalizeSignIn(_ event: StateMachineEvent) -> Bool {
        finalizedSignIn(event) != nil
    }

    private static func finalizedSignIn(_ event: StateMachineEvent) -> SignedInData? {
        guard case .finalizeSignIn(let data) = (event as? SignInEvent)?.eventType else {
            return nil
        }
        return data
    }

    private static func thrownError(_ event: StateMachineEvent) -> SignInError? {
        guard case .throwError(let error) = (event as? HostedUIEvent)?.eventType else {
            return nil
        }
        return error
    }
}

/// The refresh tokens an observer was told.
private final class SeenTokens: @unchecked Sendable {
    // `@unchecked Sendable`: only touched while holding `lock`.
    private let lock = NSLock()
    private var seen: [String] = []

    var tokens: [String] {
        lock.lock()
        defer { lock.unlock() }
        return seen
    }

    func append(_ token: String) {
        lock.lock()
        seen.append(token)
        lock.unlock()
    }
}
