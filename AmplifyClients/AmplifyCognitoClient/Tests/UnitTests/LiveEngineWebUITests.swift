//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(macOS) || os(visionOS)
import AuthenticationServices
import AWSCognitoIdentityProvider
import InternalAWSCognitoAuth
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// The live engine's hosted UI over scripted Cognito, a presenter spy in place of the browser, and a stubbed
/// token endpoint. No real browser is shown.
final class LiveEngineWebUITests: XCTestCase {

    private var presenter: PresenterSpy!
    private var harness: LiveEngineHarness!
    private var window: AuthClientPresentationAnchor!

    override func setUp() async throws {
        presenter = PresenterSpy()
        harness = LiveEngineHarness(
            configuration: HostedUIFixtures.configuration,
            hostedUIPresenter: presenter,
            hostedUIURLSession: TokenEndpointStub.session
        )
        window = await HostedUIFixtures.window()
        let presenter = presenter!
        TokenEndpointStub.respond { _ in TokenEndpointStub.tokens("alice", nonce: presenter.lastQueryItem("nonce")) }
        harness.scriptIdentityPool()
    }

    override func tearDown() {
        TokenEndpointStub.reset()
        presenter = nil
        harness = nil
        window = nil
    }

    private func request(
        _ options: WebUIOptions = WebUIOptions(),
        identity: EngineIdentityPolicy = .none,
        nonce: String = "flow-nonce"
    ) async -> EngineWebUISignInRequest {
        let window = window!
        let box = await MainActor.run { EnginePresentationAnchorBox(window) }
        return EngineWebUISignInRequest(anchor: box, options: EngineWebUIOptions(options, nonce: nonce), identity: identity)
    }

    private func box() async -> EnginePresentationAnchorBox {
        let window = window!
        return await MainActor.run { EnginePresentationAnchorBox(window) }
    }

    private func signedInData(_ payload: Data) throws -> SignedInData {
        try XCTUnwrap(AmplifyCredentials.decoded(payload).signedInData)
    }

    // MARK: Sign-in

    /// - Given: a hosted UI, a browser that returns a code, and a token endpoint that returns alice's tokens
    ///   for this flow's nonce
    /// - When: a hosted-UI sign-in runs, ephemeral and not
    /// - Then:
    ///    - it reaches `.done` with a payload whose sign-in method is the hosted UI with the chosen privacy, and
    ///      whose user is alice; the browser was asked for that privacy, in the request's window
    func testAHostedUISignInReachesDoneWithTheChosenPrivacy() async throws {
        for ephemeral in [true, false] {
            let engine = try harness.engine()
            let request = await request(WebUIOptions(prefersEphemeralSession: ephemeral))

            let result = try await engine.signInWithWebUI(request, current: nil, epoch: 0)

            guard case .done(let payload) = result else {
                return XCTFail("expected .done, got \(result)")
            }
            let signedIn = try signedInData(payload)
            XCTAssertEqual(signedIn.username, "alice")
            XCTAssertEqual(signedIn.userId, "sub-alice")
            XCTAssertEqual(signedIn.hostedUIPrefersPrivateSession, ephemeral)
            XCTAssertEqual(try engine.signOutPresentsBrowser(payload), !ephemeral)
            let shown = try XCTUnwrap(presenter.shown.last)
            XCTAssertEqual(shown.inPrivate, ephemeral)
            XCTAssertTrue(shown.anchor === window)
        }
    }

