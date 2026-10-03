//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentity
import Foundation
import InternalAWSCognitoAuth
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// The live engine's federation over a scripted identity pool (`GetId` with the provider's
/// login, then `GetCredentialsForIdentity`), the refresh of a federated payload, and the public API over
/// the live engine end to end.
final class LiveEngineFederationTests: XCTestCase {

    private var harness: LiveEngineHarness!

    override func setUp() {
        super.setUp()
        harness = LiveEngineHarness()
    }

    override func tearDown() {
        harness = nil
        super.tearDown()
    }

    private static func request(
        _ token: String = "provider-token",
        _ provider: AuthClientProvider = .facebook,
        developerProvidedIdentityId: String? = nil
    ) -> EngineFederationRequest {
        EngineFederationRequest(token: token, provider: provider, developerProvidedIdentityId: developerProvidedIdentityId)
    }

    // MARK: Federating

    /// - Given: the identity pool scripted
    /// - When: a Facebook token is federated with no current payload
    /// - Then:
    ///    - `GetId` carries the token under `graph.facebook.com`, then `GetCredentialsForIdentity` carries it
    ///      for the identity `GetId` returned
    ///    - the payload is `identityPoolWithFederation` with the token, the identity and the credentials, and
    ///      describes as federated with no user
    func testFederationSendsTheProviderLoginToGetIdThenGetCredentials() async throws {
        let engine = try harness.engine()
        harness.scriptIdentityPool(identityId: "us-east-1:federated-id")

        let payload = try await engine.federateToIdentityPool(Self.request(), current: nil)

        XCTAssertEqual(harness.cognito.operations, ["GetId", "GetCredentialsForIdentity"])
        let getId = try XCTUnwrap(harness.cognito.inputs("GetId", as: GetIdInput.self).first)
        XCTAssertEqual(getId.logins, ["graph.facebook.com": "provider-token"])
        let getCredentials = try XCTUnwrap(harness.cognito.inputs("GetCredentialsForIdentity", as: GetCredentialsForIdentityInput.self).first)
        XCTAssertEqual(getCredentials.identityId, "us-east-1:federated-id")
        XCTAssertEqual(getCredentials.logins, ["graph.facebook.com": "provider-token"])
        guard case .identityPoolWithFederation(let token, let identityId, let credentials) = try AmplifyCredentials.decoded(payload) else {
            return XCTFail("expected a federated payload")
        }
        XCTAssertEqual(token, FederatedToken(token: "provider-token", provider: .facebook))
        XCTAssertEqual(identityId, "us-east-1:federated-id")
        XCTAssertEqual(credentials.accessKeyId, "AKID-v1")
        XCTAssertEqual(
            try engine.describe(payload),
            CredentialSummary(kind: .federated, username: nil, userId: nil, identityId: "us-east-1:federated-id")
        )
    }

    /// Every provider reaches the identity pool under the engine's login key.
    ///
    /// - Given: the identity pool scripted
    /// - When: each provider's token is federated
    /// - Then:
    ///    - `GetId`'s login key is the plugin's identity pool provider name: the well-known domains, or the
    ///      name given for OIDC, SAML and custom providers
    func testEachProviderUsesTheIdentityPoolLoginKey() async throws {
        let cases: [(AuthClientProvider, String)] = [
            (.amazon, "www.amazon.com"),
            (.apple, "appleid.apple.com"),
            (.facebook, "graph.facebook.com"),
            (.google, "accounts.google.com"),
            (.twitter, "api.twitter.com"),
            (.oidc("issuer.example.com"), "issuer.example.com"),
            (.saml("saml-provider"), "saml-provider"),
            (.custom("login.example.app"), "login.example.app")
        ]
        harness.scriptIdentityPool()
        for (provider, key) in cases {
            harness.cognito.clearCalls()
            _ = try await harness.engine().federateToIdentityPool(Self.request("t", provider), current: nil)
            XCTAssertEqual(harness.cognito.inputs("GetId", as: GetIdInput.self).first?.logins, [key: "t"], "\(provider)")
        }
    }

