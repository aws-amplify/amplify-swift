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

/// The two credential providers and the refresh path behind them.
final class CredentialProviderTests: XCTestCase {

    private var harness: ClientHarness!
    private let work = ClientFixtures.id("work")
    private let home = ClientFixtures.id("home")

    override func setUp() {
        harness = ClientHarness()
    }

    override func tearDown() async throws {
        harness.keychain.clearFailures()
        await harness.waitForBaseline()
        harness = nil
    }

    private func credentialsError(_ body: () async throws -> some Any, file: StaticString = #filePath, line: UInt = #line) async -> CredentialsError? {
        do {
            _ = try await body()
            XCTFail("expected an error", file: file, line: line)
            return nil
        } catch let error as CredentialsError {
            return error
        } catch {
            XCTFail("expected a CredentialsError, got \(error)", file: file, line: line)
            return nil
        }
    }

    // MARK: The state table

    /// - Given: a session with nothing stored
    /// - When: both providers are asked
    /// - Then:
    ///    - both throw `notSignedIn` (disposition `.discard`), and no guest credentials are fetched
    func testSignedOutFailsAndNeverFallsBackToGuest() async throws {
        let client = try harness.client(work)

        let aws = await credentialsError { try await client.credentialsProvider.resolve() }
        let token = await credentialsError { try await client.userPoolTokenProvider.accessToken() }

        XCTAssertEqual(aws?.isNotSignedIn, true)
        XCTAssertEqual(aws?.disposition, .discard)
        XCTAssertEqual(token?.isNotSignedIn, true)
        XCTAssertEqual(harness.engine(for: work)?.guestFetchCount, 0)
    }

    /// - Given: a guest session
    /// - When: both providers are asked
    /// - Then:
    ///    - the AWS credentials are the guest credentials; the access token throws `notSignedIn`
    func testGuestVendsGuestCredentialsButNoToken() async throws {
        let guest = FakePayload.guest()
        try harness.signIn(work, guest)
        let client = try harness.client(work)

        let credentials = try await client.credentialsProvider.resolve()
        let token = await credentialsError { try await client.userPoolTokenProvider.accessToken() }

        XCTAssertEqual(credentials as? CognitoAWSCredentials, guest.awsCredentials)
        XCTAssertEqual(token?.isNotSignedIn, true)
    }

    /// - Given: a signed-in session with an identity pool
    /// - When: both providers are asked
    /// - Then:
    ///    - both vend the session's credentials and token, bound to its session ID
    func testSignedInVendsBoth() async throws {
        let alice = FakePayload.signedIn("alice")
        try harness.signIn(work, alice)
        let client = try harness.client(work)

        let credentials = try await client.credentialsProvider.resolve()
        let token = try await client.userPoolTokenProvider.accessToken()

        XCTAssertEqual(credentials as? CognitoAWSCredentials, alice.awsCredentials)
        XCTAssertEqual(token, alice.accessToken)
        XCTAssertEqual(client.credentialsProvider.sessionId, work)
        XCTAssertEqual(client.userPoolTokenProvider.sessionId, work)
    }

    /// A user-pool-only session has no identity-pool credentials to give: a misconfiguration, so it
    /// fails loudly rather than retrying forever or pretending to be signed out.
    ///
    /// - Given: a signed-in session whose record holds only user pool tokens, and a signed-in session
    ///   whose configuration has no identity pool at all
    /// - When: each is asked for AWS credentials, and for an access token
    /// - Then:
    ///    - AWS credentials throw `notConfigured` (disposition `.failLoudly`); the token is vended
    func testUserPoolOnlySessionAskedForAWSCredentialsIsNotConfigured() async throws {
        let poolOnly = FakePayload.signedIn("alice", kind: .userPoolOnly)
        try harness.signIn(work, poolOnly)
        let client = try harness.client(work)
        let noIdentityPool = try harness.client(home, configuration: ClientFixtures.userPoolOnlyConfiguration)
        try harness.store(configuration: ClientFixtures.userPoolOnlyConfiguration)
            .write(poolOnly.record(), for: home, expecting: nil)

        let fromRecord = await credentialsError { try await client.credentialsProvider.resolve() }
        let fromConfiguration = await credentialsError { try await noIdentityPool.credentialsProvider.resolve() }
        let token = try await client.userPoolTokenProvider.accessToken()

        XCTAssertEqual(fromRecord?.isNotConfigured, true, "\(String(describing: fromRecord))")
        XCTAssertEqual(fromRecord?.disposition, .failLoudly)
        XCTAssertEqual(fromConfiguration?.isNotConfigured, true, "\(String(describing: fromConfiguration))")
        XCTAssertEqual(token, poolOnly.accessToken)
    }

