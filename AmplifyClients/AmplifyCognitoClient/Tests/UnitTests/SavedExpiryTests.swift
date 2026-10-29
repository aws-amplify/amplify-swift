//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyFoundation
import Foundation
import Security
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// A dead refresh token's expiry is saved with the session's record (`SessionRecord.deadToken`): in a named session's
/// envelope, and in `.default`'s sidecar beside the Auth plugin's record. A new session core, once every handle and
/// provider of the session was released or after a relaunch, starts expired while the record still holds that token,
/// so it never refreshes the dead token again. Any new login or federation ends it, whoever saved it.
final class SavedExpiryTests: XCTestCase {

    private var harness: ClientHarness!
    /// Other harnesses over `harness`'s keychain (a relaunch, or a second process), waited on at tear-down.
    private var others: [ClientHarness] = []
    private let work = ClientFixtures.id("work")
    private let alice = AuthClientUser(username: "alice", userId: "sub-alice")
    private var pluginAccount: String { SessionRecordKey.pluginSessionAccount(in: StorageFixtures.pools) }
    private var sidecarAccount: String { SessionRecordKey.metaAccount(in: StorageFixtures.pools) }

    override func setUp() {
        harness = ClientHarness()
        others = []
    }

    override func tearDown() async throws {
        harness.keychain.clearFailures()
        await harness.waitForBaseline()
        for other in others {
            await other.waitForBaseline()
        }
        others = []
        harness = nil
    }

    /// A new harness over the same keychain: a relaunch of the app, or another process sharing its access group.
    private func relaunch() -> ClientHarness {
        let relaunched = ClientHarness(keychain: harness.keychain)
        others.append(relaunched)
        return relaunched
    }

    // MARK: Released, and relaunched

    /// - Given: a session whose refresh token two reuse refusals, `RefreshTokenReuse.minimumGap` apart, proved dead;
    ///   its client then released
    /// - When: a new client of the session asks both providers, and fetches the session, unforced and forced
    /// - Then:
    ///    - every answer is the proof's `sessionExpired` ("already used", `refreshTokenReused` underneath)
    ///    - the new client makes no refresh, and sends no `.sessionExpired` of its own
    ///    - the record keeps its credentials, and the session stays signed in as the user
    func testAReuseExpirySurvivesReleasingTheClient() async throws {
        let stale = FakePayload.signedIn("alice", stale: true)
        try harness.signIn(work, stale)
        try await expireByReuse(work, in: harness)

        let next = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let events = StreamRecorder(next.listenToAuthEvents())
        let aws = await credentialsError { try await next.credentialsProvider.resolve() }
        let token = await credentialsError { try await next.userPoolTokenProvider.accessToken() }
        let unforced = try await next.fetchAuthSession()
        let forced = try await next.fetchAuthSession(options: .init(forceRefresh: true))

        for (name, error) in [("the AWS credentials provider", aws), ("the token provider", token)] {
            XCTAssertEqual(error?.isSessionExpired, true, "\(name): \(String(describing: error))")
            assertAlreadyUsed(error?.underlyingError as? AuthClientError, work, name)
        }
        assertEveryField(of: unforced, isAlreadyUsed: work, "the unforced fetch")
        assertEveryField(of: forced, isAlreadyUsed: work, "the forced fetch")
        XCTAssertEqual(engine.refreshCalls, [])
        XCTAssertEqual(try harness.storedRecord(work)?.credentials, stale.data)
        let state = await next.currentSessionState()
        XCTAssertEqual(state, .signedIn(alice))
        // Ends with a known event, so a `.sessionExpired` still in the recorder's buffer is counted too.
        _ = await next.signOut()
        await events.waitFor(1)
        XCTAssertEqual(events.received, [.signedOut])
    }

    /// - Given: a named session's refresh token proved dead by two reuse refusals
    /// - When: the app relaunches (a new harness over the same keychain) and asks for credentials
    /// - Then:
    ///    - the answer is the proof's `sessionExpired` ("already used"), with no refresh
    ///    - the envelope holds the marker: the dead refresh token's digest and its cause
    func testAReuseExpirySurvivesARelaunch() async throws {
        let stale = FakePayload.signedIn("alice", stale: true)
        try harness.signIn(work, stale)
        try await expireByReuse(work, in: harness)

        let relaunched = relaunch()
        let client = try relaunched.client(work)
        let engine = try XCTUnwrap(relaunched.engine(for: work))
        let error = await credentialsError { try await client.credentialsProvider.resolve() }

        XCTAssertEqual(error?.isSessionExpired, true, "\(String(describing: error))")
        assertAlreadyUsed(error?.underlyingError as? AuthClientError, work, "after the relaunch")
        XCTAssertEqual(engine.refreshCalls, [])
        let saved = try XCTUnwrap(try relaunched.storedRecord(work)?.deadToken)
        XCTAssertEqual(saved.cause, .reused)
        XCTAssertEqual(saved.token, DeadToken.digest(refreshToken: stale.userPoolTokens?.refreshToken, credentials: stale.data))
    }