    /// - Given: options with a provider and an `idpIdentifier`, no scopes, no prompt, and the other fields
    /// - When: a hosted-UI sign-in runs
    /// - Then:
    ///    - the authorize URL sends `idp_identifier` and no `identity_provider`, the configuration's scopes
    ///      sorted, the nonce, `lang`, `login_hint` and `resource`, and no `prompt` item
    func testTheAuthorizeRequestCarriesTheOptions() async throws {
        let engine = try harness.engine()
        let request = await request(WebUIOptions(
            provider: .google,
            idpIdentifier: "corp",
            language: "fr",
            loginHint: "alice@example.com",
            prompt: [],
            resource: "https://api.example.com"
        ))

        _ = try await engine.signInWithWebUI(request, current: nil, epoch: 0)

        let items = try XCTUnwrap(presenter.shown.first?.queryItems)
        let names = Set(items.map(\.name))
        XCTAssertTrue(names.contains("idp_identifier"))
        XCTAssertFalse(names.contains("identity_provider"))
        XCTAssertFalse(names.contains("prompt"))
        let values = Dictionary(items.map { ($0.name, $0.value) }, uniquingKeysWith: { first, _ in first })
        XCTAssertEqual(values["idp_identifier"], "corp")
        XCTAssertEqual(values["scope"], "email openid profile")
        XCTAssertEqual(values["nonce"], "flow-nonce")
        XCTAssertEqual(values["lang"], "fr")
        XCTAssertEqual(values["login_hint"], "alice@example.com")
        XCTAssertEqual(values["resource"], "https://api.example.com")
    }

    /// - Given: a provider alone, and a prompt list
    /// - When: a hosted-UI sign-in runs
    /// - Then:
    ///    - the authorize URL sends the provider's `identity_provider` and the prompt, space-separated
    func testAProviderAndAPromptReachTheAuthorizeRequest() async throws {
        let engine = try harness.engine()
        let request = await request(WebUIOptions(provider: .apple, prompt: [.login, .selectAccount]))

        _ = try await engine.signInWithWebUI(request, current: nil, epoch: 0)

        let items = try XCTUnwrap(presenter.shown.first?.queryItems)
        let values = Dictionary(items.map { ($0.name, $0.value) }, uniquingKeysWith: { first, _ in first })
        XCTAssertEqual(values["identity_provider"], "SignInWithApple")
        XCTAssertEqual(values["prompt"], "login select_account")
    }

    /// - Given: an expectation of bob, and separately an exclusion of alice, while alice comes back
    /// - When: each hosted-UI sign-in runs
    /// - Then:
    ///    - each throws `.unexpectedIdentity` returning alice (the first carrying the expectation), and no payload
    ///      is returned, so nothing can be committed
    func testAnUnexpectedIdentityIsRefused() async throws {
        let alice = AuthClientUser(username: "alice", userId: "sub-alice")
        for (identity, expected) in [
            (EngineIdentityPolicy(expectedIdentity: "bob"), "bob" as String?),
            (EngineIdentityPolicy(excludedSubjects: ["sub-alice"]), nil)
        ] {
            let engine = try harness.engine()
            let request = await request(identity: identity)

            let error = await authClientError { try await engine.signInWithWebUI(request, current: nil, epoch: 0) }

            XCTAssertEqual(error?.kind, .unexpectedIdentity(expected: expected, returned: alice))
            XCTAssertTrue(error?.underlyingError is HostedUIIdentityMismatch)
            let pending = await engine.pendingChallenge
            XCTAssertNil(pending)
        }
    }

    /// - Given: a token endpoint whose ID token carries another flow's nonce
    /// - When: a hosted-UI sign-in runs
    /// - Then:
    ///    - it throws `.service` naming the nonce check, with no identity in its strings
    func testAResponseForAnotherFlowIsRefused() async throws {
        TokenEndpointStub.respond { _ in TokenEndpointStub.tokens("alice", nonce: "another-flow") }
        let engine = try harness.engine()
        let request = await request()

        let error = await authClientError { try await engine.signInWithWebUI(request, current: nil, epoch: 0) }

        XCTAssertEqual(error?.kind, .service(nil))
        XCTAssertTrue(error?.errorDescription.contains("nonce") == true, "\(String(describing: error))")
        XCTAssertFalse(error?.errorDescription.contains("alice") == true)
    }

