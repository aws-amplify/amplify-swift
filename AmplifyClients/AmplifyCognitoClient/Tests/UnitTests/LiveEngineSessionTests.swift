//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentity
import AWSCognitoIdentityProvider
import Foundation
import InternalAWSCognitoAuth
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// The live engine's session operations over scripted Cognito:
/// refresh and its classification, guest credentials, revoke and global sign-out, delete user.
final class LiveEngineSessionTests: XCTestCase {

    private var harness: LiveEngineHarness!

    override func setUp() {
        super.setUp()
        harness = LiveEngineHarness()
    }

    override func tearDown() {
        harness.cognito.assertConsumed()
        harness = nil
        super.tearDown()
    }

    /// Signs alice in, then forgets the calls it took, so each test sees only its own.
    private func signedIn(on engine: LiveSessionEngine) async throws -> Data {
        let payload = try await harness.signedInPayload(on: engine)
        harness = harness.resettingCalls()
        return payload
    }

    // MARK: Refresh

    /// A refresh of a signed-in payload: the refresh token, then AWS credentials for the same identity.
    ///
    /// - Given: alice's signed-in payload
    /// - When:
    ///    - it is refreshed
    /// - Then:
    ///    - the calls are `GetTokensFromRefreshToken` with her refresh token, then `GetCredentialsForIdentity`
    ///      for her identity
    ///    - the payload holds the new tokens, the same identity and new AWS credentials
    ///
    func testRefreshUsesTheRefreshTokenAndKeepsTheIdentity() async throws {
        let engine = try harness.engine()
        let payload = try await signedIn(on: engine)
        let engine2 = try harness.engine()
        harness.scriptRefresh(version: 2)
        harness.scriptIdentityPool(version: 2)

        let refreshed = try await engine2.refresh(payload)

        XCTAssertEqual(harness.cognito.operations, ["GetTokensFromRefreshToken", "GetCredentialsForIdentity"])
        let refresh = try XCTUnwrap(harness.cognito.inputs("GetTokensFromRefreshToken", as: GetTokensFromRefreshTokenInput.self).first)
        XCTAssertEqual(refresh.refreshToken, "refresh-alice-v1")
        XCTAssertEqual(refresh.clientId, ClientFixtures.userPool.appClientId)
        let credentials = harness.cognito.inputs("GetCredentialsForIdentity", as: GetCredentialsForIdentityInput.self)
        XCTAssertEqual(credentials.first?.identityId, LiveEngineFixtures.identityId)
        let decoded = try AmplifyCredentials.decoded(refreshed)
        XCTAssertEqual(decoded.signedInData?.cognitoUserPoolTokens.accessToken, LiveEngineFixtures.jwt("alice", use: "access", version: 2))
        XCTAssertEqual(decoded.identityId, LiveEngineFixtures.identityId)
        XCTAssertEqual(try engine2.awsCredentials(in: refreshed)?.accessKeyId, "AKID-v2")
    }

    /// Every refresh is one forced refresh of that payload: never coalesced, cached or skipped.
    ///
    /// - Given: a signed-in payload with fresh tokens
    /// - When:
    ///    - it is refreshed twice
    /// - Then:
    ///    - `GetTokensFromRefreshToken` was called twice, although nothing needed a refresh
    ///
    func testEveryRefreshIsForced() async throws {
        let engine = try harness.engine()
        let payload = try await signedIn(on: engine)
        harness.scriptRefresh()
        harness.scriptIdentityPool()

        _ = try await engine.refresh(payload)
        _ = try await engine.refresh(payload)

        XCTAssertEqual(harness.cognito.inputs("GetTokensFromRefreshToken", as: GetTokensFromRefreshTokenInput.self).count, 2)
    }

