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

/// The public `signOut(options:)`: local, global and purging sign-out, their partial results and events.
final class SignOutOptionsTests: XCTestCase {

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

    /// Design §4.7: sign-out keeps the row by default.
    ///
    /// - Given: a signed-in, labelled session
    /// - When: it signs out with the default options
    /// - Then:
    ///    - the engine revokes locally, not globally; the result is complete; the row is kept, signed out,
    ///      with its label; the state is signed out and `.signedOut` is sent
    func testDefaultSignOutRevokesLocallyAndKeepsTheRow() async throws {
        let alice = FakePayload.signedIn("alice")
        try harness.signIn(work, alice, label: "Work")
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        _ = await client.currentSessionState()
        let events = StreamRecorder(client.listenToAuthEvents())

        let result = try await client.signOut()

        XCTAssertEqual(result, .complete)
        XCTAssertEqual(engine.revokeCalls, [alice.data])
        XCTAssertEqual(engine.revokeGlobalFlags, [false])
        XCTAssertEqual(try harness.storedRecord(work), .signedOut(label: "Work", username: "alice", userId: "sub-alice"))
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedOut)
        await events.waitFor(1)
        XCTAssertEqual(events.received, [.signedOut])
    }

    /// - Given: a signed-in session
    /// - When: it signs out globally
    /// - Then:
    ///    - the engine is asked for a global sign-out, and the session is signed out
    func testGlobalSignOutRoutesGlobalToTheEngine() async throws {
        try harness.signIn(work, .signedIn("alice"))
        let client = try harness.client(work)

        let result = try await client.signOut(options: .init(globalSignOut: true))

        XCTAssertEqual(result, .complete)
        XCTAssertEqual(harness.engine(for: work)?.revokeGlobalFlags, [true])
        XCTAssertEqual(try harness.storedRecord(work)?.isSignedOut, true)
    }

    /// The engine contract for a failed global sign-out is the plugin's — `RevokeToken` is
    /// skipped — and the outcome carries the real global error and no placeholder revoke error.
    ///
    /// - Given: a signed-in session whose global sign-out fails at Cognito, reported as the contract says
    /// - When: it signs out globally
    /// - Then:
    ///    - it is still signed out on this device, and the result is `.partial` with the global failure
    ///      only: `revokeError` is `nil`, not an empty error
    func testAFailedGlobalSignOutIsPartial() async throws {
        try harness.signIn(work, .signedIn("alice"))
        let client = try harness.client(work)
        let global = AuthClientError.service(.network, "global sign-out failed", "retry")
        harness.engine(for: work)?.scriptRevokeOutcome { _, _ in
            EngineSignOutOutcome(revokeError: nil, globalSignOutError: global)
        }

        let result = try await client.signOut(options: .init(globalSignOut: true))

        XCTAssertEqual(result, .partial(AuthClientPartialSignOut(revokeError: nil, globalSignOutError: global)))
        guard case .partial(let partial) = result else {
            return XCTFail("\(result)")
        }
        XCTAssertNil(partial.revokeError)
        XCTAssertEqual(partial.globalSignOutError?.errorDescription, "global sign-out failed")
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedOut)
    }

    /// - Given: a signed-in, labelled session
    /// - When: it signs out with `purgeStoredSession`
    /// - Then:
    ///    - it revokes, then the row is gone from storage and from the listing; `.signedOut` is sent once
    func testPurgingSignOutRemovesTheRow() async throws {
        try harness.signIn(work, .signedIn("alice"), label: "Work")
        let client = try harness.client(work)
        _ = await client.currentSessionState()
        let events = StreamRecorder(client.listenToAuthEvents())

        let result = try await client.signOut(options: .init(purgeStoredSession: true))

        XCTAssertEqual(result, .complete)
        XCTAssertEqual(harness.engine(for: work)?.revokeCalls.count, 1)
        XCTAssertEqual(try harness.store().read(work), .absent)
        XCTAssertEqual(try harness.store().storedSessions(includingSignedOut: true), [])
        await events.waitFor(1)
        XCTAssertEqual(events.received, [.signedOut])
    }

    /// - Given: a labelled signed-out row
    /// - When: it signs out with `purgeStoredSession`
    /// - Then:
    ///    - nothing is revoked and no event is sent, but the row is removed
    func testPurgingSignOutOfASignedOutRowRemovesIt() async throws {
        try harness.store().write(.signedOut(label: "Work", username: "alice"), for: work, expecting: nil)
        let client = try harness.client(work)
        let events = StreamRecorder(client.listenToAuthEvents())

        let result = try await client.signOut(options: .init(purgeStoredSession: true))

        XCTAssertEqual(result, .complete)
        XCTAssertEqual(harness.engine(for: work)?.revokeCalls, [])
        XCTAssertEqual(try harness.store().read(work), .absent)
        XCTAssertEqual(events.received, [])
    }

    /// When only the purge fails, the thrown error must not lose what the sign-out reported.
    ///
    /// - Given: a signed-in session whose revoke fails at Cognito, and whose keychain removals fail
    /// - When: it signs out with `purgeStoredSession`
    /// - Then:
    ///    - it throws `storageUnavailable`, whose underlying error is the revoke failure; the session is
    ///      signed out and its row kept
    func testAFailedPurgeCarriesThePartialSignOut() async throws {
        try harness.signIn(work, .signedIn("alice"))
        let client = try harness.client(work)
        let revoke = AuthClientError.service(.network, "revoke failed", "retry")
        harness.engine(for: work)?.scriptRevokeOutcome { _, _ in EngineSignOutOutcome(revokeError: revoke) }
        harness.keychain.failingRemovals(of: harness.store().sessionAccount(for: work), with: errSecInteractionNotAllowed)

        let error = await authClientError { try await client.signOut(options: .init(purgeStoredSession: true)) }

        XCTAssertEqual(error?.kind, .storageUnavailable(.locked))
        let underlying = error?.underlyingError as? AuthClientError
        XCTAssertEqual(underlying.map { $0.isEquivalent(to: revoke) }, true)
        harness.keychain.clearFailures()
        XCTAssertEqual(try harness.storedRecord(work)?.isSignedOut, true)
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedOut)
    }

    /// A purge must never delete another user's row.
    ///
    /// - Given: a session whose record another process replaces with a different user during the revoke
    /// - When: it signs out with `purgeStoredSession`
    /// - Then:
    ///    - the result is `.superseded`, and the other user's record is kept
    func testASupersededSignOutPurgesNothing() async throws {
        try harness.signIn(work, .signedIn("alice"))
        let client = try harness.client(work)
        let store = harness.store()
        let bob = FakePayload.signedIn("bob")
        harness.engine(for: work)?.scriptRevoke { [work] _ in
            if case .record(let envelope) = try store.read(work) {
                try store.write(bob.record(), for: work, expecting: envelope.generation)
            }
        }

        let result = try await client.signOut(options: .init(purgeStoredSession: true))

        XCTAssertEqual(result, .superseded)
        XCTAssertEqual(try harness.storedRecord(work)?.credentials, bob.data)
    }

    /// - Given: a signed-in session whose storage is locked
    /// - When: it signs out
    /// - Then:
    ///    - it throws `storageUnavailable(.locked)`, not a signed-out result, and nothing is revoked
    func testSignOutOverUnavailableStorageThrows() async throws {
        try harness.signIn(work, .signedIn("alice"))
        let client = try harness.client(work)
        harness.keychain.failing(.read, with: errSecInteractionNotAllowed)

        let error = await authClientError { try await client.signOut() }

        XCTAssertEqual(error?.kind, .storageUnavailable(.locked))
        XCTAssertEqual(harness.engine(for: work)?.revokeCalls, [])
    }

    /// Design §4.7: global sign-out crosses sessions server-side; the sibling finds out on its next
    /// refresh. Nothing client-side tells it sooner.
    ///
    /// - Given: `work` and `home` both signed in as alice
    /// - When: `work` signs out globally
    /// - Then:
    ///    - `home` is untouched: still signed in, no event, its record kept
    func testGlobalSignOutDoesNotReachIntoASiblingSession() async throws {
        try harness.signIn(work, .signedIn("alice"))
        let homeEnvelope = try harness.signIn(home, .signedIn("alice"))
        let workClient = try harness.client(work)
        let homeClient = try harness.client(home)
        _ = await homeClient.currentSessionState()
        let homeEvents = StreamRecorder(homeClient.listenToAuthEvents())

        _ = try await workClient.signOut(options: .init(globalSignOut: true))

        let homeState = await homeClient.currentSessionState()
        XCTAssertEqual(homeState, .signedIn(AuthClientUser(username: "alice", userId: "sub-alice")))
        XCTAssertEqual(homeEvents.received, [])
        XCTAssertEqual(try harness.store().read(home), .record(homeEnvelope))
        XCTAssertEqual(harness.engine(for: home)?.revokeCalls, [])
    }
}