    /// With a developer-provided identity ID the engine skips `GetId`, as the plugin does.
    ///
    /// - Given: the identity pool scripted
    /// - When: a token is federated with a developer-provided identity ID
    /// - Then:
    ///    - the only call is `GetCredentialsForIdentity` for that identity; the payload holds it
    func testADeveloperProvidedIdentitySkipsGetId() async throws {
        let engine = try harness.engine()
        harness.scriptIdentityPool()

        let payload = try await engine.federateToIdentityPool(
            Self.request(developerProvidedIdentityId: "us-east-1:developer-id"),
            current: nil
        )

        XCTAssertEqual(harness.cognito.operations, ["GetCredentialsForIdentity"])
        XCTAssertEqual(harness.cognito.inputs("GetCredentialsForIdentity", as: GetCredentialsForIdentityInput.self).first?.identityId, "us-east-1:developer-id")
        XCTAssertEqual(try engine.describe(payload).identityId, "us-east-1:developer-id")
    }

    /// A guest's payload seeds the federation, as the plugin's machine federates from an established guest
    /// session; the federation replaces the guest's identity.
    ///
    /// - Given: a guest payload
    /// - When: a token is federated with it as `current`
    /// - Then:
    ///    - `GetId` is called with the login (the guest's identity is not reused); the payload is federated
    func testAGuestFederates() async throws {
        harness.scriptIdentityPool(identityId: "us-east-1:guest")
        let guest = try await harness.engine().fetchGuestCredentials(current: nil)
        harness.cognito.clearCalls()
        harness.cognito.always("GetId") { (_: GetIdInput) in GetIdOutput(identityId: "us-east-1:federated-id") }

        let payload = try await harness.engine().federateToIdentityPool(Self.request(), current: guest)

        XCTAssertEqual(harness.cognito.operations, ["GetId", "GetCredentialsForIdentity"])
        XCTAssertEqual(harness.cognito.inputs("GetId", as: GetIdInput.self).first?.logins, ["graph.facebook.com": "provider-token"])
        XCTAssertEqual(try harness.engine().describe(payload).kind, .federated)
        XCTAssertEqual(try harness.engine().describe(payload).identityId, "us-east-1:federated-id")
    }

    /// FE-1's unit mirror: the identity pool rejects the token.
    ///
    /// - Given: `GetId` failing with the identity pool's `NotAuthorizedException`
    /// - When: the token is federated
    /// - Then:
    ///    - it throws `SessionEngineError.service(.notAuthorized)`, the plugin's `AuthError.notAuthorized`,
    ///      and no credentials are requested
    func testARejectedTokenIsNotAuthorized() async throws {
        let engine = try harness.engine()
        harness.cognito.once("GetId") { (_: GetIdInput) -> GetIdOutput in
            throw AWSCognitoIdentity.NotAuthorizedException(message: "Invalid login token. Not a valid OpenId Connect identity token.")
        }

        await assertThrowsAsync({ try await engine.federateToIdentityPool(Self.request("someToken"), current: nil) }) { error in
            guard case SessionEngineError.service(.notAuthorized) = error else {
                return XCTFail("expected notAuthorized, got \(error)")
            }
        }
        XCTAssertEqual(harness.cognito.operations, ["GetId"])
    }

    /// The identity pool can accept the login for `GetId`, then refuse it for the credentials.
    ///
    /// - Given: `GetId` answering an identity, and `GetCredentialsForIdentity` failing with `NotAuthorizedException`
    /// - When: the token is federated
    /// - Then:
    ///    - it throws `.service(.notAuthorized)` after both calls, with no retry
    func testCredentialsRefusedAfterGetIdAreNotAuthorized() async throws {
        let engine = try harness.engine()
        harness.cognito.always("GetId") { (_: GetIdInput) in GetIdOutput(identityId: "us-east-1:federated-id") }
        harness.cognito.always("GetCredentialsForIdentity") { (_: GetCredentialsForIdentityInput) -> GetCredentialsForIdentityOutput in
            throw AWSCognitoIdentity.NotAuthorizedException(message: "Invalid login token. Token is expired.")
        }

        await assertThrowsAsync({ try await engine.federateToIdentityPool(Self.request(), current: nil) }) { error in
            guard case SessionEngineError.service(.notAuthorized) = error else {
                return XCTFail("expected notAuthorized, got \(error)")
            }
        }
        XCTAssertEqual(harness.cognito.operations, ["GetId", "GetCredentialsForIdentity"])
    }