    /// - Given: an identity-pool-only configuration
    /// - When: its token provider is asked
    /// - Then:
    ///    - it throws `notConfigured`: there is no user pool to have a token from
    func testIdentityPoolOnlySessionAskedForATokenIsNotConfigured() async throws {
        let client = try harness.client(work, configuration: ClientFixtures.identityPoolOnlyConfiguration)

        let token = await credentialsError { try await client.userPoolTokenProvider.accessToken() }

        XCTAssertEqual(token?.isNotConfigured, true)
    }

    /// A refresh that succeeded on the network but could not be saved must say so, not hand out tokens
    /// that storage does not hold.
    ///
    /// - Given: a session needing a refresh, and a keychain whose writes fail as if locked
    /// - When: credentials are requested
    /// - Then:
    ///    - it throws `storageUnavailable(.locked)`, after one engine refresh, and the stored record is
    ///      unchanged
    func testRefreshWhoseWriteFailsSurfacesTheStorageError() async throws {
        let stale = FakePayload.signedIn("alice", stale: true)
        try harness.signIn(work, stale)
        let client = try harness.client(work)
        harness.keychain.failing(.write, with: errSecInteractionNotAllowed)

        let error = await credentialsError { try await client.credentialsProvider.resolve() }

        XCTAssertEqual(error?.storageUnavailableReason, .locked, "\(String(describing: error))")
        XCTAssertEqual(harness.engine(for: work)?.refreshCalls.count, 1)
        harness.keychain.clearFailures()
        XCTAssertEqual(try harness.storedRecord(work)?.credentials, stale.data)
    }

    /// A federated session is signed in but holds no user pool tokens. `notSignedIn` would tell a
    /// consumer to discard its buffered work for a session that is signed in.
    ///
    /// - Given: a signed-in federated session
    /// - When: both providers are asked
    /// - Then:
    ///    - the AWS credentials are vended; the access token throws `notConfigured` (disposition
    ///      `.failLoudly`), not `notSignedIn`
    func testFederatedSessionAskedForATokenIsNotConfigured() async throws {
        let federated = FakePayload.federated()
        try harness.signIn(work, federated)
        let client = try harness.client(work)

        let credentials = try await client.credentialsProvider.resolve()
        let token = await credentialsError { try await client.userPoolTokenProvider.accessToken() }

        XCTAssertEqual(credentials as? CognitoAWSCredentials, federated.awsCredentials)
        XCTAssertEqual(token?.isNotConfigured, true, "\(String(describing: token))")
        XCTAssertEqual(token?.disposition, .failLoudly)
    }

    /// - Given: a stored session whose storage is locked
    /// - When: both providers are asked
    /// - Then:
    ///    - both throw `storageUnavailable(.locked)` (disposition `.retryWithBackoff`) — never
    ///      `notSignedIn`
    func testUnavailableStorageIsStorageUnavailable() async throws {
        try harness.signIn(work, .signedIn("alice"))
        let client = try harness.client(work)
        harness.keychain.failing(.read, with: errSecInteractionNotAllowed)

        let aws = await credentialsError { try await client.credentialsProvider.resolve() }
        let token = await credentialsError { try await client.userPoolTokenProvider.accessToken() }

        XCTAssertEqual(aws?.storageUnavailableReason, .locked)
        XCTAssertEqual(aws?.disposition, .retryWithBackoff)
        XCTAssertEqual(token?.storageUnavailableReason, .locked)
    }