    /// - Given: a browser the user closes
    /// - When: a hosted-UI sign-in runs
    /// - Then:
    ///    - it throws `.userCancelled`, and nothing was sent to the token endpoint
    func testClosingTheBrowserIsUserCancelled() async throws {
        presenter.behave(.fail(.cancelled))
        let engine = try harness.engine()
        let request = await request()

        let error = await authClientError { try await engine.signInWithWebUI(request, current: nil, epoch: 0) }

        XCTAssertEqual(error?.kind, .userCancelled)
        XCTAssertEqual(TokenEndpointStub.requestCount, 0)
    }

    /// - Given: a browser that stays up
    /// - When: the calling task is cancelled
    /// - Then:
    ///    - the presenter's `cancel()` is reached, and the call ends
    func testCancellingTheCallerReachesThePresentersCancel() async throws {
        presenter.behave(.hold)
        let engine = try harness.engine()
        let request = await request()
        let signIn = Task { try await engine.signInWithWebUI(request, current: nil, epoch: 0) }
        await presenter.showing.waitForArrivals(1)

        signIn.cancel()

        _ = await signIn.result
        XCTAssertGreaterThanOrEqual(presenter.cancelCount, 1)
    }

    /// - Given: a browser that stays up
    /// - When: the session's pending sign-in is cancelled (a sign-out of the session)
    /// - Then:
    ///    - the presenter's `cancel()` is reached, and the call throws
    func testCancellingThePendingSignInReachesThePresentersCancel() async throws {
        presenter.behave(.hold)
        let engine = try harness.engine()
        let request = await request()
        let signIn = Task { try await engine.signInWithWebUI(request, current: nil, epoch: 0) }
        await presenter.showing.waitForArrivals(1)

        await engine.cancelPendingSignIn(before: 1)

        let result = await signIn.result
        XCTAssertThrowsError(try result.get())
        XCTAssertGreaterThanOrEqual(presenter.cancelCount, 1)
    }

    /// - Given: a request whose window has closed
    /// - When: a hosted-UI sign-in runs
    /// - Then:
    ///    - it throws `.validation(field: "presentationAnchor")`, and nothing is shown
    func testAClosedWindowIsRefusedBeforeAnythingIsShown() async throws {
        let gone = EnginePresentationAnchorBox.empty()
        let engine = try harness.engine()
        let request = EngineWebUISignInRequest(
            anchor: gone,
            options: EngineWebUIOptions(WebUIOptions(), nonce: "n"),
            identity: .none
        )

        let error = await authClientError { try await engine.signInWithWebUI(request, current: nil, epoch: 0) }

        XCTAssertEqual(error?.kind, .validation(field: "presentationAnchor"))
        XCTAssertTrue(presenter.shown.isEmpty)
    }

    /// - Given: a configuration without a hosted UI
    /// - When: a hosted-UI sign-in runs
    /// - Then:
    ///    - it throws `.configuration`, and nothing is shown
    func testAConfigurationWithoutAHostedUIIsRefused() async throws {
        harness = LiveEngineHarness(hostedUIPresenter: presenter)
        let engine = try harness.engine()
        let request = await request()

        let error = await authClientError { try await engine.signInWithWebUI(request, current: nil, epoch: 0) }

        XCTAssertEqual(error?.kind, .configuration)
        XCTAssertTrue(presenter.shown.isEmpty)
    }

    // MARK: Sign-out

    /// Pins the non-ephemeral logout HU-2 cannot
    ///
    /// - Given: a payload from a hosted-UI sign-in that shared the browser's cookies
    /// - When: it is revoked with `.present`
    /// - Then:
    ///    - the logout page is shown non-ephemerally in the window, then the token is revoked; complete
    func testAPresentingSignOutShowsTheLogoutWithTheSignInsCookies() async throws {
        let payload = try await sharedCookiePayload()
        let engine = try harness.engine()
        harness.scriptSignOut()
        harness.cognito.clearCalls()

        let outcome = try await engine.revoke(payload, global: false, hostedUI: .present(box()))

        XCTAssertEqual(outcome, .complete)
        let logout = try XCTUnwrap(presenter.shown.last)
        XCTAssertEqual(logout.url.path, "/logout")
        XCTAssertFalse(logout.inPrivate)
        XCTAssertTrue(logout.anchor === window)
        XCTAssertEqual(harness.cognito.operations, ["RevokeToken"])
    }

