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

/// Carrying a session forward across a pool configuration change, through the client and its core: the restore
/// carries it with no network call and keeps the old record; the identity is fetched on first use, and its
/// failures reported and retried as they should be; the stored-session statics and the restore take each other's
/// gates, and refuse a session live under another configuration.
final class SessionCopyForwardTests: XCTestCase {

    private var harness: ClientHarness!
    private let work = ClientFixtures.id("work")
    private let alice = AuthClientUser(username: "alice", userId: "sub-alice")

    override func setUp() {
        harness = ClientHarness()
    }

    override func tearDown() async throws {
        harness.keychain.clearFailures()
        await harness.waitForBaseline()
        harness = nil
    }

    private var userPoolOnlyStore: SessionRecordStore {
        harness.store(configuration: ClientFixtures.userPoolOnlyConfiguration)
    }

    private var identityPoolOnlyStore: SessionRecordStore {
        harness.store(configuration: ClientFixtures.identityPoolOnlyConfiguration)
    }

    private var userPoolOnlyNamespace: SessionStorageNamespace {
        SessionStorageNamespace(pools: ClientFixtures.userPoolOnlyConfiguration.poolNamespace, accessGroup: nil)
    }

    /// alice signed in under the user pool alone, as this app configured without an identity pool left her: the
    /// record, whose creation writes the session's marker naming that namespace. Returns its bytes.
    @discardableResult
    private func aliceUnderTheUserPoolOnly() throws -> Data? {
        try userPoolOnlyStore.write(FakePayload.signedIn("alice", kind: .userPoolOnly).record(label: "Work"), for: work, expecting: nil)
        harness.keychain.resetLogs()
        return harness.keychain.value(userPoolOnlyStore.sessionAccount(for: work))
    }

    private func currentRecord(file: StaticString = #filePath, line: UInt = #line) throws -> SessionRecord? {
        guard case .record(let envelope) = try harness.store().read(work) else {
            XCTFail("no record", file: file, line: line)
            return nil
        }
        return envelope.record
    }

    /// Asserts `result` failed with an error described as `expected` is.
    private func assertFails<Value>(
        _ result: Result<Value, AuthClientError>,
        with expected: AuthClientError,
        _ message: String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard case .failure(let error) = result else {
            return XCTFail("expected a failure. \(message)", file: file, line: line)
        }
        XCTAssertEqual(error.errorDescription, expected.errorDescription, message, file: file, line: line)
    }

    /// The description of the error `body` throws, or `nil` if it throws none.
    private func authClientErrorDescription(_ body: () async throws -> some Any) async -> String? {
        do {
            _ = try await body()
            return nil
        } catch let error as CredentialsError {
            return error.errorDescription
        } catch let error as AuthClientError {
            return error.errorDescription
        } catch {
            return "\(error)"
        }
    }

    /// A refresh that stores new user pool tokens, then fails the identity step with `error`.
    private func scriptIdentityFailure(_ engine: FakeSessionEngine, _ error: AuthClientError) {
        let stored = FakePayload.signedIn("alice", kind: .userPoolOnly, version: 2)
        engine.scriptRefresh { _ in
            throw SessionEngineError.refreshedThenFailed(payload: stored.data, error: .service(error))
        }
    }

    // MARK: The carry

    /// CS-2.
    ///
    /// - Given: alice signed in under the user pool alone
    /// - When: a client over the user pool and an identity pool reads the session's state
    /// - Then:
    ///    - it is `.signedIn(alice)`, with no engine call: nothing is refreshed at restore
    ///    - the session's record is carried, labelled, with `identityPending`, and the old one is kept
    func testRestoreCarriesTheUserPoolSessionWithNoNetworkCall() async throws {
        let old = try aliceUnderTheUserPoolOnly()
        let client = try harness.client(work)

        let state = await client.currentSessionState()

        XCTAssertEqual(state, .signedIn(alice))
        XCTAssertEqual(harness.engine(for: work)?.refreshCalls.count, 0)
        let record = try XCTUnwrap(currentRecord())
        XCTAssertTrue(record.identityPending)
        XCTAssertEqual(record.label, "Work")
        XCTAssertEqual(harness.keychain.value(userPoolOnlyStore.sessionAccount(for: work)), old, "the old record is kept")
    }

    /// - Given: alice's session carried from the user pool alone, and a refresh that returns her tokens with an
    ///   identity and AWS credentials
    /// - When: the session is fetched, then fetched again
    /// - Then: the first fetch refreshes once (unforced) and reports an identity and credentials; the record no
    ///   longer waits; the second fetch refreshes nothing
    func testTheIdentityIsFetchedOnFirstUse() async throws {
        try aliceUnderTheUserPoolOnly()
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        engine.scriptRefresh { _ in FakePayload.signedIn("alice", version: 2, identityId: "us-east-1:new").data }

        let first = try await client.fetchAuthSession()
        let second = try await client.fetchAuthSession()

        XCTAssertEqual(try first.identityIdResult.get(), "us-east-1:new")
        XCTAssertNoThrow(try first.awsCredentialsResult.get())
        XCTAssertEqual(engine.refreshForceFlags, [false])
        XCTAssertEqual(try second.identityIdResult.get(), "us-east-1:new")
        let record = try XCTUnwrap(currentRecord())
        XCTAssertFalse(record.identityPending)
        XCTAssertEqual(record.kind, .userPoolAndIdentityPool)
    }

    /// - Given: alice's session carried from the user pool alone, and a refresh that adds an identity
    /// - When: the credentials provider resolves
    /// - Then: it vends the refreshed AWS credentials (not `notConfigured`), after one refresh
    func testTheCredentialsProviderFetchesThePendingIdentity() async throws {
        try aliceUnderTheUserPoolOnly()
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let refreshed = FakePayload.signedIn("alice", version: 2, identityId: "us-east-1:new")
        engine.scriptRefresh { _ in refreshed.data }

        let credentials = try await client.credentialsProvider.resolve()

        XCTAssertEqual(credentials.accessKeyId, refreshed.awsCredentials.accessKeyId)
        XCTAssertEqual(engine.refreshCalls.count, 1)
    }

    /// - Given: alice's session carried from the user pool alone
    /// - When: the user pool token provider is asked for an access token
    /// - Then: it vends her token with no refresh, and the record still waits for its identity
    func testAnAccessTokenDoesNotWaitForThePendingIdentity() async throws {
        try aliceUnderTheUserPoolOnly()
        let client = try harness.client(work)

        let token = try await client.userPoolTokenProvider.accessToken()

        XCTAssertEqual(token, FakePayload.signedIn("alice", kind: .userPoolOnly).accessToken)
        XCTAssertEqual(harness.engine(for: work)?.refreshCalls.count, 0)
        XCTAssertTrue(try XCTUnwrap(currentRecord()).identityPending)
    }

