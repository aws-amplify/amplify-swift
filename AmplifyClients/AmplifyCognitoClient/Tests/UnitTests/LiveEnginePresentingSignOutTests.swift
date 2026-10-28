//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(macOS) || os(visionOS)
import AWSCognitoIdentityProvider
import InternalAWSCognitoAuth
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// The live engine's sign-out with the hosted UI's logout page, over a payload the Auth plugin marked expired: the
/// client decides what a closed page does with an expired session, not the plugin's persisted flag.
final class LiveEnginePresentingSignOutTests: XCTestCase {

    private var presenter: PresenterSpy!
    private var harness: LiveEngineHarness!

    override func setUp() async throws {
        presenter = PresenterSpy()
        harness = LiveEngineHarness(
            configuration: HostedUIFixtures.configuration,
            hostedUIPresenter: presenter,
            hostedUIURLSession: TokenEndpointStub.session
        )
        let presenter = presenter!
        TokenEndpointStub.respond { _ in TokenEndpointStub.tokens("alice", nonce: presenter.lastQueryItem("nonce")) }
        harness.scriptIdentityPool()
    }

    override func tearDown() {
        TokenEndpointStub.reset()
        presenter = nil
        harness = nil
    }

    /// - Given: a shared-cookie hosted-UI payload whose `isRefreshTokenExpired` is set, as the Auth plugin persists
    ///   it in `.default`'s shared record
    /// - When: it is revoked with `.present`, and the user closes the logout page
    /// - Then:
    ///    - the revoke throws `.userCancelled` and nothing is revoked, as for any other payload: the engine does not
    ///      sign out past the closed page on the plugin's flag
    func testClosingTheLogoutPageOfAPayloadThePluginMarkedExpiredRevokesNothing() async throws {
        let payload = try await expired(sharedCookiePayload())
        presenter.behave(.fail(.cancelled))
        harness.scriptSignOut()
        harness.cognito.clearCalls()
        let engine = try harness.engine()

        let error = await authClientError { try await engine.revoke(payload, global: false, hostedUI: .present(box())) }

        XCTAssertEqual(error?.kind, .userCancelled)
        XCTAssertEqual(harness.cognito.operations, [])
    }

    /// - Given: a shared-cookie hosted-UI payload whose `isRefreshTokenExpired` is set
    /// - When: it is revoked with `.present`, and the logout page completes
    /// - Then:
    ///    - the token is revoked and the outcome is complete
    func testAPayloadThePluginMarkedExpiredStillSignsOutThroughThePage() async throws {
        let payload = try await expired(sharedCookiePayload())
        harness.scriptSignOut()
        harness.cognito.clearCalls()
        let engine = try harness.engine()

        let outcome = try await engine.revoke(payload, global: false, hostedUI: .present(box()))

        XCTAssertEqual(outcome, .complete)
        XCTAssertEqual(harness.cognito.operations, ["RevokeToken"])
    }

    /// - Given: payloads with `isRefreshTokenExpired` set and not set, and payloads without user pool tokens
    /// - When: each is made a presenting sign-out's seed
    /// - Then:
    ///    - the flag is cleared and every other field kept; a payload without the flag set, or without user pool
    ///      tokens, is the same bytes
    func testThePresentingSignOutsSeedClearsOnlyTheExpiredFlag() async throws {
        let payload = try await sharedCookiePayload()
        let expired = try expired(payload)

        let seed = try LiveSessionEngine.presentingSignOutSeed(expired)

        let seeded = try AmplifyCredentials.decoded(seed)
        XCTAssertEqual(seeded.signedInData?.isRefreshTokenExpired, false)
        XCTAssertEqual(seeded, try AmplifyCredentials.decoded(payload))
        XCTAssertEqual(try LiveSessionEngine.presentingSignOutSeed(payload), payload)
        let guest = try CredentialSlot.encode(.identityPoolOnly(
            identityID: "identity",
            credentials: EngineAWSCredentials(accessKeyId: "a", secretAccessKey: "s", sessionToken: "t", expiration: Date())
        ))
        XCTAssertEqual(try LiveSessionEngine.presentingSignOutSeed(guest), guest)
    }

    // MARK: Helpers

    private func box() async -> EnginePresentationAnchorBox {
        let window = await HostedUIFixtures.window()
        return await MainActor.run { EnginePresentationAnchorBox(window) }
    }

    private func sharedCookiePayload() async throws -> Data {
        let engine = try harness.engine()
        let window = await HostedUIFixtures.window()
        let box = await MainActor.run { EnginePresentationAnchorBox(window) }
        let request = EngineWebUISignInRequest(
            anchor: box,
            options: EngineWebUIOptions(WebUIOptions(prefersEphemeralSession: false), nonce: "flow-nonce"),
            identity: .none
        )
        guard case .done(let payload) = try await engine.signInWithWebUI(request, current: nil, epoch: 0) else {
            throw FixtureError(description: "the hosted-UI sign-in did not finish")
        }
        return payload
    }

    /// `payload` with `isRefreshTokenExpired` set, as the plugin saves it once a refresh found the token dead.
    private func expired(_ payload: Data) throws -> Data {
        switch try AmplifyCredentials.decoded(payload) {
        case .userPoolAndIdentityPool(var signedInData, let identityID, let credentials):
            signedInData.isRefreshTokenExpired = true
            return try CredentialSlot.encode(.userPoolAndIdentityPool(
                signedInData: signedInData,
                identityID: identityID,
                credentials: credentials
            ))
        case .userPoolOnly(var signedInData):
            signedInData.isRefreshTokenExpired = true
            return try CredentialSlot.encode(.userPoolOnly(signedInData: signedInData))
        case .identityPoolOnly, .identityPoolWithFederation, .noCredentials:
            throw FixtureError(description: "the payload has no user pool tokens")
        }
    }
}
#endif
