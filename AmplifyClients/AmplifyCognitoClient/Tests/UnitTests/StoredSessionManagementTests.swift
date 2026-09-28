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

/// The static session-management calls, and sign-out's handling of a concurrent writer.
final class StoredSessionManagementTests: XCTestCase {

    private var harness: ClientHarness!
    private let work = ClientFixtures.id("work")
    private let home = ClientFixtures.id("home")
    private var pluginAccount: String { SessionRecordKey.legacySessionAccount(in: StorageFixtures.pools) }

    override func setUp() {
        harness = ClientHarness()
    }

    override func tearDown() async throws {
        harness.keychain.clearFailures()
        await harness.waitForBaseline()
        harness = nil
    }

    // MARK: Calls under test

    private func storedSessions(accessGroup: String? = nil, includingSignedOut: Bool = false) async throws -> [StoredSession] {
        try await AmplifyCognitoClient.storedSessions(
            configuration: ClientFixtures.configuration,
            accessGroup: accessGroup,
            includingSignedOut: includingSignedOut,
            dependencies: harness.dependencies
        )
    }

    private func purge(_ sessionId: SessionID, accessGroup: String? = nil) async throws {
        try await AmplifyCognitoClient.purgeStoredSession(
            sessionId: sessionId,
            configuration: ClientFixtures.configuration,
            accessGroup: accessGroup,
            dependencies: harness.dependencies
        )
    }

    private func signOut(_ sessionId: SessionID, accessGroup: String? = nil) async throws -> AuthClientSignOutResult {
        try await AmplifyCognitoClient.signOutStoredSession(
            sessionId: sessionId,
            configuration: ClientFixtures.configuration,
            accessGroup: accessGroup,
            dependencies: harness.dependencies
        )
    }

    // MARK: Listing

    /// - Given: a signed-in session, a signed-out row with a label, and a session in a shared access group
    /// - When: saved sessions are listed with and without signed-out rows, and for the access group
    /// - Then:
    ///    - the default hides the signed-out row, `includingSignedOut: true` shows it, and each access
    ///      group sees only its own sessions
    func testListingWrapsTheStoreAndIsScopedToTheAccessGroup() async throws {
        try harness.signIn(work, .signedIn("alice"))
        try harness.store().write(.signedOut(label: "Home", username: "bob"), for: home, expecting: nil)
        try harness.signIn(ClientFixtures.id("shared"), .signedIn("carol"), accessGroup: "group.shared")

        let signedIn = try await storedSessions()
        let all = try await storedSessions(includingSignedOut: true)
        let shared = try await storedSessions(accessGroup: "group.shared")

        XCTAssertEqual(signedIn.map(\.sessionId), [work])
        XCTAssertEqual(all.map(\.sessionId), [home, work])
        XCTAssertEqual(all.first?.label, "Home")
        XCTAssertEqual(shared.map(\.username), ["carol"])
    }

    /// - Given: saved sessions, and a keychain whose listing fails as if locked
    /// - When: saved sessions are listed
    /// - Then:
    ///    - it throws `storageUnavailable(.locked)`, never `[]`
    func testListingFailureThrowsRatherThanReturningNothing() async throws {
        try harness.signIn(work, .signedIn("alice"))
        harness.keychain.failing(.list, with: errSecInteractionNotAllowed)

        await assertThrowsAsync({ try await self.storedSessions() }) { error in
            XCTAssertEqual((error as? AuthClientError)?.storageUnavailableReason, .locked, "\(error)")
        }
    }

    // MARK: Purge

    /// - Given: a saved session no client holds, and `.default` reading through to the plugin's record
    /// - When: both are purged
    /// - Then:
    ///    - their records are gone, the plugin's included, and no session was built to do it
    func testPurgeWithNoLiveSessionDeletesTheRecords() async throws {
        try harness.signIn(work, .signedIn("alice"))
        harness.keychain.put(FakePayload.signedIn("alice").data, pluginAccount)

        try await purge(work)
        try await purge(.default)

        XCTAssertEqual(try harness.store().read(work), .absent)
        XCTAssertEqual(try harness.store().read(.default), .absent)
        XCTAssertNil(harness.keychain.value(pluginAccount))
        XCTAssertEqual(harness.engines.count, 0)
    }