    /// - Given: a browser that answers with another flow's `state`
    /// - When: a hosted-UI sign-in runs
    /// - Then:
    ///    - it throws `.service` (the plugin's security failure), and the code is never exchanged
    func testAStateMismatchIsRefusedBeforeTheExchange() async throws {
        presenter.behave(.answerWrongState)
        let engine = try harness.engine()
        let request = await request()

        let error = await authClientError { try await engine.signInWithWebUI(request, current: nil, epoch: 0) }

        XCTAssertEqual(error?.kind, .service(nil))
        XCTAssertEqual(TokenEndpointStub.requestCount, 0)
    }

    /// - Given: a shared-cookie hosted-UI payload
    /// - When: it is refreshed
    /// - Then:
    ///    - the refreshed payload keeps its sign-in method, so signing it out still shows the logout page
    func testARefreshedSharedCookiePayloadStillPresentsTheLogout() async throws {
        let payload = try await sharedCookiePayload()
        harness.scriptRefresh()
        let engine = try harness.engine()

        let refreshed = try await engine.refresh(payload, force: true)

        XCTAssertNotEqual(refreshed, payload)
        XCTAssertTrue(try engine.signOutPresentsBrowser(refreshed))
        XCTAssertEqual(try signedInData(refreshed).hostedUIPrefersPrivateSession, false)
    }

    /// - Given: a shared-cookie payload
    /// - When: it is revoked globally with `.present`, and again with `GlobalSignOut` failing
    /// - Then:
    ///    - the logout page comes first, before any Cognito call, then `GlobalSignOut`, then `RevokeToken`;
    ///      after a failed `GlobalSignOut` the token is not revoked, and the failure is reported beside the
    ///      plugin's placeholder revoke error
    func testAGlobalPresentingSignOutShowsTheLogoutFirst() async throws {
        let payload = try await sharedCookiePayload()
        let engine = try harness.engine()
        let cognito = harness.cognito
        let callsWhenShown = CallsAtShow()
        presenter.onShow { _ in callsWhenShown.record(cognito.operations) }
        harness.scriptSignOut()
        cognito.clearCalls()

        let outcome = try await engine.revoke(payload, global: true, hostedUI: .present(box()))

        XCTAssertEqual(outcome, .complete)
        XCTAssertEqual(callsWhenShown.calls, [[]])
        XCTAssertEqual(cognito.operations, ["GlobalSignOut", "RevokeToken"])

        cognito.clearCalls()
        cognito.once("GlobalSignOut") { (_: GlobalSignOutInput) -> GlobalSignOutOutput in
            throw FixtureError(description: "global sign-out failed")
        }
        let failed = try await engine.revoke(payload, global: true, hostedUI: .present(box()))

        XCTAssertEqual(cognito.operations, ["GlobalSignOut"])
        XCTAssertNotNil(failed.globalSignOutError)
        XCTAssertEqual(failed.revokeError?.kind, .service(nil))
        XCTAssertEqual(failed.revokeError?.errorDescription, "")
    }

    /// a page the user asked for that cannot be shown is the plugin's `.failed`.
    ///
    /// - Given: a shared-cookie payload, and a window that has closed
    /// - When: it is revoked with `.present`
    /// - Then:
    ///    - nothing is shown; it throws a `SignOutRefusal` with `.validation(field: "presentationAnchor")`, and
    ///      nothing is revoked
    func testAPresentingSignOutWithAClosedWindowIsRefused() async throws {
        let payload = try await sharedCookiePayload()
        let shownBefore = presenter.shown.count
        harness.scriptSignOut()
        harness.cognito.clearCalls()
        let engine = try harness.engine()

        do {
            _ = try await engine.revoke(payload, global: false, hostedUI: .present(.empty()))
            XCTFail("expected a refusal")
        } catch let refusal as SignOutRefusal {
            XCTAssertEqual(refusal.error.kind, .validation(field: "presentationAnchor"))
        }

        XCTAssertEqual(presenter.shown.count, shownBefore)
        XCTAssertEqual(harness.cognito.operations, [])
    }