    /// An access token on a carried session whose tokens expired is the refreshed one, even when the identity step
    /// after the refresh fails.
    ///
    /// - Given: alice's session carried from the user pool alone with expired tokens, and a refresh that stores new
    ///   tokens then fails the identity step
    /// - When: the user pool token provider is asked for an access token
    /// - Then: it vends the refreshed token
    func testAnAccessTokenOfAnExpiredCarriedSessionIsTheRefreshedOne() async throws {
        var expired = FakePayload.signedIn("alice", kind: .userPoolOnly)
        expired.stale = true
        expired.tokensStale = true
        try userPoolOnlyStore.write(expired.record(), for: work, expecting: nil)
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        scriptIdentityFailure(engine, .service(.network, "The network connection was lost.", "Retry."))

        let token = try await client.userPoolTokenProvider.accessToken()

        XCTAssertEqual(token, "access-alice-v2")
    }

    /// A successful refresh that brings no identity stops the record waiting for one: the engine's refresh fetches
    /// the identity whenever an identity pool is configured, so a user-pool-only result is final.
    ///
    /// - Given: alice's session carried from the user pool alone, and a refresh that returns user pool tokens only
    /// - When: the session is fetched
    /// - Then: its tokens and sub succeed, its identity fails, and the record no longer waits
    func testASuccessfulRefreshWithoutAnIdentityStopsWaiting() async throws {
        try aliceUnderTheUserPoolOnly()
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        engine.scriptRefresh { _ in FakePayload.signedIn("alice", kind: .userPoolOnly, version: 2).data }

        let session = try await client.fetchAuthSession()

        XCTAssertThrowsError(try session.identityIdResult.get())
        XCTAssertEqual(try session.userPoolTokensResult.get().accessToken, "access-alice-v2")
        XCTAssertEqual(try session.userSubResult.get(), "sub-alice")
        XCTAssertFalse(try XCTUnwrap(currentRecord()).identityPending)
    }

    // MARK: Identity-step failures

    /// An identity step refused for good fails only the identity, and is not retried in this process, by this core
    /// or a later one of the same record; the record keeps waiting, so a new process tries again, as the plugin
    /// retries on every launch.
    ///
    /// - Given: alice's session carried from the user pool alone, and a refresh that stores new tokens then fails
    ///   the identity step with `.notAuthorized` (an identity pool that does not federate the user pool)
    /// - When: the session is fetched twice, the credentials provider resolves, the clock passes the retry interval
    ///   and the session is fetched again; then the client is released and a new one, on a new core in the same
    ///   process, fetches it
    /// - Then:
    ///    - every fetch returns the tokens and sub, and fails the identity and credentials with the refusal, as does
    ///      the provider; only the first refreshes; the record still waits for its identity
    ///    - the new core does not refresh either, and reports the refusal
    func testAPermanentIdentityFailureIsNotRetriedInThisProcess() async throws {
        try aliceUnderTheUserPoolOnly()
        let refusal = AuthClientError.notAuthorized("Invalid login token.", "Check the identity pool's providers.")
        var client: AmplifyCognitoClient? = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        scriptIdentityFailure(engine, refusal)

        let first = try await XCTUnwrap(client).fetchAuthSession()
        let second = try await XCTUnwrap(client).fetchAuthSession()
        let provider = await authClientErrorDescription { try await XCTUnwrap(client).credentialsProvider.resolve() }
        harness.advanceClock(by: PendingIdentityRetry.interval + 1)
        let later = try await XCTUnwrap(client).fetchAuthSession()

        for session in [first, second, later] {
            XCTAssertEqual(try session.userPoolTokensResult.get().accessToken, "access-alice-v2")
            XCTAssertEqual(try session.userSubResult.get(), "sub-alice")
            assertFails(session.identityIdResult, with: refusal)
            assertFails(session.awsCredentialsResult, with: refusal)
        }
        XCTAssertEqual(provider, refusal.errorDescription)
        XCTAssertEqual(engine.refreshCalls.count, 1, "no user pool refresh on every call")
        XCTAssertTrue(try XCTUnwrap(currentRecord()).identityPending, "the record keeps waiting")

        client = nil
        await harness.waitForBaseline()
        let relaunched = try harness.client(work)
        let next = try XCTUnwrap(harness.engine(for: work))
        XCTAssertFalse(next === engine, "a new core")
        next.scriptRefresh { _ in FakePayload.signedIn("alice", version: 3, identityId: "us-east-1:new").data }
        let fetched = try await relaunched.fetchAuthSession()
        XCTAssertEqual(next.refreshCalls.count, 0, "the refusal holds for the process")
        assertFails(fetched.identityIdResult, with: refusal)
        XCTAssertEqual(try fetched.userSubResult.get(), "sub-alice")
    }

    /// A transient identity failure keeps the record waiting, but the next attempt waits its interval, so a
    /// throttled `GetId` does not spend a refresh token per call; until then the failure answers for the identity.
    ///
    /// - Given: alice's session carried from the user pool alone, and a refresh that stores new tokens then fails
    ///   the identity step, in turn with throttling, `.unknown`, a service error with no code, and an engine failure
    ///   that is not an `AuthClientError`
    /// - When: the session is fetched, fetched again at once, the credentials provider resolves, then the session is
    ///   fetched after `PendingIdentityRetry.interval`
    /// - Then:
    ///    - the first fetch and the last refresh; the second fetch and the provider do not
    ///    - the second fetch returns the tokens and fails its identity and credentials with the first fetch's
    ///      error, and so does the provider (not "no identity pool", not "sign in again")
    ///    - the record keeps waiting throughout
    func testATransientIdentityFailureIsRetriedAfterItsInterval() async throws {
        let failures: [(String, SessionEngineError)] = [
            ("throttling", .service(.service(.limitExceeded, "Rate exceeded.", "Retry."))),
            ("unknown", .service(.unknown("Something failed.", "Retry."))),
            ("no code", .service(.service(nil, "InternalErrorException", "Retry."))),
            ("not an AuthClientError", .refreshedThenFailed(payload: Data(), error: .notSignedIn))
        ]
        for (name, failure) in failures {
            harness = ClientHarness()
            try aliceUnderTheUserPoolOnly()
            let client = try harness.client(work)
            let engine = try XCTUnwrap(harness.engine(for: work))
            let stored = FakePayload.signedIn("alice", kind: .userPoolOnly, version: 2)
            engine.scriptRefresh { _ in throw SessionEngineError.refreshedThenFailed(payload: stored.data, error: failure) }

            let first = try await client.fetchAuthSession()
            let second = try await client.fetchAuthSession()
            let provider = await authClientErrorDescription { try await client.credentialsProvider.resolve() }
            XCTAssertEqual(engine.refreshCalls.count, 1, "\(name): no retry within the interval")
            XCTAssertTrue(try XCTUnwrap(currentRecord()).identityPending, name)
            harness.advanceClock(by: PendingIdentityRetry.interval + 1)
            _ = try await client.fetchAuthSession()

            XCTAssertEqual(engine.refreshCalls.count, 2, name)
            guard case .failure(let error) = first.identityIdResult else {
                XCTFail("\(name): the identity should fail")
                continue
            }
            XCTAssertEqual(try first.userPoolTokensResult.get().accessToken, "access-alice-v2", name)
            XCTAssertEqual(try second.userPoolTokensResult.get().accessToken, "access-alice-v2", name)
            assertFails(second.identityIdResult, with: error, name)
            assertFails(second.awsCredentialsResult, with: error, name)
            XCTAssertEqual(provider, error.errorDescription, name)
            XCTAssertTrue(try XCTUnwrap(currentRecord()).identityPending, name)
        }
    }

