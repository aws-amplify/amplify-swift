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

        let result = await client.signOut()

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

        let result = await client.signOut(options: .init(globalSignOut: true))

        XCTAssertEqual(result, .complete)
        XCTAssertEqual(harness.engine(for: work)?.revokeGlobalFlags, [true])
        XCTAssertEqual(try harness.storedRecord(work)?.isSignedOut, true)
    }

    /// the engine contract for a failed global sign-out is the plugin's — `RevokeToken` is skipped — and
    /// the outcome carries the real global error beside the plugin's placeholder revoke error.
    ///
    /// - Given: a signed-in session whose global sign-out fails at Cognito, reported as the contract says
    /// - When: it signs out globally
    /// - Then:
    ///    - it is still signed out on this device, and the result is `.partial` with the global failure and the
    ///      placeholder `revokeTokenError`
    func testAFailedGlobalSignOutIsPartial() async throws {
        try harness.signIn(work, .signedIn("alice"))
        let client = try harness.client(work)
        let global = AuthClientError.service(.network, "global sign-out failed", "retry")
        let placeholder = AuthClientError.service(nil, "", "")
        harness.engine(for: work)?.scriptRevokeOutcome { _, _ in
            EngineSignOutOutcome(revokeError: placeholder, globalSignOutError: global)
        }

        let result = await client.signOut(options: .init(globalSignOut: true))

        XCTAssertEqual(result, .partialResult(revokeTokenError: placeholder, globalSignOutError: global))
        XCTAssertTrue(result.signedOutLocally)
        XCTAssertEqual(result.partialErrors?.globalSignOutError?.errorDescription, "global sign-out failed")
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

        let result = await client.signOut(options: .init(purgeStoredSession: true))

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

        let result = await client.signOut(options: .init(purgeStoredSession: true))

        XCTAssertEqual(result, .complete)
        XCTAssertEqual(harness.engine(for: work)?.revokeCalls, [])
        XCTAssertEqual(try harness.store().read(work), .absent)
        XCTAssertEqual(events.received, [])
    }

    /// when only the purge fails, the session is signed out, and the result keeps what the sign-out
    /// reported beside the purge's failure.
    ///
    /// - Given: a signed-in session whose revoke fails at Cognito, and whose keychain removals fail
    /// - When: it signs out with `purgeStoredSession`
    /// - Then:
    ///    - the result is `.partial` with the revoke failure and a `storageUnavailable(.locked)` `storageError`;
    ///      `signedOutLocally` is `true`; the session is signed out and its row kept
    func testAFailedPurgeCarriesThePartialSignOut() async throws {
        try harness.signIn(work, .signedIn("alice"))
        let client = try harness.client(work)
        let revoke = AuthClientError.service(.network, "revoke failed", "retry")
        harness.engine(for: work)?.scriptRevokeOutcome { _, _ in EngineSignOutOutcome(revokeError: revoke) }
        harness.keychain.failingRemovals(of: harness.store().sessionAccount(for: work), with: errSecInteractionNotAllowed)

        let result = await client.signOut(options: .init(purgeStoredSession: true))

        XCTAssertTrue(result.signedOutLocally)
        let partial = try XCTUnwrap(result.partialErrors, "\(result)")
        XCTAssertEqual(partial.revokeTokenError.map { $0.isEquivalent(to: revoke) }, true)
        XCTAssertNil(partial.globalSignOutError)
        XCTAssertNil(partial.hostedUIError)
        XCTAssertEqual(partial.storageError?.kind, .storageUnavailable(.locked))
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
    ///    - the result is `.failed(.invalidState)`, and the other user's record is kept
    func testASupersededSignOutPurgesNothing() async throws {
        try harness.signIn(work, .signedIn("alice"))
        let client = try harness.client(work)
        let store = harness.store()
        let bob = FakePayload.signedIn("bob")
        harness.engine(for: work)?.scriptRevoke { [work] _ in
            if case .record(let envelope) = try store.read(work) {
                try store.write(bob.record(), for: work, expecting: envelope.version)
            }
        }

        let result = await client.signOut(options: .init(purgeStoredSession: true))

        XCTAssertEqual(result, .failed(SessionSignOut.supersededError()))
        XCTAssertEqual(try harness.storedRecord(work)?.credentials, bob.data)
    }

    /// - Given: a signed-in session whose storage is locked
    /// - When: it signs out
    /// - Then:
    ///    - the result is `.failed(.storageUnavailable(.locked))`, not a signed-out result, and nothing is
    ///      revoked
    func testSignOutOverUnavailableStorageFails() async throws {
        try harness.signIn(work, .signedIn("alice"))
        let client = try harness.client(work)
        harness.keychain.failing(.read, with: errSecInteractionNotAllowed)

        let error = await failedSignOutError(client.signOut())

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
        let homeRecord = try harness.signIn(home, .signedIn("alice"))
        let homeBytes = harness.storedBytes(home)
        let workClient = try harness.client(work)
        let homeClient = try harness.client(home)
        _ = await homeClient.currentSessionState()
        let homeEvents = StreamRecorder(homeClient.listenToAuthEvents())

        _ = await workClient.signOut(options: .init(globalSignOut: true))

        let homeState = await homeClient.currentSessionState()
        XCTAssertEqual(homeState, .signedIn(AuthClientUser(username: "alice", userId: "sub-alice")))
        XCTAssertEqual(homeEvents.received, [])
        XCTAssertEqual(try harness.store().read(home), .record(homeRecord))
        XCTAssertEqual(harness.storedBytes(home), homeBytes)
        XCTAssertEqual(harness.engine(for: home)?.revokeCalls, [])
    }
}
