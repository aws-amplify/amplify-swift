//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) @testable import AmplifyFoundation
import AWSCognitoIdentityProvider
import Foundation
import InternalAWSCognitoAuth
import Security
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// The sign-out result when storage fails, or another writer changes the record, around the revoke.
extension SignOutResultShapeTests {

    // MARK: Storage and other writers

    /// A step after the signed-out record is saved is best effort: the session is signed out
    /// by then, so its failure must not report it as still signed in.
    ///
    /// - Given: two signed-in sessions whose revokes succeed, and whose interrupted-sign-in records cannot be deleted
    /// - When: one signs out through its client, the other through `signOutStoredSession`
    /// - Then:
    ///    - both results are `.complete`, signed out locally, and both records are signed out; the live session is
    ///      signed out in memory and sends `.signedOut`
    ///    - each sign-out logs exactly one warning, the store's, under `AmplifyCognitoClient.SessionRecordStore`: the
    ///      live session's core tries no second delete of its own
    func testAFailedChallengeDeleteAfterTheSignOutIsSavedIsStillComplete() async throws {
        let home = ClientFixtures.id("home")
        try harness.signIn(work, .signedIn("alice"))
        try harness.signIn(home, .signedIn("bob"))
        let client = try harness.client(work)
        _ = await client.currentSessionState()
        let events = StreamRecorder(client.listenToAuthEvents())
        let store = harness.store()
        harness.keychain.failingRemovals(of: store.challengeAccount(for: work), with: errSecInteractionNotAllowed)
        harness.keychain.failingRemovals(of: store.challengeAccount(for: home), with: errSecInteractionNotAllowed)
        let sink = CategoryCapture()
        AmplifyLogging.addSink(sink)
        defer { AmplifyLogging.removeSink(sink) }

        let live = await client.signOut()
        let stored = await signOutStored(home)

        XCTAssertEqual(live, .complete)
        XCTAssertEqual(stored, .complete)
        harness.keychain.clearFailures()
        XCTAssertEqual(try harness.storedRecord(work)?.isSignedOut, true)
        XCTAssertEqual(try harness.storedRecord(home)?.isSignedOut, true)
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedOut)
        await waitUntil("the live session sends .signedOut") { events.received == [.signedOut] }
        XCTAssertEqual(sink.lines(in: [ClientLog.category(ClientLog.sessionRecordStore)]), [
            SessionRecordStore.ChallengeLog.signOutDeleteFailed,
            SessionRecordStore.ChallengeLog.signOutDeleteFailed
        ])
    }

    /// A sign-out with nothing to revoke still ends an interrupted sign-in, and a failed delete of its record is
    /// logged once, as a signed-out session's.
    ///
    /// - Given: a signed-out session with an interrupted sign-in saved, whose record cannot be deleted
    /// - When: it signs out through its client
    /// - Then:
    ///    - the result is `.complete`; exactly one warning is logged, `ChallengeLog.signOutDeleteFailed`
    ///    - once the keychain recovers, a sign-out deletes the interrupted sign-in's record
    func testASignOutWithNothingToRevokeLogsAFailedChallengeDeleteOnce() async throws {
        let store = harness.store()
        _ = try store.write(.signedOut(label: nil, username: "alice", userId: "sub-alice"), for: work, expecting: nil)
        let challenge = store.challengeAccount(for: work)
        harness.keychain.put(Data("an interrupted sign-in".utf8), challenge)
        let client = try harness.client(work)
        _ = await client.currentSessionState()
        harness.keychain.failingRemovals(of: challenge, with: errSecInteractionNotAllowed)
        let sink = CategoryCapture()
        AmplifyLogging.addSink(sink)
        defer { AmplifyLogging.removeSink(sink) }

        let result = await client.signOut()

        XCTAssertEqual(result, .complete)
        XCTAssertEqual(
            sink.lines(in: [ClientLog.category(ClientLog.sessionRecordStore)]),
            [SessionRecordStore.ChallengeLog.signOutDeleteFailed]
        )
        harness.keychain.clearFailures()
        let again = await client.signOut()
        XCTAssertEqual(again, .complete)
        XCTAssertNil(harness.keychain.value(challenge))
    }

    /// The static path ends an interrupted first sign-in as a live sign-out does: with
    /// nothing to revoke, `signOutStoredSession` still deletes the session's interrupted-sign-in record.
    ///
    /// - Given: a signed-out session no client holds, with an interrupted first sign-in saved
    /// - When: it is signed out through `signOutStoredSession`
    /// - Then:
    ///    - the result is `.complete`, nothing is revoked, and the interrupted sign-in's record is deleted
    func testStaticSignOutWithNothingToRevokeDeletesThePendingSignIn() async throws {
        let store = harness.store()
        _ = try store.write(.signedOut(label: nil, username: "alice", userId: "sub-alice"), for: work, expecting: nil)
        let challenge = store.challengeAccount(for: work)
        harness.keychain.put(Data("an interrupted sign-in".utf8), challenge)

        let result = await signOutStored(work)

        XCTAssertEqual(result, .complete)
        XCTAssertEqual(harness.revoker.revokeCalls, [])
        XCTAssertNil(harness.keychain.value(challenge))
    }

    /// A record that cannot be read back after the sign-out saved it keeps the row the session knew,
    /// rather than no row.
    ///
    /// - Given: a signed-in session labelled "Work", whose record cannot be read back once the sign-out has saved it
    /// - When: it signs out
    /// - Then:
    ///    - the result is `.complete`; in memory the session is a signed-out row with its label and last user, as the
    ///      saved record is
    func testAFailedReloadAfterTheSignOutKeepsTheKnownLabel() async throws {
        try harness.signIn(work, .signedIn("alice"))
        let client = try harness.client(work)
        try await client.setSessionLabel("Work")
        let store = harness.store()
        let keychain = harness.keychain
        let challenge = store.challengeAccount(for: work)
        let session = store.sessionAccount(for: work)
        // The store's sign-out deletes the challenge record after the signed-out record is saved, and nothing reads the
        // record again until the core reads it back.
        keychain.onceBeforeRemoving(challenge) { keychain.failingReads(of: session, with: errSecInteractionNotAllowed) }

        let result = await client.signOut()

        XCTAssertEqual(result, .complete)
        let known = await client.core.restoredSnapshotIfAny?.ownRecord
        XCTAssertEqual(known?.isSignedOut, true)
        XCTAssertEqual(known?.label, "Work")
        XCTAssertEqual(known?.username, "alice")
        XCTAssertNil(known?.credentials)
        harness.keychain.clearFailures()
        let stored = try XCTUnwrap(harness.storedRecord(work))
        XCTAssertEqual(stored.isSignedOut, true)
        XCTAssertEqual(stored.label, "Work")
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedOut)
    }

    /// - Given: a signed-in session whose revoke succeeds, and whose record cannot then be written
    /// - When: it signs out
    /// - Then:
    ///    - the result is `.failed(.storageUnavailable(.locked))`: the session is still signed in, stored and
    ///      in memory, and no `.signedOut` is sent
    func testStorageFailureBeforeTheClearIsFailedAndTheSessionStaysSignedIn() async throws {
        let payload = FakePayload.signedIn("alice")
        try harness.signIn(work, payload)
        let client = try harness.client(work)
        _ = await client.currentSessionState()
        let events = StreamRecorder(client.listenToAuthEvents())
        harness.keychain.failing(.write, with: errSecInteractionNotAllowed)

        let result = await client.signOut()

        XCTAssertEqual(failedSignOutError(result)?.kind, .storageUnavailable(.locked))
        XCTAssertEqual(harness.engine(for: work)?.revokeCalls, [payload.data])
        harness.keychain.clearFailures()
        XCTAssertEqual(try harness.storedRecord(work)?.credentials, payload.data)
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedIn(alice))
        XCTAssertEqual(events.received, [])
    }

    /// A record that becomes unreadable during the revoke is reported as what it is, not as another sign-in.
    ///
    /// - Given: two signed-in sessions, and revokes during which another writer replaces one record with bytes that are
    ///   not a record, and the other with a newer schema's record
    /// - When: each signs out
    /// - Then:
    ///    - each is `.failed(.unknown)`, saying the record became unreadable, or that a newer version of the app saved
    ///      it (with its schema), never that another sign-in replaced the session; each record is left as it was
    ///      written, and neither session sends `.signedOut`
    func testARecordUnreadableAfterTheRevokeIsReportedAsWhatItIs() async throws {
        let home = ClientFixtures.id("home")
        try harness.signIn(work, .signedIn("alice"))
        try harness.signIn(home, .signedIn("bob"))
        let corruptClient = try harness.client(work)
        let newerClient = try harness.client(home)
        _ = await corruptClient.currentSessionState()
        _ = await newerClient.currentSessionState()
        let corruptEvents = StreamRecorder(corruptClient.listenToAuthEvents())
        let newerEvents = StreamRecorder(newerClient.listenToAuthEvents())
        let store = harness.store()
        let keychain = harness.keychain
        let corrupt = Data("not a session record".utf8)
        let newer = Data(#"{"schemaVersion":9,"generation":1,"lastWriteTimestamp":0,"kind":"none"}"#.utf8)
        harness.engine(for: work)?.scriptRevoke { [work] _ in keychain.put(corrupt, store.sessionAccount(for: work)) }
        harness.engine(for: home)?.scriptRevoke { _ in keychain.put(newer, store.sessionAccount(for: home)) }

        let corruptResult = await corruptClient.signOut()
        let newerResult = await newerClient.signOut()

        let corruptError = try XCTUnwrap(failedSignOutError(corruptResult), "\(corruptResult)")
        XCTAssertEqual(corruptError.kind, .unknown)
        XCTAssertEqual(
            corruptError.errorDescription,
            "The session's saved record became unreadable during sign-out, so it was left as it is. Its tokens were revoked."
        )
        let newerError = try XCTUnwrap(failedSignOutError(newerResult), "\(newerResult)")
        XCTAssertEqual(newerError.kind, .unknown)
        XCTAssertEqual(
            newerError.errorDescription,
            "A newer version of the app saved this session during sign-out (record schema 9), so it was left as it is. "
                + "Its tokens were revoked."
        )
        for error in [corruptError, newerError] {
            XCTAssertFalse(error.isEquivalent(to: SessionSignOut.supersededError()), "\(error)")
        }
        XCTAssertEqual(keychain.value(store.sessionAccount(for: work)), corrupt)
        XCTAssertEqual(keychain.value(store.sessionAccount(for: home)), newer)
        XCTAssertEqual(corruptEvents.received, [])
        XCTAssertEqual(newerEvents.received, [])
    }

    /// - Given: a session whose same user keeps refreshing during every revoke
    /// - When: it signs out
    /// - Then:
    ///    - after the last attempt the result is `.failed(.storageUnavailable(.interrupted))`, and the session is
    ///      still signed in
    func testContendedIsFailedInterrupted() async throws {
        try harness.signIn(work, .signedIn("alice", version: 1))
        let client = try harness.client(work)
        let store = harness.store()
        harness.engine(for: work)?.scriptRevoke { [work] _ in
            if case .record(let envelope) = try store.read(work),
               let current = envelope.record.credentials.flatMap(FakePayload.decode) {
                try store.write(current.refreshed.record(), for: work, expecting: envelope.version)
            }
        }

        let result = await client.signOut()

        XCTAssertEqual(failedSignOutError(result)?.storageUnavailableReason, .interrupted)
        XCTAssertEqual(harness.engine(for: work)?.revokeCalls.count, SessionSignOut.maximumAttempts)
        XCTAssertEqual(try harness.storedRecord(work)?.isSignedOut, false)
    }

    /// - Given: a signed-in session whose first revoke attempt reports the user closing the hosted UI's page
    /// - When: it signs out
    /// - Then:
    ///    - the result is `.failed(.userCancelled)`, and the session is still signed in
    func testClosedHostedUIPageIsFailedUserCancelledAndStaysSignedIn() async throws {
        let payload = FakePayload.signedIn("alice")
        try harness.signIn(work, payload)
        let client = try harness.client(work)
        harness.engine(for: work)?.scriptRevoke { _ in throw AuthClientError.userCancelled("closed", "retry") }

        let result = await client.signOut()

        XCTAssertEqual(failedSignOutError(result)?.kind, .userCancelled)
        XCTAssertEqual(try harness.storedRecord(work)?.credentials, payload.data)
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedIn(alice))
    }
}