    /// A cancelled identity step starts no back-off: the next call tries again.
    ///
    /// - Given: alice's session carried from the user pool alone, and a refresh that stores new tokens then fails
    ///   the identity step with an error caused by a cancellation (as the engine reports a cancelled `GetId`), then
    ///   one that succeeds with an identity
    /// - When: the session is fetched twice, at once
    /// - Then: the first throws `CancellationError`; the second refreshes again, and has an identity
    func testACancelledIdentityStepStartsNoBackOff() async throws {
        try aliceUnderTheUserPoolOnly()
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let stored = FakePayload.signedIn("alice", kind: .userPoolOnly, version: 2)
        let calls = CallCounter()
        engine.scriptRefresh { _ in
            calls.increment()
            if calls.count == 1 {
                throw SessionEngineError.refreshedThenFailed(
                    payload: stored.data,
                    error: .service(.unknown("The request was cancelled.", "Retry.", CancellationError()))
                )
            }
            return FakePayload.signedIn("alice", version: 3, identityId: "us-east-1:new").data
        }

        do {
            _ = try await client.fetchAuthSession()
            XCTFail("expected a cancellation")
        } catch {
            XCTAssertTrue(error is CancellationError, "\(error)")
        }
        let second = try await client.fetchAuthSession()

        XCTAssertEqual(engine.refreshCalls.count, 2)
        XCTAssertEqual(try second.identityIdResult.get(), "us-east-1:new")
    }

    /// - Given: a bare `CancellationError`, an `AuthClientError` caused by one, and two other failures
    /// - When: `isCancellation` classifies each
    /// - Then: the first two are cancellations, the others not
    func testWhichFailuresAreCancellations() {
        XCTAssertTrue(SessionCore.isCancellation(CancellationError()))
        XCTAssertTrue(SessionCore.isCancellation(AuthClientError.unknown("", "", CancellationError())))
        XCTAssertFalse(SessionCore.isCancellation(AuthClientError.unknown("", "")))
        XCTAssertFalse(SessionCore.isCancellation(FixtureError(description: "not a cancellation")))
    }

    /// A refresh whose identity step failed, but whose commit lost to another writer that stored a complete record
    /// (its identity fetched), answers with that record.
    ///
    /// - Given: alice's session carried from the user pool alone, and a refresh during which another process stores
    ///   alice with an identity, then which stores new tokens and fails the identity step
    /// - When: the session is fetched
    /// - Then: it has the other writer's identity, and the record no longer waits
    func testAnIdentityFailureAdoptsAnotherWritersCompleteRecord() async throws {
        try aliceUnderTheUserPoolOnly()
        let client = try harness.client(work)
        _ = await client.currentSessionState()
        let engine = try XCTUnwrap(harness.engine(for: work))
        let store = harness.store()
        let work = work
        let stored = FakePayload.signedIn("alice", kind: .userPoolOnly, version: 2)
        engine.scriptRefresh { _ in
            if case .record(let envelope) = try store.read(work) {
                _ = try store.write(
                    FakePayload.signedIn("alice", version: 3, identityId: "us-east-1:other-writer").record(label: "Work"),
                    for: work,
                    expecting: envelope.generation
                )
            }
            throw SessionEngineError.refreshedThenFailed(payload: stored.data, error: .service(.service(.limitExceeded, "", "")))
        }

        let session = try await client.fetchAuthSession()

        XCTAssertEqual(try session.identityIdResult.get(), "us-east-1:other-writer")
        XCTAssertFalse(try XCTUnwrap(currentRecord()).identityPending)
    }

    /// A refresh whose refresh token is refused reports the session expired in every field, as the plugin does;
    /// only an identity-step failure keeps the tokens.
    ///
    /// - Given: alice's session carried from the user pool alone, and a refresh refusing the refresh token
    /// - When: the session is fetched
    /// - Then: every field fails with `sessionExpired`
    func testARefusedRefreshTokenExpiresEveryField() async throws {
        try aliceUnderTheUserPoolOnly()
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        engine.scriptRefresh { _ in throw SessionEngineError.refreshTokenInvalid }

        let session = try await client.fetchAuthSession()

        for result in [session.userPoolTokensResult.map { _ in () }, session.userSubResult.map { _ in () },
                       session.identityIdResult.map { _ in () }, session.awsCredentialsResult.map { _ in () }] {
            guard case .failure(let error) = result else {
                XCTFail("every field should fail")
                continue
            }
            XCTAssertEqual(error.kind, .sessionExpired)
        }
    }

    /// An identity-step failure whose stored tokens need a refresh after all reports the session expired.
    ///
    /// - Given: alice's session carried from the user pool alone, and a refresh that stores still-expired tokens
    ///   then fails the identity step
    /// - When: the session is fetched
    /// - Then: every field fails with `sessionExpired`: the partial result is only for tokens that need no refresh
    func testAnIdentityFailureWithTokensThatNeedARefreshExpiresEveryField() async throws {
        try aliceUnderTheUserPoolOnly()
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        var staleTokens = FakePayload.signedIn("alice", kind: .userPoolOnly, version: 2)
        staleTokens.tokensStale = true
        let stored = staleTokens.data
        engine.scriptRefresh { _ in
            throw SessionEngineError.refreshedThenFailed(
                payload: stored,
                error: .service(.notAuthorized("Invalid login token.", "Check the identity pool's providers."))
            )
        }

        let session = try await client.fetchAuthSession()

        guard case .failure(let error) = session.userPoolTokensResult else {
            return XCTFail("the tokens need a refresh: expired")
        }
        XCTAssertEqual(error.kind, .sessionExpired)
        XCTAssertThrowsError(try session.identityIdResult.get())
    }

