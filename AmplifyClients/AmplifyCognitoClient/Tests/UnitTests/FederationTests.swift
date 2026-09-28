//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// `federateToIdentityPool` and `clearFederationToIdentityPool` over the fake engine. The commit
/// and its guards (the sign-in lock, the epoch, compare-before-write), the federated session's refresh and
/// sign-out, and per-session isolation. The live engine's side is `LiveEngineFederationTests`.
final class FederationTests: XCTestCase {

    private var harness: ClientHarness!
    private let work = ClientFixtures.id("work")
    private let home = ClientFixtures.id("home")

    override func setUp() {
        harness = ClientHarness()
    }

    override func tearDown() async throws {
        await harness.waitForBaseline()
        harness = nil
    }

    // MARK: Federating

    /// - Given: two signed-out sessions, `work` and `home`
    /// - When: `work` federates
    /// - Then:
    ///    - the result is the engine's identity and AWS credentials; `work` stores a federated record with no
    ///      user and reports `.federated(identityId:)`, and its session holds the credentials
    ///    - `home`'s engine sees nothing, it stores nothing and stays signed out
    func testFederationCommitsOnItsOwnSessionOnly() async throws {
        let client = try harness.client(work)
        let other = try harness.client(home)
        let federated = FakePayload.federated(identityId: "us-east-1:fed")
        let engine = try XCTUnwrap(harness.engine(for: work))
        engine.scriptPhase5(.federateToIdentityPool) { _ in federated.data }

        let result = try await client.federateToIdentityPool(withProviderToken: "token", for: .google)

        XCTAssertEqual(result.identityId, "us-east-1:fed")
        XCTAssertEqual(result.credentials, AuthClientAWSCredentials(federated.awsCredentials))
        let record = try XCTUnwrap(harness.storedRecord(work))
        XCTAssertEqual(record.kind, .federated)
        XCTAssertNil(record.username)
        XCTAssertNil(record.userId)
        XCTAssertEqual(record.credentials, federated.data)
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .federated(identityId: "us-east-1:fed"))
        let session = try await client.fetchAuthSession()
        XCTAssertEqual(try session.identityIdResult.get(), "us-east-1:fed")
        XCTAssertEqual(try session.awsCredentialsResult.get(), AuthClientAWSCredentials(federated.awsCredentials))

