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

/// `signIn`: the request the engine receives, the commit, the per-session refusal, the guest seed, the
/// errors, and the commit that loses its race.
final class SignInTests: XCTestCase {

    private var harness: ClientHarness!
    private let work = ClientFixtures.id("work")
    private let home = ClientFixtures.id("home")
    private let alice = AuthClientUser(username: "alice", userId: "sub-alice")

    override func setUp() {
        harness = ClientHarness()
    }

    override func tearDown() async throws {
        harness.keychain.clearFailures()
        harness.keychain.afterEveryRead(of: harness.store().sessionAccount(for: work), nil)
        await harness.waitForBaseline()
        harness = nil
    }

    // MARK: Completion

    /// - Given: a signed-out session with a labelled row
    /// - When: a user signs in
    /// - Then:
    ///    - the engine receives the username, password, flow and metadata, with no guest seed
    ///    - the result is done; the record holds the payload, the user and the label
    ///    - the state becomes `.signedIn(user)` and `.signedIn` is sent once
    func testSignInCommitsTheSessionAndSendsSignedIn() async throws {
        try harness.store().write(.signedOut(label: "Work", username: nil), for: work, expecting: nil)
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let events = StreamRecorder(client.listenToAuthEvents())
        let states = StreamRecorder(client.listenToSessionStateChanges())
        _ = await client.currentSessionState()

        let result = try await client.signIn(
            username: "alice",
            password: "hunter2",
            options: .init(authFlowType: .userPassword, clientMetadata: ["k": "v"])
        )

        XCTAssertEqual(result.nextStep, .done)
        let call = try XCTUnwrap(engine.signInCalls.first)
        XCTAssertEqual(call.request, EngineSignInRequest(
            username: "alice",
            password: "hunter2",
            authFlowType: .userPassword,
            clientMetadata: ["k": "v"]
        ))
        XCTAssertNil(call.current)
        XCTAssertEqual(try harness.storedRecord(work), FakePayload.signedIn("alice").record(label: "Work"))
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedIn(alice))
        await events.waitFor(1)
        await states.waitFor(2)
        XCTAssertEqual(events.received, [.signedIn])
        XCTAssertEqual(states.received, [.signedOut, .signedIn(alice)])
    }

    /// - Given: a session that signed in
    /// - When: its providers and `getCurrentUser` are asked
    /// - Then:
    ///    - they vend the signed-in user's credentials, with no refresh
    func testASignedInSessionVendsItsCredentials() async throws {
        let client = try harness.client(work)
        try await client.signInForTest("alice")

        let credentials = try await client.credentialsProvider.resolve()
        let token = try await client.userPoolTokenProvider.accessToken()
        let user = try await client.getCurrentUser()

        XCTAssertEqual(credentials as? CognitoAWSCredentials, FakePayload.signedIn("alice").awsCredentials)
        XCTAssertEqual(token, "access-alice-v1")
        XCTAssertEqual(user, alice)
        XCTAssertEqual(harness.engine(for: work)?.refreshCalls, [])
    }

    // MARK: Validation and refusal

    /// - Given: a session
    /// - When: `signIn` is called with an empty username
    /// - Then:
    ///    - it throws `validation(field: "username")` with the plugin's strings, and the engine is not called
    func testEmptyUsernameIsAValidationError() async throws {
        let client = try harness.client(work)

        let error = await authClientError { try await client.signIn(username: "", password: "p") }

        XCTAssertEqual(error?.kind, .validation(field: "username"))
        XCTAssertEqual(error?.errorDescription, "Username is required to signIn")
        XCTAssertEqual(harness.engine(for: work)?.signInCalls.count, 0)
    }

    /// - Given: a configuration with only an identity pool
    /// - When: `signIn` is called
    /// - Then:
    ///    - it throws `configuration`, and the engine is not called
    func testSignInWithoutAUserPoolIsAConfigurationError() async throws {
        let client = try harness.client(work, configuration: ClientFixtures.identityPoolOnlyConfiguration)

        let error = await authClientError { try await client.signInForTest() }

        XCTAssertEqual(error?.kind, .configuration)
        XCTAssertEqual(harness.engine(for: work)?.signInCalls.count, 0)
    }

    /// The plugin refuses whenever its one machine is signed in. The client refuses only when this
    /// session is.
    ///
    /// - Given: `work` signed in as alice, and `home` signed out
    /// - When: `work` and `home` each sign in
    /// - Then:
    ///    - `work` throws `invalidState` with the plugin's message and its engine is not called
    ///    - `home` signs in as bob; `work` still holds alice
    func testRefusalIsPerSession() async throws {
        try harness.signIn(work, .signedIn("alice"))
        let workClient = try harness.client(work)
        let homeClient = try harness.client(home)

        let error = await authClientError { try await workClient.signInForTest("carol") }
        let result = try await homeClient.signInForTest("bob")

        XCTAssertEqual(error?.kind, .invalidState)
        XCTAssertEqual(
            error?.errorDescription,
            "There is already a user in signedIn state. SignOut the user first before calling signIn"
        )
        XCTAssertEqual(harness.engine(for: work)?.signInCalls.count, 0)
        XCTAssertEqual(result.nextStep, .done)
        XCTAssertEqual(try harness.storedRecord(work)?.username, "alice")
        let homeState = await homeClient.currentSessionState()
        XCTAssertEqual(homeState, .signedIn(AuthClientUser(username: "bob", userId: "sub-bob")))
    }

    /// An expired session stays `.signedIn(user)` so the app knows whom to re-authenticate. It must
    /// be able to.
    ///
    /// - Given: a signed-in session whose refresh token proved dead
    /// - When: the user signs in again
    /// - Then:
    ///    - it is not refused; the fresh credentials are committed and the providers work again
    func testAnExpiredSessionCanSignInAgain() async throws {
        try harness.signIn(work, .signedIn("alice", stale: true), label: "Alice at work")
        let client = try harness.client(work)
        harness.engine(for: work)?.scriptRefresh { _ in throw SessionEngineError.refreshTokenInvalid }
        _ = try? await client.userPoolTokenProvider.accessToken()

        let result = try await client.signInForTest("alice")

        XCTAssertEqual(result.nextStep, .done)
        let token = try await client.userPoolTokenProvider.accessToken()
        XCTAssertEqual(token, "access-alice-v1")
        XCTAssertEqual(try harness.storedRecord(work)?.label, "Alice at work")
    }

    /// A different user may sign in over an expired session. The row is
    /// replaced, and its label, which named the previous user, is cleared.
    ///
    /// - Given: a labelled session whose user's refresh token proved dead
    /// - When: a different user signs in to it
    /// - Then:
    ///    - it is not refused; the row now holds the new user, with no label; the state is the new user
    func testADifferentUserSigningInOverAnExpiredSessionClearsTheLabel() async throws {
        try harness.signIn(work, .signedIn("alice", stale: true), label: "Alice at work")
        let client = try harness.client(work)
        harness.engine(for: work)?.scriptRefresh { _ in throw SessionEngineError.refreshTokenInvalid }
        _ = try? await client.userPoolTokenProvider.accessToken()

        try await client.signInForTest("bob")

        XCTAssertEqual(try harness.storedRecord(work), FakePayload.signedIn("bob").record(label: nil))
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedIn(AuthClientUser(username: "bob", userId: "sub-bob")))
    }

    // MARK: Guest

    /// Design §4.4: guest browsing, then signing in, is one session.
    ///
    /// - Given: a guest session
    /// - When: a user signs in
    /// - Then:
    ///    - the engine is seeded with the guest payload; the guest record is replaced in place; the state
    ///      goes from `.guest` to `.signedIn`; the registry still holds one session
    func testGuestSignInKeepsOneSession() async throws {
        let guest = FakePayload.guest(identityId: "us-east-1:guest")
        try harness.signIn(work, guest)
        let client = try harness.client(work)
        let before = await client.currentSessionState()

        try await client.signInForTest("alice")

        XCTAssertEqual(before, .guest)
        XCTAssertEqual(harness.engine(for: work)?.signInCalls.first?.current, guest.data)
        XCTAssertEqual(try harness.storedRecord(work)?.username, "alice")
        let listed = try harness.store().storedSessions(includingSignedOut: true)
        XCTAssertEqual(listed.map(\.sessionId), [work])
        XCTAssertEqual(harness.registry.entryCount, 1)
        let after = await client.currentSessionState()
        XCTAssertEqual(after, .signedIn(alice))
    }

    // MARK: Storage and errors

    /// Storage that cannot be read is never taken for signed out, so a sign-in cannot proceed over it.
    ///
    /// - Given: a session whose storage is locked
    /// - When: a user signs in
    /// - Then:
    ///    - it throws `storageUnavailable(.locked)`, and the engine is not called
    func testUnavailableStorageIsNotSignedOut() async throws {
        try harness.signIn(work, .signedIn("alice"))
        let client = try harness.client(work)
        harness.keychain.failing(.read, with: errSecInteractionNotAllowed)

        let error = await authClientError { try await client.signInForTest("bob") }

        XCTAssertEqual(error?.kind, .storageUnavailable(.locked))
        XCTAssertEqual(harness.engine(for: work)?.signInCalls.count, 0)
    }

    /// - Given: a session that signs in successfully at Cognito, but whose record cannot be written
    /// - When: the result is committed
    /// - Then:
    ///    - it throws `storageUnavailable`; no `.signedIn` is sent and the state is not signed in
    ///    - the fresh tokens, which nothing holds, are revoked
    func testACommitThatCannotBeSavedThrowsTheStorageError() async throws {
        let client = try harness.client(work)
        _ = await client.currentSessionState()
        let events = StreamRecorder(client.listenToAuthEvents())
        harness.keychain.failing(.write, with: errSecInteractionNotAllowed)

        let error = await authClientError { try await client.signInForTest("alice") }

        XCTAssertEqual(error?.kind, .storageUnavailable(.locked))
        XCTAssertEqual(harness.engine(for: work)?.revokeCalls, [FakePayload.signedIn("alice").data])
        harness.keychain.clearFailures()
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedOut)
        XCTAssertEqual(events.received, [])
    }

    /// - Given: a session whose saved record is corrupt
    /// - When: a user signs in
    /// - Then:
    ///    - it throws the record's own error rather than write over it, which the store would refuse
    func testAnUnreadableRecordIsNotSignedInOver() async throws {
        harness.keychain.put(Data("not a record".utf8), harness.store().sessionAccount(for: work))
        let client = try harness.client(work)

        let error = await authClientError { try await client.signInForTest("alice") }

        XCTAssertEqual(error?.kind, .unknown)
        XCTAssertEqual(harness.engine(for: work)?.signInCalls.count, 0)
    }

    /// - Given: engine sign-ins that fail with a mapped error, a seam error, and an unmapped error
    /// - When: each is surfaced
    /// - Then:
    ///    - an `AuthClientError` passes through; `SessionEngineError.service` is unwrapped; anything else
    ///      is `unknown` with the engine's error underneath. Nothing is committed, no event is sent
    func testEngineFailuresAreMapped() async throws {
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let events = StreamRecorder(client.listenToAuthEvents())

        engine.scriptSignIn { _, _ in throw AuthClientError.notAuthorized("Incorrect username or password.", "Check them.") }
        let notAuthorized = await authClientError { try await client.signInForTest() }
        engine.scriptSignIn { _, _ in
            throw SessionEngineError.service(.service(.userNotConfirmed, "not confirmed", "confirm"))
        }
        let service = await authClientError { try await client.signInForTest() }
        engine.scriptSignIn { _, _ in throw FixtureError(description: "engine bug") }
        let unknown = await authClientError { try await client.signInForTest() }

        XCTAssertEqual(notAuthorized?.kind, .notAuthorized)
        XCTAssertEqual(notAuthorized?.errorDescription, "Incorrect username or password.")
        XCTAssertEqual(service?.kind, .service(.userNotConfirmed))
        XCTAssertEqual(unknown?.kind, .unknown)
        XCTAssertTrue(unknown?.underlyingError is FixtureError)
        XCTAssertNil(try harness.storedRecord(work))
        XCTAssertEqual(events.received, [])
    }

    /// A sign-in Cognito completed must not be lost because the caller stopped waiting: the
    /// engine step runs in the same unstructured task as the commit, so the caller's cancellation never
    /// reaches it.
    ///
    /// - Given: a sign-in held inside an engine that honours cancellation
    /// - When: the calling task is cancelled, then the engine completes
    /// - Then:
    ///    - the engine step was not cancelled; the sign-in is still committed and `.signedIn` is sent
    func testACancelledCallerDoesNotLoseACompletedSignIn() async throws {
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let latch = Gate()
        engine.holdSignIns(on: latch, honouringCancellation: true)
        let events = StreamRecorder(client.listenToAuthEvents())

        let signIn = Task { try await client.signInForTest("alice") }
        await latch.waitForArrivals(1)
        signIn.cancel()
        await latch.open()
        _ = try? await signIn.value

        await events.waitFor(1)
        XCTAssertEqual(events.received, [.signedIn])
        XCTAssertEqual(try harness.storedRecord(work)?.username, "alice")
    }

    /// The network step runs outside the record's gate; only the commit takes it.
    ///
    /// - Given: a session whose record gate is held by another operation
    /// - When: a user signs in
    /// - Then:
    ///    - the engine is reached while the gate is held; the commit waits for the gate, and the session is
    ///      signed in only after it is released
    func testTheCommitWaitsForTheRecordGateButTheNetworkStepDoesNot() async throws {
        let client = try harness.client(work)
        _ = await client.currentSessionState()
        let engine = try XCTUnwrap(harness.engine(for: work))
        let holder = Gate()
        let holding = Task { try await client.core.gate.withLock { await holder.pass() } }
        await holder.waitForArrivals(1)

        let signIn = Task { try await client.signInForTest("alice") }
        await waitUntil("the sign-in reaches the engine") { engine.signInCalls.count == 1 }
        await waitUntil("the commit queues on the gate") { await client.core.gate.waiterCount == 1 }
        let during = await client.currentSessionState()
        await holder.open()
        try await holding.value
        _ = try await signIn.value

        XCTAssertEqual(during, .signedOut)
        let after = await client.currentSessionState()
        XCTAssertEqual(after, .signedIn(alice))
    }

    // MARK: The commit lost its race

    /// - Given: a sign-in during which another process wrote a labelled signed-out row
    /// - When: the sign-in commits
    /// - Then:
    ///    - its first write is discarded; it re-reads and writes again against the new generation, keeping
    ///      the label
    func testADiscardedCommitOverASignedOutRowWritesAgain() async throws {
        let client = try harness.client(work)
        _ = await client.currentSessionState()
        let store = harness.store()
        harness.engine(for: work)?.scriptSignIn { [work] request, _ in
            try store.write(.signedOut(label: "Other", username: nil), for: work, expecting: nil)
            return .done(payload: FakePayload.signedIn(request.username).data)
        }

        try await client.signInForTest("alice")

        XCTAssertEqual(try harness.storedRecord(work), FakePayload.signedIn("alice").record(label: "Other"))
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedIn(alice))
    }

    /// - Given: a sign-in as alice during which another process stored alice's older credentials
    /// - When: the sign-in commits
    /// - Then:
    ///    - it writes ours over them: the same user, and ours is the sign-in the caller asked for
    func testADiscardedCommitOverTheSamePrincipalWritesOurs() async throws {
        let client = try harness.client(work)
        _ = await client.currentSessionState()
        let store = harness.store()
        let theirs = FakePayload.signedIn("alice", version: 7)
        harness.engine(for: work)?.scriptSignIn { [work] request, _ in
            try store.write(theirs.record(), for: work, expecting: nil)
            return .done(payload: FakePayload.signedIn(request.username).data)
        }

        try await client.signInForTest("alice")

        XCTAssertEqual(try harness.storedRecord(work)?.credentials, FakePayload.signedIn("alice").data)
        // The replaced sign-in's tokens now have no holder, so they are revoked.
        XCTAssertEqual(harness.engine(for: work)?.revokeCalls, [theirs.data])
    }

    /// In one process: two sign-ins of the same user at once, from two handles.
    ///
    /// - Given: a signed-out session, with the first sign-in held in the engine
    /// - When: a second handle signs the same user in, then the first is let go
    /// - Then:
    ///    - the second waits for the first and is refused once it has signed in; only one sign-in reached
    ///      the engine, so no tokens are orphaned
    func testTwoConcurrentSignInsOfTheSameUserLeaveNoOrphan() async throws {
        let first = try harness.client(work)
        let second = try harness.client(work)
        _ = await first.currentSessionState()
        let engine = try XCTUnwrap(harness.engine(for: work))
        let latch = Gate()
        engine.holdSignIns(on: latch)

        let firstSignIn = Task { try await first.signInForTest("alice") }
        await latch.waitForArrivals(1)
        let secondSignIn = Task { try await second.signInForTest("alice") }
        await waitUntil("the second sign-in queues behind the first") {
            await first.core.signInLock.waiterCount == 1
        }
        await latch.open()
        _ = try await firstSignIn.value
        let error = await authClientError { try await secondSignIn.value }

        XCTAssertEqual(error?.kind, .invalidState)
        XCTAssertEqual(engine.signInCalls.count, 1)
        XCTAssertEqual(engine.revokeCalls, [])
        XCTAssertEqual(try harness.storedRecord(work)?.credentials, FakePayload.signedIn("alice").data)
    }

    /// - Given: a sign-in as alice during which another process signed bob in to the same session ID
    /// - When: the sign-in commits
    /// - Then:
    ///    - bob is not overwritten; alice's fresh tokens are revoked; it throws `invalidState`; the state
    ///      is bob; no `.signedIn` is sent
    func testADiscardedCommitOverADifferentPrincipalLeavesThemSignedIn() async throws {
        let client = try harness.client(work)
        _ = await client.currentSessionState()
        let engine = try XCTUnwrap(harness.engine(for: work))
        let events = StreamRecorder(client.listenToAuthEvents())
        let store = harness.store()
        let bob = FakePayload.signedIn("bob")
        engine.scriptSignIn { [work] request, _ in
            try store.write(bob.record(), for: work, expecting: nil)
            return .done(payload: FakePayload.signedIn(request.username).data)
        }

        let error = await authClientError { try await client.signInForTest("alice") }

        XCTAssertEqual(error?.kind, .invalidState)
        XCTAssertEqual(error?.errorDescription, "Another sign-in completed for this session while this one was in progress")
        XCTAssertEqual(try harness.storedRecord(work)?.credentials, bob.data)
        XCTAssertEqual(engine.revokeCalls, [FakePayload.signedIn("alice").data])
        XCTAssertEqual(engine.revokeGlobalFlags, [false])
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedIn(AuthClientUser(username: "bob", userId: "sub-bob")))
        XCTAssertEqual(events.received, [])
    }

    /// - Given: a sign-in whose record another writer changes on every read
    /// - When: the sign-in commits
    /// - Then:
    ///    - it gives up after three writes with `storageUnavailable(.interrupted)`
    func testACommitThatKeepsLosingGivesUp() async throws {
        try harness.store().write(.signedOut(label: "L", username: nil), for: work, expecting: nil)
        let client = try harness.client(work)
        _ = await client.currentSessionState()
        let store = harness.store()
        let rival = ConcurrentWriter(store: store, sessionId: work, budget: 100) { envelope in
            var record = envelope.record
            record.label = "L\(envelope.generation)"
            return record
        }
        harness.engine(for: work)?.scriptSignIn { [keychain = harness.keychain, work] request, _ in
            keychain.afterEveryRead(of: store.sessionAccount(for: work)) { rival.move() }
            return .done(payload: FakePayload.signedIn(request.username).data)
        }

        let error = await authClientError { try await client.signInForTest("alice") }

        XCTAssertEqual(error?.kind, .storageUnavailable(.interrupted))
        XCTAssertEqual(try harness.storedRecord(work)?.isSignedOut, true)
        XCTAssertEqual(harness.engine(for: work)?.revokeCalls, [FakePayload.signedIn("alice").data])
    }
}