    /// Which identity-step failures are transient: only the known refusals are permanent.
    ///
    /// - Given: each kind of failure, every `AuthClientError` case among them
    /// - When: `isTransient` classifies it
    /// - Then: `.notAuthorized`, `.invalidParameter`, `.resourceNotFound` and `.configuration` are permanent; a 5xx,
    ///   a service error with no code, `.unknown`, the network, the three limit-exceeded codes, storage, a
    ///   cancellation, an error that is not an `AuthClientError`, and every other `AuthClientError` case are
    ///   transient
    func testWhichIdentityFailuresAreTransient() {
        let permanent: [Error] = [
            AuthClientError.notAuthorized("", ""),
            AuthClientError.service(.invalidParameter, "", ""),
            AuthClientError.service(.resourceNotFound, "", ""),
            AuthClientError.configuration("", "")
        ]
        let transient: [Error] = [
            AuthClientError.service(nil, "InternalErrorException", ""),
            AuthClientError.service(.externalServiceException, "", ""),
            AuthClientError.unknown("", ""),
            AuthClientError.service(.network, "", ""),
            AuthClientError.service(.limitExceeded, "", ""),
            AuthClientError.service(.requestLimitExceeded, "", ""),
            AuthClientError.service(.limitExceededException, "", ""),
            AuthClientError.storageUnavailable(.locked, "", ""),
            CancellationError(),
            FixtureError(description: "not an AuthClientError"),
            AuthClientError.sessionExpired("", ""),
            AuthClientError.notSignedIn("", ""),
            AuthClientError.invalidSessionID("", ""),
            AuthClientError.challengeExpired("", ""),
            AuthClientError.browserBusy(holder: .default, "", ""),
            AuthClientError.sessionConfigurationMismatch(.default, "", ""),
            AuthClientError.validation(field: "username", "", ""),
            AuthClientError.invalidState("", ""),
            AuthClientError.userCancelled("", ""),
            AuthClientError.webAuthnCeremonyFailed(.failed, "", ""),
            AuthClientError.unexpectedIdentity(expected: nil, returned: AuthClientUser(username: "alice", userId: "sub-alice"), "", "")
        ]
        for error in permanent {
            XCTAssertFalse(SessionCore.isTransient(error), "\(error)")
        }
        for error in transient {
            XCTAssertTrue(SessionCore.isTransient(error), "\(error)")
        }
    }

    /// - Given: alice's session carried from the user pool alone, and a forced refresh that adds an identity
    /// - When: the session is fetched with `forceRefresh`
    /// - Then: one forced refresh, an identity, and the record no longer waits
    func testAForcedRefreshOfAPendingRecordFetchesTheIdentity() async throws {
        try aliceUnderTheUserPoolOnly()
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        engine.scriptRefresh { _ in FakePayload.signedIn("alice", version: 2, identityId: "us-east-1:new").data }

        let session = try await client.fetchAuthSession(options: .init(forceRefresh: true))

        XCTAssertEqual(engine.refreshForceFlags, [true])
        XCTAssertEqual(try session.identityIdResult.get(), "us-east-1:new")
        let record = try XCTUnwrap(currentRecord())
        XCTAssertFalse(record.identityPending)
        XCTAssertEqual(record.kind, .userPoolAndIdentityPool)
    }

    /// - Given: alice's session carried from the user pool alone, and a refresh that finds another process has
    ///   meanwhile refreshed the record and fetched its identity (`refreshTokenReused`)
    /// - When: the session is fetched
    /// - Then: it adopts the other writer's record: an identity, and no longer waiting
    func testRefreshTokenReusedAdoptsAnotherWritersIdentity() async throws {
        try aliceUnderTheUserPoolOnly()
        let client = try harness.client(work)
        _ = await client.currentSessionState()
        let engine = try XCTUnwrap(harness.engine(for: work))
        let store = harness.store()
        let work = work
        engine.scriptRefresh { _ in
            if case .record(let envelope) = try store.read(work) {
                _ = try store.write(
                    FakePayload.signedIn("alice", version: 3, identityId: "us-east-1:other-writer").record(label: "Work"),
                    for: work,
                    expecting: envelope.generation
                )
            }
            throw SessionEngineError.refreshTokenReused
        }

        let session = try await client.fetchAuthSession()

        XCTAssertEqual(try session.identityIdResult.get(), "us-east-1:other-writer")
        XCTAssertFalse(try XCTUnwrap(currentRecord()).identityPending)
    }

    // MARK: Guests, failures

    /// CS-1.
    ///
    /// - Given: a guest session under the identity pool alone
    /// - When: a client over the user pool and that identity pool fetches the session
    /// - Then: it is `.guest` with the same identity and access key, and nothing was fetched
    func testRestoreCarriesTheGuestAsItIs() async throws {
        let guest = FakePayload.guest(identityId: "us-east-1:guest-1")
        try identityPoolOnlyStore.write(guest.record(), for: work, expecting: nil)
        let client = try harness.client(work)

        let session = try await client.fetchAuthSession()

        let state = await client.currentSessionState()
        XCTAssertEqual(state, .guest)
        XCTAssertEqual(try session.identityIdResult.get(), "us-east-1:guest-1")
        XCTAssertEqual(try session.awsCredentialsResult.get().accessKeyId, guest.awsCredentials.accessKeyId)
        XCTAssertEqual(harness.engine(for: work)?.guestFetchCount, 0)
        XCTAssertEqual(harness.engine(for: work)?.refreshCalls.count, 0)
    }

    /// - Given: alice under the user pool alone, and reads of that record failing
    /// - When: a client over both pools reads its state, then storage recovers and it reads again
    /// - Then: first `.unavailable(.locked)`, never signed out; then `.signedIn(alice)`
    func testAFailedReadIsUnavailableThenCarries() async throws {
        try aliceUnderTheUserPoolOnly()
        harness.keychain.failingReads(of: userPoolOnlyStore.sessionAccount(for: work), with: errSecInteractionNotAllowed)
        let client = try harness.client(work)

        let failed = await client.currentSessionState()
        harness.keychain.clearFailures()
        let recovered = await client.currentSessionState()

        XCTAssertEqual(failed, .unavailable(.locked))
        XCTAssertEqual(recovered, .signedIn(alice))
    }

    // MARK: Stored-session calls

    /// - Given: alice under the user pool alone, and no live client
    /// - When: `signOutStoredSession` runs over both pools, then a client reads the session
    /// - Then: the carried tokens are revoked, `.complete`; the row is kept signed out under both pools; the kept
    ///   copy was untouched, so it is swept; the client reads `.signedOut`
    func testSignOutStoredSessionBeforeARestoreNeverResurrectsIt() async throws {
        try aliceUnderTheUserPoolOnly()

        let result = try await AmplifyCognitoClient.signOutStoredSession(
            sessionId: work,
            configuration: ClientFixtures.configuration,
            accessGroup: nil,
            dependencies: harness.dependencies
        )

        XCTAssertEqual(result, .complete)
        XCTAssertEqual(harness.revoker.revokeCalls.compactMap { FakePayload.decode($0)?.username }, ["alice"])
        XCTAssertTrue(try XCTUnwrap(currentRecord()).isSignedOut)
        XCTAssertEqual(try userPoolOnlyStore.read(work), .absent)
        let state = await (try harness.client(work)).currentSessionState()
        XCTAssertEqual(state, .signedOut)
    }