    /// - Given: a shared-cookie payload
    /// - When: the user closes the logout page
    /// - Then:
    ///    - the revoke throws `.userCancelled`, and nothing was revoked
    func testClosingTheLogoutPageRevokesNothing() async throws {
        let payload = try await sharedCookiePayload()
        presenter.behave(.fail(.cancelled))
        harness.scriptSignOut()
        harness.cognito.clearCalls()
        let engine = try harness.engine()

        let error = await authClientError { try await engine.revoke(payload, global: false, hostedUI: .present(box())) }

        XCTAssertEqual(error?.kind, .userCancelled)
        XCTAssertEqual(harness.cognito.operations, [])
    }

    /// the engine's own refusals of the hosted UI's sign-out end it, as the plugin's `.failed` does,
    /// instead of rerunning it without the page.
    ///
    /// - Given: a shared-cookie payload
    /// - When: the logout step fails with no hosted-UI configuration (`HostedUIError.pluginConfiguration`), and
    ///   then with no usable sign-out redirect URI (`HostedUIError.signOutRedirectURI`)
    /// - Then:
    ///    - each revoke throws a `SignOutRefusal` carrying `SessionCore.noHostedUIForSignOut()`, the one value of
    ///      the core's own check, with the engine's mapped `.configuration` error underneath; nothing was revoked
    func testAHostedUIConfigurationRefusalRevokesNothing() async throws {
        let payload = try await sharedCookiePayload()
        let engine = try harness.engine()
        for failure in [HostedUIError.pluginConfiguration("no hosted UI"), .signOutRedirectURI] {
            presenter.behave(.fail(failure))
            harness.scriptSignOut()
            harness.cognito.clearCalls()

            do {
                _ = try await engine.revoke(payload, global: false, hostedUI: .present(box()))
                XCTFail("expected a refusal for \(failure)")
            } catch let refusal as SignOutRefusal {
                XCTAssertTrue(refusal.error.isEquivalent(to: SessionCore.noHostedUIForSignOut()), "\(failure)")
                XCTAssertEqual((refusal.error.underlyingError as? AuthClientError)?.kind, .configuration, "\(failure)")
            }

            XCTAssertEqual(harness.cognito.operations, [], "\(failure)")
        }
    }

    /// as the plugin, every other `HostedUIError` of the logout step stops the sign-out, instead of rerunning
    /// it without the page.
    ///
    /// - Given: a shared-cookie payload
    /// - When: the logout step fails in each other way: the browser fails to start, an invalid context, an unknown
    ///   failure, a service message, a sign-out URL that cannot be built
    /// - Then:
    ///    - each revoke throws a `SignOutRefusal` with the mapped failure (`.service(.errorLoadingUI)` for a failed
    ///      start), and nothing was revoked
    func testEveryOtherLogoutFailureIsRefusedAndRevokesNothing() async throws {
        let payload = try await sharedCookiePayload()
        let engine = try harness.engine()
        let failures: [HostedUIError] = [
            .unableToStartASWebAuthenticationSession, .invalidContext, .unknown, .serviceMessage("down"), .signOutURI
        ]
        for failure in failures {
            presenter.behave(.fail(failure))
            harness.scriptSignOut()
            harness.cognito.clearCalls()

            do {
                _ = try await engine.revoke(payload, global: false, hostedUI: .present(box()))
                XCTFail("expected a refusal for \(failure)")
            } catch let refusal as SignOutRefusal {
                XCTAssertTrue(
                    refusal.error.isEquivalent(to: AuthClientError(engine: failure.engineError)),
                    "\(failure): \(refusal.error)"
                )
            }

            XCTAssertEqual(harness.cognito.operations, [], "\(failure)")
        }
        XCTAssertEqual(AuthClientError(engine: HostedUIError.unableToStartASWebAuthenticationSession.engineError).kind, .service(.errorLoadingUI))
    }

