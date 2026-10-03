//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyFoundation
import Security
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// `fetchAuthSession(options:)` and `getCurrentUser()`: the per-field results for each
/// kind of session, refresh through the single flight, guest acquisition, and the failures that throw.
final class FetchAuthSessionTests: XCTestCase {

    private var harness: ClientHarness!
    private let work = ClientFixtures.id("work")
    private let home = ClientFixtures.id("home")
    private let alice = AuthClientUser(username: "alice", userId: "sub-alice")

    override func setUp() {
        harness = ClientHarness()
    }

    override func tearDown() async throws {
        harness.keychain.clearFailures()
        await harness.waitForBaseline()
        harness = nil
    }

    // MARK: The field table

    /// - Given: a session signed in to both pools
    /// - When: its session is fetched
    /// - Then:
    ///    - every field succeeds with the payload's values; the state is signed in; nothing is refreshed
    func testSignedInSessionReportsEveryField() async throws {
        let payload = FakePayload.signedIn("alice", identityId: "us-east-1:alice")
        try harness.signIn(work, payload)
        let client = try harness.client(work)

        let session = try await client.fetchAuthSession()

        XCTAssertEqual(session, AuthClientSession(
            identityIdResult: .success("us-east-1:alice"),
            awsCredentialsResult: .success(AuthClientAWSCredentials(payload.awsCredentials)),
            userSubResult: .success("sub-alice"),
            userPoolTokensResult: .success(try XCTUnwrap(payload.userPoolTokens))
        ))
        XCTAssertEqual(harness.engine(for: work)?.refreshCalls, [])
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedIn(alice))
    }

    /// - Given: a user-pool-only session
    /// - When: its session is fetched
    /// - Then:
    ///    - the tokens and sub succeed; the identity ID and AWS credentials fail with `configuration`
    func testUserPoolOnlySessionHasNoIdentityPoolFields() async throws {
        try harness.signIn(work, .signedIn("alice", kind: .userPoolOnly))
        let client = try harness.client(work)

        let session = try await client.fetchAuthSession()

        XCTAssertEqual(try session.userSubResult.get(), "sub-alice")
        XCTAssertNoThrow(try session.userPoolTokensResult.get())
        XCTAssertThrowsError(try session.awsCredentialsResult.get()) { error in
            XCTAssertEqual((error as? AuthClientError)?.kind, .configuration)
        }
        XCTAssertThrowsError(try session.identityIdResult.get())
    }

    /// - Given: a guest session
    /// - When: its session is fetched
    /// - Then:
    ///    - the identity ID and AWS credentials succeed; the sub and tokens fail with `notSignedIn`; the
    ///      state is `.guest`
    func testGuestSessionHasCredentialsButNoUser() async throws {
        let guest = FakePayload.guest(identityId: "us-east-1:guest-1")
        try harness.signIn(work, guest)
        let client = try harness.client(work)

        let session = try await client.fetchAuthSession()

        let state = await client.currentSessionState()
        XCTAssertEqual(state, .guest)
        XCTAssertEqual(try session.identityIdResult.get(), "us-east-1:guest-1")
        XCTAssertEqual(try session.awsCredentialsResult.get(), AuthClientAWSCredentials(guest.awsCredentials))
        XCTAssertThrowsError(try session.userSubResult.get()) { error in
            XCTAssertEqual((error as? AuthClientError)?.kind, .notSignedIn)
        }
        XCTAssertThrowsError(try session.userPoolTokensResult.get())
    }

    // MARK: Guest acquisition

    /// fetchAuthSession is the only path from `.signedOut` to `.guest`.
    ///
    /// - Given: a signed-out session with an identity pool
    /// - When: its session is fetched
    /// - Then:
    ///    - guest credentials are fetched once and committed; the state becomes `.guest` and publishes;
    ///      no event is sent; the providers now vend the guest credentials
    func testSignedOutSessionAcquiresGuestCredentials() async throws {
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        _ = await client.currentSessionState()
        let states = StreamRecorder(client.listenToSessionStateChanges())
        let events = StreamRecorder(client.listenToAuthEvents())

        let session = try await client.fetchAuthSession()

        XCTAssertThrowsError(try session.userPoolTokensResult.get())
        XCTAssertEqual(try session.identityIdResult.get(), "us-east-1:guest")
        XCTAssertEqual(engine.guestFetchCount, 1)
        XCTAssertEqual(try harness.storedRecord(work)?.kind, .guest)
        await states.waitFor(1)
        XCTAssertEqual(states.received, [.guest])
        XCTAssertEqual(events.received, [])
        let credentials = try await client.credentialsProvider.resolve()
        XCTAssertEqual(credentials.accessKeyId, FakePayload.guest().awsCredentials.accessKeyId)
    }

    /// - Given: a signed-out session whose identity pool allows no guest access, and one with no identity
    ///   pool at all
    /// - When: their sessions are fetched
    /// - Then:
    ///    - both stay signed out, every field fails with `notSignedIn`; the one without an identity pool
    ///      never asks the engine
    func testNoGuestAccessStaysSignedOut() async throws {
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        engine.scriptGuestCredentials { _ in throw SessionEngineError.notSignedIn }
        let poolOnly = try harness.client(home, configuration: ClientFixtures.userPoolOnlyConfiguration)

        let noGuest = try await client.fetchAuthSession()
        let noPool = try await poolOnly.fetchAuthSession()

        XCTAssertEqual(noGuest, FetchAuthSessionTests.signedOut(work))
        XCTAssertEqual(noPool, FetchAuthSessionTests.signedOut(home))
        XCTAssertEqual(engine.guestFetchCount, 1)
        XCTAssertEqual(harness.engine(for: home)?.guestFetchCount, 0)
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedOut)
        XCTAssertNil(try harness.storedRecord(work))
    }

    /// - Given: a signed-out session whose guest fetch fails with a service error
    /// - When: its session is fetched
    /// - Then:
    ///    - it does not throw: every field carries the error, and the session stays signed out
    func testAFailedGuestFetchIsReportedInTheFields() async throws {
        let client = try harness.client(work)
        harness.engine(for: work)?.scriptGuestCredentials { _ in
            throw SessionEngineError.service(.service(.network, "offline", "retry"))
        }

        let session = try await client.fetchAuthSession()

        XCTAssertThrowsError(try session.awsCredentialsResult.get()) { error in
            XCTAssertEqual((error as? AuthClientError)?.kind, .service(.network))
        }
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedOut)
    }

    /// - Given: a signed-out session, with guest fetches held in the engine
    /// - When: twenty sessions are fetched at once
    /// - Then:
    ///    - the engine fetched guest credentials once, and every caller got the guest session
    func testConcurrentGuestAcquisitionIsSingleFlight() async throws {
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        // Restored first: a caller that restores while the held flight holds the record's gate would
        // queue on the gate instead of joining the flight.
        _ = await client.currentSessionState()
        let latch = Gate()
        engine.scriptGuestCredentials { _ in
            await latch.pass()
            return FakePayload.guest(identityId: "us-east-1:guest").data
        }

        let fetches = (0 ..< 20).map { _ in Task { try await client.fetchAuthSession() } }
        await latch.waitForArrivals(1)
        await waitUntil("the other callers join the flight") { await client.core.guestFlight.waiterCount == 20 }
        await latch.open()
        for fetch in fetches {
            let session = try await fetch.value
            XCTAssertEqual(try session.identityIdResult.get(), "us-east-1:guest")
        }

        XCTAssertEqual(engine.guestFetchCount, 1)
    }

    // MARK: Refresh

    /// - Given: a signed-in session whose credentials need a refresh, held in the engine
    /// - When: twenty sessions are fetched at once
    /// - Then:
    ///    - the engine refreshed once, through the refresh flight, and every caller got the refreshed tokens
    func testConcurrentFetchesShareOneRefresh() async throws {
        let stale = FakePayload.signedIn("alice", stale: true)
        try harness.signIn(work, stale)
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        // Restored first: a caller that restores while the held flight holds the record's gate would
        // queue on the gate instead of joining the flight.
        _ = await client.currentSessionState()
        let latch = Gate()
        engine.holdRefreshes(on: latch)

        let fetches = (0 ..< 20).map { _ in Task { try await client.fetchAuthSession() } }
        await latch.waitForArrivals(1)
        await waitUntil("the other callers join the flight") { await client.core.refreshFlight.waiterCount == 20 }
        await latch.open()
        for fetch in fetches {
            let session = try await fetch.value
            XCTAssertEqual(try session.userPoolTokensResult.get().accessToken, "access-alice-v2")
        }

        XCTAssertEqual(engine.refreshCalls, [stale.data])
        XCTAssertEqual(try harness.storedRecord(work)?.credentials, stale.refreshed.data)
    }

    /// A forced refresh must never be satisfied by joining a normal refresh already in flight,
    /// whose result need not be a refresh at all.
    ///
    /// - Given: a stale session whose provider-driven refresh is held in the engine
    /// - When: a forced `fetchAuthSession` starts while it is held, and then the refresh is let go
    /// - Then:
    ///    - the forced call runs its own refresh after the first: two engine refreshes, and it reports the
    ///      second refresh's tokens
    func testAForcedFetchDoesNotJoinANormalRefresh() async throws {
        let stale = FakePayload.signedIn("alice", stale: true)
        try harness.signIn(work, stale)
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let latch = Gate()
        engine.holdRefreshes(on: latch)

        let normal = Task { try await client.userPoolTokenProvider.accessToken() }
        await latch.waitForArrivals(1)
        let forced = Task { try await client.fetchAuthSession(options: .init(forceRefresh: true)) }
        await waitUntil("the forced call joins the flight or queues on the gate") {
            let joined = await client.core.refreshFlight.waiterCount == 2
            let queued = await client.core.gate.waiterCount == 1
            return joined || queued
        }
        await latch.open()
        let token = try await normal.value
        let session = try await forced.value

        XCTAssertEqual(token, "access-alice-v2")
        XCTAssertEqual(engine.refreshCalls.count, 2)
        XCTAssertEqual(try session.userPoolTokensResult.get().accessToken, "access-alice-v3")
    }

    /// - Given: a signed-in session whose credentials are still valid
    /// - When: its session is fetched, then fetched with `forceRefresh`
    /// - Then:
    ///    - the first does not refresh; the forced one does, and reports the refreshed tokens
    func testForceRefreshRefreshesValidCredentials() async throws {
        let fresh = FakePayload.signedIn("alice")
        try harness.signIn(work, fresh)
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))

        _ = try await client.fetchAuthSession()
        XCTAssertEqual(engine.refreshCalls, [])
        let forced = try await client.fetchAuthSession(options: .init(forceRefresh: true))

        XCTAssertEqual(engine.refreshCalls, [fresh.data])
        XCTAssertEqual(try forced.userPoolTokensResult.get().accessToken, "access-alice-v2")
    }

    /// - Given: a signed-in session whose refresh token is dead
    /// - When: its session is fetched twice
    /// - Then:
    ///    - it does not throw; every field is `sessionExpired`, and the state is still signed in as the
    ///      user; `.sessionExpired` is sent once, and the second fetch does not refresh again
    func testADeadRefreshTokenIsReportedAsSessionExpired() async throws {
        try harness.signIn(work, .signedIn("alice", stale: true))
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        engine.scriptRefresh { _ in throw SessionEngineError.refreshTokenInvalid }
        let events = StreamRecorder(client.listenToAuthEvents())

        let first = try await client.fetchAuthSession()
        let second = try await client.fetchAuthSession()

        for session in [first, second] {
            XCTAssertThrowsError(try session.userPoolTokensResult.get()) { error in
                XCTAssertEqual((error as? AuthClientError)?.kind, .sessionExpired)
            }
            XCTAssertThrowsError(try session.awsCredentialsResult.get())
        }
        XCTAssertEqual(engine.refreshCalls.count, 1)
        await events.waitFor(1)
        XCTAssertEqual(events.received, [.sessionExpired])
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedIn(alice))
    }

    /// - Given: a signed-in session whose refresh fails at the network
    /// - When: its session is fetched
    /// - Then:
    ///    - it does not throw; the fields carry the service error; the session is not expired
    func testAFailedRefreshIsReportedInTheFields() async throws {
        try harness.signIn(work, .signedIn("alice", stale: true))
        let client = try harness.client(work)
        harness.engine(for: work)?.scriptRefresh { _ in
            throw SessionEngineError.service(.service(.network, "offline", "retry"))
        }

        let session = try await client.fetchAuthSession()

        XCTAssertThrowsError(try session.userPoolTokensResult.get()) { error in
            XCTAssertEqual((error as? AuthClientError)?.kind, .service(.network))
        }
        let expired = await client.core.isExpired
        XCTAssertFalse(expired)
    }

    /// The engine refreshes unforced for a stale session, and forced only when the caller forces it.
    ///
    /// - Given: a stale session whose user pool tokens are still fresh, and one whose tokens are stale
    /// - When: the first is fetched, then fetched with `forceRefresh`; the second is fetched
    /// - Then: the engine's refreshes were unforced, then forced, then forced (by the core's clock)
    func testTheEngineRefreshIsForcedOnlyWhenTheCallerOrTheTokensNeedIt() async throws {
        try harness.signIn(work, .signedIn("alice", stale: true))
        let client = try harness.client(work)

        _ = try await client.fetchAuthSession()
        _ = try await client.fetchAuthSession(options: .init(forceRefresh: true))

        XCTAssertEqual(harness.engine(for: work)?.refreshForceFlags, [false, true])

        var tokensStale = FakePayload.signedIn("bob", stale: true)
        tokensStale.tokensStale = true
        try harness.signIn(home, tokensStale)
        let bob = try harness.client(home)

        _ = try await bob.fetchAuthSession()

        XCTAssertEqual(harness.engine(for: home)?.refreshForceFlags, [true])
    }

    /// A refresh that stored rotated tokens and then failed is committed, then reported as the failure it was.
    ///
    /// - Given: a stale session whose engine refresh stores the next tokens, then fails its identity pool step
    /// - When: its session is fetched
    /// - Then:
    ///    - the fields fail with the mapped service error
    ///    - the record holds the new tokens, so the next refresh uses them, and the session is not expired
    func testARefreshThatStoredTokensThenFailedCommitsThem() async throws {
        let stale = FakePayload.signedIn("alice", stale: true)
        try harness.signIn(work, stale)
        let client = try harness.client(work)
        let stored = stale.refreshed
        harness.engine(for: work)?.scriptRefresh { _ in
            throw SessionEngineError.refreshedThenFailed(
                payload: stored.data,
                error: .service(.service(.network, "identity pool offline", "retry"))
            )
        }

        let session = try await client.fetchAuthSession()

        XCTAssertThrowsError(try session.userPoolTokensResult.get()) { error in
            XCTAssertEqual((error as? AuthClientError)?.kind, .service(.network))
        }
        let record = try harness.storedRecord(work)
        XCTAssertEqual(record.flatMap { $0.credentials.flatMap(FakePayload.decode) }, stored, "the rotated tokens are kept")
        let expired = await client.core.isExpired
        XCTAssertFalse(expired)
    }

    /// Like the providers, `fetchAuthSession` never hands out credentials that still need a
    /// refresh after the refresh flight.
    ///
    /// - Given: a stale session whose refresh returns credentials that are still stale
    /// - When: its session is fetched
    /// - Then:
    ///    - it does not throw, and the fields fail with a retryable `unknown` rather than carry the tokens
    func testCredentialsStillStaleAfterTheRefreshAreNotHandedOut() async throws {
        try harness.signIn(work, .signedIn("alice", stale: true))
        let client = try harness.client(work)
        harness.engine(for: work)?.scriptRefresh { payload in
            var next = try XCTUnwrap(FakePayload.decode(payload))
            next.version += 1
            return next.data
        }

        let session = try await client.fetchAuthSession()

        XCTAssertThrowsError(try session.userPoolTokensResult.get()) { error in
            XCTAssertEqual((error as? AuthClientError)?.kind, .unknown)
        }
        XCTAssertThrowsError(try session.awsCredentialsResult.get())
    }

    /// A `CredentialsError` from inside the session core never escapes `fetchAuthSession`,
    /// which speaks `AuthClientError` only.
    ///
    /// - Given: a stale session whose refresh throws `CredentialsError.notConfigured`
    /// - When: its session is fetched
    /// - Then:
    ///    - it does not throw; the fields carry an `AuthClientError.unknown` with that error underneath
    func testACredentialsErrorIsReportedAsAnAuthClientError() async throws {
        try harness.signIn(work, .signedIn("alice", stale: true))
        let client = try harness.client(work)
        harness.engine(for: work)?.scriptRefresh { _ in
            throw CredentialsError.notConfigured("no identity pool", "configure one")
        }

        let session = try await client.fetchAuthSession()

        XCTAssertThrowsError(try session.userPoolTokensResult.get()) { error in
            let error = error as? AuthClientError
            XCTAssertEqual(error?.kind, .unknown)
            XCTAssertEqual(error?.errorDescription, "no identity pool")
            XCTAssertTrue(error?.underlyingError is CredentialsError)
        }
    }

    // MARK: Throws

    /// Storage that cannot be read is never reported as a signed-out session.
    ///
    /// - Given: a signed-in session whose storage is locked
    /// - When: its session is fetched, and its user asked for
    /// - Then:
    ///    - both throw `storageUnavailable(.locked)`; no guest credentials are fetched
    func testUnavailableStorageThrowsRatherThanReportingSignedOut() async throws {
        try harness.signIn(work, .signedIn("alice"))
        let client = try harness.client(work)
        harness.keychain.failing(.read, with: errSecInteractionNotAllowed)

        let session = await authClientError { try await client.fetchAuthSession() }
        let user = await authClientError { try await client.getCurrentUser() }

        XCTAssertEqual(session?.kind, .storageUnavailable(.locked))
        XCTAssertEqual(user?.kind, .storageUnavailable(.locked))
        XCTAssertEqual(harness.engine(for: work)?.guestFetchCount, 0)
    }

    /// - Given: a session whose saved record is corrupt
    /// - When: its session is fetched
    /// - Then:
    ///    - it throws the record's error, and fetches no guest credentials over it
    func testAnUnreadableRecordThrows() async throws {
        harness.keychain.put(Data("not a record".utf8), harness.store().sessionAccount(for: work))
        let client = try harness.client(work)

        let error = await authClientError { try await client.fetchAuthSession() }

        XCTAssertEqual(error?.kind, .unknown)
        XCTAssertEqual(harness.engine(for: work)?.guestFetchCount, 0)
    }

    // MARK: getCurrentUser

    /// - Given: a signed-in session, a guest session and a signed-out session
    /// - When: each is asked for its user
    /// - Then:
    ///    - the signed-in one answers with its user without the network; the others throw `notSignedIn`
    func testGetCurrentUser() async throws {
        try harness.signIn(work, .signedIn("alice"))
        try harness.signIn(home, .guest())
        let signedIn = try harness.client(work)
        let guest = try harness.client(home)
        let signedOut = try harness.client(ClientFixtures.id("other"))

        let user = try await signedIn.getCurrentUser()
        let guestError = await authClientError { try await guest.getCurrentUser() }
        let signedOutError = await authClientError { try await signedOut.getCurrentUser() }

        XCTAssertEqual(user, alice)
        XCTAssertEqual(guestError?.kind, .notSignedIn)
        XCTAssertEqual(signedOutError?.kind, .notSignedIn)
        XCTAssertEqual(signedOutError?.errorDescription, "There is no user signed in to retrieve current user")
        XCTAssertEqual(signedOutError?.recoverySuggestion, "Call signIn to sign a user in to this session, then call getCurrentUser.")
        XCTAssertEqual(harness.engine(for: work)?.refreshCalls, [])
    }

    static func signedOut(_ sessionId: SessionID) -> AuthClientSession {
        SessionCore.signedOutSession(sessionId)
    }
}