    /// The same for `.default`, whose marker is in the sidecar: the Auth plugin's record is never rewritten for it.
    ///
    /// - Given: `.default` holding the plugin's record for alice, whose refresh token two reuse refusals proved dead
    /// - When: the app relaunches and asks for credentials
    /// - Then:
    ///    - the answer is the proof's `sessionExpired` ("already used"), with no refresh
    ///    - the plugin's record holds the same bytes, and the sidecar holds the marker
    func testADefaultSessionsExpirySurvivesARelaunchInItsSidecar() async throws {
        let stale = FakePayload.signedIn("alice", stale: true)
        harness.keychain.put(stale.data, pluginAccount)
        try await expireByReuse(.default, in: harness)

        let relaunched = relaunch()
        let client = try relaunched.client(.default)
        let engine = try XCTUnwrap(relaunched.engine(for: .default))
        let error = await credentialsError { try await client.credentialsProvider.resolve() }

        XCTAssertEqual(error?.isSessionExpired, true, "\(String(describing: error))")
        assertAlreadyUsed(error?.underlyingError as? AuthClientError, .default, "after the relaunch")
        XCTAssertEqual(engine.refreshCalls, [])
        XCTAssertEqual(harness.keychain.value(pluginAccount), stale.data)
        let sidecar = try XCTUnwrap(harness.keychain.value(sidecarAccount).map(DefaultSessionMeta.decode))
        guard case .meta(let meta) = sidecar else {
            return XCTFail("the sidecar is not readable: \(sidecar)")
        }
        XCTAssertEqual(meta.deadToken?.cause, .reused)
        XCTAssertEqual(meta.userId, "sub-alice")
    }

    /// A refused refresh token's expiry is saved too, with its own text.
    ///
    /// - Given: a session whose refresh is refused as `refreshTokenInvalid`
    /// - When: the app relaunches and asks for credentials
    /// - Then: the answer is `sessionExpired` saying the refresh token has expired or been revoked, with
    ///   `refreshTokenInvalid` underneath, and no refresh
    func testAnInvalidRefreshTokensExpirySurvivesARelaunch() async throws {
        try harness.signIn(work, .signedIn("alice", stale: true))
        var client: AmplifyCognitoClient? = try harness.client(work)
        harness.engine(for: work)?.scriptRefresh { _ in throw SessionEngineError.refreshTokenInvalid }
        _ = await credentialsError { try await XCTUnwrap(client).credentialsProvider.resolve() }
        client = nil
        await harness.waitForBaseline()

        let relaunched = relaunch()
        let next = try relaunched.client(work)
        let engine = try XCTUnwrap(relaunched.engine(for: work))
        let error = await credentialsError { try await next.credentialsProvider.resolve() }

        XCTAssertEqual(error?.isSessionExpired, true, "\(String(describing: error))")
        let underlying = error?.underlyingError as? AuthClientError
        XCTAssertEqual(underlying?.errorDescription, "Session \"work\"'s refresh token has expired or been revoked.")
        guard case SessionEngineError.refreshTokenInvalid? = underlying?.underlyingError as? SessionEngineError else {
            return XCTFail("expected refreshTokenInvalid underneath, got \(String(describing: underlying?.underlyingError))")
        }
        XCTAssertEqual(engine.refreshCalls, [])
    }

    /// Another process's proof reaches a core already in memory: its next refresh re-reads first, and does not spend
    /// the dead token again.
    ///
    /// - Given: two processes over one keychain, each with a client of the session restored; the first proves the
    ///   refresh token dead with two reuse refusals
    /// - When: the second asks for credentials, which need a refresh
    /// - Then: it answers the proof's `sessionExpired` ("already used") with no refresh of its own, and the session
    ///   stays signed in as the user
    func testAnotherProcesssSavedExpiryStopsTheNextRefresh() async throws {
        try harness.signIn(work, .signedIn("alice", stale: true))
        let other = relaunch()
        let otherClient = try other.client(work)
        _ = await otherClient.currentSessionState()
        let otherEngine = try XCTUnwrap(other.engine(for: work))
        try await expireByReuse(work, in: harness)

        let error = await credentialsError { try await otherClient.credentialsProvider.resolve() }

        XCTAssertEqual(error?.isSessionExpired, true, "\(String(describing: error))")
        assertAlreadyUsed(error?.underlyingError as? AuthClientError, work, "the other process")
        XCTAssertEqual(otherEngine.refreshCalls, [])
        let state = await otherClient.currentSessionState()
        XCTAssertEqual(state, .signedIn(alice))
    }