    /// Purge deletes only what this app copied: a record it never carried from stays, and nothing is carried later.
    ///
    /// - Given: alice under the user pool alone (the marker naming it), and no live client
    /// - When: `purgeStoredSession` runs over both pools, then a client over both pools reads the session
    /// - Then: the user-pool record is kept (never carried, so not this purge's), the marker is gone, and the client
    ///   reads `.signedOut`
    func testPurgeBeforeARestoreForgetsTheSession() async throws {
        try aliceUnderTheUserPoolOnly()

        try await AmplifyCognitoClient.purgeStoredSession(
            sessionId: work,
            configuration: ClientFixtures.configuration,
            accessGroup: nil,
            dependencies: harness.dependencies
        )

        XCTAssertNotEqual(try userPoolOnlyStore.read(work), .absent)
        XCTAssertNil(try harness.store().marker(for: work))
        let state = await (try harness.client(work)).currentSessionState()
        XCTAssertEqual(state, .signedOut)
    }

    /// Race: a purge and a restore that carries, of the same session at once. They share the record's gate, so
    /// whichever goes first, the session ends purged here and nothing is carried back.
    ///
    /// - Given: alice under the user pool alone, and a client over both pools
    /// - When: its state is read while `purgeStoredSession` runs over both pools, concurrently, many times over
    ///   (each bounded)
    /// - Then: afterwards the session reads `.signedOut`, and holds no record under both pools
    func testAConcurrentPurgeAndRestoreNeverResurrect() async throws {
        for _ in 1 ... 20 {
            harness = ClientHarness()
            try aliceUnderTheUserPoolOnly()
            let client = try harness.client(work)
            let dependencies = harness.dependencies
            let work = work

            async let state = client.currentSessionState()
            async let purge: Void = bounded(10, "the purge") {
                try await AmplifyCognitoClient.purgeStoredSession(
                    sessionId: work,
                    configuration: ClientFixtures.configuration,
                    accessGroup: nil,
                    dependencies: dependencies
                )
            }
            _ = await state
            try await purge

            let after = await client.currentSessionState()
            XCTAssertEqual(after, .signedOut)
            XCTAssertEqual(try harness.store().read(work), .absent)
        }
    }

    /// Race, the other interleaving: a warm restore that carries, constructed while a stored-session call over the
    /// old configuration runs. The call either finds the session live elsewhere and refuses, or ran first.
    ///
    /// - Given: alice under the user pool alone
    /// - When: a client over both pools is built with a warm restore, while `purgeStoredSession` runs over the user
    ///   pool alone
    /// - Then: the purge either refuses with `sessionConfigurationMismatch` (the session was live under both pools)
    ///   or succeeds, and in both cases the session never ends signed in with a purged source it did not copy
    func testAStoredSessionCallRacingAWarmRestore() async throws {
        for _ in 1 ... 20 {
            harness = ClientHarness(restoresOnConstruction: true)
            try aliceUnderTheUserPoolOnly()
            let dependencies = harness.dependencies
            let work = work

            async let purge: Result<Void, Error> = Result(catching: {
                try await bounded(10, "the purge") {
                    try await AmplifyCognitoClient.purgeStoredSession(
                        sessionId: work,
                        configuration: ClientFixtures.userPoolOnlyConfiguration,
                        accessGroup: nil,
                        dependencies: dependencies
                    )
                }
            })
            let client = try harness.client(work)
            let state = await client.currentSessionState()
            let outcome = await purge

            switch outcome {
            case .success:
                // The purge ran before the restore carried (and the restore then found nothing), or after: then the
                // restore's copy is its own record, and the user-pool record was the purge's to delete.
                XCTAssertTrue(state == .signedOut || state == .signedIn(alice), "\(state)")
            case .failure(let error):
                guard case .sessionConfigurationMismatch = error as? AuthClientError else {
                    return XCTFail("unexpected \(error)")
                }
                XCTAssertEqual(state, .signedIn(alice))
                XCTAssertNotEqual(try userPoolOnlyStore.read(work), .absent)
            }
        }
    }

    /// A restore that carries holds the source namespace's gate, so a stored-session call on that namespace and the
    /// carry never interleave.
    ///
    /// - Given: alice under the user pool alone, and that namespace's gate held
    /// - When: a client over both pools reads its state
    /// - Then: the restore waits on the held gate (it is queued there) and nothing is carried meanwhile; once the
    ///   gate is released, the session reads `.signedIn(alice)`
    func testARestoreThatCarriesTakesTheSourceNamespacesGate() async throws {
        try aliceUnderTheUserPoolOnly()
        let gate = harness.gates.gate(for: userPoolOnlyNamespace, sessionId: work)
        let (release, held) = try await holdGate(gate)
        let client = try harness.client(work)

        let restore = Task { await client.currentSessionState() }
        await waitUntil("the restore is queued on the source namespace's gate") { await gate.waiterCount == 1 }

        XCTAssertEqual(try harness.store().read(work), .absent, "nothing is carried while the gate is held")
        release.finish()
        try await held.value
        let state = try await bounded(10, "the restore") { await restore.value }
        XCTAssertEqual(state, .signedIn(alice))
    }

    /// A restore back under a namespace the marker does not name (a rollback) also holds the gate of the namespace it
    /// names, whose record it reads to decide whether the copy here was swept.
    ///
    /// - Given: alice's record under both pools, and the marker naming the user pool alone, which holds alice too, and
    ///   the user pool's gate held
    /// - When: a client over both pools reads its state
    /// - Then: the restore waits on the held gate, and the marker is untouched meanwhile; once released, the session
    ///   reads `.signedIn(alice)` and the marker names both pools
    func testARestoreBackUnderAnotherNamespaceTakesTheMarkersNamespaceGate() async throws {
        try aliceUnderTheUserPoolOnly()
        let markerAccount = SessionRecordKey.markerAccount(for: work, scope: TestKeychain.markerScope)
        let before = harness.keychain.value(markerAccount)
        let own = try SessionRecordEnvelope(
            generation: 1,
            lastWriteTimestamp: Date(),
            record: FakePayload.signedIn("alice").record(label: "Work")
        ).encoded()
        harness.keychain.put(own, harness.store().sessionAccount(for: work))
        let gate = harness.gates.gate(for: userPoolOnlyNamespace, sessionId: work)
        let (release, held) = try await holdGate(gate)
        let client = try harness.client(work)

        let restore = Task { await client.currentSessionState() }
        await waitUntil("the restore is queued on the marker's namespace's gate") { await gate.waiterCount == 1 }

        XCTAssertEqual(harness.keychain.value(markerAccount), before, "nothing is recorded while the gate is held")
        release.finish()
        try await held.value
        let state = try await bounded(10, "the restore") { await restore.value }
        XCTAssertEqual(state, .signedIn(alice))
        XCTAssertEqual(try harness.store().marker(for: work)?.poolNamespace, ClientFixtures.configuration.poolNamespace.keyComponent)
    }