    /// - Given: a live, signed-in session with a pending challenge and an event subscriber
    /// - When: it is purged through the static call
    /// - Then:
    ///    - the purge goes through the live session: its record is gone, its pending sign-in is
    ///      cancelled, it sends `.signedOut` and is now `.signedOut`, and its provider throws `notSignedIn`
    func testPurgeRoutesThroughALiveSession() async throws {
        try harness.signIn(work, .signedIn("alice"))
        let client = try harness.client(work)
        _ = await client.currentSessionState()
        let events = StreamRecorder(client.listenToAuthEvents())
        let provider = client.credentialsProvider

        try await purge(work)

        await events.waitFor(1)
        XCTAssertEqual(events.received, [.signedOut])
        XCTAssertEqual(try harness.store().read(work), .absent)
        XCTAssertEqual(harness.engine(for: work)?.cancelPendingSignInCount, 1)
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedOut)
        await assertThrowsAsync({ try await provider.resolve() }) { error in
            XCTAssertEqual((error as? CredentialsError)?.isNotSignedIn, true, "\(error)")
        }
    }

    /// A session registered while a static purge holds the record's gate is blocked in its restore until
    /// the purge commits, so it reads nothing rather than the record being deleted.
    ///
    /// - Given: a saved session no client holds, and a hook that constructs a client for it and starts
    ///   reading its state just as the static purge is deleting the record
    /// - When: the session is purged
    /// - Then:
    ///    - the new session restores as `.signedOut`, sends no event, and the record stays gone
    func testSessionBuiltDuringAPurgeRestoresAbsent() async throws {
        try harness.signIn(work, .signedIn("alice"))
        let harness = harness!
        let work = work
        let reader = ReaderBox()
        harness.keychain.onceBeforeRemoving(harness.store().sessionAccount(for: work)) {
            do {
                let client = try harness.client(work)
                reader.start(client)
            } catch {
                XCTFail("construction during the purge failed: \(error)")
            }
        }

        try await purge(work)

        let state = try await reader.state()
        XCTAssertEqual(state, .signedOut)
        XCTAssertEqual(reader.events.received, [])
        XCTAssertEqual(try harness.store().read(work), .absent)
    }

    /// The commit guard is the backstop: a live session's next write after an out-of-band purge re-reads
    /// and finds nothing, so it can never resurrect the purged credentials.
    ///
    /// - Given: a restored session whose credentials need a refresh, and its record purged by another
    ///   process behind its back
    /// - When: its provider is asked for credentials
    /// - Then:
    ///    - it throws `notSignedIn`, no refresh is attempted, and the record stays absent
    func testStaleSessionNeverResurrectsAPurgedRecord() async throws {
        try harness.signIn(work, .signedIn("alice", stale: true))
        let client = try harness.client(work)
        _ = await client.currentSessionState()
        try harness.store().purge(work)

        await assertThrowsAsync({ try await client.credentialsProvider.resolve() }) { error in
            XCTAssertEqual((error as? CredentialsError)?.isNotSignedIn, true, "\(error)")
        }

        XCTAssertEqual(harness.engine(for: work)?.refreshCalls.count, 0)
        XCTAssertEqual(try harness.store().read(work), .absent)
    }

    /// The access group selects the record, so each static call acts on its own group's copy only.
    ///
    /// - Given: a saved `"work"` in the unshared namespace and another in a shared access group, and no
    ///   live client
    /// - When: the shared one is purged
    /// - Then:
    ///    - only the shared record is gone
    func testPurgeIsScopedToTheAccessGroup() async throws {
        try harness.signIn(work, .signedIn("alice"))
        try harness.signIn(work, .signedIn("carol"), accessGroup: "group.shared")

        try await purge(work, accessGroup: "group.shared")

        XCTAssertEqual(try harness.store(accessGroup: "group.shared").read(work), .absent)
        XCTAssertEqual(try harness.storedRecord(work), FakePayload.signedIn("alice").record())
    }

    /// - Given: a saved `"work"` in the unshared namespace and another in a shared access group, and no
    ///   live client
    /// - When: the shared one is signed out through the static call
    /// - Then:
    ///    - only the shared copy's credentials were revoked and cleared, and the unshared one is untouched
    func testStaticSignOutIsScopedToTheAccessGroup() async throws {
        let carol = FakePayload.signedIn("carol")
        try harness.signIn(work, .signedIn("alice"))
        try harness.signIn(work, carol, accessGroup: "group.shared")

        let result = try await signOut(work, accessGroup: "group.shared")

        XCTAssertEqual(result, .complete)
        XCTAssertEqual(harness.revoker.revokeCalls, [carol.data])
        XCTAssertEqual(try harness.storedRecord(work, accessGroup: "group.shared")?.isSignedOut, true)
        XCTAssertEqual(try harness.storedRecord(work), FakePayload.signedIn("alice").record())
    }

    /// - Given: a live session for `"work"` in the unshared namespace, and a saved `"work"` in a shared
    ///   access group
    /// - When: the shared one is purged
    /// - Then:
    ///    - only the shared record is gone; the live session, its record and its streams are untouched
    func testPurgeOfAnotherNamespaceLeavesTheLiveSessionAlone() async throws {
        try harness.signIn(work, .signedIn("alice"))
        try harness.signIn(work, .signedIn("carol"), accessGroup: "group.shared")
        let client = try harness.client(work)
        _ = await client.currentSessionState()
        let events = StreamRecorder(client.listenToAuthEvents())

        try await purge(work, accessGroup: "group.shared")

        XCTAssertEqual(try harness.store(accessGroup: "group.shared").read(work), .absent)
        XCTAssertNotNil(try harness.storedRecord(work))
        XCTAssertEqual(harness.engine(for: work)?.cancelPendingSignInCount, 0)
        XCTAssertEqual(events.received, [])
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedIn(AuthClientUser(username: "alice", userId: "sub-alice")))
    }

    // MARK: Sign-out without a live session

    /// Revoke first, then clear locally, keeping the row.
    ///
    /// - Given: a saved, signed-in session no client holds, and a revoker that checks the record is
    ///   still signed in when it is called
    /// - When: it is signed out through the static call
    /// - Then:
    ///    - the revoker got the stored credentials while they were still stored; the row is kept, signed
    ///      out, with its label; the result is `.complete`
    func testStaticSignOutRevokesThenClearsKeepingTheRow() async throws {
        let payload = FakePayload.signedIn("alice")
        try harness.signIn(work, payload, label: "Work")
        let store = harness.store()
        let work = work
        let stillSignedIn = Flag()
        harness.revoker.scriptRevoke { _ in
            if case .record(let envelope) = try store.read(work), !envelope.record.isSignedOut {
                stillSignedIn.raise()
            }
        }

        let result = try await signOut(work)

        XCTAssertEqual(result, .complete)
        XCTAssertEqual(harness.revoker.revokeCalls, [payload.data])
        XCTAssertTrue(stillSignedIn.isRaised, "revoked before clearing")
        XCTAssertEqual(try harness.storedRecord(work), .signedOut(label: "Work", username: "alice", userId: "sub-alice"))
    }

    /// - Given: a saved session, and a revoker that fails
    /// - When: it is signed out through the static call
    /// - Then:
    ///    - it is still signed out locally, and the result is `.partial` with the revoke error
    func testStaticSignOutWithAFailedRevokeIsPartial() async throws {
        try harness.signIn(work, .signedIn("alice"))
        harness.revoker.scriptRevoke { _ in throw AuthClientError.unknown("network down", "retry") }

        let result = try await signOut(work)

        XCTAssertEqual(result, .partial(AuthClientPartialSignOut(revokeError: .unknown("network down", "retry"))))
        XCTAssertEqual(try harness.storedRecord(work)?.isSignedOut, true)
    }

    /// The engine reports a failed revoke in its outcome rather than throwing, because sign-out
    /// continues locally past it.
    ///
    /// - Given: a saved session, and a revoker whose outcome reports a failed revoke
    /// - When: it is signed out through the static call
    /// - Then:
    ///    - it is signed out locally, and the result is `.partial` with that error and no global failure
    func testStaticSignOutWithAReportedRevokeFailureIsPartial() async throws {
        try harness.signIn(work, .signedIn("alice"))
        let failure = AuthClientError.service(.network, "revoke failed", "retry")
        harness.revoker.scriptRevokeOutcome { _ in EngineSignOutOutcome(revokeError: failure) }

        let result = try await signOut(work)

        XCTAssertEqual(result, .partial(AuthClientPartialSignOut(revokeError: failure, globalSignOutError: nil)))
        XCTAssertEqual(try harness.storedRecord(work)?.isSignedOut, true)
    }

    /// - Given: a session with nothing stored, and a session already signed out
    /// - When: each is signed out through the static call
    /// - Then:
    ///    - both are `.complete`, and nothing is revoked
    func testStaticSignOutWithNothingToSignOutRevokesNothing() async throws {
        try harness.store().write(.signedOut(label: nil, username: "bob"), for: home, expecting: nil)

        let absent = try await signOut(work)
        let signedOut = try await signOut(home)

        XCTAssertEqual(absent, .complete)
        XCTAssertEqual(signedOut, .complete)
        XCTAssertEqual(harness.revoker.revokeCalls, [])
    }

    /// Another process refreshes the same user during the sign-out window, so the store's sign-out is
    /// superseded. The same user is still to be signed out: revoke the new credentials too, and retry.
    ///
    /// - Given: alice's saved session, and another process that refreshes alice's credentials right after
    ///   the store's sign-out reads the record
    /// - When: it is signed out through the static call
    /// - Then:
    ///    - both the original and the refreshed credentials are revoked, in that order
    ///    - the session ends signed out, and the result is `.complete`
    func testSupersededBySameUserRevokesTheNewCredentialsAndRetries() async throws {
        let original = FakePayload.signedIn("alice", version: 1)
        let refreshed = FakePayload.signedIn("alice", version: 2)
        try harness.signIn(work, original)
        let rival = ConcurrentWriter(store: harness.store(), sessionId: work) { envelope in
            var record = envelope.record
            record.credentials = refreshed.data
            return record
        }
        // Reads of the record: 1 the initial read, 2 the check after the revoke, 3 the store sign-out's.
        harness.keychain.onceAfterReading(harness.store().sessionAccount(for: work), occurrence: 3) { rival.move() }

        let result = try await signOut(work)

        XCTAssertEqual(rival.commits, 1)
        XCTAssertEqual(harness.revoker.revokeCalls, [original.data, refreshed.data])
        XCTAssertEqual(try harness.storedRecord(work)?.isSignedOut, true)
        XCTAssertEqual(result, .complete)
    }

    /// Another process signs a different user in to the same session ID during the sign-out window. That
    /// user must not be signed out: the caller asked to sign out a session that now holds someone else.
    ///
    /// - Given: alice's saved session, and another process that signs bob in right after the store's
    ///   sign-out reads the record
    /// - When: it is signed out through the static call
    /// - Then:
    ///    - only alice's credentials were revoked; bob's record is untouched; the result is `.superseded`
    func testSupersededByADifferentUserLeavesThemSignedIn() async throws {
        let alice = FakePayload.signedIn("alice")
        let bob = FakePayload.signedIn("bob")
        try harness.signIn(work, alice)
        let rival = ConcurrentWriter(store: harness.store(), sessionId: work) { _ in bob.record() }
        harness.keychain.onceAfterReading(harness.store().sessionAccount(for: work), occurrence: 3) { rival.move() }

        let result = try await signOut(work)

        XCTAssertEqual(result, .superseded)
        XCTAssertEqual(harness.revoker.revokeCalls, [alice.data])
        XCTAssertEqual(try harness.storedRecord(work), bob.record())
    }

    /// The narrowest cross-process window: bob lands after sign-out has confirmed it still holds alice, but
    /// before the store clears the record. The store must clear only the credentials that were revoked, or
    /// bob is signed out with his tokens never revoked.
    ///
    /// - Given: alice's saved session, and another process that signs bob in right after the check that
    ///   follows the revoke (the second read of the record)
    /// - When: it is signed out through the static call
    /// - Then:
    ///    - the result is `.superseded`, only alice was revoked, and bob's record is untouched
    func testDifferentUserLandingAfterTheFinalCheckIsNotSignedOut() async throws {
        let alice = FakePayload.signedIn("alice")
        let bob = FakePayload.signedIn("bob")
        try harness.signIn(work, alice)
        let rival = ConcurrentWriter(store: harness.store(), sessionId: work) { _ in bob.record() }
        harness.keychain.onceAfterReading(harness.store().sessionAccount(for: work), occurrence: 2) { rival.move() }

        let result = try await signOut(work)

        XCTAssertEqual(rival.commits, 1)
        XCTAssertEqual(result, .superseded)
        XCTAssertEqual(harness.revoker.revokeCalls, [alice.data])
        XCTAssertEqual(try harness.storedRecord(work), bob.record())
    }

    /// - Given: alice's saved session, and a revoke during which another process signs bob in
    /// - When: it is signed out through the static call
    /// - Then:
    ///    - the check after the revoke sees bob, so nothing is cleared and the result is `.superseded`
    func testDifferentUserSigningInDuringTheRevokeIsNotSignedOut() async throws {
        let bob = FakePayload.signedIn("bob")
        try harness.signIn(work, .signedIn("alice"))
        let store = harness.store()
        let work = work
        harness.revoker.scriptRevoke { _ in
            if case .record(let envelope) = try store.read(work) {
                try store.write(bob.record(), for: work, expecting: envelope.generation)
            }
        }

        let result = try await signOut(work)

        XCTAssertEqual(result, .superseded)
        XCTAssertEqual(try harness.storedRecord(work), bob.record())
    }

    /// A caller that gave up is not a failed revoke: nothing is cleared, and cancellation is what it sees.
    ///
    /// - Given: a saved session, and a revoke that throws `CancellationError`
    /// - When: it is signed out through the static call
    /// - Then:
    ///    - it throws `CancellationError`, and the session is still signed in
    func testCancelledRevokeClearsNothing() async throws {
        try harness.signIn(work, .signedIn("alice"))
        harness.revoker.scriptRevoke { _ in throw CancellationError() }

        await assertThrowsAsync({ try await self.signOut(work) }) { error in
            XCTAssertTrue(error is CancellationError, "\(error)")
        }

        XCTAssertEqual(try harness.storedRecord(work)?.isSignedOut, false)
    }

    /// - Given: a saved guest session
    /// - When: it is signed out through the static call
    /// - Then:
    ///    - its guest credentials are revoked and cleared, and the result is `.complete`
    func testStaticSignOutOfAGuestSessionCompletes() async throws {
        let guest = FakePayload.guest()
        try harness.signIn(work, guest)

        let result = try await signOut(work)

        XCTAssertEqual(result, .complete)
        XCTAssertEqual(harness.revoker.revokeCalls, [guest.data])
        XCTAssertEqual(try harness.storedRecord(work)?.isSignedOut, true)
    }

    /// Two guest sessions have no user to compare, so nothing shows that new guest credentials are the
    /// same principal's. Treating them as the same would revoke and clear a session this call never saw.
    ///
    /// - Given: a saved guest session, and another process that stores different guest credentials during
    ///   the revoke
    /// - When: it is signed out through the static call
    /// - Then:
    ///    - the result is `.superseded`, only the original credentials were revoked, and the new ones are
    ///      kept
    func testDifferentGuestCredentialsDuringTheRevokeAreNotSignedOut() async throws {
        let guest = FakePayload.guest(version: 1)
        let otherGuest = FakePayload.guest(version: 2)
        try harness.signIn(work, guest)
        let store = harness.store()
        let work = work
        harness.revoker.scriptRevoke { _ in
            if case .record(let envelope) = try store.read(work) {
                try store.write(otherGuest.record(), for: work, expecting: envelope.generation)
            }
        }

        let result = try await signOut(work)

        XCTAssertEqual(result, .superseded)
        XCTAssertEqual(harness.revoker.revokeCalls, [guest.data])
        XCTAssertEqual(try harness.storedRecord(work), otherGuest.record())
    }

    /// - Given: alice's saved session, and another process that refreshes alice's credentials during
    ///   every revoke
    /// - When: it is signed out through the static call
    /// - Then:
    ///    - it gives up after three attempts and throws `storageUnavailable(.interrupted)`, and the session
    ///      is still signed in — it never forces over credentials it did not revoke
    ///    - the first revoke failure is not dropped: it is the thrown error's underlying error
    func testSignOutGivesUpWhenTheSameUserKeepsRefreshing() async throws {
        try harness.signIn(work, .signedIn("alice", version: 1))
        let store = harness.store()
        let work = work
        harness.revoker.scriptRevoke { _ in
            if case .record(let envelope) = try store.read(work),
               let current = envelope.record.credentials.flatMap(FakePayload.decode) {
                try store.write(current.refreshed.record(), for: work, expecting: envelope.generation)
            }
            throw AuthClientError.unknown("revoke failed", "retry")
        }

        await assertThrowsAsync({ try await self.signOut(work) }) { error in
            let error = error as? AuthClientError
            XCTAssertEqual(error?.storageUnavailableReason, .interrupted, "\(String(describing: error))")
            XCTAssertEqual((error?.underlyingError as? AuthClientError)?.errorDescription, "revoke failed")
        }
        XCTAssertEqual(harness.revoker.revokeCalls.count, SessionSignOut.maximumAttempts)
        XCTAssertEqual(try harness.storedRecord(work)?.isSignedOut, false)
    }

    // MARK: Sign-out through a live session

    /// - Given: a live, signed-in session with an event subscriber
    /// - When: it is signed out through the static call
    /// - Then:
    ///    - the sign-out goes through the live session: its engine revokes, it sends `.signedOut`, it is
    ///      `.signedOut`, its provider throws `notSignedIn`, and the row is kept
    func testStaticSignOutRoutesThroughALiveSession() async throws {
        let payload = FakePayload.signedIn("alice")
        try harness.signIn(work, payload)
        let client = try harness.client(work)
        _ = await client.currentSessionState()
        let events = StreamRecorder(client.listenToAuthEvents())

        let result = try await signOut(work)

        XCTAssertEqual(result, .complete)
        XCTAssertEqual(harness.engine(for: work)?.revokeCalls, [payload.data])
        XCTAssertEqual(harness.revoker.revokeCalls, [])
        await events.waitFor(1)
        XCTAssertEqual(events.received, [.signedOut])
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedOut)
        XCTAssertEqual(try harness.storedRecord(work)?.isSignedOut, true)
        await assertThrowsAsync({ try await client.userPoolTokenProvider.accessToken() }) { error in
            XCTAssertEqual((error as? CredentialsError)?.isNotSignedIn, true, "\(error)")
        }
    }

    /// - Given: a live session holding alice, and another process that signs bob in right after the
    ///   store's sign-out reads the record
    /// - When: the session is signed out through the static call
    /// - Then:
    ///    - the result is `.superseded`, no `.signedOut` event is sent, and the session now reports bob
    ///    - see also `testLiveSignOutCancelsAPendingChallenge`
    func testLiveSignOutSupersededKeepsThePendingChallenge() async throws {
        let bob = FakePayload.signedIn("bob")
        try harness.signIn(work, .signedIn("alice"))
        let client = try harness.client(work)
        _ = await client.currentSessionState()
        let rival = ConcurrentWriter(store: harness.store(), sessionId: work) { _ in bob.record() }
        harness.keychain.onceAfterReading(harness.store().sessionAccount(for: work), occurrence: 3) { rival.move() }

        let result = try await signOut(work)

        XCTAssertEqual(result, .superseded)
        XCTAssertEqual(harness.engine(for: work)?.cancelPendingSignInCount, 0, "a superseded sign-out ends nothing")
    }

    /// A sign-out cancels a pending sign-in unconditionally. A session waiting on a challenge
    /// holds no credentials, but it must still land in `.signedOut`.
    ///
    /// - Given: a live session with no credentials and a sign-in waiting on a challenge
    /// - When: it is signed out through the static call, which routes to it
    /// - Then:
    ///    - the result is `.complete`, the pending sign-in was cancelled, and the state is `.signedOut`
    func testLiveSignOutCancelsAPendingChallenge() async throws {
        let client = try harness.client(work)
        harness.engine(for: work)?.setPendingChallenge(.confirmSignInWithTOTPCode)
        let before = await client.currentSessionState()
        XCTAssertEqual(before, .awaitingChallenge(.confirmSignInWithTOTPCode))

        let result = try await signOut(work)

        XCTAssertEqual(result, .complete)
        XCTAssertEqual(harness.engine(for: work)?.cancelPendingSignInCount, 1)
        let after = await client.currentSessionState()
        XCTAssertEqual(after, .signedOut)
    }

    /// - Given: a live session holding alice, and another process that signs bob in right after the
    ///   store's sign-out reads the record
    /// - When: the session is signed out through the static call
    /// - Then:
    ///    - the result is `.superseded`, no `.signedOut` event is sent, and the session now reports bob
    func testLiveSignOutSupersededByADifferentUser() async throws {
        let bob = FakePayload.signedIn("bob")
        try harness.signIn(work, .signedIn("alice"))
        let client = try harness.client(work)
        _ = await client.currentSessionState()
        let events = StreamRecorder(client.listenToAuthEvents())
        let rival = ConcurrentWriter(store: harness.store(), sessionId: work) { _ in bob.record() }
        harness.keychain.onceAfterReading(harness.store().sessionAccount(for: work), occurrence: 3) { rival.move() }

        let result = try await signOut(work)

        XCTAssertEqual(result, .superseded)
        XCTAssertEqual(events.received, [])
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedIn(AuthClientUser(username: "bob", userId: "sub-bob")))
    }
}

/// Starts a state read and an event subscription on a client made inside a keychain hook, and hands
/// the results back to the test.
private final class ReaderBox: @unchecked Sendable {
    private let lock = NSLock()
    private var client: AmplifyCognitoClient?
    private var task: Task<AuthSessionState, Never>?
    private var recorder: StreamRecorder<AuthEvent>?

    var events: StreamRecorder<AuthEvent> {
        lock.lock()
        defer { lock.unlock() }
        return recorder!
    }

    func start(_ client: AmplifyCognitoClient) {
        let recorder = StreamRecorder(client.listenToAuthEvents())
        let task = Task { await client.currentSessionState() }
        lock.lock()
        self.client = client
        self.recorder = recorder
        self.task = task
        lock.unlock()
    }

    func state() async throws -> AuthSessionState {
        guard let task = startedTask() else {
            throw FixtureError(description: "the hook never constructed a client")
        }
        return await task.value
    }

    private func startedTask() -> Task<AuthSessionState, Never>? {
        lock.lock()
        defer { lock.unlock() }
        return task
    }
}