    // MARK: What ends it

    /// - Given: a session restored expired from its saved marker, after its client was released
    /// - When: the user signs in again, and the app then relaunches
    /// - Then:
    ///    - the sign-in is not refused: an expired session signs in again
    ///    - after the relaunch the session vends the new login's credentials, with no refresh: the sign-in's record
    ///      carries no marker
    func testASignInEndsTheSavedExpiry() async throws {
        try harness.signIn(work, .signedIn("alice", stale: true))
        try await expireByReuse(work, in: harness)
        var client: AmplifyCognitoClient? = try harness.client(work)
        _ = await credentialsError { try await XCTUnwrap(client).credentialsProvider.resolve() }

        _ = try await XCTUnwrap(client).signInForTest()
        client = nil
        await harness.waitForBaseline()
        let relaunched = relaunch()
        let next = try relaunched.client(work)
        let credentials = try await next.credentialsProvider.resolve()

        XCTAssertEqual(credentials as? CognitoAWSCredentials, FakePayload.signedIn("alice").awsCredentials)
        XCTAssertEqual(relaunched.engine(for: work)?.refreshCalls, [])
        XCTAssertNil(try relaunched.storedRecord(work)?.deadToken)
    }

    /// - Given: a named session's saved expiry, then another process saving a new login of the same user, with another
    ///   refresh token, that needs no refresh
    /// - When: a new client of the session asks for credentials
    /// - Then: they are the new login's, with no refresh, and the session is signed in as the user
    func testANewLoginAnotherProcessSavedEndsTheSavedExpiry() async throws {
        try harness.signIn(work, .signedIn("alice", stale: true))
        try await expireByReuse(work, in: harness)
        let newLogin = FakePayload.signedIn("alice", version: 2)
        let otherStore = relaunch().store()
        guard case .record(let stored) = try otherStore.read(work) else {
            return XCTFail("the expired record was not kept")
        }
        try otherStore.write(newLogin.record(), for: work, expecting: stored.version)

        let next = try harness.client(work)
        let credentials = try await next.credentialsProvider.resolve()

        XCTAssertEqual(credentials as? CognitoAWSCredentials, newLogin.awsCredentials)
        XCTAssertEqual(harness.engine(for: work)?.refreshCalls, [])
        let state = await next.currentSessionState()
        XCTAssertEqual(state, .signedIn(alice))
    }

