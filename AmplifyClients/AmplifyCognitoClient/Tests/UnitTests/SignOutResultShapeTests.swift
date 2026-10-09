//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) @testable import AmplifyFoundation
import AWSCognitoIdentityProvider
import Foundation
import InternalAWSCognitoAuth
import Security
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// The sign-out result in the plugin's shape: `signOut` and
/// `signOutStoredSession` never throw; they return `.complete`, `.partial(...)` or `.failed(error)`, with
/// `signedOutLocally`.
final class SignOutResultShapeTests: XCTestCase {

    var harness: ClientHarness!
    let work = ClientFixtures.id("work")
    let alice = AuthClientUser(username: "alice", userId: "sub-alice")

    override func setUp() {
        harness = ClientHarness()
    }

    override func tearDown() async throws {
        harness.keychain.clearFailures()
        await harness.waitForBaseline()
        harness = nil
    }

    // MARK: The shape

    /// - Given: every case of the result
    /// - When: `signedOutLocally` is read
    /// - Then:
    ///    - it is `false` for `.failed` only
    func testSignedOutLocallyIsFalseOnlyForFailed() {
        let error = AuthClientError.unknown("failed", "retry")
        XCTAssertTrue(AuthClientSignOutResult.complete.signedOutLocally)
        XCTAssertTrue(AuthClientSignOutResult.partialResult(revokeTokenError: error).signedOutLocally)
        XCTAssertTrue(AuthClientSignOutResult.partialResult(globalSignOutError: error).signedOutLocally)
        XCTAssertTrue(AuthClientSignOutResult.partialResult(hostedUIError: error).signedOutLocally)
        XCTAssertTrue(AuthClientSignOutResult.partialResult(storageError: error).signedOutLocally)
        XCTAssertFalse(AuthClientSignOutResult.failed(error).signedOutLocally)
    }

    /// Security fix H1: unlike the plugin's, the partial result carries errors only.
    ///
    /// - Given: a session signed in over the live engine, and `RevokeToken` failing at Cognito
    /// - When: it signs out
    /// - Then:
    ///    - the result is `.partial(revokeTokenError: …)`, signed out locally
    ///    - no string anywhere in the value, or in its description, holds any of the session's tokens
    func testPartialCarriesErrorsAndNoTokens() async throws {
        let live = LiveEngineHarness()
        let client = try liveClient(live)
        try await signInAlice(client, live)
        let tokens = try storedTokens()
        live.cognito.once("RevokeToken") { (_: RevokeTokenInput) -> RevokeTokenOutput in
            throw AWSCognitoIdentityProvider.InternalErrorException(message: "boom")
        }
        live.scriptSignOut()

        let result = await client.signOut()

        XCTAssertTrue(result.signedOutLocally)
        let partial = try XCTUnwrap(result.partialErrors, "\(result)")
        XCTAssertNotNil(partial.revokeTokenError)
        XCTAssertNil(partial.globalSignOutError)
        let strings = Self.strings(in: result) + ["\(result)", String(reflecting: result)]
        for token in tokens {
            XCTAssertFalse(strings.contains { $0.contains(token) }, "a token is reachable from the result")
        }
    }