    /// The refresh failure's classification: an expired or revoked refresh token, a reused one, and anything else.
    ///
    /// - Given: a signed-in payload, and `GetTokensFromRefreshToken` failing with each error
    /// - When:
    ///    - it is refreshed
    /// - Then:
    ///    - `NotAuthorizedException` is `refreshTokenInvalid`; `RefreshTokenReuseException` is
    ///      `refreshTokenReused`; `InternalErrorException` is `service` with the mapped error
    ///
    func testRefreshFailuresAreClassified() async throws {
        let engine = try harness.engine()
        let payload = try await signedIn(on: engine)
        let cases: [(Error, (Error) -> Bool)] = [
            (AWSCognitoIdentityProvider.NotAuthorizedException(message: "Refresh Token has been revoked"), {
                if case SessionEngineError.refreshTokenInvalid = $0 { return true }
                return false
            }),
            (RefreshTokenReuseException(message: "Refresh token has been used"), {
                if case SessionEngineError.refreshTokenReused = $0 { return true }
                return false
            }),
            (AWSCognitoIdentityProvider.InternalErrorException(message: "boom"), {
                // Mapped by the engine (to the plugin's unknown), not folded into either refresh-token case.
                if case SessionEngineError.service(.unknown(let description, _, _)) = $0 {
                    return description.contains("boom")
                }
                return false
            })
        ]
        for (thrown, matches) in cases {
            harness.cognito.once("GetTokensFromRefreshToken") { (_: GetTokensFromRefreshTokenInput) -> GetTokensFromRefreshTokenOutput in
                throw thrown
            }

            await assertThrowsAsync({ try await engine.refresh(payload) }) { error in
                XCTAssertTrue(matches(error), "\(thrown) was classified as \(error)")
            }
        }
    }

    /// A payload with no credentials is not refreshed.
    ///
    /// - Given: a `noCredentials` payload
    /// - When:
    ///    - it is refreshed
    /// - Then:
    ///    - it throws `SessionEngineError.notSignedIn`, with no call
    ///
    func testRefreshingNoCredentialsIsNotSignedIn() async throws {
        let engine = try harness.engine()

        await assertThrowsAsync({ try await engine.refresh(EnginePayloadFixtures.data("noCredentials")) }) { error in
            guard case SessionEngineError.notSignedIn = error else {
                return XCTFail("expected notSignedIn, got \(error)")
            }
        }
        XCTAssertEqual(harness.cognito.operations, [])
    }

    // MARK: Guest

    /// Guest credentials: an identity with no logins, and its credentials.
    ///
    /// - Given: the identity pool scripted
    /// - When:
    ///    - guest credentials are fetched with no current payload
    /// - Then:
    ///    - `GetId` has no logins (an empty map); the payload is `identityPoolOnly` with the identity and credentials
    ///
    func testGuestCredentials() async throws {
        let engine = try harness.engine()
        harness.scriptIdentityPool(identityId: "us-east-1:guest")

        let payload = try await engine.fetchGuestCredentials(current: nil)

        XCTAssertEqual(harness.cognito.operations, ["GetId", "GetCredentialsForIdentity"])
        XCTAssertEqual(harness.cognito.inputs("GetId", as: GetIdInput.self).first?.logins ?? [:], [:])
        XCTAssertEqual(try engine.describe(payload), CredentialSummary(kind: .guest, username: nil, userId: nil, identityId: "us-east-1:guest"))
    }

    /// Guest access off: `notSignedIn`, the plugin's `makeSessionWithNoGuestAccess`.
    ///
    /// - Given: `GetId` failing with the identity pool's `NotAuthorizedException`
    /// - When:
    ///    - guest credentials are fetched
    /// - Then:
    ///    - it throws `SessionEngineError.notSignedIn`
    ///
    func testGuestAccessOffIsNotSignedIn() async throws {
        let engine = try harness.engine()
        harness.cognito.once("GetId") { (_: GetIdInput) -> GetIdOutput in
            throw AWSCognitoIdentity.NotAuthorizedException(message: "Unauthenticated access is not supported for this identity pool.")
        }

        await assertThrowsAsync({ try await engine.fetchGuestCredentials(current: nil) }) { error in
            guard case SessionEngineError.notSignedIn = error else {
                return XCTFail("expected notSignedIn, got \(error)")
            }
        }
    }

    /// Without an identity pool there is no guest: a configuration error, with no call.
    ///
    /// - Given: a user-pool-only engine
    /// - When:
    ///    - guest credentials are fetched
    /// - Then:
    ///    - it throws `configuration`
    ///
    func testGuestNeedsAnIdentityPool() async throws {
        harness = LiveEngineHarness(configuration: ClientFixtures.userPoolOnlyConfiguration)
        let engine = try harness.engine()

        await assertThrowsAsync({ try await engine.fetchGuestCredentials(current: nil) }) { error in
            guard case .configuration = authError(error) else {
                return XCTFail("expected configuration, got \(error)")
            }
        }
        XCTAssertEqual(harness.cognito.operations, [])
    }

    // MARK: Revoke and global sign-out