    /// A sign-out that sweeps a copy holding a refresh token its revoke does not reach (rotated under the other
    /// configuration since the carry) revokes that copy first; a copy with the same refresh token is not revoked
    /// twice.
    ///
    /// - Given: alice carried from the user pool alone into both pools, then refreshed there with rotation (a new
    ///   refresh token), then restored again under the user pool alone (a rollback), which remembers the
    ///   both-pools record as a copy; and, in a second run, the same without the rotation
    /// - When: the user-pool-only client signs out
    /// - Then: with the rotation, the engine revokes her own record and the rotated copy, and the copy is deleted;
    ///   without it, only her own record is revoked, and the copy is deleted
    func testASignOutRevokesACopyWithARotatedRefreshToken() async throws {
        for rotated in [true, false] {
            harness = ClientHarness()
            try aliceUnderTheUserPoolOnly()
            var carrying: AmplifyCognitoClient? = try harness.client(work)
            _ = await carrying?.currentSessionState()
            let bothStore = harness.store()
            guard case .record(let carried) = try bothStore.read(work) else {
                return XCTFail("nothing carried")
            }
            var refreshed = FakePayload.signedIn("alice", version: 2)
            refreshed.refreshToken = rotated ? "refresh-alice-rotated" : nil
            try bothStore.write(refreshed.record(label: "Work"), for: work, expecting: carried.generation)
            carrying = nil
            await harness.waitForBaseline()

            let client = try harness.client(work, configuration: ClientFixtures.userPoolOnlyConfiguration)
            _ = await client.currentSessionState()
            let engine = try XCTUnwrap(harness.engine(for: work))
            _ = try await client.signOut()

            let revoked = engine.revokeCalls.compactMap { FakePayload.decode($0) }
            XCTAssertEqual(revoked.map(\.version), rotated ? [1, 2] : [1], "rotated: \(rotated)")
            XCTAssertEqual(try bothStore.read(work), .absent, "rotated: \(rotated): the copy is swept")
        }
    }

    /// `signOutStoredSession` revokes a swept copy with a rotated refresh token too, through the stateless revoker.
    ///
    /// - Given: alice carried from the user pool alone into both pools, then refreshed there, with and (a second run)
    ///   without rotation; no client held
    /// - When: `signOutStoredSession` runs with the user-pool-only configuration (a rollback)
    /// - Then: with the rotation, the revoker revokes her own record and the rotated copy; without it, only her own
    ///   record; the copy is deleted either way
    func testSignOutStoredSessionRevokesACopyWithARotatedRefreshToken() async throws {
        for rotated in [true, false] {
            harness = ClientHarness()
            try aliceUnderTheUserPoolOnly()
            var carrying: AmplifyCognitoClient? = try harness.client(work)
            _ = await carrying?.currentSessionState()
            let bothStore = harness.store()
            guard case .record(let carried) = try bothStore.read(work) else {
                return XCTFail("nothing carried")
            }
            var refreshed = FakePayload.signedIn("alice", version: 2)
            refreshed.refreshToken = rotated ? "refresh-alice-rotated" : nil
            try bothStore.write(refreshed.record(label: "Work"), for: work, expecting: carried.generation)
            carrying = nil
            await harness.waitForBaseline()

            let result = try await AmplifyCognitoClient.signOutStoredSession(
                sessionId: work,
                configuration: ClientFixtures.userPoolOnlyConfiguration,
                accessGroup: nil,
                dependencies: harness.dependencies
            )

            XCTAssertEqual(result, .complete, "rotated: \(rotated)")
            let revoked = harness.revoker.revokeCalls.compactMap { FakePayload.decode($0) }
            XCTAssertEqual(revoked.map(\.version), rotated ? [1, 2] : [1], "rotated: \(rotated)")
            XCTAssertEqual(try bothStore.read(work), .absent, "rotated: \(rotated): the copy is swept")
        }
    }

    /// A refused identity step blocks only the user it refused, and a sign-out forgets it.
    ///
    /// - Given: a record's memory with alice's identity step refused
    /// - When: it is asked about alice and about bob, then reset (a sign-out or purge), then about alice
    /// - Then: alice is blocked with the refusal, bob is not; after the reset, alice is not
    func testAnIdentityRefusalIsTheRefusedUsersAndASignOutForgetsIt() {
        let retry = PendingIdentityRetry()
        let refusal = AuthClientError.notAuthorized("Refused.", "Check the providers.")
        let now = Date()
        retry.failed(refusal, at: now, transient: false, userId: "sub-alice")

        XCTAssertEqual(retry.blockingError(at: now, userId: "sub-alice")?.errorDescription, refusal.errorDescription)
        XCTAssertNil(retry.blockingError(at: now, userId: "sub-bob"))
        retry.reset()
        XCTAssertNil(retry.blockingError(at: now, userId: "sub-alice"))
    }

    /// Every call that ends the session forgets what the process remembers about its record: the identity refusal,
    /// and the credentials of the last reused refresh token (a refresh token among them). The calls are a sign-out and
    /// a purge through a live client, a user deletion, and a stored-session sign-out and purge.
    ///
    /// - Given: alice's session carried from the user pool alone, whose identity step is refused, and, just before
    ///   each call, a reused refresh token planted in the record's memory
    /// - When: the session ends, in turn, by each call
    /// - Then: before the call, the memory blocks alice and holds the reused token; after it, it does neither
    func testEveryEndOfTheSessionForgetsTheRecordsMemory() async throws {
        let namespace = SessionStorageNamespace(pools: ClientFixtures.configuration.poolNamespace, accessGroup: nil)
        let ends: [(String, @Sendable (AmplifyCognitoClient?, ClientHarness, SessionID) async throws -> Void)] = [
            ("sign-out", { client, _, _ in _ = try await client?.signOut() }),
            ("purge through a live client", { _, harness, work in
                try await AmplifyCognitoClient.purgeStoredSession(
                    sessionId: work,
                    configuration: ClientFixtures.configuration,
                    accessGroup: nil,
                    dependencies: harness.dependencies
                )
            }),
            ("user deletion", { client, _, _ in try await client?.deleteUser() }),
            ("stored-session sign-out", { _, harness, work in
                _ = try await AmplifyCognitoClient.signOutStoredSession(
                    sessionId: work,
                    configuration: ClientFixtures.configuration,
                    accessGroup: nil,
                    dependencies: harness.dependencies
                )
            }),
            ("stored-session purge", { _, harness, work in
                try await AmplifyCognitoClient.purgeStoredSession(
                    sessionId: work,
                    configuration: ClientFixtures.configuration,
                    accessGroup: nil,
                    dependencies: harness.dependencies
                )
            })
        ]
        for (name, end) in ends {
            harness = ClientHarness()
            try aliceUnderTheUserPoolOnly()
            var client: AmplifyCognitoClient? = try harness.client(work)
            let engine = try XCTUnwrap(harness.engine(for: work))
            scriptIdentityFailure(engine, .notAuthorized("Refused.", "Check the providers."))
            let memory = harness.gates.memory(for: namespace, sessionId: work)
            _ = try await client?.fetchAuthSession()
            if name.hasPrefix("stored-session") {
                client = nil
                await harness.waitForBaseline()
            }
            let sent = Data("sent".utf8)
            _ = memory.refreshTokenReuse.repeated(sent, at: Date())
            // A repeat past the gap reports the planted token (and consumes it): plant it again.
            XCTAssertTrue(memory.refreshTokenReuse.repeated(sent, at: Date().addingTimeInterval(RefreshTokenReuse.minimumGap)), "\(name): planted")
            _ = memory.refreshTokenReuse.repeated(sent, at: Date())
            XCTAssertNotNil(memory.identityRetry.blockingError(at: Date(), userId: "sub-alice"), name)

            try await end(client, harness, work)

            XCTAssertNil(memory.identityRetry.blockingError(at: Date(), userId: "sub-alice"), name)
            XCTAssertFalse(memory.refreshTokenReuse.repeated(sent, at: Date().addingTimeInterval(RefreshTokenReuse.minimumGap)), name)
        }
    }

