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
    /// The window to anchor sheets to, made on first use rather than in `setUp()`: a process's first `UIWindow()`
    /// can block for minutes on a just-booted simulator, so a test that needs no window makes none.
    private var window: AuthClientPresentationAnchor {
        get async { await HostedUIFixtures.window() }
    }
    private let work = ClientFixtures.id("work")

    override func setUp() async throws {
        presenter = PresenterSpy()
        live = LiveEngineHarness(
            configuration: HostedUIFixtures.configuration,
            hostedUIPresenter: presenter,
            hostedUIURLSession: TokenEndpointStub.session
        )
        harness = ClientHarness()
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
    }

    /// A client whose session core runs the live engine.
    private func client(
        _ sessionId: SessionID,
        configuration: AuthClientConfiguration = HostedUIFixtures.configuration
    ) throws -> AmplifyCognitoClient {
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
            configuration: configuration,
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
        let window = await window
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
        let window = await window
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
        let window = await window
        let signIn = Task { try await client.signInWithWebUI(presentationAnchor: window) }
        await waitUntil("the code exchange is held") { exchange.hasBeenReached }

        _ = await client.signOut()
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
        let window = await window

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
        let window = await window
        let signIn = Task { try await client.signInWithWebUI(presentationAnchor: window) }
        await identity.waitForArrivals(1)

        _ = await client.signOut()
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
        let window = await window

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
        let window = await window
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
        let window = await window
        let signOut = Task { await client.signOut(presentationAnchor: window) }
        await presenter.showing.waitForArrivals(2)

        await client.cancelWebUISignIn()

        let error = await failedSignOutError(signOut.value)
        XCTAssertEqual(error?.kind, .userCancelled)
        XCTAssertGreaterThanOrEqual(presenter.cancelCount, 1)
        XCTAssertEqual(live.cognito.operations, [])
        XCTAssertEqual(try harness.storedRecord(work)?.isSignedOut, false)
    }

    // MARK: A logout page that cannot be shown or completed

    /// Asserts `result` is `.failed` with an error of `kind`, and that nothing was revoked or cleared.
    private func assertRefusedAndStillSignedIn(
        _ result: AuthClientSignOutResult,
        _ kind: AuthClientError.Kind,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        XCTAssertEqual(failedSignOutError(result, file: file, line: line)?.kind, kind, file: file, line: line)
        XCTAssertEqual(live.cognito.operations, [], "nothing revoked", file: file, line: line)
        XCTAssertEqual(try harness.storedRecord(work)?.isSignedOut, false, file: file, line: line)
    }

    /// - Given: a shared-cookie session over the live engine, whose logout browser fails to start
    /// - When: it is signed out with a window
    /// - Then:
    ///    - the result is `.failed(.service(.errorLoadingUI))`: nothing is revoked, and the session is still
    ///      signed in, stored and in memory
    func testABrowserThatFailsToStartIsFailedAndRevokesNothing() async throws {
        let client = try await signedInSharingCookies()
        presenter.behave(.fail(.unableToStartASWebAuthenticationSession))
        let window = await window

        let result = await client.signOut(presentationAnchor: window)

        try await assertRefusedAndStillSignedIn(result, .service(.errorLoadingUI))
        let state = await client.currentSessionState()
        guard case .signedIn = state else {
            return XCTFail("expected the session still signed in, got \(state)")
        }
    }

    /// - Given: a shared-cookie session over the live engine, and another session holding the system sheet
    /// - When: it is signed out with a window
    /// - Then:
    ///    - the result is `.failed(.browserBusy(holder:))` naming the holder; nothing is shown or revoked, and
    ///      the session is still signed in
    func testABusySheetIsFailedAndRevokesNothing() async throws {
        let client = try await signedInSharingCookies()
        let shownBefore = presenter.shown.count
        let lock = harness.sheetLock
        let home = ClientFixtures.id("home")
        let holds = Gate(isOpen: true)
        let release = Gate()
        let other = Task {
            try await lock.withLease(for: home, policy: .fail) { _ in
                await holds.pass()
                await release.pass()
            }
        }
        await holds.waitForArrivals(1)
        let window = await window

        let result = await client.signOut(presentationAnchor: window)

        try await assertRefusedAndStillSignedIn(result, .browserBusy(holder: home))
        XCTAssertEqual(failedSignOutError(result)?.recoverySuggestion, SessionCore.signOutBrowserBusySuggestion)
        XCTAssertEqual(presenter.shown.count, shownBefore)
        await release.open()
        _ = try await other.value
    }

    /// - Given: a shared-cookie session over the live engine, and a window that has closed
    /// - When: the core signs it out with that window
    /// - Then:
    ///    - the result is `.failed(.validation(field: "presentationAnchor"))`: nothing is shown or revoked, and
    ///      the session is still signed in
    func testAClosedWindowIsFailedAndRevokesNothing() async throws {
        let client = try await signedInSharingCookies()
        let shownBefore = presenter.shown.count

        let result = await client.core.signOut(window: .anchor(.empty()))

        try await assertRefusedAndStillSignedIn(result, .validation(field: "presentationAnchor"))
        XCTAssertEqual(presenter.shown.count, shownBefore)
    }

    /// The engine's own check of the sign-out redirect URI, through the core: the core's check passes (the URI is
    /// there), and the engine cannot use it (no scheme).
    ///
    /// - Given: a shared-cookie session over the live engine, under a configuration whose sign-out redirect URI
    ///   has no scheme
    /// - When: it is signed out with a window
    /// - Then:
    ///    - the result is `.failed` with `SessionCore.noHostedUIForSignOut()`, the engine's `.configuration` error
    ///      underneath; nothing is revoked, and the session is still signed in
    func testAnUnusableSignOutRedirectURIIsFailedWithTheOneNoHostedUIValue() async throws {
        let oauth = try XCTUnwrap(HostedUIFixtures.userPool.oauth)
        let userPool = AuthClientConfiguration.UserPool(
            poolId: HostedUIFixtures.userPool.poolId,
            appClientId: HostedUIFixtures.userPool.appClientId,
            region: HostedUIFixtures.userPool.region,
            oauth: AuthClientConfiguration.OAuth(
                domain: oauth.domain,
                scopes: oauth.scopes,
                redirectSignInURIs: oauth.redirectSignInURIs,
                redirectSignOutURIs: ["no-scheme"]
            )
        )
        let configuration = ClientFixtures.make(userPool: userPool, identityPool: ClientFixtures.identityPool)
        live = LiveEngineHarness(
            configuration: configuration,
            hostedUIPresenter: presenter,
            hostedUIURLSession: TokenEndpointStub.session
        )
        live.scriptIdentityPool()
        live.scriptSignOut()
        let client = try client(work, configuration: configuration)
        let window = await window
        _ = try await client.signInWithWebUI(presentationAnchor: window, options: WebUIOptions(prefersEphemeralSession: false))
        live.cognito.clearCalls()

        let result = await client.signOut(presentationAnchor: window)

        let error = failedSignOutError(result)
        XCTAssertEqual(error.map { $0.isEquivalent(to: SessionCore.noHostedUIForSignOut()) }, true, "\(result)")
        XCTAssertEqual((error?.underlyingError as? AuthClientError)?.kind, .configuration)
        XCTAssertEqual(result, .failed(SessionCore.noHostedUIForSignOut()))
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
        let window = await window
        let signOut = Task { await client.signOut(presentationAnchor: window) }
        await revoking.waitForArrivals(1)

        await client.cancelWebUISignIn()
        await revoking.open()

        let result = await signOut.value
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
        let window = await window
        let signOut = Task { await client.signOut(presentationAnchor: window) }
        await revoking.waitForArrivals(1)

        signOut.cancel()
        await revoking.open()

        let result = await signOut.value
        XCTAssertEqual(result, .complete)
        XCTAssertEqual(live.cognito.operations, ["RevokeToken"])
        XCTAssertEqual(try harness.storedRecord(work)?.isSignedOut, true)
    }
}
#endif