    /// The marker names the dead token, not the record: the Auth plugin saving a new login over `.default` leaves the
    /// sidecar as it was, and its marker no longer applies.
    ///
    /// - Given: `.default`'s saved expiry, then the plugin saving a new login of the same user, with another refresh
    ///   token, over its record alone
    /// - When: the app relaunches and asks for credentials
    /// - Then:
    ///    - the sidecar still holds the marker
    ///    - the credentials are the new login's, with no refresh, and the session is signed in as the user
    func testANewLoginThePluginSavedEndsTheSavedExpiryLeftInTheSidecar() async throws {
        harness.keychain.put(FakePayload.signedIn("alice", stale: true).data, pluginAccount)
        try await expireByReuse(.default, in: harness)
        let newLogin = FakePayload.signedIn("alice", version: 2)
        harness.keychain.put(newLogin.data, pluginAccount)

        let relaunched = relaunch()
        let client = try relaunched.client(.default)
        let credentials = try await client.credentialsProvider.resolve()

        guard case .meta(let meta)? = harness.keychain.value(sidecarAccount).map(DefaultSessionMeta.decode) else {
            return XCTFail("the sidecar is not readable")
        }
        XCTAssertEqual(meta.deadToken?.cause, .reused, "the plugin never writes the sidecar")
        XCTAssertEqual(credentials as? CognitoAWSCredentials, newLogin.awsCredentials)
        XCTAssertEqual(relaunched.engine(for: .default)?.refreshCalls, [])
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedIn(alice))
    }

    /// A federated session's refused provider token is saved too (by its credentials, which hold no refresh token),
    /// and a new federation ends it.
    ///
    /// - Given: a federated session whose refresh is refused as `refreshTokenInvalid` (the identity pool no longer
    ///   accepts its provider token), its client then released
    /// - When: a new client asks for credentials, federates again, and asks again; then the app relaunches and asks
    /// - Then:
    ///    - the first answer is `sessionExpired` saying the provider token is no longer accepted, with no refresh
    ///    - the federation commits, and both later answers are the new federation's credentials, with no refresh
    func testANewFederationEndsAFederatedSessionsSavedExpiry() async throws {
        try harness.signIn(work, .federated(stale: true))
        var client: AmplifyCognitoClient? = try harness.client(work)
        harness.engine(for: work)?.scriptRefresh { _ in throw SessionEngineError.refreshTokenInvalid }
        _ = await credentialsError { try await XCTUnwrap(client).credentialsProvider.resolve() }
        client = nil
        await harness.waitForBaseline()

        let next = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let expired = await credentialsError { try await next.credentialsProvider.resolve() }
        let federated = FakePayload.federated(version: 2)
        engine.scriptAccountOperation(.federateToIdentityPool) { _ in federated.data }
        _ = try await next.federateToIdentityPool(withProviderToken: "new-token", for: .google)
        let after = try await next.credentialsProvider.resolve()
        let relaunched = relaunch()
        let relaunchedClient = try relaunched.client(work)
        let afterRelaunch = try await relaunchedClient.credentialsProvider.resolve()

        XCTAssertEqual(expired?.isSessionExpired, true, "\(String(describing: expired))")
        XCTAssertEqual(
            (expired?.underlyingError as? AuthClientError)?.errorDescription,
            "Session \"work\"'s provider token is no longer accepted by the identity pool."
        )
        XCTAssertEqual(after as? CognitoAWSCredentials, federated.awsCredentials)
        XCTAssertEqual(afterRelaunch as? CognitoAWSCredentials, federated.awsCredentials)
        XCTAssertEqual(engine.refreshCalls, [])
        XCTAssertEqual(relaunched.engine(for: work)?.refreshCalls, [])
    }

    /// The save is best effort: when it fails, the expiry stays the core's, and a later core refreshes once more.
    ///
    /// - Given: a session whose refresh token two reuse refusals prove dead while its record cannot be written
    /// - When: the client is released, and a new client asks for credentials after `RefreshTokenReuse.minimumGap`
    /// - Then:
    ///    - the proof still answers "already used", and the record holds no marker
    ///    - the new client refreshes again (the retryable `unknown` of a first reuse)
    func testAnExpiryThatCouldNotBeSavedStaysTheCoresOnly() async throws {
        try harness.signIn(work, .signedIn("alice", stale: true))
        harness.keychain.failingWrites(of: harness.store().sessionAccount(for: work), with: errSecInteractionNotAllowed)
        try await expireByReuse(work, in: harness)
        harness.keychain.clearFailures()
        XCTAssertNil(try harness.storedRecord(work)?.deadToken)

        harness.advanceClock(by: RefreshTokenReuse.minimumGap)
        let next = try harness.client(work)
        harness.engine(for: work)?.scriptRefresh { _ in throw SessionEngineError.refreshTokenReused }
        let error = await credentialsError { try await next.credentialsProvider.resolve() }

        XCTAssertEqual(error?.isUnknown, true, "\(String(describing: error))")
        XCTAssertEqual(harness.engine(for: work)?.refreshCalls.count, 1)
    }

    // MARK: Stored format

    /// - Given: a named session's record with a marker, and one without
    /// - When: each is encoded, and decoded back
    /// - Then:
    ///    - the marker is the envelope's `deadToken` key, `{"cause":"reused","token":"<digest>"}`, and round-trips
    ///    - a record without one has no `deadToken` key
    func testTheEnvelopeStoresTheMarkerOnlyWhenSet() throws {
        let deadToken = DeadToken(token: DeadToken.digest(refreshToken: "refresh", credentials: Data()), cause: .reused)
        var record = FakePayload.signedIn("alice").record()
        let without = try SessionRecordEnvelope(generation: 1, lastWriteTimestamp: TestClock.start, record: record).encoded()
        record.deadToken = deadToken
        let with = try SessionRecordEnvelope(generation: 1, lastWriteTimestamp: TestClock.start, record: record).encoded()

        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: with) as? [String: Any])
        XCTAssertEqual(json["deadToken"] as? [String: String], ["cause": "reused", "token": deadToken.token])
        XCTAssertFalse(String(decoding: without, as: UTF8.self).contains("deadToken"))
        guard case .envelope(let decoded) = SessionRecordEnvelope.decode(with) else {
            return XCTFail("the envelope did not decode")
        }
        XCTAssertEqual(decoded.record.deadToken, deadToken)
        XCTAssertEqual(deadToken.token.count, 64)
    }

    /// A marker this build cannot read (a newer build's cause) is ignored: the record is still read, never taken for a
    /// corrupt one, and the session refreshes as if nothing were saved.
    ///
    /// - Given: an envelope and a sidecar whose `deadToken` has a cause this build does not know
    /// - When: each is decoded
    /// - Then: both decode, with no marker, and the rest of each as stored
    func testAnUnreadableMarkerIsIgnored() throws {
        let record = FakePayload.signedIn("alice").record()
        let envelope = try SessionRecordEnvelope(generation: 3, lastWriteTimestamp: TestClock.start, record: record).encoded()
        var envelopeJSON = try XCTUnwrap(JSONSerialization.jsonObject(with: envelope) as? [String: Any])
        envelopeJSON["deadToken"] = ["cause": "future", "token": "abc"]
        let sidecar = try DefaultSessionMeta(lastWriteTimestamp: TestClock.start, label: "Work", username: "alice", userId: "sub-alice").encoded()
        var sidecarJSON = try XCTUnwrap(JSONSerialization.jsonObject(with: sidecar) as? [String: Any])
        sidecarJSON["deadToken"] = ["cause": "future", "token": "abc"]

        guard case .envelope(let decoded) = try SessionRecordEnvelope.decode(JSONSerialization.data(withJSONObject: envelopeJSON)) else {
            return XCTFail("an unreadable marker made the envelope unreadable")
        }
        XCTAssertNil(decoded.record.deadToken)
        XCTAssertEqual(decoded.record.credentials, record.credentials)
        XCTAssertEqual(decoded.generation, 3)
        guard case .meta(let meta) = try DefaultSessionMeta.decode(JSONSerialization.data(withJSONObject: sidecarJSON)) else {
            return XCTFail("an unreadable marker made the sidecar unreadable")
        }
        XCTAssertNil(meta.deadToken)
        XCTAssertEqual(meta.label, "Work")
    }

    // MARK: Helpers

    /// Proves `sessionId`'s refresh token dead in `harness` with two reuse refusals, `RefreshTokenReuse.minimumGap`
    /// apart, then releases the client and waits for its core to go.
    private func expireByReuse(_ sessionId: SessionID, in harness: ClientHarness, file: StaticString = #filePath, line: UInt = #line) async throws {
        var client: AmplifyCognitoClient? = try harness.client(sessionId)
        harness.engine(for: sessionId)?.scriptRefresh { _ in throw SessionEngineError.refreshTokenReused }
        let first = await credentialsError { try await XCTUnwrap(client).credentialsProvider.resolve() }
        XCTAssertEqual(first?.isUnknown, true, "the first reuse: \(String(describing: first))", file: file, line: line)
        harness.advanceClock(by: RefreshTokenReuse.minimumGap)
        let proof = await credentialsError { try await XCTUnwrap(client).credentialsProvider.resolve() }
        assertAlreadyUsed(proof?.underlyingError as? AuthClientError, sessionId, "the proof", file: file, line: line)
        client = nil
        await harness.waitForBaseline(file: file, line: line)
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

    /// Asserts `error` is the dead token after a reuse for `sessionId`.
    private func assertAlreadyUsed(
        _ error: AuthClientError?,
        _ sessionId: SessionID,
        _ name: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let error else {
            return XCTFail("\(name): no error", file: file, line: line)
        }
        XCTAssertEqual(error.kind, .sessionExpired, "\(name): \(error)", file: file, line: line)
        XCTAssertEqual(
            error.errorDescription,
            "Session \"\(sessionId)\"'s refresh token was already used, and no refreshed tokens were saved, so the session cannot be renewed.",
            name,
            file: file,
            line: line
        )
        guard case SessionEngineError.refreshTokenReused? = error.underlyingError as? SessionEngineError else {
            return XCTFail("\(name): expected refreshTokenReused underneath, got \(String(describing: error.underlyingError))", file: file, line: line)
        }
    }

    private func assertEveryField(
        of session: AuthClientSession,
        isAlreadyUsed sessionId: SessionID,
        _ name: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let fields: [(String, Result<Void, AuthClientError>)] = [
            ("userPoolTokens", session.userPoolTokensResult.map { _ in () }),
            ("userSub", session.userSubResult.map { _ in () }),
            ("identityId", session.identityIdResult.map { _ in () }),
            ("awsCredentials", session.awsCredentialsResult.map { _ in () })
        ]
        for (field, result) in fields {
            guard case .failure(let error) = result else {
                XCTFail("\(name): \(field) should fail", file: file, line: line)
                continue
            }
            assertAlreadyUsed(error, sessionId, "\(name), \(field)", file: file, line: line)
        }
    }
}