    /// A developer-provided identity the identity pool refuses for this login.
    ///
    /// - Given: `GetCredentialsForIdentity` failing with `NotAuthorizedException` for the developer's identity
    /// - When: the token is federated with that identity
    /// - Then:
    ///    - it throws `.service(.notAuthorized)` after the one call: no `GetId`, no retry
    func testARejectedDeveloperProvidedIdentityIsNotAuthorized() async throws {
        let engine = try harness.engine()
        harness.cognito.always("GetCredentialsForIdentity") { (_: GetCredentialsForIdentityInput) -> GetCredentialsForIdentityOutput in
            throw AWSCognitoIdentity.NotAuthorizedException(message: "Invalid identity for this login.")
        }

        await assertThrowsAsync({
            try await engine.federateToIdentityPool(Self.request(developerProvidedIdentityId: "us-east-1:developer-id"), current: nil)
        }) { error in
            guard case SessionEngineError.service(.notAuthorized) = error else {
                return XCTFail("expected notAuthorized, got \(error)")
            }
        }
        XCTAssertEqual(harness.cognito.operations, ["GetCredentialsForIdentity"])
    }

    /// A provider the identity pool is not configured for, or does not know, is a service error with the
    /// identity pool's code, not `notAuthorized`.
    ///
    /// - Given: `GetId` failing with `InvalidParameterException`, then with `ResourceNotFoundException`
    /// - When: a token is federated each time
    /// - Then:
    ///    - each throws `.service` with `invalidParameter`, then `resourceNotFound`
    func testAnUnconfiguredProviderIsAServiceError() async throws {
        let cases: [(Error, AuthClientServiceErrorCode)] = [
            (AWSCognitoIdentity.InvalidParameterException(message: "Invalid login provider."), .invalidParameter),
            (AWSCognitoIdentity.ResourceNotFoundException(message: "Identity pool not found."), .resourceNotFound)
        ]
        for (thrown, code) in cases {
            harness.cognito.clearCalls()
            harness.cognito.once("GetId") { (_: GetIdInput) -> GetIdOutput in throw thrown }
            await assertThrowsAsync({
                try await self.harness.engine().federateToIdentityPool(Self.request("t", .oidc("unknown.example.com")), current: nil)
            }) { error in
                guard case SessionEngineError.service(.service(code?, _, _, _)) = error else {
                    return XCTFail("expected \(code), got \(error)")
                }
            }
            XCTAssertEqual(harness.cognito.operations, ["GetId"])
        }
    }

    /// - Given: a user-pool-only engine
    /// - When: a token is federated
    /// - Then:
    ///    - it throws `configuration`, with no call
    func testFederationNeedsAnIdentityPool() async throws {
        harness = LiveEngineHarness(configuration: ClientFixtures.userPoolOnlyConfiguration)
        let engine = try harness.engine()

        await assertThrowsAsync({ try await engine.federateToIdentityPool(Self.request(), current: nil) }) { error in
            guard case .configuration = authError(error) else {
                return XCTFail("expected configuration, got \(error)")
            }
        }
        XCTAssertEqual(harness.cognito.operations, [])
    }

    // MARK: Refresh

    /// A federated payload refreshes by federating again with its stored token and identity, as the plugin's
    /// `refreshIfRequired` does.
    ///
    /// - Given: a federated payload
    /// - When: it is refreshed
    /// - Then:
    ///    - the only call is `GetCredentialsForIdentity` for the stored identity, with the stored login
    ///    - the payload is federated, with the same token and identity and the new credentials
    func testRefreshOfAFederatedPayloadReusesItsTokenAndIdentity() async throws {
        harness.scriptIdentityPool(identityId: "us-east-1:federated-id")
        let payload = try await harness.engine().federateToIdentityPool(Self.request(), current: nil)
        harness.cognito.clearCalls()
        harness.scriptIdentityPool(identityId: "us-east-1:federated-id", version: 2)

        let refreshed = try await harness.engine().refresh(payload, force: false)

        XCTAssertEqual(harness.cognito.operations, ["GetCredentialsForIdentity"])
        let input = try XCTUnwrap(harness.cognito.inputs("GetCredentialsForIdentity", as: GetCredentialsForIdentityInput.self).first)
        XCTAssertEqual(input.identityId, "us-east-1:federated-id")
        XCTAssertEqual(input.logins, ["graph.facebook.com": "provider-token"])
        guard case .identityPoolWithFederation(let token, let identityId, let credentials) = try AmplifyCredentials.decoded(refreshed) else {
            return XCTFail("expected a federated payload")
        }
        XCTAssertEqual(token.token, "provider-token")
        XCTAssertEqual(identityId, "us-east-1:federated-id")
        XCTAssertEqual(credentials.accessKeyId, "AKID-v2")
    }