    /// - Given: a shared-cookie payload
    /// - When: it is revoked with `.skip`, and an ephemeral one with `.present`
    /// - Then:
    ///    - nothing is shown for either, and both are revoked
    func testSkipAndAPrivateSignInShowNothing() async throws {
        let shared = try await sharedCookiePayload()
        let engine = try harness.engine()
        let privateRequest = await request()
        guard case .done(let ephemeral) = try await engine.signInWithWebUI(privateRequest, current: nil, epoch: 0) else {
            return XCTFail("expected .done")
        }
        let shownBefore = presenter.shown.count
        harness.scriptSignOut()
        harness.cognito.clearCalls()

        let skipped = try await engine.revoke(shared, global: false, hostedUI: .skip)
        let privateOne = try await engine.revoke(ephemeral, global: false, hostedUI: .present(box()))

        XCTAssertEqual(skipped, .complete)
        XCTAssertEqual(privateOne, .complete)
        XCTAssertEqual(presenter.shown.count, shownBefore)
        XCTAssertEqual(harness.cognito.operations, ["RevokeToken", "RevokeToken"])
    }

    private func sharedCookiePayload() async throws -> Data {
        let engine = try harness.engine()
        let sharedRequest = await request(WebUIOptions(prefersEphemeralSession: false))
        guard case .done(let payload) = try await engine.signInWithWebUI(sharedRequest, current: nil, epoch: 0) else {
            throw FixtureError(description: "the hosted-UI sign-in did not finish")
        }
        return payload
    }
}

/// `AuthClientError(hostedUIMismatch:)`, every reason.
final class HostedUIMismatchMappingTests: XCTestCase {

    /// - Given: a mismatch of each reason, returning a user by `sub` and username
    /// - When: it is mapped
    /// - Then:
    ///    - the two identity reasons are `.unexpectedIdentity`, the expectation only for `notExpectedIdentity`;
    ///      the response reasons are `.service(nil)` naming the failed check
    ///    - the mismatch is the underlying error, and no string holds the returned identity
    func testEveryReasonMaps() {
        for reason in HostedUIIdentityMismatch.Reason.allCases {
            let mismatch = HostedUIIdentityMismatch(
                reason: reason,
                expected: reason == .notExpectedIdentity ? "bob" : nil,
                returnedUsername: "alice",
                returnedUserId: "sub-alice"
            )

            let error = AuthClientError(hostedUIMismatch: mismatch)

            switch reason {
            case .notExpectedIdentity:
                XCTAssertEqual(error.kind, .unexpectedIdentity(expected: "bob", returned: AuthClientUser(username: "alice", userId: "sub-alice")))
            case .signedInToAnotherSession:
                XCTAssertEqual(error.kind, .unexpectedIdentity(expected: nil, returned: AuthClientUser(username: "alice", userId: "sub-alice")))
            case .tokenUse, .audience, .issuer, .nonce, .subject, .missingIdentity:
                XCTAssertEqual(error.kind, .service(nil), "\(reason)")
                XCTAssertTrue(error.errorDescription.contains("could not be verified"), "\(reason)")
            }
            XCTAssertEqual((error.underlyingError as? HostedUIIdentityMismatch)?.reason, reason)
            for text in [error.errorDescription, error.recoverySuggestion] {
                XCTAssertFalse(text.contains("alice"), "\(reason): \(text)")
                XCTAssertFalse(text.contains("bob"), "\(reason): \(text)")
            }
        }
    }