    /// - Given: a session with a sign-in waiting on the user
    /// - When: both providers are asked
    /// - Then:
    ///    - both throw `notSignedIn`
    func testAwaitingChallengeIsNotSignedIn() async throws {
        let client = try harness.client(work)
        harness.engine(for: work)?.setPendingChallenge(.confirmSignInWithTOTPCode)

        let aws = await credentialsError { try await client.credentialsProvider.resolve() }
        let token = await credentialsError { try await client.userPoolTokenProvider.accessToken() }

        XCTAssertEqual(aws?.isNotSignedIn, true)
        XCTAssertEqual(token?.isNotSignedIn, true)
    }

    // MARK: Refresh

    /// - Given: a signed-in session whose credentials need a refresh, with the refresh held open
    /// - When: ten `resolve()` and ten `accessToken()` calls are made at once, and the refresh is let go
    /// - Then:
    ///    - the engine refreshed exactly once, every caller got the refreshed credentials, and the
    ///      refreshed payload was committed
    func testConcurrentCallersShareOneRefresh() async throws {
        let stale = FakePayload.signedIn("alice", stale: true)
        try harness.signIn(work, stale)
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        // Restored first: a caller that restores while the held flight holds the record's gate would
        // queue on the gate instead of joining the flight.
        _ = await client.currentSessionState()
        let latch = Gate()
        engine.holdRefreshes(on: latch)
        let credentialsProvider = client.credentialsProvider
        let tokenProvider = client.userPoolTokenProvider

        let resolves = (0 ..< 10).map { _ in Task { try await credentialsProvider.resolve() as? CognitoAWSCredentials } }
        let tokens = (0 ..< 10).map { _ in Task { try await tokenProvider.accessToken() } }
        await latch.waitForArrivals(1)
        await waitUntil("every caller waits on the one refresh") { await client.core.refreshFlight.waiterCount == 20 }
        await latch.open()

        for resolve in resolves {
            let credentials = try await resolve.value
            XCTAssertEqual(credentials, stale.refreshed.awsCredentials)
        }
        for token in tokens {
            let value = try await token.value
            XCTAssertEqual(value, stale.refreshed.accessToken)
        }
        XCTAssertEqual(engine.refreshCalls.count, 1)
        XCTAssertEqual(try harness.storedRecord(work)?.credentials, stale.refreshed.data)
    }

    /// Different sessions refresh independently. Asserted by completion, not timing: B's refresh
    /// finishes while A's is still held.
    ///
    /// - Given: two sessions needing a refresh, with A's refresh held open indefinitely
    /// - When: both are asked for credentials
    /// - Then:
    ///    - B's call completes while A's is still waiting
    func testOneSessionsRefreshDoesNotDelayAnother() async throws {
        try harness.signIn(work, .signedIn("alice", stale: true))
        try harness.signIn(home, .signedIn("bob", stale: true))
        let clientA = try harness.client(work)
        let clientB = try harness.client(home)
        let latch = Gate()
        try XCTUnwrap(harness.engine(for: work)).holdRefreshes(on: latch)
        let providerA = clientA.credentialsProvider

        let callA = Task { try await providerA.resolve() as? CognitoAWSCredentials }
        await latch.waitForArrivals(1)
        let credentialsB = try await clientB.credentialsProvider.resolve()

        XCTAssertEqual(credentialsB as? CognitoAWSCredentials, FakePayload.signedIn("bob", stale: true).refreshed.awsCredentials)
        let stillHeld = await latch.arrivalCount
        XCTAssertEqual(stillHeld, 1, "A's refresh was still held when B finished")
        await latch.open()
        _ = try await callA.value
    }

    /// Under refresh-token rotation, abandoning a refresh after Cognito rotated the token but before it
    /// was stored would strand the session, so a caller losing interest never cancels it.
    ///
    /// - Given: a session needing a refresh, with the refresh held open, and one caller waiting on it
    /// - When: the caller is cancelled, and then the refresh is let go
    /// - Then:
    ///    - the caller throws `CancellationError`, unwrapped
    ///    - the refresh still completes and commits, so the next call is served without another refresh
    func testCancelledCallerDoesNotCancelTheRefresh() async throws {
        let stale = FakePayload.signedIn("alice", stale: true)
        try harness.signIn(work, stale)
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let latch = Gate()
        engine.holdRefreshes(on: latch)
        let provider = client.credentialsProvider

        let caller = Task { try await provider.resolve() as? CognitoAWSCredentials }
        await latch.waitForArrivals(1)
        caller.cancel()
        await assertThrowsAsync({ try await caller.value }) { error in
            XCTAssertTrue(error is CancellationError, "\(error)")
        }
        await latch.open()
        await waitUntil("the abandoned refresh commits") {
            (try? harness.storedRecord(work)?.credentials) == stale.refreshed.data
        }

        let credentials = try await provider.resolve()
        XCTAssertEqual(credentials as? CognitoAWSCredentials, stale.refreshed.awsCredentials)
        XCTAssertEqual(engine.refreshCalls.count, 1)
    }