    /// A stored provider token the identity pool no longer accepts is a dead login, as a dead refresh token is.
    ///
    /// - Given: a federated payload, and `GetCredentialsForIdentity` failing with `NotAuthorizedException`
    /// - When: it is refreshed
    /// - Then:
    ///    - it throws `SessionEngineError.refreshTokenInvalid`, which the core reports as `sessionExpired`
    func testRefreshWithAnExpiredProviderTokenIsRefreshTokenInvalid() async throws {
        harness.scriptIdentityPool(identityId: "us-east-1:federated-id")
        let payload = try await harness.engine().federateToIdentityPool(Self.request(), current: nil)
        harness.cognito.clearCalls()
        harness.cognito.always("GetCredentialsForIdentity") { (_: GetCredentialsForIdentityInput) -> GetCredentialsForIdentityOutput in
            throw AWSCognitoIdentity.NotAuthorizedException(message: "Invalid login token. Token is expired.")
        }

        await assertThrowsAsync({ try await self.harness.engine().refresh(payload, force: false) }) { error in
            guard case SessionEngineError.refreshTokenInvalid = error else {
                return XCTFail("expected refreshTokenInvalid, got \(error)")
            }
        }
        XCTAssertEqual(harness.cognito.operations, ["GetCredentialsForIdentity"])
    }

    /// Any other failure of a federated refresh keeps its mapped error: only a refused login expires it.
    ///
    /// - Given: a federated payload, and `GetCredentialsForIdentity` failing with `TooManyRequestsException`
    /// - When: it is refreshed
    /// - Then:
    ///    - it throws `SessionEngineError.service`, not `refreshTokenInvalid`
    func testOtherFederatedRefreshFailuresAreNotExpiry() async throws {
        harness.scriptIdentityPool(identityId: "us-east-1:federated-id")
        let payload = try await harness.engine().federateToIdentityPool(Self.request(), current: nil)
        harness.cognito.always("GetCredentialsForIdentity") { (_: GetCredentialsForIdentityInput) -> GetCredentialsForIdentityOutput in
            throw AWSCognitoIdentity.TooManyRequestsException(message: "Rate exceeded")
        }

        await assertThrowsAsync({ try await self.harness.engine().refresh(payload, force: false) }) { error in
            guard case SessionEngineError.service = error else {
                return XCTFail("expected service, got \(error)")
            }
        }
    }

    // MARK: The public API over the live engine

    /// A client over the live engine and a scripted identity pool, on `work`.
    private func liveClient(_ clientHarness: ClientHarness) throws -> AmplifyCognitoClient {
        let base = clientHarness.dependencies
        let harness = harness!
        let dependencies = SessionCoreDependencies(
            registry: base.registry,
            gates: base.gates,
            makeStore: base.makeStore,
            makeClients: base.makeClients,
            makeEngine: { _ in try harness.engine() },
            makeRevoker: base.makeRevoker,
            scheduleRestore: base.scheduleRestore,
            bounds: base.bounds,
            now: { Date() }
        )
        return try AmplifyCognitoClient(
            configuration: ClientFixtures.configuration,
            options: .init(sessionId: ClientFixtures.id("work")),
            dependencies: dependencies
        )
    }