    /// A copy revoke that fails is logged, with no identifiers, and the sweep goes ahead.
    ///
    /// - Given: alice carried from the user pool alone into both pools, refreshed there with rotation, then restored
    ///   under the user pool alone (the rotated copy remembered), and an engine whose revoke of that copy fails
    /// - When: the user-pool-only client signs out
    /// - Then: the sign-out completes; the copy-revoke warning is logged once, naming no user, session or pool; the
    ///   copy is deleted
    func testAFailedCopyRevokeIsLoggedAndTheSweepGoesAhead() async throws {
        let warnings = CopyRevokeWarningCapture.shared
        let before = warnings.count
        try aliceUnderTheUserPoolOnly()
        var carrying: AmplifyCognitoClient? = try harness.client(work)
        _ = await carrying?.currentSessionState()
        let bothStore = harness.store()
        guard case .record(let carried) = try bothStore.read(work) else {
            return XCTFail("nothing carried")
        }
        var refreshed = FakePayload.signedIn("alice", version: 2)
        refreshed.refreshToken = "refresh-alice-rotated"
        try bothStore.write(refreshed.record(label: "Work"), for: work, expecting: carried.generation)
        carrying = nil
        await harness.waitForBaseline()
        let client = try harness.client(work, configuration: ClientFixtures.userPoolOnlyConfiguration)
        _ = await client.currentSessionState()
        let engine = try XCTUnwrap(harness.engine(for: work))
        engine.scriptRevoke { payload in
            if FakePayload.decode(payload)?.version == 2 {
                throw AuthClientError.service(.network, "The network connection was lost.", "Retry.")
            }
        }

        let result = try await client.signOut()

        XCTAssertEqual(result, .complete)
        XCTAssertEqual(warnings.count - before, 1)
        let logged = try XCTUnwrap(warnings.last)
        XCTAssertEqual(logged, SessionSignOut.copyRevokeFailedWarning)
        for identifier in ["alice", "sub-alice", "work", StorageFixtures.userPoolId, StorageFixtures.identityPoolId] {
            XCTAssertFalse(logged.contains(identifier), "the warning names no identifier")
        }
        XCTAssertEqual(try bothStore.read(work), .absent, "the copy is swept")
    }