    /// A local sign-out revokes the refresh token and nothing else.
    ///
    /// - Given: alice's signed-in payload
    /// - When:
    ///    - it is revoked with `global: false`
    /// - Then:
    ///    - the only call is `RevokeToken` with her refresh token; the outcome is complete
    ///
    func testRevokeRevokesTheRefreshToken() async throws {
        let engine = try harness.engine()
        let payload = try await signedIn(on: engine)
        harness.scriptSignOut()

        let outcome = try await engine.revoke(payload, global: false)

        XCTAssertEqual(outcome, .complete)
        XCTAssertEqual(harness.cognito.operations, ["RevokeToken"])
        XCTAssertEqual(harness.cognito.inputs("RevokeToken", as: RevokeTokenInput.self).first?.token, "refresh-alice-v1")
    }

    /// A global sign-out signs out everywhere, then revokes.
    ///
    /// - Given: alice's signed-in payload
    /// - When:
    ///    - it is revoked with `global: true`
    /// - Then:
    ///    - the calls are `GlobalSignOut` with her access token, then `RevokeToken`; the outcome is complete
    ///
    func testGlobalSignOutThenRevoke() async throws {
        let engine = try harness.engine()
        let payload = try await signedIn(on: engine)
        harness.scriptSignOut()

        let outcome = try await engine.revoke(payload, global: true)

        XCTAssertEqual(outcome, .complete)
        XCTAssertEqual(harness.cognito.operations, ["GlobalSignOut", "RevokeToken"])
        XCTAssertEqual(
            harness.cognito.inputs("GlobalSignOut", as: GlobalSignOutInput.self).first?.accessToken,
            LiveEngineFixtures.jwt("alice", use: "access")
        )
    }

    /// After a failed global sign-out, `RevokeToken` is not called, and only the real global failure is
    /// reported.
    ///
    /// - Given: `GlobalSignOut` failing
    /// - When:
    ///    - alice's payload is revoked with `global: true`
    /// - Then:
    ///    - the only call is `GlobalSignOut`; the outcome has the mapped global error and `revokeError` nil
    ///
    func testAFailedGlobalSignOutSkipsTheRevoke() async throws {
        let engine = try harness.engine()
        let payload = try await signedIn(on: engine)
        harness.cognito.once("GlobalSignOut") { (_: GlobalSignOutInput) -> GlobalSignOutOutput in
            throw AWSCognitoIdentityProvider.TooManyRequestsException(message: "slow down")
        }
        harness.scriptSignOut()

        let outcome = try await engine.revoke(payload, global: true)

        XCTAssertEqual(harness.cognito.operations, ["GlobalSignOut"])
        XCTAssertNil(outcome.revokeError)
        guard case .service(.requestLimitExceeded?, _, _, _) = outcome.globalSignOutError else {
            return XCTFail("expected the mapped global sign-out failure, got \(String(describing: outcome.globalSignOutError))")
        }
    }

    /// A failed revoke is reported in the outcome, not thrown: sign-out continues locally.
    ///
    /// - Given: `RevokeToken` failing
    /// - When:
    ///    - alice's payload is revoked
    /// - Then:
    ///    - the outcome carries the mapped revoke error, and no global error
    ///
    func testAFailedRevokeIsReportedInTheOutcome() async throws {
        let engine = try harness.engine()
        let payload = try await signedIn(on: engine)
        harness.cognito.once("RevokeToken") { (_: RevokeTokenInput) -> RevokeTokenOutput in
            throw AWSCognitoIdentityProvider.InternalErrorException(message: "boom")
        }

        let outcome = try await engine.revoke(payload, global: false)

        guard case .unknown(let description, _, _) = outcome.revokeError else {
            return XCTFail("expected the mapped revoke failure, got \(String(describing: outcome.revokeError))")
        }
        XCTAssertTrue(description.contains("boom"), description)
        XCTAssertNil(outcome.globalSignOutError)
    }

    /// A guest, federated or empty payload has nothing to revoke: complete, with no call.
    ///
    /// - Given: the guest, federated and no-credentials fixtures
    /// - When:
    ///    - each is revoked, globally
    /// - Then:
    ///    - each outcome is complete, and nothing was called
    ///
    func testPayloadsWithoutUserPoolTokensHaveNothingToRevoke() async throws {
        let engine = try harness.engine()
        for name in ["identityPoolOnly", "identityPoolWithFederation", "noCredentials"] {
            let outcome = try await engine.revoke(EnginePayloadFixtures.data(name), global: true)
            XCTAssertEqual(outcome, .complete, name)
        }
        XCTAssertEqual(harness.cognito.operations, [])
    }