    /// An expired provider token expires the session (the client's divergence from the plugin):
    /// `.sessionExpired` once, every field `sessionExpired` with no further request, the state still
    /// `.federated`; federating again recovers it.
    ///
    /// - Given: a client federated over the live engine, whose stored login the identity pool then refuses
    /// - When: the session is force-refreshed, fetched again, and federated again
    /// - Then:
    ///    - the refresh reports `sessionExpired` in every field and sends `.sessionExpired` once; the state is
    ///      still `.federated`; the second fetch makes no request
    ///    - federating again succeeds, and the session's credentials are served again
    func testAnExpiredProviderTokenExpiresTheSessionUntilItFederatesAgain() async throws {
        let clientHarness = ClientHarness()
        let client = try liveClient(clientHarness)
        harness.scriptIdentityPool(identityId: "us-east-1:federated-id")
        _ = try await client.federateToIdentityPool(withProviderToken: "provider-token", for: .google)
        let events = StreamRecorder(client.listenToAuthEvents())
        harness.cognito.once("GetCredentialsForIdentity") { (_: GetCredentialsForIdentityInput) -> GetCredentialsForIdentityOutput in
            throw AWSCognitoIdentity.NotAuthorizedException(message: "Invalid login token. Token is expired.")
        }
        harness.cognito.clearCalls()

        let expired = try await client.fetchAuthSession(options: .init(forceRefresh: true))
        harness.cognito.clearCalls()
        let again = try await client.fetchAuthSession()
        let state = await client.currentSessionState()

        for session in [expired, again] {
            XCTAssertThrowsError(try session.awsCredentialsResult.get()) { error in
                guard case .sessionExpired = authError(error) else {
                    return XCTFail("expected sessionExpired, got \(error)")
                }
            }
        }
        XCTAssertEqual(harness.cognito.operations, [])
        XCTAssertEqual(state, .federated(identityId: "us-east-1:federated-id"))
        await events.waitFor(1)
        XCTAssertEqual(events.received, [.sessionExpired])

        _ = try await client.federateToIdentityPool(withProviderToken: "fresh-token", for: .google)
        let recovered = try await client.fetchAuthSession()
        XCTAssertEqual(try recovered.awsCredentialsResult.get().accessKeyId, "AKID-v1")
    }


    /// Federation end to end over the live engine and a scripted identity pool.
    ///
    /// - Given: a signed-out client over the live engine
    /// - When: it federates, is fetched, clears the federation, and federates and signs out
    /// - Then:
    ///    - the result, the state, the session and the stored record all hold the federated identity and its
    ///      credentials, with no user
    ///    - clearing leaves the row signed out; the sign-out makes no Cognito call
    func testFederationOverTheLiveEngine() async throws {
        let clientHarness = ClientHarness()
        let base = clientHarness.dependencies
        let harness = harness!
        let dependencies = SessionCoreDependencies(
            registry: base.registry,
            gates: base.gates,
            makeStore: base.makeStore,
            makeClients: base.makeClients,
            makeEngine: { _ in try harness.engine() },
            makeRevoker: base.makeRevoker,
            scheduleRestore: base.scheduleRestore,
            bounds: base.bounds,
            now: { Date() }
        )
        let work = ClientFixtures.id("work")
        let client = try AmplifyCognitoClient(
            configuration: ClientFixtures.configuration,
            options: .init(sessionId: work),
            dependencies: dependencies
        )
        harness.scriptIdentityPool(identityId: "us-east-1:federated-id")

        let result = try await client.federateToIdentityPool(withProviderToken: "provider-token", for: .google)
        let state = await client.currentSessionState()
        let session = try await client.fetchAuthSession()
        let record = try clientHarness.storedRecord(work)

        XCTAssertEqual(result.identityId, "us-east-1:federated-id")
        XCTAssertEqual(result.credentials.accessKeyId, "AKID-v1")
        XCTAssertEqual(state, .federated(identityId: "us-east-1:federated-id"))
        XCTAssertEqual(try session.identityIdResult.get(), "us-east-1:federated-id")
        XCTAssertEqual(try session.awsCredentialsResult.get().accessKeyId, "AKID-v1")
        XCTAssertThrowsError(try session.userPoolTokensResult.get())
        XCTAssertEqual(record?.kind, .federated)
        XCTAssertNil(record?.username)

        try await client.clearFederationToIdentityPool()
        XCTAssertEqual(try clientHarness.storedRecord(work)?.kind, SessionKind.signedOut)
        let cleared = await client.currentSessionState()
        XCTAssertEqual(cleared, .signedOut)

        _ = try await client.federateToIdentityPool(withProviderToken: "provider-token", for: .google)
        harness.cognito.clearCalls()
        let signOut = await client.signOut()
        XCTAssertEqual(signOut, .complete)
        XCTAssertEqual(harness.cognito.operations, [])
        let signedOut = await client.currentSessionState()
        XCTAssertEqual(signedOut, .signedOut)
    }
}