    /// A restore whose marker keeps changing under it fails as interrupted, which is not cached, so a later call on
    /// the same core restores, and carries, again.
    ///
    /// - Given: alice under the user pool alone, and every read of the session's marker followed by another writer
    ///   pointing it at another namespace
    /// - When: a client over both pools reads its state; then, with the marker left alone, reads it again
    /// - Then: the first is `.unavailable(.interrupted)` and nothing is carried; the second is `.signedIn(alice)`
    func testARestoreWhoseMarkerKeepsChangingIsRetriedByTheNextCall() async throws {
        try aliceUnderTheUserPoolOnly()
        let markerAccount = SessionRecordKey.markerAccount(for: work, scope: TestKeychain.markerScope)
        let original = try XCTUnwrap(harness.keychain.value(markerAccount))
        let elsewhere = Data(#"{"copies":[],"poolNamespace":"\#(ClientFixtures.identityPoolOnlyConfiguration.poolNamespace.keyComponent)","schemaVersion":1}"#.utf8)
        let keychain = harness.keychain
        let flips = CallCounter()
        keychain.afterEveryRead(of: markerAccount) {
            flips.increment()
            keychain.put(flips.count % 2 == 1 ? elsewhere : original, markerAccount)
        }
        let client = try harness.client(work)

        let first = await client.currentSessionState()

        keychain.afterEveryRead(of: markerAccount, nil)
        XCTAssertEqual(first, .unavailable(.interrupted))
        XCTAssertEqual(try harness.store().read(work), .absent, "nothing is carried")
        keychain.put(original, markerAccount)
        let second = await client.currentSessionState()
        XCTAssertEqual(second, .signedIn(alice))
    }

    /// A stored-session call holds the gate of every namespace the session's marker names, not only its own.
    ///
    /// - Given: alice under the user pool alone, and that namespace's gate held
    /// - When: `purgeStoredSession` runs over both pools
    /// - Then: it is queued on the held gate, and the user-pool record is untouched; once released, it finishes
    func testAStoredSessionCallTakesTheRecordedNamespacesGate() async throws {
        try aliceUnderTheUserPoolOnly()
        let dependencies = harness.dependencies
        let work = work
        let gate = harness.gates.gate(for: userPoolOnlyNamespace, sessionId: work)
        let (release, held) = try await holdGate(gate)

        let purge = Task {
            try await AmplifyCognitoClient.purgeStoredSession(
                sessionId: work,
                configuration: ClientFixtures.configuration,
                accessGroup: nil,
                dependencies: dependencies
            )
        }
        await waitUntil("the purge is queued on the recorded namespace's gate") { await gate.waiterCount == 1 }

        XCTAssertNotEqual(try userPoolOnlyStore.read(work), .absent)
        release.finish()
        try await held.value
        try await bounded(10, "the purge") { try await purge.value }
    }

    /// Holds `gate` until the returned continuation finishes; returns once it is held.
    private func holdGate(_ gate: SessionRecordGate) async throws -> (AsyncStream<Void>.Continuation, Task<Void, Error>) {
        let (stream, release) = AsyncStream<Void>.makeStream()
        let held = expectation(description: "the gate is held")
        let holder = Task {
            try await gate.withLock {
                held.fulfill()
                for await _ in stream {}
            }
        }
        await fulfillment(of: [held], timeout: 10)
        return (release, holder)
    }

    /// - Given: alice carried from the user pool alone, and a copy written back under the user pool by another
    ///   writer (different bytes)
    /// - When: the live client signs out
    /// - Then: the rewritten copy is left: it is that writer's
    func testSignOutLeavesACopyAnotherWriterRewrote() async throws {
        try aliceUnderTheUserPoolOnly()
        let client = try harness.client(work)
        _ = await client.currentSessionState()
        guard case .record(let envelope) = try userPoolOnlyStore.read(work) else {
            return XCTFail("the old record is kept")
        }
        try userPoolOnlyStore.write(FakePayload.signedIn("alice", kind: .userPoolOnly, version: 5).record(), for: work, expecting: envelope.generation)

        _ = try await client.signOut()

        XCTAssertNotEqual(try userPoolOnlyStore.read(work), .absent)
    }

    /// - Given: alice under the user pool alone
    /// - When: the sessions over both pools are listed
    /// - Then: one row, `work`, labelled, user-pool-only; nothing is carried
    func testStoredSessionsListsAPendingCarryOnce() async throws {
        try aliceUnderTheUserPoolOnly()

        let listed = try await AmplifyCognitoClient.storedSessions(
            configuration: ClientFixtures.configuration,
            accessGroup: nil,
            includingSignedOut: true,
            dependencies: harness.dependencies
        )

        XCTAssertEqual(listed, [StoredSession(sessionId: work, label: "Work", username: "alice", kind: .userPoolOnly)])
        XCTAssertEqual(try harness.store().read(work), .absent)
    }

    /// - Given: alice under the user pool alone, and reads of that record failing
    /// - When: `signOutStoredSession` runs over both pools
    /// - Then: it throws `storageUnavailable`; nothing is revoked, and alice's record is kept
    func testSignOutStoredSessionWithAFailedReadRevokesNothing() async throws {
        try aliceUnderTheUserPoolOnly()
        harness.keychain.failingReads(of: userPoolOnlyStore.sessionAccount(for: work), with: errSecInteractionNotAllowed)

        do {
            _ = try await AmplifyCognitoClient.signOutStoredSession(
                sessionId: work,
                configuration: ClientFixtures.configuration,
                accessGroup: nil,
                dependencies: harness.dependencies
            )
            XCTFail("a failed read must fail the sign-out")
        } catch let error as AuthClientError {
            XCTAssertEqual(error.storageUnavailableReason, .locked)
        }

        XCTAssertEqual(harness.revoker.revokeCalls, [])
        harness.keychain.clearFailures()
        XCTAssertNotEqual(try userPoolOnlyStore.read(work), .absent)
    }

    /// - Given: `work` live, restored, under the user pool alone
    /// - When: `purgeStoredSession` and `signOutStoredSession` run over both pools
    /// - Then: each throws `sessionConfigurationMismatch`; the live session's record is intact, nothing revoked
    func testStoredSessionCallsRefuseASessionLiveUnderAnotherConfiguration() async throws {
        try aliceUnderTheUserPoolOnly()
        let live = try harness.client(work, configuration: ClientFixtures.userPoolOnlyConfiguration)
        _ = await live.currentSessionState()
        let dependencies = harness.dependencies
        let work = work

        let purge = await Result(catching: { try await AmplifyCognitoClient.purgeStoredSession(
            sessionId: work, configuration: ClientFixtures.configuration, accessGroup: nil, dependencies: dependencies
        ) })
        let signOut = await Result(catching: { try await AmplifyCognitoClient.signOutStoredSession(
            sessionId: work, configuration: ClientFixtures.configuration, accessGroup: nil, dependencies: dependencies
        ) })

        for (name, error) in [("purge", purge.failure), ("sign-out", signOut.failure)] {
            guard case .sessionConfigurationMismatch(let id, _, _, _) = error as? AuthClientError else {
                XCTFail("\(name) should refuse, got \(String(describing: error))")
                continue
            }
            XCTAssertEqual(id, work)
        }
        XCTAssertNotEqual(try userPoolOnlyStore.read(work), .absent)
        XCTAssertEqual(harness.revoker.revokeCalls, [])
        let state = await live.currentSessionState()
        XCTAssertEqual(state, .signedIn(alice))
    }

    /// The refusal covers a session live under any other namespace, not only one the marker names.
    ///
    /// - Given: `work` live under the identity pool alone (a guest), which its marker does not name
    /// - When: `purgeStoredSession` runs over both pools
    /// - Then: it throws `sessionConfigurationMismatch`
    func testStoredSessionCallsRefuseASessionLiveUnderAnUnrelatedConfiguration() async throws {
        try identityPoolOnlyStore.write(FakePayload.guest().record(), for: ClientFixtures.id("other"), expecting: nil)
        let live = try harness.client(work, configuration: ClientFixtures.identityPoolOnlyConfiguration)
        _ = await live.currentSessionState()
        let dependencies = harness.dependencies
        let work = work

        let purge = await Result(catching: { try await AmplifyCognitoClient.purgeStoredSession(
            sessionId: work, configuration: ClientFixtures.configuration, accessGroup: nil, dependencies: dependencies
        ) })

        guard case .sessionConfigurationMismatch = purge.failure as? AuthClientError else {
            return XCTFail("the purge should refuse, got \(String(describing: purge.failure))")
        }
        _ = live
    }
}

private extension Result where Failure == Error {
    init(catching body: () async throws -> Success) async {
        do {
            self = .success(try await body())
        } catch {
            self = .failure(error)
        }
    }

    var failure: Error? {
        if case .failure(let error) = self {
            return error
        }
        return nil
    }
}

/// Captures the copy-revoke warning (`SessionSignOut.copyRevokeFailedWarning`) from the process's log.
final class CopyRevokeWarningCapture: LogSinkBehavior, @unchecked Sendable {

    static let shared: CopyRevokeWarningCapture = {
        let sink = CopyRevokeWarningCapture()
        AmplifyLogging.addSink(sink)
        return sink
    }()

    let id = "SessionCopyForwardTests.copyRevokeCapture"

    // `@unchecked Sendable`: `captured` is only touched while holding `lock`.
    private let lock = NSLock()
    private var captured: [String] = []

    var count: Int {
        lock.withLock { captured.count }
    }

    var last: String? {
        lock.withLock { captured.last }
    }

    func isEnabled(for logLevel: LogLevel) -> Bool {
        true
    }

    func emit(message: LogMessage) {
        guard message.content == SessionSignOut.copyRevokeFailedWarning else {
            return
        }
        lock.withLock { captured.append(message.content) }
    }
}
