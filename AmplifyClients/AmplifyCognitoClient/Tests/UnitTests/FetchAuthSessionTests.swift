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

/// `fetchAuthSession(options:)` and `getCurrentUser()`: what each kind of session holds, refresh through the
/// single flight, guest acquisition, and the failures, which all throw.
final class FetchAuthSessionTests: XCTestCase {

    private var harness: ClientHarness!
    private let work = ClientFixtures.id("work")
    private let home = ClientFixtures.id("home")
    private let alice = AmplifyCognitoClientUser(username: "alice", userId: "sub-alice")

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
    ///    - every field holds the payload's values; the state is signed in; nothing is refreshed
    func testSignedInSessionReportsEveryField() async throws {
        let payload = FakePayload.signedIn("alice", identityId: "us-east-1:alice")
        try harness.signIn(work, payload)
        let client = try harness.client(work)

        let session = try await client.fetchAuthSession()

        XCTAssertEqual(session, AmplifyCognitoClientAuthSession(
            identityId: "us-east-1:alice",
            awsCredentials: AmplifyCognitoClientAWSCredentials(payload.awsCredentials),
            userSub: "sub-alice",
            userPoolTokens: try XCTUnwrap(payload.userPoolTokens)
        ))
        XCTAssertEqual(harness.engine(for: work)?.refreshCalls, [])
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedIn(alice))
    }

    /// - Given: a user-pool-only session
    /// - When: its session is fetched
    /// - Then:
    ///    - it holds the tokens and sub; the identity ID and AWS credentials are `nil`
    func testUserPoolOnlySessionHasNoIdentityPoolFields() async throws {
        try harness.signIn(work, .signedIn("alice", kind: .userPoolOnly))
        let client = try harness.client(work)

        let session = try await client.fetchAuthSession()

        XCTAssertEqual(session.userSub, "sub-alice")
        XCTAssertNotNil(session.userPoolTokens)
        XCTAssertNil(session.awsCredentials)
        XCTAssertNil(session.identityId)
    }

    /// - Given: a guest session
    /// - When: its session is fetched
    /// - Then:
    ///    - it holds the identity ID and AWS credentials; the sub and tokens are `nil`; the state is `.guest`
    func testGuestSessionHasCredentialsButNoUser() async throws {
        let guest = FakePayload.guest(identityId: "us-east-1:guest-1")
        try harness.signIn(work, guest)
        let client = try harness.client(work)

        let session = try await client.fetchAuthSession()

        let state = await client.currentSessionState()
        XCTAssertEqual(state, .guest)
        XCTAssertEqual(session.identityId, "us-east-1:guest-1")
        XCTAssertEqual(session.awsCredentials, AmplifyCognitoClientAWSCredentials(guest.awsCredentials))
        XCTAssertNil(session.userSub)
        XCTAssertNil(session.userPoolTokens)
    }

    /// - Given: a session signed in under a configuration with no identity pool
    /// - When: its session is fetched
    /// - Then:
    ///    - it holds the tokens and sub, and no identity ID or AWS credentials, whatever the saved login holds
    func testASessionWithNoIdentityPoolHasNoIdentityFields() async throws {
        let client = try harness.client(home, configuration: ClientFixtures.userPoolOnlyConfiguration)
        _ = try await client.signInForTest()

        let session = try await client.fetchAuthSession()

        XCTAssertEqual(session.userSub, "sub-alice")
        XCTAssertNotNil(session.userPoolTokens)
        XCTAssertNil(session.identityId)
        XCTAssertNil(session.awsCredentials)
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

        XCTAssertNil(session.userPoolTokens)
        XCTAssertEqual(session.identityId, "us-east-1:guest")
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
    ///    - both throw `notSignedIn` and stay signed out; the one without an identity pool never asks the engine
    func testNoGuestAccessStaysSignedOut() async throws {
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        engine.scriptGuestCredentials { _ in throw SessionEngineError.notSignedIn }
        let poolOnly = try harness.client(home, configuration: ClientFixtures.userPoolOnlyConfiguration)

        let noGuest = await authClientError { try await client.fetchAuthSession() }
        let noPool = await authClientError { try await poolOnly.fetchAuthSession() }

        XCTAssertEqual(noGuest?.isEquivalent(to: SessionCore.notSignedIn(work)), true, "\(String(describing: noGuest))")
        XCTAssertEqual(noPool?.isEquivalent(to: SessionCore.notSignedIn(home)), true, "\(String(describing: noPool))")
        XCTAssertEqual(engine.guestFetchCount, 1)
        XCTAssertEqual(harness.engine(for: home)?.guestFetchCount, 0)
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedOut)
        XCTAssertNil(try harness.storedRecord(work))
    }

    /// - Given: a signed-out session whose guest fetch fails with a service error
    /// - When: its session is fetched
    /// - Then:
    ///    - it throws that error, and the session stays signed out
    func testAFailedGuestFetchThrows() async throws {
        let client = try harness.client(work)
        harness.engine(for: work)?.scriptGuestCredentials { _ in
            throw SessionEngineError.service(.service(.network, "offline", "retry"))
        }

        let error = await authClientError { try await client.fetchAuthSession() }

        XCTAssertEqual(error?.kind, .service(.network))
        XCTAssertEqual(error?.errorDescription, "offline")
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
            XCTAssertEqual(session.identityId, "us-east-1:guest")
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
            XCTAssertEqual(session.userPoolTokens?.accessToken, "access-alice-v2")
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
        XCTAssertEqual(session.userPoolTokens?.accessToken, "access-alice-v3")
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
        XCTAssertEqual(forced.userPoolTokens?.accessToken, "access-alice-v2")
    }

    /// A forced refresh of a session signed out in this process still calls Cognito when another writer has saved a
    /// login since: the session adopts that login, then refreshes it.
    ///
    /// - Given: a session restored signed out, with an identity pool; then another writer (an app extension, or the
    ///   Auth plugin over `.default`) saves bob's login in its record
    /// - When: its session is fetched with `forceRefresh`, and on a second such session, without it
    /// - Then:
    ///    - the forced fetch refreshes bob's saved login once and reports the refreshed tokens; no guest is fetched
    ///    - the unforced fetch adopts bob's saved tokens, which need no refresh, and reports them with no refresh
    func testAForcedFetchOfASignedOutSessionRefreshesAnotherWritersLogin() async throws {
        let bob = FakePayload.signedIn("bob")
        let forcedClient = try harness.client(work)
        let unforcedClient = try harness.client(home)
        _ = await forcedClient.currentSessionState()
        _ = await unforcedClient.currentSessionState()
        try harness.signIn(work, bob)
        try harness.signIn(home, bob)
        let forcedEngine = try XCTUnwrap(harness.engine(for: work))
        let unforcedEngine = try XCTUnwrap(harness.engine(for: home))

        let forced = try await forcedClient.fetchAuthSession(options: .init(forceRefresh: true))
        let unforced = try await unforcedClient.fetchAuthSession()

        XCTAssertEqual(forcedEngine.refreshCalls, [bob.data])
        XCTAssertEqual(forced.userPoolTokens?.accessToken, "access-bob-v2")
        XCTAssertEqual(forcedEngine.guestFetchCount, 0)
        XCTAssertEqual(unforcedEngine.refreshCalls, [])
        XCTAssertEqual(unforced.userPoolTokens?.accessToken, bob.accessToken)
    }

    /// A forced fetch of a session signed out in this process still refreshes another writer's login when an unforced
    /// fetch running alongside adopted it first.
    ///
    /// - Given: a session restored signed out, with an identity pool; another writer then saves bob's login in its
    ///   record; an unforced fetch holds the record's gate, its read of bob's login stalled
    /// - When: a forced fetch starts while the session is still signed out, and queues for the gate; then the read
    ///   finishes
    /// - Then:
    ///    - the forced fetch refreshes bob's login once and reports the refreshed tokens; no guest is fetched
    ///    - the unforced fetch reports bob's saved tokens
    func testAForcedFetchRefreshesALoginAnUnforcedFetchAdoptedFirst() async throws {
        let bob = FakePayload.signedIn("bob")
        let client = try harness.client(work)
        _ = await client.currentSessionState()
        try harness.signIn(work, bob)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let stall = Stall()
        defer { stall.release() }
        harness.keychain.onceAfterReading(harness.store().sessionAccount(for: work)) { stall.block() }

        let unforced = Task { try await client.fetchAuthSession() }
        await waitUntil("the unforced fetch reads the record") { stall.hasBeenReached }
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedOut, "the forced fetch starts while the session is signed out")
        let forced = Task { try await client.fetchAuthSession(options: .init(forceRefresh: true)) }
        await waitUntil("the forced fetch queues for the record's gate") { await client.core.gate.waiterCount == 1 }
        stall.release()

        let forcedSession = try await forced.value
        let unforcedSession = try await unforced.value
        XCTAssertEqual(engine.refreshCalls, [bob.data])
        XCTAssertEqual(forcedSession.userPoolTokens?.accessToken, "access-bob-v2")
        XCTAssertEqual(engine.guestFetchCount, 0)
        XCTAssertEqual(unforcedSession.userPoolTokens?.accessToken, bob.accessToken)
    }

    /// A forced fetch of a session signed out in this process never joins an unforced fetch's guest acquisition: it
    /// waits for it, then refreshes the guest it saved.
    ///
    /// - Given: a session restored signed out, with an identity pool and no saved login; an unforced fetch whose guest
    ///   fetch is held in the engine
    /// - When: a forced fetch starts while it is held, then the guest fetch finishes
    /// - Then: one guest is fetched, and the forced fetch refreshes it once and reports the refreshed guest's
    ///   credentials; the unforced fetch reports the guest it fetched
    func testAForcedFetchDoesNotJoinAnUnforcedGuestAcquisition() async throws {
        let guest = FakePayload.guest(identityId: "us-east-1:guest")
        let client = try harness.client(work)
        _ = await client.currentSessionState()
        let engine = try XCTUnwrap(harness.engine(for: work))
        let latch = Gate()
        engine.scriptGuestCredentials { _ in
            await latch.pass()
            return guest.data
        }

        let unforced = Task { try await client.fetchAuthSession() }
        await latch.waitForArrivals(1)
        let forced = Task { try await client.fetchAuthSession(options: .init(forceRefresh: true)) }
        await waitUntil("the forced fetch queues for the record's gate") { await client.core.gate.waiterCount == 1 }
        await latch.open()

        let forcedSession = try await forced.value
        let unforcedSession = try await unforced.value
        XCTAssertEqual(engine.guestFetchCount, 1)
        XCTAssertEqual(engine.refreshCalls, [guest.data])
        XCTAssertEqual(forcedSession.awsCredentials, AmplifyCognitoClientAWSCredentials(guest.refreshed.awsCredentials))
        XCTAssertEqual(unforcedSession.awsCredentials, AmplifyCognitoClientAWSCredentials(guest.awsCredentials))
    }

    /// A forced fetch of a session signed out in this process never takes an unforced fetch's guest acquisition as its
    /// answer: that one may adopt a login another writer saved, which the forced fetch refreshes instead.
    ///
    /// - Given: a session restored signed out, with an identity pool and no saved login; a forced fetch holds the
    ///   record's gate, its read of the empty record stalled; an unforced fetch has started its guest acquisition and
    ///   queues for the gate
    /// - When: another writer saves bob's login, then the read finishes
    /// - Then:
    ///    - the forced fetch refreshes bob's login once and reports the refreshed tokens, not bob's saved ones; the
    ///      guest it fetched is not saved over bob's login
    func testAForcedFetchNeverAnswersWithAnUnforcedFetchsGuestAcquisition() async throws {
        let bob = FakePayload.signedIn("bob")
        let client = try harness.client(work)
        _ = await client.currentSessionState()
        let engine = try XCTUnwrap(harness.engine(for: work))
        let stall = Stall()
        defer { stall.release() }
        harness.keychain.onceAfterReading(harness.store().sessionAccount(for: work)) { stall.block() }

        let forced = Task { try await client.fetchAuthSession(options: .init(forceRefresh: true)) }
        await waitUntil("the forced fetch reads the record") { stall.hasBeenReached }
        let unforced = Task { try await client.fetchAuthSession() }
        await waitUntil("the unforced fetch's guest acquisition queues for the record's gate") {
            await client.core.gate.waiterCount == 1
        }
        try harness.signIn(work, bob)
        stall.release()

        let forcedSession = try await forced.value
        _ = try await unforced.value
        XCTAssertEqual(engine.refreshCalls, [bob.data])
        XCTAssertEqual(forcedSession.userPoolTokens?.accessToken, "access-bob-v2")
        XCTAssertEqual(FakePayload.decode(try XCTUnwrap(harness.storedRecord(work)?.credentials))?.username, "bob")
    }

    /// An unforced fetch of a session signed out in this process answers another writer's saved credentials as the
    /// signed-in or guest session they make it: credentials that need a refresh are refreshed, never handed out.
    ///
    /// - Given: two sessions restored signed out, with an identity pool; another writer (an app extension, or the Auth
    ///   plugin over `.default`) then saves bob's expired login in one's record, and an expired guest in the other's
    /// - When: each is fetched without `forceRefresh`
    /// - Then:
    ///    - each refreshes what was saved once, and reports the refreshed tokens or AWS credentials; no guest is
    ///      fetched, and the record holds the refreshed credentials
    func testAnUnforcedFetchOfASignedOutSessionRefreshesAnotherWritersExpiredCredentials() async throws {
        let bob = FakePayload.signedIn("bob", stale: true)
        let guest = FakePayload.guest(stale: true, identityId: "us-east-1:saved-guest")
        let loginClient = try harness.client(work)
        let guestClient = try harness.client(home)
        _ = await loginClient.currentSessionState()
        _ = await guestClient.currentSessionState()
        try harness.signIn(work, bob)
        try harness.signIn(home, guest)
        let loginEngine = try XCTUnwrap(harness.engine(for: work))
        let guestEngine = try XCTUnwrap(harness.engine(for: home))

        let login = try await loginClient.fetchAuthSession()
        let guestSession = try await guestClient.fetchAuthSession()

        XCTAssertEqual(loginEngine.refreshCalls, [bob.data])
        XCTAssertEqual(login.userPoolTokens?.accessToken, "access-bob-v2")
        XCTAssertEqual(login.awsCredentials, AmplifyCognitoClientAWSCredentials(bob.refreshed.awsCredentials))
        XCTAssertEqual(try harness.storedRecord(work)?.credentials, bob.refreshed.data)
        XCTAssertEqual(loginEngine.guestFetchCount, 0)
        XCTAssertEqual(guestEngine.refreshCalls, [guest.data])
        XCTAssertEqual(guestSession.awsCredentials, AmplifyCognitoClientAWSCredentials(guest.refreshed.awsCredentials))
        XCTAssertEqual(try harness.storedRecord(home)?.credentials, guest.refreshed.data)
        XCTAssertEqual(guestEngine.guestFetchCount, 0)
        let state = await loginClient.currentSessionState()
        XCTAssertEqual(state, .signedIn(AmplifyCognitoClientUser(username: "bob", userId: "sub-bob")))
    }

    /// - Given: a session restored signed out, with an identity pool; another writer then saves bob's valid login in its
    ///   record
    /// - When: its session is fetched without `forceRefresh`
    /// - Then:
    ///    - it reports bob's saved tokens and AWS credentials with no refresh; no guest is fetched
    func testAnUnforcedFetchOfASignedOutSessionReportsAnotherWritersValidLoginWithoutARefresh() async throws {
        let bob = FakePayload.signedIn("bob")
        let client = try harness.client(work)
        _ = await client.currentSessionState()
        try harness.signIn(work, bob)
        let engine = try XCTUnwrap(harness.engine(for: work))

        let session = try await client.fetchAuthSession()

        XCTAssertEqual(engine.refreshCalls, [])
        XCTAssertEqual(engine.guestFetchCount, 0)
        XCTAssertEqual(session.userPoolTokens?.accessToken, bob.accessToken)
        XCTAssertEqual(session.awsCredentials, AmplifyCognitoClientAWSCredentials(bob.awsCredentials))
    }

    /// A guest a signed-out session fetches itself is fresh, so it is not refreshed, even by a forced fetch.
    ///
    /// - Given: two sessions restored signed out, with an identity pool and nothing saved
    /// - When: one is fetched, and the other fetched with `forceRefresh`
    /// - Then:
    ///    - each fetches one guest and reports it, with no refresh
    func testAGuestASignedOutSessionFetchesIsNotRefreshed() async throws {
        let unforcedClient = try harness.client(work)
        let forcedClient = try harness.client(home)
        let unforcedEngine = try XCTUnwrap(harness.engine(for: work))
        let forcedEngine = try XCTUnwrap(harness.engine(for: home))

        let unforced = try await unforcedClient.fetchAuthSession()
        let forced = try await forcedClient.fetchAuthSession(options: .init(forceRefresh: true))

        for (session, engine) in [(unforced, unforcedEngine), (forced, forcedEngine)] {
            XCTAssertEqual(engine.guestFetchCount, 1)
            XCTAssertEqual(engine.refreshCalls, [])
            XCTAssertEqual(session.identityId, "us-east-1:guest")
            XCTAssertEqual(session.awsCredentials?.accessKeyId, FakePayload.guest().awsCredentials.accessKeyId)
        }
    }

    /// An adopted login whose refresh fails throws after one refresh: the fetch does not go round again.
    ///
    /// - Given: a session restored signed out, with an identity pool; another writer then saves bob's expired login,
    ///   whose refresh token is dead
    /// - When: its session is fetched without `forceRefresh`
    /// - Then:
    ///    - one refresh; it throws `sessionExpired`; the session is signed in as bob; no guest is fetched
    func testAnAdoptedLoginWhoseRefreshFailsThrowsAfterOneRefresh() async throws {
        let bob = FakePayload.signedIn("bob", stale: true)
        let client = try harness.client(work)
        _ = await client.currentSessionState()
        try harness.signIn(work, bob)
        let engine = try XCTUnwrap(harness.engine(for: work))
        engine.scriptRefresh { _ in throw SessionEngineError.refreshTokenInvalid }

        let error = await authClientError { try await client.fetchAuthSession() }

        XCTAssertEqual(engine.refreshCalls, [bob.data])
        XCTAssertEqual(engine.guestFetchCount, 0)
        XCTAssertEqual(error?.kind, .sessionExpired)
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedIn(AmplifyCognitoClientUser(username: "bob", userId: "sub-bob")))
    }

    /// - Given: a signed-in session whose refresh token is dead
    /// - When: its session is fetched twice
    /// - Then:
    ///    - both throw `sessionExpired`, and the state is still signed in as the user; `.sessionExpired` is sent
    ///      once, and the second fetch does not refresh again
    func testADeadRefreshTokenThrowsSessionExpired() async throws {
        try harness.signIn(work, .signedIn("alice", stale: true))
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        engine.scriptRefresh { _ in throw SessionEngineError.refreshTokenInvalid }
        let events = StreamRecorder(client.listenToAuthEvents())

        let first = await authClientError { try await client.fetchAuthSession() }
        let second = await authClientError { try await client.fetchAuthSession() }

        XCTAssertEqual(first?.kind, .sessionExpired)
        XCTAssertEqual(second?.kind, .sessionExpired)
        XCTAssertEqual(engine.refreshCalls.count, 1)
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedIn(alice))
        // Ends on an event no fetch sends: once `.signedIn` has arrived, a second `.sessionExpired` has too.
        _ = try await client.signInForTest()
        await waitUntil("the sign-in's event arrives") { events.received.last == .signedIn }
        XCTAssertEqual(events.received, [.sessionExpired, .signedIn])
    }

    /// - Given: a signed-in session whose refresh fails at the network
    /// - When: its session is fetched
    /// - Then:
    ///    - it throws the service error; the session is not expired, and stays signed in
    func testAFailedRefreshThrows() async throws {
        try harness.signIn(work, .signedIn("alice", stale: true))
        let client = try harness.client(work)
        harness.engine(for: work)?.scriptRefresh { _ in
            throw SessionEngineError.service(.service(.network, "offline", "retry"))
        }

        let error = await authClientError { try await client.fetchAuthSession() }

        XCTAssertEqual(error?.kind, .service(.network))
        let expired = await client.core.isExpired
        XCTAssertFalse(expired)
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedIn(alice))
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

    /// A refresh that stored rotated tokens and then failed is committed, then thrown as the failure it was.
    ///
    /// - Given: a stale session whose engine refresh stores the next tokens, then fails its identity pool step
    /// - When: its session is fetched
    /// - Then:
    ///    - it throws the mapped service error
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

        let error = await authClientError { try await client.fetchAuthSession() }

        XCTAssertEqual(error?.kind, .service(.network))
        let record = try harness.storedRecord(work)
        XCTAssertEqual(record.flatMap { $0.credentials.flatMap(FakePayload.decode) }, stored, "the rotated tokens are kept")
        let expired = await client.core.isExpired
        XCTAssertFalse(expired)
    }

    /// Like the providers, `fetchAuthSession` reports what its own refresh committed, as the plugin reports what its
    /// refresh established, even when those credentials still read as needing a refresh (a device clock running
    /// ahead of Cognito's). Only a re-read or adopted record that still needs one is never reported
    /// (`RefreshResultTests`).
    ///
    /// - Given: a stale session whose refresh returns credentials that still read as stale
    /// - When: its session is fetched
    /// - Then:
    ///    - it holds the refreshed tokens and AWS credentials, and throws no retryable `unknown`
    func testCredentialsStillStaleAfterTheirOwnRefreshAreReported() async throws {
        try harness.signIn(work, .signedIn("alice", stale: true))
        let client = try harness.client(work)
        harness.engine(for: work)?.scriptRefresh { payload in
            var next = try XCTUnwrap(FakePayload.decode(payload))
            next.version += 1
            return next.data
        }

        let session = try await client.fetchAuthSession()

        XCTAssertEqual(session.userPoolTokens?.accessToken, "access-alice-v2")
        XCTAssertEqual(session.awsCredentials, AmplifyCognitoClientAWSCredentials(FakePayload.signedIn("alice", version: 2).awsCredentials))
    }

    /// A `CredentialsError` from inside the session core never escapes `fetchAuthSession`,
    /// which speaks `AmplifyCognitoClientError` only.
    ///
    /// - Given: a stale session whose refresh throws `CredentialsError.notConfigured`
    /// - When: its session is fetched
    /// - Then:
    ///    - it throws an `AmplifyCognitoClientError.unknown` with that error underneath
    func testACredentialsErrorIsThrownAsAnAmplifyCognitoClientError() async throws {
        try harness.signIn(work, .signedIn("alice", stale: true))
        let client = try harness.client(work)
        harness.engine(for: work)?.scriptRefresh { _ in
            throw CredentialsError.notConfigured("no identity pool", "configure one")
        }

        let error = await authClientError { try await client.fetchAuthSession() }

        XCTAssertEqual(error?.kind, .unknown)
        XCTAssertEqual(error?.errorDescription, "no identity pool")
        XCTAssertTrue(error?.underlyingError is CredentialsError)
    }

    // MARK: Signed out during the call, cancellation, missing data

    /// A refresh that finds the session signed out by another writer answers as a signed-out session's fetch does,
    /// once: it does not go round again.
    ///
    /// - Given: a stale signed-in session, and a refresh during which another process signs the session out; in turn
    ///   with an identity pool that allows guests, and with one that allows none
    /// - When: the session is fetched
    /// - Then:
    ///    - with guest access it returns a guest session, and the state is `.guest`
    ///    - without it, it throws `notSignedIn`, and the state is `.signedOut`
    ///    - each refreshed once and asked for guest credentials once
    func testARefreshThatFindsTheSessionSignedOutAnswersAsASignedOutSession() async throws {
        for guestAccess in [true, false] {
            await harness.waitForBaseline()
            harness = ClientHarness()
            try harness.signIn(work, .signedIn("alice", stale: true))
            let client = try harness.client(work)
            _ = await client.currentSessionState()
            let engine = try XCTUnwrap(harness.engine(for: work))
            let store = harness.store()
            let work = work
            engine.scriptRefresh { payload in
                _ = try store.signOut(work)
                return try XCTUnwrap(FakePayload.decode(payload)).refreshed.data
            }

            if guestAccess {
                let session = try await client.fetchAuthSession()
                XCTAssertEqual(session, AmplifyCognitoClientAuthSession(
                    identityId: "us-east-1:guest",
                    awsCredentials: AmplifyCognitoClientAWSCredentials(FakePayload.guest().awsCredentials)
                ))
            } else {
                engine.scriptGuestCredentials { _ in throw SessionEngineError.notSignedIn }
                let error = await authClientError { try await client.fetchAuthSession() }
                XCTAssertEqual(error?.isEquivalent(to: SessionCore.notSignedIn(work)), true, "\(String(describing: error))")
            }
            XCTAssertEqual(engine.refreshCalls.count, 1, "guest access: \(guestAccess)")
            XCTAssertEqual(engine.guestFetchCount, 1, "guest access: \(guestAccess)")
            let state = await client.currentSessionState()
            XCTAssertEqual(state, guestAccess ? .guest : .signedOut)
        }
    }

    /// A refresh or a guest fetch the engine reports as cancelled (a service call cancelled mid-flight) throws
    /// `CancellationError`, never an `AmplifyCognitoClientError` that wraps one.
    ///
    /// - Given: a stale signed-in session whose refresh fails with an error caused by a cancellation, and a
    ///   signed-out session whose guest fetch fails the same way
    /// - When: each session is fetched
    /// - Then:
    ///    - both throw `CancellationError`; the first is not expired, and the second stays signed out
    func testACancelledRefreshOrGuestFetchThrowsCancellationError() async throws {
        try harness.signIn(work, .signedIn("alice", stale: true))
        let signedIn = try harness.client(work)
        let signedOut = try harness.client(home)
        let cancelled = SessionEngineError.service(.unknown("The request was cancelled.", "Retry.", CancellationError()))
        harness.engine(for: work)?.scriptRefresh { _ in throw cancelled }
        harness.engine(for: home)?.scriptGuestCredentials { _ in throw cancelled }

        for (name, client) in [("refresh", signedIn), ("guest fetch", signedOut)] {
            do {
                _ = try await client.fetchAuthSession()
                XCTFail("\(name): expected a cancellation")
            } catch {
                XCTAssertTrue(error is CancellationError, "\(name): \(error)")
            }
        }
        let expired = await signedIn.core.isExpired
        XCTAssertFalse(expired)
        let state = await signedOut.currentSessionState()
        XCTAssertEqual(state, .signedOut)
    }

    /// - Given: under a configuration with an identity pool, a signed-in session whose saved credentials name no
    ///   identity, one whose saved credentials hold no AWS credentials, and one whose saved credentials hold no
    ///   user pool tokens
    /// - When: each is fetched
    /// - Then:
    ///    - each throws `unknown` saying what the saved credentials lack, and suggesting a new sign-in
    func testSavedCredentialsMissingAFieldThrowUnknown() async throws {
        let personal = ClientFixtures.id("personal")
        var noIdentity = FakePayload.signedIn("alice")
        noIdentity.identityId = nil
        var noAWSCredentials = FakePayload.signedIn("bob")
        noAWSCredentials.aws = false
        var noTokens = FakePayload.signedIn("carol")
        noTokens.withoutUserPoolTokens = true
        try harness.signIn(work, noIdentity)
        try harness.signIn(home, noAWSCredentials)
        try harness.signIn(personal, noTokens)
        let alice = try harness.client(work)
        let bob = try harness.client(home)
        let carol = try harness.client(personal)

        let identity = await authClientError { try await alice.fetchAuthSession() }
        let credentials = await authClientError { try await bob.fetchAuthSession() }
        let tokens = await authClientError { try await carol.fetchAuthSession() }

        XCTAssertEqual(
            tokens?.isEquivalent(to: SessionCore.missing("user pool tokens", in: personal)),
            true,
            "\(String(describing: tokens))"
        )

        XCTAssertEqual(
            identity?.isEquivalent(to: SessionCore.missing("an identity ID", in: work)),
            true,
            "\(String(describing: identity))"
        )
        XCTAssertEqual(
            credentials?.isEquivalent(to: SessionCore.missing("AWS credentials", in: home)),
            true,
            "\(String(describing: credentials))"
        )
        XCTAssertEqual(identity?.recoverySuggestion, "Sign the session out and sign in again.")
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
}