    /// - Given: an identity mismatch whose username could not be read
    /// - When: it is mapped
    /// - Then:
    ///    - the returned user's username falls back to the `sub`
    func testTheReturnedUsernameFallsBackToTheSubject() {
        let mismatch = HostedUIIdentityMismatch(reason: .signedInToAnotherSession, returnedUsername: nil, returnedUserId: "sub-alice")

        let error = AuthClientError(hostedUIMismatch: mismatch)

        XCTAssertEqual(error.kind, .unexpectedIdentity(expected: nil, returned: AuthClientUser(username: "sub-alice", userId: "sub-alice")))
    }

    /// - Given: a hosted-UI failure that is not an identity check (the browser could not start)
    /// - When: it is mapped as a sign-in failure
    /// - Then:
    ///    - it maps as any engine error does: `.service(.errorLoadingUI)`
    func testOtherHostedUIFailuresMapAsEngineErrors() {
        let error = AuthClientError(hostedUISignIn: .hostedUI(.unableToStartASWebAuthenticationSession))

        XCTAssertEqual(error.kind, .service(.errorLoadingUI))
    }
}

/// A browser presenter that answers as the hosted UI would, with no browser: the authorize URL's `state` back
/// with a code, or a failure, or nothing until cancelled.
///
/// - Note: `@unchecked Sendable`: every property below is only touched while holding `lock`.
final class PresenterSpy: HostedUISessionBehavior, @unchecked Sendable {

    enum Behavior {
        case answer
        /// Answers the authorize page with another flow's `state`.
        case answerWrongState
        case hold
        case fail(HostedUIError)
    }

    struct Shown {
        let url: URL
        let inPrivate: Bool
        let anchor: EnginePresentationAnchor?

        var queryItems: [URLQueryItem] {
            URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        }
    }

    /// One arrival per page shown.
    let showing = Gate(isOpen: true)

    private let lock = NSLock()
    private var behavior: Behavior = .answer
    private var shownPages: [Shown] = []
    private var cancels = 0
    private var held: CheckedContinuation<[URLQueryItem], Error>?
    private var cancelledEarly = false
    private var showHook: (@Sendable (URL) -> Void)?

    func behave(_ behavior: Behavior) {
        withLock { self.behavior = behavior }
    }

    /// Runs as each page is shown, before it is answered.
    func onShow(_ hook: (@Sendable (URL) -> Void)?) {
        withLock { showHook = hook }
    }

    var shown: [Shown] {
        withLock { shownPages }
    }

    var cancelCount: Int {
        withLock { cancels }
    }

    /// A query item of the last page shown: the nonce the token endpoint's ID token must carry.
    func lastQueryItem(_ name: String) -> String? {
        shown.last?.queryItems.first { $0.name == name }?.value
    }

    func showHostedUI(
        url: URL,
        callbackScheme: String,
        inPrivate: Bool,
        presentationAnchor: EnginePresentationAnchor?
    ) async throws -> [URLQueryItem] {
        let page = Shown(url: url, inPrivate: inPrivate, anchor: presentationAnchor)
        let (behavior, hook) = withLock { () -> (Behavior, (@Sendable (URL) -> Void)?) in
            shownPages.append(page)
            return (self.behavior, showHook)
        }
        hook?(url)
        await showing.pass()
        switch behavior {
        case .answerWrongState:
            return [URLQueryItem(name: "code", value: "auth-code"), URLQueryItem(name: "state", value: "another-flow")]
        case .answer:
            if url.path == "/logout" {
                return []
            }
            let state = page.queryItems.first { $0.name == "state" }?.value
            return [URLQueryItem(name: "code", value: "auth-code"), URLQueryItem(name: "state", value: state)]
        case .fail(let error):
            throw error
        case .hold:
            return try await withCheckedThrowingContinuation { continuation in
                let cancelled = withLock { () -> Bool in
                    guard !cancelledEarly else {
                        return true
                    }
                    held = continuation
                    return false
                }
                if cancelled {
                    continuation.resume(throwing: HostedUIError.cancelled)
                }
            }
        }
    }

    func cancel() {
        let continuation = withLock { () -> CheckedContinuation<[URLQueryItem], Error>? in
            cancels += 1
            guard let held else {
                cancelledEarly = true
                return nil
            }
            self.held = nil
            return held
        }
        continuation?.resume(throwing: HostedUIError.cancelled)
    }