    /// O-3: a hosted-UI session's sign-out skips the hosted-UI step and still revokes.
    ///
    /// - Given: a signed-in payload whose sign-in method is the hosted UI (not a private session), as an
    ///   adopted plugin record would have
    /// - When:
    ///    - it is revoked
    /// - Then:
    ///    - it revokes the refresh token and completes; no hosted-UI sign-out was attempted (without the skip,
    ///      this configuration, which has no OAuth settings, would fail the sign-out)
    ///
    func testAHostedUISessionSignsOutWithoutTheHostedUI() async throws {
        let engine = try harness.engine()
        let payload = try await signedIn(on: engine)
        let hostedUI = try Self.withHostedUISignInMethod(payload)
        harness.scriptSignOut()

        let outcome = try await engine.revoke(hostedUI, global: false)

        XCTAssertEqual(outcome, .complete)
        XCTAssertEqual(harness.cognito.operations, ["RevokeToken"])
    }

    // MARK: Delete user

    /// Deleting the user: `DeleteUser` with the access token. The engine's own sign-out afterwards is
    /// discarded.
    ///
    /// - Given: alice's signed-in payload
    /// - When:
    ///    - the user is deleted
    /// - Then:
    ///    - `DeleteUser` was called first, with her access token, and the call returns
    ///
    func testDeleteUser() async throws {
        let engine = try harness.engine()
        let payload = try await signedIn(on: engine)
        harness.cognito.once("DeleteUser") { (_: DeleteUserInput) in DeleteUserOutput() }
        harness.scriptSignOut()

        try await engine.deleteUser(payload)

        XCTAssertEqual(harness.cognito.operations.first, "DeleteUser")
        XCTAssertEqual(harness.cognito.inputs("DeleteUser", as: DeleteUserInput.self).first?.accessToken, LiveEngineFixtures.jwt("alice", use: "access"))
    }

    /// A user Cognito no longer knows: `.service(.userNotFound)`, which the core answers with a global
    /// sign-out.
    ///
    /// - Given: `DeleteUser` failing with `UserNotFoundException`
    /// - When:
    ///    - the user is deleted
    /// - Then:
    ///    - it throws `.service(.userNotFound, …)`
    ///
    func testDeletingAMissingUserIsUserNotFound() async throws {
        let engine = try harness.engine()
        let payload = try await signedIn(on: engine)
        harness.cognito.once("DeleteUser") { (_: DeleteUserInput) -> DeleteUserOutput in
            throw UserNotFoundException(message: "User does not exist.")
        }

        await assertThrowsAsync({ try await engine.deleteUser(payload) }) { error in
            guard case .service(.userNotFound?, _, _, _) = authError(error) else {
                return XCTFail("expected .service(.userNotFound), got \(error)")
            }
        }
    }

    // MARK: Helpers

    /// `payload` with its sign-in method replaced by a hosted-UI one, as the plugin writes after a web UI
    /// sign-in.
    static func withHostedUISignInMethod(_ payload: Data) throws -> Data {
        var tree = try XCTUnwrap(JSONSerialization.jsonObject(with: payload) as? [String: Any])
        var kind = try XCTUnwrap(tree["userPoolAndIdentityPool"] as? [String: Any])
        var signedIn = try XCTUnwrap(kind["signedInData"] as? [String: Any])
        let hostedUI = SignInMethod.hostedUI(HostedUIOptions(
            scopes: ["openid"],
            providerInfo: HostedUIProviderInfo(authProvider: nil, idpIdentifier: nil),
            presentationAnchor: nil,
            preferPrivateSession: false,
            nonce: nil,
            language: nil,
            loginHint: nil,
            prompt: nil,
            resource: nil
        ))
        signedIn["signInMethod"] = try JSONSerialization.jsonObject(with: JSONEncoder().encode(hostedUI))
        kind["signedInData"] = signedIn
        tree["userPoolAndIdentityPool"] = kind
        return try JSONSerialization.data(withJSONObject: tree)
    }
}

extension LiveEngineHarness {

    /// The same harness, keychain and scripts, with the call log cleared.
    func resettingCalls() -> LiveEngineHarness {
        cognito.clearCalls()
        return self
    }
}