    /// `.superseded` is gone. Another sign-in that replaced the session during the sign-out is a failure,
    /// and that user stays signed in.
    ///
    /// - Given: alice's live session, and a revoke during which another process signs bob in
    /// - When: it signs out
    /// - Then:
    ///    - the result is `.failed(.invalidState)` with the decided texts; bob is still signed in, stored and
    ///      in memory, and no `.signedOut` is sent
    func testSupersededBecomesFailedInvalidStateAndTheNewUserStaysSignedIn() async throws {
        try harness.signIn(work, .signedIn("alice"))
        let client = try harness.client(work)
        _ = await client.currentSessionState()
        let events = StreamRecorder(client.listenToAuthEvents())
        let store = harness.store()
        let bob = FakePayload.signedIn("bob")
        harness.engine(for: work)?.scriptRevoke { [work] _ in
            if case .record(let envelope) = try store.read(work) {
                try store.write(bob.record(), for: work, expecting: envelope.version)
            }
        }

        let result = await client.signOut()

        let error = try XCTUnwrap(failedSignOutError(result))
        XCTAssertEqual(error.kind, .invalidState)
        XCTAssertEqual(
            error.errorDescription,
            "Another sign-in replaced this session while it was signing out; that user is still signed in."
        )
        XCTAssertEqual(error.recoverySuggestion, "Check the session's state, then sign out again if needed.")
        XCTAssertEqual(try harness.storedRecord(work)?.credentials, bob.data)
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedIn(AuthClientUser(username: "bob", userId: "sub-bob")))
        XCTAssertEqual(events.received, [])
    }

    // MARK: Purge

    /// - Given: a signed-in session whose revoke succeeds, and whose keychain removals fail
    /// - When: it signs out with `purgeStoredSession`
    /// - Then:
    ///    - the result is `.partial` with only a `storageUnavailable(.locked)` `storageError`, and
    ///      `signedOutLocally` is `true`: the session is signed out and its row kept
    func testPurgeFailureAfterTheSignOutIsPartialWithStorageError() async throws {
        try harness.signIn(work, .signedIn("alice"))
        let client = try harness.client(work)
        harness.keychain.failingRemovals(of: harness.store().sessionAccount(for: work), with: errSecInteractionNotAllowed)

        let result = await client.signOut(options: .init(purgeStoredSession: true))

        XCTAssertTrue(result.signedOutLocally)
        let partial = try XCTUnwrap(result.partialErrors, "\(result)")
        XCTAssertNil(partial.revokeTokenError)
        XCTAssertNil(partial.globalSignOutError)
        XCTAssertNil(partial.hostedUIError)
        XCTAssertEqual(partial.storageError?.kind, .storageUnavailable(.locked))
        harness.keychain.clearFailures()
        XCTAssertEqual(try harness.storedRecord(work)?.isSignedOut, true)
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedOut)
    }

    // MARK: As the plugin

    /// - Given: a session signed in over the live engine, and `GlobalSignOut` failing at Cognito
    /// - When: it signs out globally
    /// - Then:
    ///    - the result is `.partial` with the mapped global failure and the plugin's placeholder revoke error
    ///      (`.service`, no code, empty texts); `RevokeToken` was never called; the session is signed out
    func testFailedGlobalSignOutAddsThePluginsPlaceholderRevokeError() async throws {
        let live = LiveEngineHarness()
        let client = try liveClient(live)
        try await signInAlice(client, live)
        live.cognito.once("GlobalSignOut") { (_: GlobalSignOutInput) -> GlobalSignOutOutput in
            throw AWSCognitoIdentityProvider.TooManyRequestsException(message: "slow down")
        }
        live.scriptSignOut()
        live.cognito.clearCalls()

        let result = await client.signOut(options: .init(globalSignOut: true))

        XCTAssertTrue(result.signedOutLocally)
        let partial = try XCTUnwrap(result.partialErrors, "\(result)")
        guard case .service(nil, "", "", _) = partial.revokeTokenError else {
            return XCTFail("expected the placeholder revoke error, got \(String(describing: partial.revokeTokenError))")
        }
        guard case .service(.requestLimitExceeded?, _, _, _) = partial.globalSignOutError else {
            return XCTFail("expected the mapped global failure, got \(String(describing: partial.globalSignOutError))")
        }
        XCTAssertFalse(live.cognito.operations.contains("RevokeToken"))
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedOut)
    }

    // MARK: Deliberate differences

    /// A documented difference: the plugin refuses a federated session's sign-out; the client signs it out.
    ///
    /// - Given: a federated session
    /// - When: it signs out
    /// - Then:
    ///    - the result is `.complete`, signed out locally, and the session is signed out
    func testFederatedSessionSignsOutComplete() async throws {
        try harness.signIn(work, .federated())
        let client = try harness.client(work)

        let result = await client.signOut()

        XCTAssertEqual(result, .complete)
        XCTAssertTrue(result.signedOutLocally)
        XCTAssertEqual(try harness.storedRecord(work)?.isSignedOut, true)
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedOut)
    }

    // MARK: signOutStoredSession

    /// - Given: saved sessions: one whose revoke succeeds, one whose revoke fails, one whose revoke is cancelled,
    ///   and one live in this process under another configuration
    /// - When: each is signed out through `signOutStoredSession`
    /// - Then:
    ///    - the results are `.complete`, `.partial(revokeTokenError:)`, `.failed(.unknown)`, and
    ///      `.failed(.sessionConfigurationMismatch)`; only the `.failed` ones are still signed in
    func testStaticSignOutStoredSessionReturnsTheSameShapes() async throws {
        let home = ClientFixtures.id("home")
        let school = ClientFixtures.id("school")
        let other = ClientFixtures.id("other")
        try harness.signIn(work, .signedIn("alice"))
        try harness.signIn(home, .signedIn("bob"))
        try harness.signIn(school, .signedIn("carol"))
        let failure = AuthClientError.service(.network, "revoke failed", "retry")
        harness.revoker.scriptRevoke { payload in
            switch FakePayload.decode(payload)?.username {
            case "bob":
                throw failure
            case "carol":
                throw CancellationError()
            default:
                return
            }
        }
        let live = try harness.client(other, configuration: ClientFixtures.userPoolOnlyConfiguration)
        _ = await live.currentSessionState()

        let complete = await signOutStored(work)
        let partial = await signOutStored(home)
        let cancelled = await signOutStored(school)
        let mismatch = await signOutStored(other)

        XCTAssertEqual(complete, .complete)
        XCTAssertEqual(try harness.storedRecord(work)?.isSignedOut, true)
        XCTAssertEqual(partial, .partialResult(revokeTokenError: failure))
        XCTAssertEqual(try harness.storedRecord(home)?.isSignedOut, true)
        XCTAssertEqual(cancelled, .failed(SessionSignOut.cancelledError()))
        XCTAssertEqual(try harness.storedRecord(school)?.isSignedOut, false)
        XCTAssertEqual(failedSignOutError(mismatch)?.isMismatch(for: other), true, "\(mismatch)")
    }

    // MARK: Helpers

    func signOutStored(_ sessionId: SessionID) async -> AuthClientSignOutResult {
        await AmplifyCognitoClient.signOutStoredSession(
            sessionId: sessionId,
            configuration: ClientFixtures.configuration,
            accessGroup: nil,
            dependencies: harness.dependencies
        )
    }

    /// A client over the live engine and scripted Cognito, on `work`.
    func liveClient(_ live: LiveEngineHarness) throws -> AmplifyCognitoClient {
        let base = harness.dependencies
        let dependencies = SessionCoreDependencies(
            registry: base.registry,
            gates: base.gates,
            makeStore: base.makeStore,
            makeClients: base.makeClients,
            makeEngine: { _ in try live.engine() },
            makeRevoker: base.makeRevoker,
            scheduleRestore: base.scheduleRestore,
            bounds: base.bounds,
            now: { Date() }
        )
        return try AmplifyCognitoClient(
            configuration: ClientFixtures.configuration,
            options: .init(sessionId: work),
            dependencies: dependencies
        )
    }

    func signInAlice(_ client: AmplifyCognitoClient, _ live: LiveEngineHarness) async throws {
        live.scriptSRP()
        live.scriptIdentityPool()
        let result = try await client.signIn(username: "alice", password: "password")
        guard case .done = result.nextStep else {
            throw FixtureError(description: "the scripted sign-in did not finish: \(result.nextStep)")
        }
    }

    /// The user pool tokens of `work`'s stored live-engine credentials.
    private func storedTokens() throws -> [String] {
        let payload = try XCTUnwrap(harness.storedRecord(work)?.credentials)
        let tokens = try XCTUnwrap(AmplifyCredentials.decoded(payload).signedInData?.cognitoUserPoolTokens)
        return [tokens.idToken, tokens.accessToken, tokens.refreshToken]
    }

    /// Every string reachable from `value` through its mirror, a few levels deep.
    private static func strings(in value: Any, depth: Int = 0) -> [String] {
        if let string = value as? String {
            return [string]
        }
        guard depth < 8 else {
            return []
        }
        var found = ["\(value)"]
        for child in Mirror(reflecting: value).children {
            found += strings(in: child.value, depth: depth + 1)
        }
        return found
    }
}
