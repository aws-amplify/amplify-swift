//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(macOS) || os(visionOS)
import AWSCognitoIdentity
import AWSCognitoIdentityProvider
import InternalAWSCognitoAuth
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// The hosted UI through a session core over the live engine: scripted Cognito, a presenter spy, a stubbed
/// token endpoint, and the client harness's own sheet lock. What the fake engine cannot show: whether a
/// revoke the core sends after an interrupt really reaches Cognito.
final class LiveWebUICoreTests: XCTestCase {

    private var presenter: PresenterSpy!
    private var live: LiveEngineHarness!
    private var harness: ClientHarness!
    private var window: AuthClientPresentationAnchor!
    private let work = ClientFixtures.id("work")

    override func setUp() async throws {
        presenter = PresenterSpy()
        live = LiveEngineHarness(
            configuration: HostedUIFixtures.configuration,
            hostedUIPresenter: presenter,
            hostedUIURLSession: TokenEndpointStub.session
        )
        harness = ClientHarness()
        window = await HostedUIFixtures.window()
        let presenter = presenter!
        TokenEndpointStub.respond { _ in TokenEndpointStub.tokens("alice", nonce: presenter.lastQueryItem("nonce")) }
        live.scriptIdentityPool()
        live.scriptSignOut()
    }

    override func tearDown() async throws {
        TokenEndpointStub.reset()
        let holder = await harness.sheetLock.currentHolder
        XCTAssertNil(holder, "a test left the sheet held")
        presenter = nil
        live = nil
        harness = nil
        window = nil
    }

    /// A client whose session core runs the live engine.
    private func client(_ sessionId: SessionID) throws -> AmplifyCognitoClient {
        let engine = try live.engine()
        var dependencies = harness.dependencies
        dependencies = SessionCoreDependencies(
            registry: dependencies.registry,
            gates: dependencies.gates,
            makeStore: dependencies.makeStore,
            makeClients: dependencies.makeClients,
            makeEngine: { _ in engine },
            makeRevoker: dependencies.makeRevoker,
            scheduleRestore: dependencies.scheduleRestore,
            bounds: dependencies.bounds,
            now: { Date() }
        )
        dependencies.sheetLock = harness.sheetLock
        return try AmplifyCognitoClient(
            configuration: HostedUIFixtures.configuration,
            options: .init(sessionId: sessionId),
            dependencies: dependencies
        )
    }

    private func revokedRefreshTokens() -> [String] {
        live.cognito.inputs("RevokeToken", as: RevokeTokenInput.self).compactMap(\.token)
    }

