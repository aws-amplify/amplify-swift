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

/// `deleteUser()`: the engine call, the row removal, the event, the
/// `userNotFound` global sign-out, and the refusals.
final class DeleteUserTests: XCTestCase {

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

    /// A deleted user's row is removed, not kept signed out.
    ///
    /// - Given: a signed-in, labelled session with a pending challenge in its engine
    /// - When: the user is deleted
    /// - Then:
    ///    - the engine deletes with the session's payload; the row is gone from storage and the listing;
    ///      the state is signed out; `.userDeleted` is sent, and only it; the pending sign-in is cancelled
    func testDeleteUserRemovesTheRowAndSendsUserDeleted() async throws {
        let alice = FakePayload.signedIn("alice")
        try harness.signIn(work, alice, label: "Work")
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        _ = await client.currentSessionState()
        let events = StreamRecorder(client.listenToAuthEvents())
        let states = StreamRecorder(client.listenToSessionStateChanges())

        try await client.deleteUser()

        XCTAssertEqual(engine.deleteUserCalls, [alice.data])
        XCTAssertEqual(try harness.store().read(work), .absent)
        XCTAssertEqual(try harness.store().storedSessions(includingSignedOut: true), [])
        XCTAssertEqual(engine.cancelPendingSignInCount, 1)
        XCTAssertEqual(engine.revokeCalls, [])
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedOut)
        await events.waitFor(1)
        await states.waitFor(1)
        XCTAssertEqual(events.received, [.userDeleted])
        XCTAssertEqual(states.received, [.signedOut])
    }

    /// - Given: a signed-in session whose access token needs a refresh
    /// - When: the user is deleted
    /// - Then:
    ///    - it refreshes first, and deletes with the refreshed payload
    func testDeleteUserRefreshesFirst() async throws {
        let stale = FakePayload.signedIn("alice", stale: true)
        try harness.signIn(work, stale)
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))

        try await client.deleteUser()

        XCTAssertEqual(engine.refreshCalls, [stale.data])
        XCTAssertEqual(engine.deleteUserCalls, [stale.refreshed.data])
    }

    /// The plugin signs out globally when the user no longer exists, then rethrows. The row goes too: as with a
    /// deleted user, a row for a user who no longer exists cannot be resumed.
    ///
    /// - Given: a signed-in, labelled session whose user Cognito no longer knows
    /// - When: the user is deleted
    /// - Then:
    ///    - it throws `service(.userNotFound)`; the session was signed out globally and its row purged;
    ///      `.signedOut` is sent, not `.userDeleted`
    func testUserNotFoundSignsOutGloballyAndRethrows() async throws {
        try harness.signIn(work, .signedIn("alice"), label: "Work")
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        engine.scriptDeleteUser { _ in
            throw SessionEngineError.service(.service(.userNotFound, "User not found in the system.", "Sign up."))
        }
        _ = await client.currentSessionState()
        let events = StreamRecorder(client.listenToAuthEvents())

        let error = await authClientError { try await client.deleteUser() }

        XCTAssertEqual(error?.kind, .service(.userNotFound))
        XCTAssertEqual(engine.revokeGlobalFlags, [true])
        XCTAssertEqual(try harness.store().read(work), .absent)
        XCTAssertEqual(try harness.store().storedSessions(includingSignedOut: true), [])
        await events.waitFor(1)
        XCTAssertEqual(events.received, [.signedOut])
    }

    /// Once Cognito has deleted the user, the session reports it even when the
    /// row cannot be removed.
    ///
    /// - Given: a signed-in session with a pending challenge, whose keychain removals fail
    /// - When: the user is deleted
    /// - Then:
    ///    - it throws `storageUnavailable` saying the user was deleted; the state is signed out, `.userDeleted`
    ///      is sent, and the pending sign-in is cancelled
    func testAFailedPurgeAfterDeletionStillReportsTheDeletion() async throws {
        try harness.signIn(work, .signedIn("alice"))
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        _ = await client.currentSessionState()
        let events = StreamRecorder(client.listenToAuthEvents())
        harness.keychain.failing(.remove, with: errSecInteractionNotAllowed)

        let error = await authClientError { try await client.deleteUser() }

        XCTAssertEqual(error?.kind, .storageUnavailable(.locked))
        XCTAssertTrue(error?.errorDescription.contains("The user was deleted") == true)
        XCTAssertEqual(engine.deleteUserCalls.count, 1)
        XCTAssertEqual(engine.cancelPendingSignInCount, 1)
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedOut)
        await events.waitFor(1)
        XCTAssertEqual(events.received, [.userDeleted])
    }

    /// - Given: a signed-in session whose deletion fails with another error
    /// - When: the user is deleted
    /// - Then:
    ///    - it throws the mapped error; the session is still signed in, with its record; no event
    func testAFailedDeletionChangesNothing() async throws {
        let alice = FakePayload.signedIn("alice")
        try harness.signIn(work, alice)
        let client = try harness.client(work)
        harness.engine(for: work)?.scriptDeleteUser { _ in throw AuthClientError.notAuthorized("Access Token has been revoked", "Sign in again.") }
        let events = StreamRecorder(client.listenToAuthEvents())

        let error = await authClientError { try await client.deleteUser() }

        XCTAssertEqual(error?.kind, .notAuthorized)
        XCTAssertEqual(try harness.storedRecord(work)?.credentials, alice.data)
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedIn(AuthClientUser(username: "alice", userId: "sub-alice")))
        XCTAssertEqual(events.received, [])
    }

    /// - Given: a signed-out session, a guest session, and a configuration without a user pool
    /// - When: each deletes its user
    /// - Then:
    ///    - the first two throw `notSignedIn`, the third `configuration`; the engine is never called
    func testDeleteUserNeedsASignedInUser() async throws {
        try harness.signIn(home, .guest())
        let signedOut = try harness.client(work)
        let guest = try harness.client(home)
        let noPool = try harness.client(
            ClientFixtures.id("pool"),
            configuration: ClientFixtures.identityPoolOnlyConfiguration
        )

        let signedOutError = await authClientError { try await signedOut.deleteUser() }
        let guestError = await authClientError { try await guest.deleteUser() }
        let noPoolError = await authClientError { try await noPool.deleteUser() }

        XCTAssertEqual(signedOutError?.kind, .notSignedIn)
        XCTAssertEqual(guestError?.kind, .notSignedIn)
        XCTAssertEqual(noPoolError?.kind, .configuration)
        XCTAssertEqual(harness.engines.flatMap(\.deleteUserCalls), [])
    }

    /// - Given: a signed-in session whose storage is locked
    /// - When: the user is deleted
    /// - Then:
    ///    - it throws `storageUnavailable(.locked)`, never `notSignedIn`, and deletes nothing
    func testUnavailableStorageThrows() async throws {
        try harness.signIn(work, .signedIn("alice"))
        let client = try harness.client(work)
        harness.keychain.failing(.read, with: errSecInteractionNotAllowed)

        let error = await authClientError { try await client.deleteUser() }

        XCTAssertEqual(error?.kind, .storageUnavailable(.locked))
        XCTAssertEqual(harness.engine(for: work)?.deleteUserCalls, [])
    }

    /// - Given: a signed-in session, and another process that signs a different user in once the payload
    ///   has been read
    /// - When: the user is deleted
    /// - Then:
    ///    - it throws `invalidState`, deletes nobody, and the other user stays signed in
    func testADifferentUserSignedInMeanwhileIsNotDeleted() async throws {
        try harness.signIn(work, .signedIn("alice"))
        let client = try harness.client(work)
        _ = await client.currentSessionState()
        let store = harness.store()
        let bob = FakePayload.signedIn("bob")
        if case .record(let envelope) = try store.read(work) {
            try store.write(bob.record(), for: work, expecting: envelope.generation)
        }

        let error = await authClientError { try await client.deleteUser() }

        XCTAssertEqual(error?.kind, .invalidState)
        XCTAssertEqual(harness.engine(for: work)?.deleteUserCalls, [])
        XCTAssertEqual(try harness.storedRecord(work)?.credentials, bob.data)
    }

    /// The deletion is irreversible server-side, so the caller's cancellation must not stop it
    /// half-way, with the user deleted and the row kept.
    ///
    /// - Given: a signed-in session whose deletion is held in an engine that honours cancellation
    /// - When: the caller is cancelled while it is held, and the deletion is let go
    /// - Then:
    ///    - the deletion still completes: the row is removed and `.userDeleted` is sent
    func testACancelledCallerDoesNotStopTheDeletion() async throws {
        try harness.signIn(work, .signedIn("alice"))
        let client = try harness.client(work)
        _ = await client.currentSessionState()
        let events = StreamRecorder(client.listenToAuthEvents())
        let latch = Gate()
        harness.engine(for: work)?.scriptDeleteUser { _ in
            await latch.pass()
            try Task.checkCancellation()
        }

        let deletion = Task { try await client.deleteUser() }
        await latch.waitForArrivals(1)
        deletion.cancel()
        await latch.open()
        _ = try? await deletion.value

        await events.waitFor(1)
        XCTAssertEqual(events.received, [.userDeleted])
        XCTAssertEqual(try harness.store().read(work), .absent)
    }

    /// The deletion runs under the record's gate, so it never interleaves with another operation on the
    /// same record, and never delays another session's.
    ///
    /// - Given: `work` and `home` signed in, with `work`'s deletion held in the engine
    /// - When: `home` is signed out while it is held, then the deletion is let go
    /// - Then:
    ///    - `home` signs out without waiting; `work`'s gate is held throughout the deletion
    func testDeletionHoldsOnlyItsOwnRecordsGate() async throws {
        try harness.signIn(work, .signedIn("alice"))
        try harness.signIn(home, .signedIn("bob"))
        let workClient = try harness.client(work)
        let homeClient = try harness.client(home)
        let latch = Gate()
        harness.engine(for: work)?.scriptDeleteUser { _ in await latch.pass() }

        let deletion = Task { try await workClient.deleteUser() }
        await latch.waitForArrivals(1)
        let held = await workClient.core.gate.isLocked
        let homeResult = try await homeClient.signOut()
        await latch.open()
        try await deletion.value

        XCTAssertTrue(held)
        XCTAssertEqual(homeResult, .complete)
        XCTAssertEqual(try harness.store().read(work), .absent)
    }
}