    private func withLock<Value>(_ body: () throws -> Value) rethrows -> Value {
        lock.lock()
        defer { lock.unlock() }
        return try body()
    }
}

/// The Cognito calls made by the time each page was shown.
final class CallsAtShow: @unchecked Sendable {
    // `@unchecked Sendable`: only touched while holding `lock`.
    private let lock = NSLock()
    private var recorded: [[String]] = []

    var calls: [[String]] {
        lock.lock()
        defer { lock.unlock() }
        return recorded
    }

    func record(_ calls: [String]) {
        lock.lock()
        recorded.append(calls)
        lock.unlock()
    }
}

/// The hosted UI's token endpoint, stubbed: every request the stubbed session makes is answered by the
/// current responder. Shared by the tests of one process, which XCTest runs one at a time.
final class TokenEndpointStub: URLProtocol {

    typealias Responder = @Sendable (URLRequest) -> Data

    private static let state = StubState()

    static func respond(_ responder: @escaping Responder) {
        state.set(responder)
    }

    static func reset() {
        state.reset()
    }

    static var requestCount: Int {
        state.count
    }

    /// A session whose every request is answered here.
    @Sendable
    static func session() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [TokenEndpointStub.self]
        return URLSession(configuration: configuration)
    }

    /// Cognito's token response: alice's tokens, the ID token bound to this app client, pool and `nonce`.
    ///
    /// - Parameters:
    ///   - idTokenClaims: ID token claims that replace the defaults, for a response a check refuses.
    ///   - idToken: an ID token that replaces the whole built one, for a response whose ID token cannot be read.
    static func tokens(_ username: String, nonce: String?, idTokenClaims: [String: String] = [:], idToken: String? = nil) -> Data {
        var claims: [String: Any] = [
            "sub": "sub-\(username)",
            "cognito:username": username,
            "token_use": "id",
            "aud": "app-client-1",
            "iss": "https://cognito-idp.us-east-1.amazonaws.com/\(StorageFixtures.userPoolId)",
            "exp": 4_000_000_000,
            "iat": 1_700_000_000
        ]
        claims["nonce"] = nonce
        claims.merge(idTokenClaims) { _, override in override }
        let header = LiveEngineFixtures.base64URL(#"{"alg":"none","typ":"JWT"}"#)
        let body = (try? JSONSerialization.data(withJSONObject: claims, options: [.sortedKeys])) ?? Data()
        let payload = body.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        let response: [String: Any] = [
            "id_token": idToken ?? "\(header).\(payload).signature",
            "access_token": LiveEngineFixtures.jwt(username, use: "access"),
            "refresh_token": "refresh-\(username)-hosted",
            "expires_in": 3_600,
            "token_type": "Bearer"
        ]
        return (try? JSONSerialization.data(withJSONObject: response)) ?? Data()
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        let body = Self.state.answer(request)
        let response = HTTPURLResponse(
            url: request.url ?? URL(fileURLWithPath: "/"),
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )
        if let response {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }
        client?.urlProtocol(self, didLoad: body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    /// - Note: `@unchecked Sendable`: both properties are only touched while holding `lock`.
    private final class StubState: @unchecked Sendable {
        private let lock = NSLock()
        private var responder: Responder?
        private var requests = 0

        var count: Int {
            lock.lock()
            defer { lock.unlock() }
            return requests
        }

        func set(_ responder: @escaping Responder) {
            lock.lock()
            self.responder = responder
            lock.unlock()
        }

        func reset() {
            lock.lock()
            responder = nil
            requests = 0
            lock.unlock()
        }

        func answer(_ request: URLRequest) -> Data {
            lock.lock()
            requests += 1
            let responder = responder
            lock.unlock()
            return responder?(request) ?? Data(#"{"error":"not_scripted"}"#.utf8)
        }
    }
}
#endif