    /// A late `.done` after an interrupt reaches Cognito's `RevokeToken`
    ///
    /// - Given: a hosted-UI sign-in whose code exchange is held at the token endpoint
    /// - When:
    ///    - `cancelWebUISignIn()` interrupts it, then the exchange returns alice's tokens
    /// - Then:
    ///    - the caller gets `.userCancelled`; the issued refresh token is revoked at Cognito; nothing is committed
    func testALateDoneAfterAnInterruptIsRevokedAtCognito() async throws {
        let exchange = Stall()
        let presenter = presenter!
        TokenEndpointStub.respond { _ in
            exchange.block()
            return TokenEndpointStub.tokens("alice", nonce: presenter.lastQueryItem("nonce"))
        }
        let client = try client(work)
        let window = window!
        let signIn = Task { try await client.signInWithWebUI(presentationAnchor: window) }
        await waitUntil("the code exchange is held") { exchange.hasBeenReached }

        await client.cancelWebUISignIn()
        let error = await authClientError { try await signIn.value }
        XCTAssertEqual(error?.kind, .userCancelled)
        exchange.release()

        await waitUntil("the late refresh token is revoked") { self.revokedRefreshTokens() == ["refresh-alice-hosted"] }
        XCTAssertNil(try harness.storedRecord(work))
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedOut)
        let lock = harness.sheetLock
        await waitUntil("the sheet is free") { await lock.currentHolder == nil }
    }

    /// A `.done` the body returned just before an interrupt reaches `RevokeToken`
    ///
    /// - Given: a hosted-UI sign-in whose body has returned alice's tokens, held before the lock releases its
    ///   lease
    /// - When:
    ///    - `cancelWebUISignIn()` interrupts it there
    /// - Then:
    ///    - the caller gets `.userCancelled`; alice's refresh token is revoked at Cognito once; nothing is
    ///      committed
    func testADoneReturnedJustBeforeAnInterruptIsRevokedAtCognito() async throws {
        let held = Gate()
        harness.sheetLock = SystemSheetLock(beforeRelease: { _ in await held.pass() })
        let client = try client(work)
        let window = window!
        let signIn = Task { try await client.signInWithWebUI(presentationAnchor: window) }
        await held.waitForArrivals(1)

        await client.cancelWebUISignIn()
        let error = await authClientError { try await signIn.value }
        XCTAssertEqual(error?.kind, .userCancelled)

        await waitUntil("the refresh token is revoked") { self.revokedRefreshTokens() == ["refresh-alice-hosted"] }
        await held.open()
        let lock = harness.sheetLock
        await waitUntil("the sheet is free") { await lock.currentHolder == nil }
        XCTAssertNil(try harness.storedRecord(work))
        XCTAssertEqual(revokedRefreshTokens(), ["refresh-alice-hosted"])
    }

    /// A sign-out that lands during the code exchange
    ///
    /// - Given: a hosted-UI sign-in whose code exchange is held at the token endpoint
    /// - When:
    ///    - the session is signed out, which stops the engine's machine, then the exchange returns alice's tokens
    /// - Then:
    ///    - the sign-in throws the sign-in-cancelled `invalidState`; the refresh token the exchange was issued is
    ///      revoked at Cognito, exactly once; nothing is committed
    func testATokenIssuedAfterASignOutStoppedTheFlowIsRevokedOnce() async throws {
        let exchange = Stall()
        let presenter = presenter!
        TokenEndpointStub.respond { _ in
            exchange.block()
            return TokenEndpointStub.tokens("alice", nonce: presenter.lastQueryItem("nonce"))
        }
        let client = try client(work)
        let window = window!
        let signIn = Task { try await client.signInWithWebUI(presentationAnchor: window) }
        await waitUntil("the code exchange is held") { exchange.hasBeenReached }

        _ = try await client.signOut()
        let error = await authClientError { try await signIn.value }
        XCTAssertEqual(error?.errorDescription, SessionCore.signInCancelled().errorDescription)
        exchange.release()

        await waitUntil("the issued refresh token is revoked") { self.revokedRefreshTokens() == ["refresh-alice-hosted"] }
        try await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertEqual(revokedRefreshTokens(), ["refresh-alice-hosted"], "revoked exactly once")
        XCTAssertNil(try harness.storedRecord(work)?.credentials)
    }

    /// - Given: a hosted-UI sign-in through the live engine
    /// - When: it completes
    /// - Then:
    ///    - the session is signed in and Cognito is never asked to revoke anything: neither the tap nor the claim
    ///      revokes the tokens of a sign-in nobody stopped
    func testASuccessfulSignInRevokesNothing() async throws {
        let client = try client(work)
        let window = window!

        _ = try await client.signInWithWebUI(presentationAnchor: window)

        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedIn(AuthClientUser(username: "alice", userId: "sub-alice")))
        try await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertEqual(revokedRefreshTokens(), [])
    }

    /// A sign-out once the exchange has signed the machine in, while the identity pool step runs
    ///
    /// - Given: a hosted-UI sign-in whose tokens have been issued and whose `GetId` is held
    /// - When: the session is signed out there, so the step hands back the issued tokens as `.done`, then `GetId`
    ///   answers
    /// - Then:
    ///    - the sign-in throws the sign-in-cancelled `invalidState`; the refresh token is revoked exactly once (the
    ///      tap excludes what the step hands back, and the claim revokes it); nothing is committed
    func testASignOutAfterTheExchangeRevokesTheHandedBackTokensOnce() async throws {
        let identity = Gate()
        live.cognito.once("GetId") { (_: GetIdInput) in
            await identity.pass()
            return GetIdOutput(identityId: LiveEngineFixtures.identityId)
        }
        let client = try client(work)
        let window = window!
        let signIn = Task { try await client.signInWithWebUI(presentationAnchor: window) }
        await identity.waitForArrivals(1)

        _ = try await client.signOut()
        let error = await authClientError { try await signIn.value }
        XCTAssertEqual(error?.errorDescription, SessionCore.signInCancelled().errorDescription)
        await identity.open()

        await waitUntil("the handed-back refresh token is revoked") { self.revokedRefreshTokens() == ["refresh-alice-hosted"] }
        try await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertEqual(revokedRefreshTokens(), ["refresh-alice-hosted"], "revoked exactly once")
        XCTAssertNil(try harness.storedRecord(work)?.credentials)
    }

    // MARK: A response the identity check refuses

    /// Signs `sessionId` in through the hosted UI, expecting the identity check to refuse the response.
    private func assertRefusalRevokesTheIssuedTokenOnce(
        _ sessionId: SessionID,
        options: WebUIOptions = WebUIOptions(),
        expecting kind: AuthClientError.Kind,
        _ context: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        live.cognito.clearCalls()
        let client = try client(sessionId)
        let window = window!

        let error = await authClientError({ try await client.signInWithWebUI(presentationAnchor: window, options: options) }, file: file, line: line)

        XCTAssertEqual(error?.kind, kind, context, file: file, line: line)
        await waitUntil("the refused refresh token is revoked (\(context))") { self.revokedRefreshTokens() == ["refresh-alice-hosted"] }
        try await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertEqual(revokedRefreshTokens(), ["refresh-alice-hosted"], "revoked exactly once (\(context))", file: file, line: line)
        XCTAssertNil(try harness.storedRecord(sessionId)?.credentials, "nothing committed (\(context))", file: file, line: line)
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedOut, context, file: file, line: line)
    }

    /// - Given: a hosted UI that returns alice
    /// - When: a sign-in expects bob (`.matches`), and another, with alice signed in to session "home", asks for
    ///   a user `.distinctFromOtherSessions`
    /// - Then:
    ///    - each throws `.unexpectedIdentity`; the refresh token the refused response was issued is revoked at
    ///      Cognito exactly once; nothing is committed
    func testAnIdentityTheExpectationRefusesIsRevokedOnce() async throws {
        let alice = AuthClientUser(username: "alice", userId: "sub-alice")
        try await assertRefusalRevokesTheIssuedTokenOnce(
            ClientFixtures.id("expects-bob"),
            options: WebUIOptions(identityExpectation: .matches("bob")),
            expecting: .unexpectedIdentity(expected: "bob", returned: alice),
            ".matches(\"bob\")"
        )

        _ = try harness.signIn(ClientFixtures.id("home"), .signedIn("alice"))
        try await assertRefusalRevokesTheIssuedTokenOnce(
            ClientFixtures.id("distinct"),
            options: WebUIOptions(identityExpectation: .distinctFromOtherSessions),
            expecting: .unexpectedIdentity(expected: nil, returned: alice),
            ".distinctFromOtherSessions"
        )
    }

    /// - Given: a token endpoint whose ID token is not an ID token (`token_use`), names another flow's nonce,
    ///   another app client, another issuer, no subject, or another subject than the access token's
    /// - When: a hosted-UI sign-in runs for each
    /// - Then:
    ///    - each throws `.service` naming the failed check; the refresh token the refused response was issued
    ///      is revoked at Cognito exactly once; nothing is committed
    func testAResponseTheClaimChecksRefuseIsRevokedOnce() async throws {
        let presenter = presenter!
        for (check, claims) in [
            ("tokenUse", ["token_use": "access"]),
            ("nonce", ["nonce": "another-flow"]),
            ("aud", ["aud": "another-app-client"]),
            ("iss", ["iss": "https://cognito-idp.us-east-1.amazonaws.com/us-east-1_another"]),
            ("missingIdentity", ["sub": ""]),
            ("sub", ["sub": "sub-mallory"])
        ] {
            TokenEndpointStub.respond { _ in
                var claims = claims
                if claims["nonce"] == nil {
                    claims["nonce"] = presenter.lastQueryItem("nonce")
                }
                return TokenEndpointStub.tokens("alice", nonce: nil, idTokenClaims: claims)
            }
            try await assertRefusalRevokesTheIssuedTokenOnce(ClientFixtures.id("refused-\(check)"), expecting: .service(nil), check)
        }
    }

    /// - Given: a token endpoint whose response holds tokens, but an ID token the check cannot read
    /// - When: a hosted-UI sign-in runs
    /// - Then:
    ///    - it throws `.service` (the token-parsing failure); the refresh token the response was issued is
    ///      revoked at Cognito exactly once; nothing is committed
    func testAnIDTokenTheCheckCannotReadIsRevokedOnce() async throws {
        TokenEndpointStub.respond { _ in TokenEndpointStub.tokens("alice", nonce: nil, idToken: "not-a-jwt") }

        try await assertRefusalRevokesTheIssuedTokenOnce(ClientFixtures.id("unreadable"), expecting: .service(nil), "tokenParsing")
    }

    // MARK: An interrupted logout page

    /// Signs `work` in through the hosted UI, sharing the browser's cookies.
    private func signedInSharingCookies() async throws -> AmplifyCognitoClient {
        let client = try client(work)
        let window = window!
        _ = try await client.signInWithWebUI(presentationAnchor: window, options: WebUIOptions(prefersEphemeralSession: false))
        live.cognito.clearCalls()
        return client
    }

    /// - Given: a shared-cookie session whose logout page is showing
    /// - When: `cancelWebUISignIn()` interrupts the sign-out
    /// - Then:
    ///    - the page is dismissed, the sign-out throws `.userCancelled`, nothing is revoked, and the session stays
    ///      signed in
    func testAnInterruptThatClosesTheLogoutPageRevokesNothing() async throws {
        let client = try await signedInSharingCookies()
        presenter.behave(.hold)
        let window = window!
        let signOut = Task { try await client.signOut(presentationAnchor: window) }
        await presenter.showing.waitForArrivals(2)

        await client.cancelWebUISignIn()

        let error = await authClientError { try await signOut.value }
        XCTAssertEqual(error?.kind, .userCancelled)
        XCTAssertGreaterThanOrEqual(presenter.cancelCount, 1)
        XCTAssertEqual(live.cognito.operations, [])
        XCTAssertEqual(try harness.storedRecord(work)?.isSignedOut, false)
    }

    /// - Given: a shared-cookie session whose logout page has closed and whose `RevokeToken` is in flight
    /// - When: `cancelWebUISignIn()` interrupts the sign-out, and `RevokeToken` then completes
    /// - Then:
    ///    - the sign-out reports `.complete` and the session is signed out, as Cognito was told
    func testAnInterruptAfterTheLogoutPageStillSignsOut() async throws {
        let client = try await signedInSharingCookies()
        let revoking = Gate()
        live.cognito.once("RevokeToken") { (_: RevokeTokenInput) in
            await revoking.pass()
            return RevokeTokenOutput()
        }
        let window = window!
        let signOut = Task { try await client.signOut(presentationAnchor: window) }
        await revoking.waitForArrivals(1)

        await client.cancelWebUISignIn()
        await revoking.open()

        let result = try await signOut.value
        XCTAssertEqual(result, .complete)
        XCTAssertEqual(live.cognito.operations, ["RevokeToken"])
        XCTAssertEqual(try harness.storedRecord(work)?.isSignedOut, true)
    }

    /// - Given: a shared-cookie session whose logout page has closed and whose `RevokeToken` is in flight
    /// - When: the calling task is cancelled, and `RevokeToken` then completes
    /// - Then:
    ///    - the sign-out returns `.complete` and the session is signed out, as Cognito was told
    func testACallerCancelledAfterTheLogoutPageStillSignsOut() async throws {
        let client = try await signedInSharingCookies()
        let revoking = Gate()
        live.cognito.once("RevokeToken") { (_: RevokeTokenInput) in
            await revoking.pass()
            return RevokeTokenOutput()
        }
        let window = window!
        let signOut = Task { try await client.signOut(presentationAnchor: window) }
        await revoking.waitForArrivals(1)

        signOut.cancel()
        await revoking.open()

        let result = try await signOut.value
        XCTAssertEqual(result, .complete)
        XCTAssertEqual(live.cognito.operations, ["RevokeToken"])
        XCTAssertEqual(try harness.storedRecord(work)?.isSignedOut, true)
    }
}
#endif