        XCTAssertEqual(harness.engine(for: home)?.phase5Calls, [])
        XCTAssertNil(try harness.storedRecord(home))
        let otherState = await other.currentSessionState()
        XCTAssertEqual(otherState, .signedOut)
    }

    /// A guest federates as the plugin's machine does from `signedOut` with a session established: the engine
    /// is handed the guest payload, and the row keeps its label.
    ///
    /// - Given: a labelled guest session
    /// - When: it federates
    /// - Then:
    ///    - the engine receives the guest payload as `current`; the record is federated and keeps the label
    func testAGuestFederatesKeepingItsLabel() async throws {
        let guest = FakePayload.guest(identityId: "us-east-1:guest")
        try harness.signIn(work, guest, label: "Kiosk")
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))

        _ = try await client.federateToIdentityPool(withProviderToken: "token", for: .facebook)

        XCTAssertEqual(engine.phase5Calls, [
            .federateToIdentityPool(
                EngineFederationRequest(token: "token", provider: .facebook, developerProvidedIdentityId: nil),
                current: guest.data
            )
        ])
        let record = try XCTUnwrap(harness.storedRecord(work))
        XCTAssertEqual(record.kind, .federated)
        XCTAssertEqual(record.label, "Kiosk")
    }

    /// - Given: a federated session
    /// - When: it federates again with another identity
    /// - Then:
    ///    - the new federation replaces the old one, and the state reports the new identity
    func testAFederatedSessionFederatesAgain() async throws {
        try harness.signIn(work, .federated(identityId: "us-east-1:old"))
        let client = try harness.client(work)
        let next = FakePayload.federated(identityId: "us-east-1:new", version: 2)
        harness.engine(for: work)?.scriptPhase5(.federateToIdentityPool) { _ in next.data }

        let result = try await client.federateToIdentityPool(withProviderToken: "other", for: .apple)

        XCTAssertEqual(result.identityId, "us-east-1:new")
        XCTAssertEqual(try harness.storedRecord(work)?.credentials, next.data)
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .federated(identityId: "us-east-1:new"))
    }

    /// A rejected token: the plugin's `notAuthorized` (FE-1), and nothing is written.
    ///
    /// - Given: a signed-out session whose engine rejects the token as the identity pool does
    /// - When: it federates
    /// - Then:
    ///    - it throws `notAuthorized`; no record is written and the session stays signed out
    func testARejectedTokenIsNotAuthorizedAndCommitsNothing() async throws {
        let client = try harness.client(work)
        harness.engine(for: work)?.scriptPhase5(.federateToIdentityPool) { _ in
            throw SessionEngineError.service(.notAuthorized("Invalid login token.", "Check the token."))
        }

        await assertThrowsAsync({ try await client.federateToIdentityPool(withProviderToken: "bad", for: .facebook) }) { error in
            guard case .notAuthorized = authError(error) else {
                return XCTFail("\(error)")
            }
        }
        XCTAssertEqual(harness.keychain.writtenAccounts, [])
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedOut)
    }

    /// - Given: an engine that answers with a payload that is not a federation
    /// - When: the session federates
    /// - Then:
    ///    - it throws the plugin's `unknown`, and nothing is written
    func testAPayloadThatIsNotAFederationIsNeverCommitted() async throws {
        let client = try harness.client(work)
        harness.engine(for: work)?.scriptPhase5(.federateToIdentityPool) { _ in FakePayload.signedIn("mallory").data }

        await assertThrowsAsync({ try await client.federateToIdentityPool(withProviderToken: "token", for: .google) }) { error in
            XCTAssertEqual(authError(error)?.errorDescription, "Unable to parse credentials to expected output")
        }
        XCTAssertEqual(harness.keychain.writtenAccounts, [])
    }

    /// The plugin refuses a federation while a sign-in waits on a challenge (authN `.signingIn`).
    ///
    /// - Given: a session whose sign-in waits on a TOTP code
    /// - When: it federates
    /// - Then:
    ///    - it throws the plugin's `invalidState` before the engine is called; the challenge is still pending
    func testFederationRefusesASessionAwaitingAChallenge() async throws {
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        engine.scriptSignIn { _, _ in .challenge(.confirmSignInWithTOTPCode) }
        _ = try await client.signIn(username: "alice", password: "password")

        await assertThrowsAsync({ try await client.federateToIdentityPool(withProviderToken: "token", for: .google) }) { error in
            XCTAssertEqual(authError(error)?.errorDescription, "Federation could not be completed.")
        }
        XCTAssertEqual(engine.phase5Calls, [])
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .awaitingChallenge(.confirmSignInWithTOTPCode))
    }

    // MARK: Races

    /// Federation takes sign-in's guards: a sign-out while the engine works cancels it, and it never commits.
    ///
    /// - Given: a guest session whose federation is held in the engine
    /// - When: the session is signed out, then the engine answers
    /// - Then:
    ///    - the federation throws `invalidState` (cancelled); the session stays signed out with no federated
    ///      record
    func testASignOutDuringTheFederationCancelsIt() async throws {
        try harness.signIn(work, .guest(identityId: "us-east-1:guest"))
        let client = try harness.client(work)
        let gate = Gate()
        harness.engine(for: work)?.scriptPhase5(.federateToIdentityPool) { _ in
            await gate.pass()
            return FakePayload.federated().data
        }

        let federation = Task { try await client.federateToIdentityPool(withProviderToken: "token", for: .google) }
        await gate.waitForArrivals(1)
        _ = try await client.signOut()
        await gate.open()

        await assertThrowsAsync({ try await federation.value }) { error in
            guard case .invalidState(let description, _, _) = authError(error) else {
                return XCTFail("\(error)")
            }
            XCTAssertTrue(description.hasPrefix("The federation was cancelled"), description)
        }
        XCTAssertNotEqual(try harness.storedRecord(work)?.kind, .federated)
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedOut)
    }

    /// A user another writer signed in meanwhile is never overwritten (as for sign-in).
    ///
    /// - Given: a signed-out session; while its federation is in the engine, another writer stores alice
    /// - When: the federation completes
    /// - Then:
    ///    - it throws `invalidState`; alice's record is untouched, and the session reports her
    func testAFederationNeverOverwritesAUserSignedInMeanwhile() async throws {
        let client = try harness.client(work)
        let store = harness.store()
        let work = work
        harness.engine(for: work)?.scriptPhase5(.federateToIdentityPool) { _ in
            _ = try store.write(FakePayload.signedIn("alice").record(), for: work, expecting: nil)
            return FakePayload.federated().data
        }

        await assertThrowsAsync({ try await client.federateToIdentityPool(withProviderToken: "token", for: .google) }) { error in
            guard case .invalidState(let description, _, _) = authError(error) else {
                return XCTFail("\(error)")
            }
            XCTAssertTrue(description.hasPrefix("Another sign-in or federation completed"), description)
        }
        XCTAssertEqual(try harness.storedRecord(work)?.username, "alice")
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedIn(AuthClientUser(username: "alice", userId: "sub-alice")))
    }

    /// The federation being replaced, refreshed by another writer meanwhile, is still replaced: the caller
    /// asked to replace it.
    ///
    /// - Given: a federated session; while its new federation is in the engine, another writer refreshes the
    ///   old one
    /// - When: the federation completes
    /// - Then:
    ///    - the new federation is committed
    func testAFederationReplacesTheOldOneEvenIfRefreshedMeanwhile() async throws {
        let old = FakePayload.federated(identityId: "us-east-1:old")
        let envelope = try harness.signIn(work, old)
        let client = try harness.client(work)
        let next = FakePayload.federated(identityId: "us-east-1:new")
        let store = harness.store()
        let work = work
        harness.engine(for: work)?.scriptPhase5(.federateToIdentityPool) { _ in
            _ = try store.write(old.refreshed.record(), for: work, expecting: envelope.generation)
            return next.data
        }

        let result = try await client.federateToIdentityPool(withProviderToken: "token", for: .google)

        XCTAssertEqual(result.identityId, "us-east-1:new")
        XCTAssertEqual(try harness.storedRecord(work)?.credentials, next.data)
    }

    /// Holds `work`'s federations in the engine on `gate`, then answers `result`.
    private func holdFederations(on gate: Gate, answering result: @escaping @Sendable () throws -> Data) {
        harness.engine(for: work)?.scriptPhase5(.federateToIdentityPool) { _ in
            await gate.pass()
            return try result()
        }
    }

    private static func assertCancelled(_ error: Error, file: StaticString = #filePath, line: UInt = #line) {
        guard case .invalidState(let description, _, _) = authError(error) else {
            return XCTFail("\(error)", file: file, line: line)
        }
        XCTAssertTrue(description.hasPrefix("The federation was cancelled"), description, file: file, line: line)
    }

    /// A clear while a re-federation is in the engine wins: the re-federation never lands over it.
    ///
    /// - Given: a session federated as `a`, whose re-federation as `b` is held in the engine
    /// - When: the federation is cleared, then the engine answers
    /// - Then:
    ///    - the clear succeeds; the re-federation throws "cancelled"; the session stays signed out, with no
    ///      credentials stored
    func testAClearDuringARefederationWins() async throws {
        try harness.signIn(work, .federated(identityId: "us-east-1:a"))
        let client = try harness.client(work)
        let gate = Gate()
        holdFederations(on: gate) { FakePayload.federated(identityId: "us-east-1:b").data }

        let federation = Task { try await client.federateToIdentityPool(withProviderToken: "token", for: .google) }
        await gate.waitForArrivals(1)
        try await client.clearFederationToIdentityPool()
        await gate.open()

        await assertThrowsAsync({ try await federation.value }) { Self.assertCancelled($0) }
        XCTAssertNil(try harness.storedRecord(work)?.credentials)
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedOut)
    }

    /// A purge while the engine works cancels the federation, as it cancels a sign-in.
    ///
    /// - Given: a guest session whose federation is held in the engine
    /// - When: the session is purged, then the engine answers
    /// - Then:
    ///    - the federation throws "cancelled"; nothing is stored, and the session is signed out
    func testAPurgeDuringTheFederationCancelsIt() async throws {
        try harness.signIn(work, .guest(identityId: "us-east-1:guest"))
        let client = try harness.client(work)
        let gate = Gate()
        holdFederations(on: gate) { FakePayload.federated().data }

        let federation = Task { try await client.federateToIdentityPool(withProviderToken: "token", for: .google) }
        await gate.waitForArrivals(1)
        try await AmplifyCognitoClient.purgeStoredSession(
            sessionId: work,
            configuration: ClientFixtures.configuration,
            accessGroup: nil,
            dependencies: harness.dependencies
        )
        await gate.open()

        await assertThrowsAsync({ try await federation.value }) { Self.assertCancelled($0) }
        XCTAssertNil(try harness.storedRecord(work))
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedOut)
    }

    /// `deleteUser` during a federation: the session has no user pool user to delete (federation starts only
    /// from a signed-out, guest or federated session), so it is refused, ends nothing, and the federation
    /// lands.
    ///
    /// - Given: a guest session whose federation is held in the engine
    /// - When: `deleteUser` is called, then the engine answers
    /// - Then:
    ///    - `deleteUser` throws `notSignedIn` and the engine deletes nothing; the federation commits
    func testDeleteUserDuringTheFederationEndsNothing() async throws {
        try harness.signIn(work, .guest(identityId: "us-east-1:guest"))
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let gate = Gate()
        holdFederations(on: gate) { FakePayload.federated(identityId: "us-east-1:fed").data }

        let federation = Task { try await client.federateToIdentityPool(withProviderToken: "token", for: .google) }
        await gate.waitForArrivals(1)
        await assertThrowsAsync({ try await client.deleteUser() }) { error in
            guard case .notSignedIn = authError(error) else {
                return XCTFail("\(error)")
            }
        }
        await gate.open()

        let result = try await federation.value
        XCTAssertEqual(result.identityId, "us-east-1:fed")
        XCTAssertEqual(engine.deleteUserCalls.count, 0)
        XCTAssertEqual(try harness.storedRecord(work)?.kind, .federated)
    }

    /// A federation still queued for the lock when a sign-out ends the session never starts.
    ///
    /// - Given: a guest session; its first federation is held in the engine and a second is queued for the
    ///   sign-in lock
    /// - When: the session is signed out, then the engine answers
    /// - Then:
    ///    - both throw "cancelled"; the engine saw only the first; nothing federated is stored
    func testAFederationQueuedBeforeASignOutNeverStarts() async throws {
        try harness.signIn(work, .guest(identityId: "us-east-1:guest"))
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let gate = Gate()
        holdFederations(on: gate) { FakePayload.federated().data }

        let first = Task { try await client.federateToIdentityPool(withProviderToken: "first", for: .google) }
        await gate.waitForArrivals(1)
        let second = Task { try await client.federateToIdentityPool(withProviderToken: "second", for: .google) }
        await waitUntil("the second federation queues") { await client.core.signInLock.waiterCount == 1 }
        _ = try await client.signOut()
        await gate.open()

        await assertThrowsAsync({ try await first.value }) { Self.assertCancelled($0) }
        await assertThrowsAsync({ try await second.value }) { Self.assertCancelled($0) }
        XCTAssertEqual(engine.phase5Calls.count, 1)
        XCTAssertNotEqual(try harness.storedRecord(work)?.kind, .federated)
    }

    /// A different federated identity another writer stored meanwhile is never overwritten, even when the
    /// session was federated to start with (`mayReplace`): only the federation being replaced is.
    ///
    /// - Given: a session federated as `a`; while its re-federation as `b` is in the engine, another writer
    ///   stores a federation as `c`
    /// - When: the re-federation completes
    /// - Then:
    ///    - it throws `invalidState`; `c` is still stored, and the session reports `c`
    func testAFederationNeverOverwritesAnotherIdentityStoredMeanwhile() async throws {
        let envelope = try harness.signIn(work, .federated(identityId: "us-east-1:a"))
        let client = try harness.client(work)
        let other = FakePayload.federated(identityId: "us-east-1:c")
        let store = harness.store()
        let work = work
        harness.engine(for: work)?.scriptPhase5(.federateToIdentityPool) { _ in
            _ = try store.write(other.record(), for: work, expecting: envelope.generation)
            return FakePayload.federated(identityId: "us-east-1:b").data
        }

        await assertThrowsAsync({ try await client.federateToIdentityPool(withProviderToken: "token", for: .google) }) { error in
            guard case .invalidState(let description, _, _) = authError(error) else {
                return XCTFail("\(error)")
            }
            XCTAssertTrue(description.hasPrefix("Another sign-in or federation completed"), description)
        }
        XCTAssertEqual(try harness.storedRecord(work)?.credentials, other.data)
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .federated(identityId: "us-east-1:c"))
    }

    /// An engine failure that arrives after a sign-out ended the session reports the cancellation, not the
    /// failure: the caller did not cause it.
    ///
    /// - Given: a guest session whose federation is held in the engine, which then rejects the token
    /// - When: the session is signed out while it is held
    /// - Then:
    ///    - the federation throws "cancelled", not `notAuthorized`
    func testAnEngineFailureAfterASignOutIsReportedAsCancelled() async throws {
        try harness.signIn(work, .guest(identityId: "us-east-1:guest"))
        let client = try harness.client(work)
        let gate = Gate()
        holdFederations(on: gate) {
            throw SessionEngineError.service(.notAuthorized("Invalid login token.", "Check the token."))
        }

        let federation = Task { try await client.federateToIdentityPool(withProviderToken: "bad", for: .facebook) }
        await gate.waitForArrivals(1)
        _ = try await client.signOut()
        await gate.open()

        await assertThrowsAsync({ try await federation.value }) { Self.assertCancelled($0) }
    }

    /// A caller cancelled once its federation holds the lock does not drop a federation Cognito completed.
    ///
    /// - Given: a signed-out session whose federation is held in the engine
    /// - When: the caller's task is cancelled, then the engine answers
    /// - Then:
    ///    - the call still returns the federation, and it is committed
    func testACallerCancelledAfterTakingTheLockStillCommits() async throws {
        let client = try harness.client(work)
        let gate = Gate()
        holdFederations(on: gate) { FakePayload.federated(identityId: "us-east-1:fed").data }

        let federation = Task { try await client.federateToIdentityPool(withProviderToken: "token", for: .google) }
        await gate.waitForArrivals(1)
        federation.cancel()
        await gate.open()

        let result = try await federation.value
        XCTAssertEqual(result.identityId, "us-east-1:fed")
        XCTAssertEqual(try harness.storedRecord(work)?.kind, .federated)
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .federated(identityId: "us-east-1:fed"))
    }

    /// Two concurrent federations on one session run one after the other, under the sign-in lock.
    ///
    /// - Given: a signed-out session whose first federation is held in the engine
    /// - When: a second federation is started, then the first released
    /// - Then:
    ///    - the second reaches the engine only after the first has committed, with the first's payload as
    ///      `current`; the second's identity is stored
    func testConcurrentFederationsAreSerialized() async throws {
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let gate = Gate()
        let first = FakePayload.federated(identityId: "us-east-1:first")
        let second = FakePayload.federated(identityId: "us-east-1:second")
        engine.scriptPhase5(.federateToIdentityPool) { call in
            guard case .federateToIdentityPool(let request, _) = call else {
                throw FixtureError(description: "unexpected \(call)")
            }
            if request.token == "first" {
                await gate.pass()
                return first.data
            }
            return second.data
        }

        let one = Task { try await client.federateToIdentityPool(withProviderToken: "first", for: .google) }
        await gate.waitForArrivals(1)
        let two = Task { try await client.federateToIdentityPool(withProviderToken: "second", for: .google) }
        await waitUntil("the second federation queues") { await client.core.signInLock.waiterCount == 1 }
        XCTAssertEqual(engine.phase5Calls.count, 1)
        await gate.open()

        _ = try await one.value
        let result = try await two.value

        XCTAssertEqual(result.identityId, "us-east-1:second")
        XCTAssertEqual(engine.phase5Calls.last, .federateToIdentityPool(
            EngineFederationRequest(token: "second", provider: .google, developerProvidedIdentityId: nil),
            current: first.data
        ))
        XCTAssertEqual(try harness.storedRecord(work)?.credentials, second.data)
    }

    // MARK: Refresh

    /// A federated session's expired credentials are refreshed through the engine (which re-federates with
    /// the stored token), once, and committed.
    ///
    /// - Given: a federated session whose credentials need a refresh
    /// - When: its session is fetched and its credentials provider asked
    /// - Then:
    ///    - the engine refreshes the federated payload once; both answers carry the refreshed credentials,
    ///      and the refreshed payload is stored
    func testAFederatedSessionIsRefreshedThroughTheEngine() async throws {
        let stale = FakePayload.federated(identityId: "us-east-1:fed", stale: true)
        try harness.signIn(work, stale)
        let client = try harness.client(work)

        let session = try await client.fetchAuthSession()
        let credentials = try await client.credentialsProvider.resolve()

        XCTAssertEqual(harness.engine(for: work)?.refreshCalls, [stale.data])
        XCTAssertEqual(try session.awsCredentialsResult.get(), AuthClientAWSCredentials(stale.refreshed.awsCredentials))
        XCTAssertEqual(credentials as? CognitoAWSCredentials, stale.refreshed.awsCredentials)
        XCTAssertEqual(try harness.storedRecord(work)?.credentials, stale.refreshed.data)
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .federated(identityId: "us-east-1:fed"))
    }

    // MARK: Clearing

    /// - Given: a labelled federated session, and a federated `home` session
    /// - When: `work` clears its federation, then clears it again
    /// - Then:
    ///    - the row is kept, signed out, with its label; the state is `.signedOut`, `.signedOut` is sent once,
    ///      and nothing is revoked
    ///    - the second clear throws the plugin's `invalidState`
    ///    - `home` stays federated
    func testClearingKeepsTheRowSignedOutOnItsSessionOnly() async throws {
        try harness.signIn(work, .federated(identityId: "us-east-1:work"), label: "Tablet")
        try harness.signIn(home, .federated(identityId: "us-east-1:home"))
        let client = try harness.client(work)
        let other = try harness.client(home)
        _ = await client.currentSessionState()
        let events = StreamRecorder(client.listenToAuthEvents())

        try await client.clearFederationToIdentityPool()

        let record = try XCTUnwrap(harness.storedRecord(work))
        XCTAssertEqual(record.kind, SessionKind.signedOut)
        XCTAssertNil(record.credentials)
        XCTAssertEqual(record.label, "Tablet")
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedOut)
        XCTAssertEqual(harness.engine(for: work)?.revokeCalls, [])

        await assertThrowsAsync({ try await client.clearFederationToIdentityPool() }) { error in
            XCTAssertEqual(authError(error)?.errorDescription, "Clearing of federation failed.")
        }
        let otherState = await other.currentSessionState()
        XCTAssertEqual(otherState, .federated(identityId: "us-east-1:home"))
        XCTAssertEqual(try harness.storedRecord(home)?.kind, .federated)

        // Settle: a federation (no event) and a sign-out (one `.signedOut`) after both clears. The stream is in
        // order, so two events in all means the clears sent exactly one between them.
        _ = try await client.federateToIdentityPool(withProviderToken: "token", for: .google)
        _ = try await client.signOut()
        await events.waitFor(2)
        XCTAssertEqual(events.received, [.signedOut, .signedOut])
    }

    /// Federating sends no event (no user signed in); the state stream reports it. Clearing then sends
    /// `.signedOut`, and the session can federate again.
    ///
    /// - Given: a signed-out session with its event and state streams open
    /// - When: it federates, clears, and federates again
    /// - Then:
    ///    - the only event is `.signedOut`; the states are `.federated`, `.signedOut`, `.federated`
    func testTheEventsAndStatesOfAFederationAndItsClearing() async throws {
        let client = try harness.client(work)
        _ = await client.currentSessionState()
        let events = StreamRecorder(client.listenToAuthEvents())
        let states = StreamRecorder(client.listenToSessionStateChanges())

        _ = try await client.federateToIdentityPool(withProviderToken: "token", for: .google)
        try await client.clearFederationToIdentityPool()
        _ = try await client.federateToIdentityPool(withProviderToken: "token", for: .google)

        await states.waitFor(3)
        await events.waitFor(1)
        XCTAssertEqual(events.received, [.signedOut])
        XCTAssertEqual(states.received, [
            .federated(identityId: "us-east-1:federated"),
            .signedOut,
            .federated(identityId: "us-east-1:federated")
        ])
    }

    /// A user pool user another writer signed in after the state check is never cleared.
    ///
    /// - Given: a federated session whose record another writer replaces with alice
    /// - When: the federation is cleared
    /// - Then:
    ///    - it throws the plugin's `invalidState`; alice's record is untouched, and the session reports her
    func testClearingNeverSignsOutAUserSignedInMeanwhile() async throws {
        let envelope = try harness.signIn(work, .federated())
        let client = try harness.client(work)
        _ = await client.currentSessionState()
        _ = try harness.store().write(FakePayload.signedIn("alice").record(), for: work, expecting: envelope.generation)

        await assertThrowsAsync({ try await client.clearFederationToIdentityPool() }) { error in
            XCTAssertEqual(authError(error)?.errorDescription, "Clearing of federation failed.")
        }
        XCTAssertEqual(try harness.storedRecord(work)?.username, "alice")
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedIn(AuthClientUser(username: "alice", userId: "sub-alice")))
    }

    /// Only the identity the clear found is ever cleared: a different federated identity stored meanwhile is
    /// another federation, not this call's.
    ///
    /// - Given: a session federated as `a`, whose record another writer replaces with a federation as `b`
    /// - When: the federation is cleared
    /// - Then:
    ///    - it throws the plugin's `invalidState`; `b`'s record is untouched, and the session reports `b`
    func testClearingNeverRemovesADifferentFederatedIdentity() async throws {
        let envelope = try harness.signIn(work, .federated(identityId: "us-east-1:a"))
        let client = try harness.client(work)
        _ = await client.currentSessionState()
        let other = FakePayload.federated(identityId: "us-east-1:b")
        _ = try harness.store().write(other.record(), for: work, expecting: envelope.generation)

        await assertThrowsAsync({ try await client.clearFederationToIdentityPool() }) { error in
            XCTAssertEqual(authError(error)?.errorDescription, "Clearing of federation failed.")
        }
        XCTAssertEqual(try harness.storedRecord(work)?.credentials, other.data)
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .federated(identityId: "us-east-1:b"))
    }

    /// The same, when the other federation lands between the clear's read and its write (`.superseded`).
    ///
    /// - Given: a session federated as `a`; right after the clear reads the record, another writer stores a
    ///   federation as `b`
    /// - When: the federation is cleared
    /// - Then:
    ///    - it throws the plugin's `invalidState`, and `b` is still stored
    func testClearingSupersededByADifferentIdentityClearsNothing() async throws {
        try harness.signIn(work, .federated(identityId: "us-east-1:a"))
        let client = try harness.client(work)
        _ = await client.currentSessionState()
        let other = FakePayload.federated(identityId: "us-east-1:b")
        let rival = ConcurrentWriter(store: harness.store(), sessionId: work) { _ in other.record() }
        harness.keychain.onceAfterReading(harness.store().sessionAccount(for: work)) { rival.move() }

        await assertThrowsAsync({ try await client.clearFederationToIdentityPool() }) { error in
            XCTAssertEqual(authError(error)?.errorDescription, "Clearing of federation failed.")
        }
        XCTAssertEqual(rival.commits, 1)
        XCTAssertEqual(try harness.storedRecord(work)?.credentials, other.data)
    }

    /// A refresh of the same identity by another writer between the read and the write is still cleared.
    ///
    /// - Given: a session federated as `a`; right after the clear reads the record, another writer stores `a`'s
    ///   refreshed credentials
    /// - When: the federation is cleared
    /// - Then:
    ///    - the refreshed credentials are cleared too, and the session is signed out
    func testClearingSupersededByTheSameIdentityClearsIt() async throws {
        let federated = FakePayload.federated(identityId: "us-east-1:a")
        try harness.signIn(work, federated)
        let client = try harness.client(work)
        _ = await client.currentSessionState()
        let rival = ConcurrentWriter(store: harness.store(), sessionId: work) { _ in federated.refreshed.record() }
        harness.keychain.onceAfterReading(harness.store().sessionAccount(for: work)) { rival.move() }

        try await client.clearFederationToIdentityPool()

        XCTAssertEqual(rival.commits, 1)
        XCTAssertNil(try harness.storedRecord(work)?.credentials)
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedOut)
    }

    // MARK: Sign-out

    /// Signing a federated session out works as for a guest: nothing to revoke server-side (the live engine
    /// makes no call), the row is kept signed out, and `.signedOut` is sent. The plugin refuses this; the
    /// client's sign-out ends any session.
    ///
    /// - Given: a federated session
    /// - When: it signs out
    /// - Then:
    ///    - the result is `.complete`; the record holds no credentials; the state is `.signedOut`; `.signedOut`
    ///      is sent
    func testSigningOutAFederatedSession() async throws {
        try harness.signIn(work, .federated())
        let client = try harness.client(work)
        _ = await client.currentSessionState()
        let events = StreamRecorder(client.listenToAuthEvents())

        let result = try await client.signOut()

        XCTAssertEqual(result, .complete)
        XCTAssertNil(try harness.storedRecord(work)?.credentials)
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedOut)
        await events.waitFor(1)
        XCTAssertEqual(events.received, [.signedOut])
    }
}