    /// `RefreshTokenReuseException` means another writer already used the token. The session re-reads
    /// and adopts what that writer stored — never signed out.
    ///
    /// - Given: a session needing a refresh, whose refresh fails as reused after another process stored
    ///   freshly refreshed credentials
    /// - When: credentials are requested
    /// - Then:
    ///    - the other process's credentials are returned, no `.sessionExpired` is sent, and the session
    ///      is still signed in
    func testReusedRefreshTokenAdoptsTheReReadRecord() async throws {
        let stale = FakePayload.signedIn("alice", version: 1, stale: true)
        let otherProcess = FakePayload.signedIn("alice", version: 5)
        try harness.signIn(work, stale)
        let client = try harness.client(work)
        let store = harness.store()
        let work = work
        harness.engine(for: work)?.scriptRefresh { _ in
            if case .record(let envelope) = try store.read(work) {
                try store.write(otherProcess.record(), for: work, expecting: envelope.generation)
            }
            throw SessionEngineError.refreshTokenReused
        }
        let events = StreamRecorder(client.listenToAuthEvents())

        let credentials = try await client.credentialsProvider.resolve()

        XCTAssertEqual(credentials as? CognitoAWSCredentials, otherProcess.awsCredentials)
        XCTAssertEqual(events.received, [])
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedIn(AuthClientUser(username: "alice", userId: "sub-alice")))
    }

    /// - Given: a session needing a refresh, whose refresh fails as reused with nothing fresher stored
    /// - When: credentials are requested
    /// - Then:
    ///    - it throws `unknown` (disposition `.retryWithBackoff`) — not `sessionExpired`, not
    ///      `notSignedIn` — and the session is still signed in
    func testReusedRefreshTokenWithNothingFresherIsRetryable() async throws {
        try harness.signIn(work, .signedIn("alice", stale: true))
        let client = try harness.client(work)
        harness.engine(for: work)?.scriptRefresh { _ in throw SessionEngineError.refreshTokenReused }

        let error = await credentialsError { try await client.credentialsProvider.resolve() }

        XCTAssertEqual(error?.isUnknown, true, "\(String(describing: error))")
        XCTAssertEqual(error?.disposition, .retryWithBackoff)
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedIn(AuthClientUser(username: "alice", userId: "sub-alice")))
    }

    /// A reused refresh token, twice in a row with the record's credentials still exactly the ones sent, the second
    /// at least `RefreshTokenReuse.minimumGap` after the first: nobody else refreshed, so the token is dead (a record
    /// rolled forward over a token the plugin rotated away). A repeat sooner than that is another writer that may
    /// still be saving (an extension suspended between Cognito's answer and its keychain write).
    ///
    /// - Given: a session needing a refresh, whose every refresh fails as reused, with nothing stored meanwhile
    /// - When: credentials are requested, again at once, then after the gap, then once more
    /// - Then:
    ///    - the first two throw `unknown` (retryable), with no event
    ///    - the third throws `sessionExpired` and sends one `.sessionExpired` event; the fourth throws
    ///      `sessionExpired` without another refresh
    ///    - the record is kept, and the state stays signed in as the user
    func testASecondReuseWithTheRecordUnchangedExpiresTheSession() async throws {
        let stale = FakePayload.signedIn("alice", stale: true)
        try harness.signIn(work, stale)
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        engine.scriptRefresh { _ in throw SessionEngineError.refreshTokenReused }
        let events = StreamRecorder(client.listenToAuthEvents())

        let first = await credentialsError { try await client.credentialsProvider.resolve() }
        let tooSoon = await credentialsError { try await client.credentialsProvider.resolve() }
        XCTAssertEqual(events.received, [], "no event while another writer may still be saving")
        harness.advanceClock(by: RefreshTokenReuse.minimumGap)
        let third = await credentialsError { try await client.credentialsProvider.resolve() }
        let fourth = await credentialsError { try await client.credentialsProvider.resolve() }

        XCTAssertEqual(first?.isUnknown, true, "\(String(describing: first))")
        XCTAssertEqual(tooSoon?.isUnknown, true, "\(String(describing: tooSoon))")
        XCTAssertEqual(third?.isSessionExpired, true, "\(String(describing: third))")
        XCTAssertEqual(fourth?.isSessionExpired, true, "\(String(describing: fourth))")
        XCTAssertEqual(engine.refreshCalls.count, 3)
        await events.waitFor(1)
        XCTAssertEqual(events.received, [.sessionExpired])
        XCTAssertEqual(try harness.storedRecord(work)?.credentials, stale.data)
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedIn(AuthClientUser(username: "alice", userId: "sub-alice")))
    }

    /// The dead-token count is the record's, for the process: a new client of the same session after the first
    /// reuse still sees it.
    ///
    /// - Given: a session needing a refresh, whose every refresh fails as reused, with nothing stored meanwhile
    /// - When: credentials are requested; the client is released; a new client, past `RefreshTokenReuse.minimumGap`,
    ///   requests them
    /// - Then: the first throws `unknown`; the new client's throws `sessionExpired`
    func testTheReuseCountOutlivesTheClient() async throws {
        let stale = FakePayload.signedIn("alice", stale: true)
        try harness.signIn(work, stale)
        var client: AmplifyCognitoClient? = try harness.client(work)
        harness.engine(for: work)?.scriptRefresh { _ in throw SessionEngineError.refreshTokenReused }

        let first = await credentialsError { try await XCTUnwrap(client).credentialsProvider.resolve() }
        client = nil
        await harness.waitForBaseline()
        harness.advanceClock(by: RefreshTokenReuse.minimumGap)
        let next = try harness.client(work)
        harness.engine(for: work)?.scriptRefresh { _ in throw SessionEngineError.refreshTokenReused }
        let second = await credentialsError { try await next.credentialsProvider.resolve() }

        XCTAssertEqual(first?.isUnknown, true, "\(String(describing: first))")
        XCTAssertEqual(second?.isSessionExpired, true, "\(String(describing: second))")
    }

    /// A second reuse whose re-read record holds other credentials, still stale, is not the same dead token: another
    /// writer stored something while the refresh ran, so it stays retryable.
    ///
    /// - Given: a session needing a refresh, whose refreshes fail as reused; during the second, another process stores
    ///   different credentials that still need a refresh
    /// - When: credentials are requested, then again after `RefreshTokenReuse.minimumGap`
    /// - Then: both throw `unknown`; no event is sent; the session is still signed in; two refreshes, both sending the
    ///   first credentials
    func testAReuseAfterTheRecordChangedIsNotADeadToken() async throws {
        let stale = FakePayload.signedIn("alice", stale: true)
        try harness.signIn(work, stale)
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let store = harness.store()
        let work = work
        let calls = CallCounter()
        engine.scriptRefresh { _ in
            calls.increment()
            if calls.count == 2, case .record(let envelope) = try store.read(work) {
                try store.write(FakePayload.signedIn("alice", version: 2, stale: true).record(), for: work, expecting: envelope.generation)
            }
            throw SessionEngineError.refreshTokenReused
        }
        let events = StreamRecorder(client.listenToAuthEvents())

        let first = await credentialsError { try await client.credentialsProvider.resolve() }
        harness.advanceClock(by: RefreshTokenReuse.minimumGap)
        let second = await credentialsError { try await client.credentialsProvider.resolve() }

        XCTAssertEqual(first?.isUnknown, true, "\(String(describing: first))")
        XCTAssertEqual(second?.isUnknown, true, "\(String(describing: second))")
        XCTAssertEqual(engine.refreshCalls, [stale.data, stale.data])
        try await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertEqual(events.received, [])
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedIn(AuthClientUser(username: "alice", userId: "sub-alice")))
    }

    /// A reuse whose record is unchanged, then one after which another writer saved a refresh: the second is the
    /// concurrent writer's refresh, adopted, never an expired session.
    ///
    /// - Given: a session needing a refresh, whose first refresh fails as reused with nothing stored, and whose
    ///   second fails as reused after another process stored freshly refreshed credentials
    /// - When: credentials are requested twice
    /// - Then:
    ///    - the first throws `unknown`; the second returns the other process's credentials
    ///    - no `.sessionExpired` is sent, and the session is still signed in
    func testAReuseAfterAnUnchangedOneStillAdoptsAConcurrentWriter() async throws {
        let stale = FakePayload.signedIn("alice", version: 1, stale: true)
        let otherProcess = FakePayload.signedIn("alice", version: 5)
        try harness.signIn(work, stale)
        let client = try harness.client(work)
        let store = harness.store()
        let work = work
        let calls = CallCounter()
        harness.engine(for: work)?.scriptRefresh { _ in
            calls.increment()
            if calls.count == 2, case .record(let envelope) = try store.read(work) {
                try store.write(otherProcess.record(), for: work, expecting: envelope.generation)
            }
            throw SessionEngineError.refreshTokenReused
        }
        let events = StreamRecorder(client.listenToAuthEvents())

        let first = await credentialsError { try await client.credentialsProvider.resolve() }
        let credentials = try await client.credentialsProvider.resolve()

        XCTAssertEqual(first?.isUnknown, true, "\(String(describing: first))")
        XCTAssertEqual(credentials as? CognitoAWSCredentials, otherProcess.awsCredentials)
        XCTAssertEqual(events.received, [])
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedIn(AuthClientUser(username: "alice", userId: "sub-alice")))
    }

    /// - Given: a session needing a refresh, whose refresh token turns out to be expired
    /// - When: credentials are requested twice
    /// - Then:
    ///    - the first throws `sessionExpired` (disposition `.retryAfterReauthentication`) and sends one
    ///      `.sessionExpired` event
    ///    - the record is kept, the state stays signed in as the user, so the app knows whom to
    ///      re-authenticate
    ///    - the second call throws `sessionExpired` without another refresh
    func testInvalidRefreshTokenExpiresTheSessionAndKeepsTheRecord() async throws {
        let stale = FakePayload.signedIn("alice", stale: true)
        try harness.signIn(work, stale)
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        engine.scriptRefresh { _ in throw SessionEngineError.refreshTokenInvalid }
        let events = StreamRecorder(client.listenToAuthEvents())

        let first = await credentialsError { try await client.credentialsProvider.resolve() }
        let second = await credentialsError { try await client.userPoolTokenProvider.accessToken() }

        XCTAssertEqual(first?.isSessionExpired, true, "\(String(describing: first))")
        XCTAssertEqual(first?.disposition, .retryAfterReauthentication)
        XCTAssertEqual(second?.isSessionExpired, true)
        XCTAssertEqual(engine.refreshCalls.count, 1)
        await events.waitFor(1)
        XCTAssertEqual(events.received, [.sessionExpired])
        XCTAssertEqual(try harness.storedRecord(work)?.credentials, stale.data)
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedIn(AuthClientUser(username: "alice", userId: "sub-alice")))
    }

    /// With rotation, a refresh racing another process's refresh can be told its token is invalid even
    /// though fresh credentials are already in storage. That is not an expired session.
    ///
    /// - Given: a session needing a refresh, whose refresh fails as invalid after another process stored
    ///   freshly refreshed credentials
    /// - When: credentials are requested
    /// - Then:
    ///    - the other process's credentials are returned, and no `.sessionExpired` is sent
    func testInvalidRefreshTokenAdoptsFreshCredentialsAnotherWriterStored() async throws {
        let stale = FakePayload.signedIn("alice", version: 1, stale: true)
        let otherProcess = FakePayload.signedIn("alice", version: 5)
        try harness.signIn(work, stale)
        let client = try harness.client(work)
        let store = harness.store()
        let work = work
        harness.engine(for: work)?.scriptRefresh { _ in
            if case .record(let envelope) = try store.read(work) {
                try store.write(otherProcess.record(), for: work, expecting: envelope.generation)
            }
            throw SessionEngineError.refreshTokenInvalid
        }
        let events = StreamRecorder(client.listenToAuthEvents())

        let credentials = try await client.credentialsProvider.resolve()

        XCTAssertEqual(credentials as? CognitoAWSCredentials, otherProcess.awsCredentials)
        XCTAssertEqual(events.received, [])
    }

    /// An expired session is not stuck: a fresh sign-in stored by another process, such as an app
    /// extension sharing the access group, is picked up by the next call.
    ///
    /// - Given: a session that a refresh proved expired, and another process that then stores a fresh
    ///   sign-in for it
    /// - When: credentials are requested again
    /// - Then:
    ///    - the new credentials are returned, with no second refresh and no second `.sessionExpired`
    func testExpiredSessionPicksUpASignInStoredByAnotherProcess() async throws {
        try harness.signIn(work, .signedIn("alice", stale: true))
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        engine.scriptRefresh { _ in throw SessionEngineError.refreshTokenInvalid }
        let events = StreamRecorder(client.listenToAuthEvents())
        await assertThrowsAsync { try await client.credentialsProvider.resolve() }
        let extensionSignIn = FakePayload.signedIn("alice", version: 7)
        guard case .record(let envelope) = try harness.store().read(work) else {
            return XCTFail("the expired record was not kept")
        }
        try harness.store().write(extensionSignIn.record(), for: work, expecting: envelope.generation)

        let credentials = try await client.credentialsProvider.resolve()

        XCTAssertEqual(credentials as? CognitoAWSCredentials, extensionSignIn.awsCredentials)
        XCTAssertEqual(engine.refreshCalls.count, 1)
        await events.waitFor(1)
        XCTAssertEqual(events.received, [.sessionExpired])
    }

    /// A lost commit race means the record moved to something newer. Re-read and adopt it; rewriting
    /// would restore a refresh token the server already rotated away.
    ///
    /// - Given: a session needing a refresh, and another process that stores newer credentials while the
    ///   engine is refreshing
    /// - When: credentials are requested
    /// - Then:
    ///    - the session's own refreshed payload is discarded, the other process's record is kept as it
    ///      was, and its credentials are returned
    func testDiscardedRefreshWriteReReadsInsteadOfRewriting() async throws {
        let stale = FakePayload.signedIn("alice", version: 1, stale: true)
        let otherProcess = FakePayload.signedIn("alice", version: 9)
        try harness.signIn(work, stale)
        let client = try harness.client(work)
        let store = harness.store()
        let work = work
        harness.engine(for: work)?.scriptRefresh { payload in
            if case .record(let envelope) = try store.read(work) {
                try store.write(otherProcess.record(), for: work, expecting: envelope.generation)
            }
            return try XCTUnwrap(FakePayload.decode(payload)).refreshed.data
        }

        let credentials = try await client.credentialsProvider.resolve()

        XCTAssertEqual(credentials as? CognitoAWSCredentials, otherProcess.awsCredentials)
        XCTAssertEqual(try harness.storedRecord(work), otherProcess.record())
    }

    /// A lost commit race where only metadata moved must not throw away the refreshed tokens: with
    /// rotation, the server has already retired the old refresh token.
    ///
    /// - Given: a session needing a refresh, and another process that changes only the record's label
    ///   while the engine is refreshing
    /// - When: credentials are requested
    /// - Then:
    ///    - the refreshed credentials are returned, not the stale ones
    ///    - the stored record holds the refreshed credentials and keeps the other process's label
    func testRefreshThatLosesToALabelOnlyChangeKeepsTheRefreshedTokens() async throws {
        let stale = FakePayload.signedIn("alice", version: 1, stale: true)
        try harness.signIn(work, stale)
        let client = try harness.client(work)
        let store = harness.store()
        let work = work
        harness.engine(for: work)?.scriptRefresh { payload in
            if case .record(let envelope) = try store.read(work) {
                var relabelled = envelope.record
                relabelled.label = "Set elsewhere"
                try store.write(relabelled, for: work, expecting: envelope.generation)
            }
            return try XCTUnwrap(FakePayload.decode(payload)).refreshed.data
        }

        let credentials = try await client.credentialsProvider.resolve()

        XCTAssertEqual(credentials as? CognitoAWSCredentials, stale.refreshed.awsCredentials)
        XCTAssertEqual(try harness.storedRecord(work), stale.refreshed.record(label: "Set elsewhere"))
        XCTAssertEqual(harness.engine(for: work)?.refreshCalls.count, 1)
    }

    /// - Given: a read-through `.default` session needing a refresh
    /// - When: credentials are requested
    /// - Then:
    ///    - the refreshed payload is committed to `.default`'s own record, and the plugin's record is left
    ///      as it was
    func testRefreshOfAReadThroughSessionWritesItsOwnRecord() async throws {
        let stale = FakePayload.signedIn("alice", stale: true)
        let pluginAccount = SessionRecordKey.legacySessionAccount(in: StorageFixtures.pools)
        harness.keychain.put(stale.data, pluginAccount)
        let client = try harness.client(.default)

        let credentials = try await client.credentialsProvider.resolve()

        XCTAssertEqual(credentials as? CognitoAWSCredentials, stale.refreshed.awsCredentials)
        XCTAssertEqual(try harness.storedRecord(.default), stale.refreshed.record())
        XCTAssertEqual(harness.keychain.value(pluginAccount), stale.data)
    }

    // MARK: Lifetime

    /// A provider keeps its session alive, exactly as a handle does.
    ///
    /// - Given: a provider taken from a client, and a weak reference to the session
    /// - When: the client is dropped, a new client is built for the session, and then everything is
    ///   dropped
    /// - Then:
    ///    - the provider alone keeps the session alive, and the new client joins it
    ///    - once the provider goes too, the session is released
    func testProviderOutlivingEveryHandleKeepsTheSessionAlive() async throws {
        try harness.signIn(work, .signedIn("alice"))
        var client: AmplifyCognitoClient? = try harness.client(work)
        var provider: CognitoCredentialsProvider? = client?.credentialsProvider
        weak let probe = client?.core

        client = nil
        XCTAssertNotNil(probe, "the provider holds the session")
        var rejoined: AmplifyCognitoClient? = try harness.client(work)
        XCTAssertTrue(rejoined?.core === provider?.core)
        XCTAssertEqual(harness.engines.count, 1)
        _ = try await provider?.resolve()

        rejoined = nil
        provider = nil
        _ = (client, rejoined, provider)
        await waitUntil("the session is released") { probe == nil }
    }

    // MARK: Error mapping

    /// - Given: each `AuthClientError` case and a foreign error
    /// - When: each is mapped onto the provider contract
    /// - Then:
    ///    - `notSignedIn`, `sessionExpired` and `storageUnavailable` keep their meaning and dispositions;
    ///      a `CredentialsError` passes through; everything else is `unknown`, which retries
    func testErrorMappingAndDispositions() {
        let cases: [(Error, CredentialsError.Disposition)] = [
            (AuthClientError.notSignedIn("d", "s"), .discard),
            (AuthClientError.sessionExpired("d", "s"), .retryAfterReauthentication),
            (AuthClientError.storageUnavailable(.locked, "d", "s"), .retryWithBackoff),
            (AuthClientError.storageUnavailable(.interrupted, "d", "s"), .retryWithBackoff),
            (AuthClientError.storageUnavailable(.denied, "d", "s"), .failLoudly),
            (CredentialsError.notConfigured("d", "s"), .failLoudly),
            (AuthClientError.configuration("d", "s"), .retryWithBackoff),
            (AuthClientError.unknown("d", "s"), .retryWithBackoff),
            (FixtureError(description: "foreign"), .retryWithBackoff)
        ]
        for (error, disposition) in cases {
            XCTAssertEqual(CredentialsError(authClientError: error).disposition, disposition, "\(error)")
        }
        let mapped = CredentialsError(authClientError: AuthClientError.storageUnavailable(.denied, "d", "s"))
        XCTAssertEqual(mapped.storageUnavailableReason, .denied)
        XCTAssertTrue(mapped.underlyingError is AuthClientError)
    }
}
