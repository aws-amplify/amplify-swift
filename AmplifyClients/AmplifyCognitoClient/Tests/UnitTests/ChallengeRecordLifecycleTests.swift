//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import Security
import XCTest
@testable import AmplifyFoundation
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// The challenge record's lifecycle in the session core (design §4.11), over the fake engine
/// and the in-memory keychain: written on a challenge, kept across a wrong answer, deleted on success, on a final
/// failure, on a new sign-in and on sign-out, purge and deletion; resumed by a new client over the same keychain,
/// which is how "the app was closed" is modelled; and the restore's rules (the ceiling, a leftover beside a signed-in
/// session, unreadable records), with the log lines each best-effort failure writes.
final class ChallengeRecordLifecycleTests: XCTestCase {

    private var harness: ClientHarness!
    private var sink: CapturingLogSink!
    private let work = ClientFixtures.id("work")
    private let alice = AuthClientUser(username: "alice", userId: "sub-alice")
    private let smsCode = AuthClientSignInStep.confirmSignInWithSMSMFACode(
        AuthClientCodeDeliveryDetails(destination: .sms("+1***"), attributeKey: .phoneNumber),
        nil
    )

    override func setUp() {
        harness = ClientHarness()
        sink = CapturingLogSink()
        AmplifyLogging.addSink(sink)
    }

    override func tearDown() async throws {
        AmplifyLogging.removeSink(sink)
        await harness.waitForBaseline()
        harness = nil
    }

    private var store: SessionRecordStore {
        harness.store()
    }

    private var challengeAccount: String {
        store.challengeAccount(for: work)
    }

    /// A client for `work` whose sign-in stops on `step`, signed in as far as that step.
    private func challenged(
        _ step: AuthClientSignInStep = .confirmSignInWithTOTPCode
    ) async throws -> (AmplifyCognitoClient, FakeSessionEngine) {
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        engine.scriptSignIn { _, _ in .challenge(step) }
        let result = try await client.signInForTest("alice")
        XCTAssertEqual(result.nextStep, step)
        return (client, engine)
    }

    /// "The app was closed": the client and its core released, then a new client over the same keychain.
    private func relaunched(dropping client: inout AmplifyCognitoClient?) async throws -> (AmplifyCognitoClient, FakeSessionEngine) {
        client = nil
        await harness.waitForBaseline()
        let next = try harness.client(work)
        return (next, try XCTUnwrap(harness.engine(for: work)))
    }

    // MARK: Written, kept, deleted

    /// - Given: a sign-in that stops on an SMS code
    /// - When: the step returns
    /// - Then:
    ///    - the challenge record holds the step's saved form, the attempt's Cognito session and username, created now
    func testAChallengeIsSaved() async throws {
        let (_, _) = try await challenged(smsCode)

        let saved = try XCTUnwrap(try store.storedChallenge(work))
        XCTAssertEqual(Optional(saved.state), .fake(smsCode, session: "fake-session-1", username: "alice"))
        XCTAssertEqual(saved.createdAt, TestClock.start)
    }

    /// - Given: a pending SMS code challenge, saved
    /// - When: a wrong code is answered, then the right one
    /// - Then:
    ///    - after the wrong code the record is unchanged (same session, same creation time)
    ///    - after the right one it is gone, and the session is signed in
    func testAWrongAnswerKeepsTheRecordAndSuccessDeletesIt() async throws {
        let (client, engine) = try await challenged(smsCode)
        let before = try store.storedChallenge(work)
        engine.scriptConfirmSignIn { _ in
            throw FakeRetryable(error: AuthClientError.service(.codeMismatch, "Wrong code", "Try again"))
        }
        harness.advanceClock(by: 30)

        await assertThrowsAsync { try await client.confirmSignIn(challengeResponse: "000000") }
        XCTAssertEqual(try store.storedChallenge(work), before)

        engine.scriptConfirmSignIn { _ in .done(payload: FakePayload.signedIn().data) }
        _ = try await client.confirmSignIn(challengeResponse: "123456")

        XCTAssertEqual(try store.readChallenge(work), .absent)
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedIn(alice))
    }

    /// - Given: a pending challenge, saved
    /// - When: the answer fails for good: the challenge session expired
    /// - Then:
    ///    - `challengeExpired` is thrown, and the record is gone with the attempt
    func testAFinalFailureDeletesTheRecord() async throws {
        let (client, engine) = try await challenged()
        engine.scriptConfirmSignIn { _ in
            throw AuthClientError.challengeExpired("The challenge session has expired.", "Sign in again.")
        }

        await assertThrowsAsync({ try await client.confirmSignIn(challengeResponse: "123456") }) { error in
            guard case .challengeExpired = error as? AuthClientError else {
                return XCTFail("expected challengeExpired, got \(error)")
            }
        }

        XCTAssertEqual(try store.readChallenge(work), .absent)
    }

    /// - Given: a pending TOTP code challenge, saved
    /// - When: the answer leads to a new challenge (a new password), then a new sign-in starts and fails at once
    /// - Then:
    ///    - the new challenge replaces the record, with its new session and creation time
    ///    - the new sign-in deletes it before its step runs, and a failed sign-in leaves none
    func testANextChallengeReplacesTheRecordAndANewSignInDeletesIt() async throws {
        let (client, engine) = try await challenged()
        harness.advanceClock(by: 60)
        engine.scriptConfirmSignIn { _ in .challenge(.confirmSignInWithNewPassword(nil)) }

        _ = try await client.confirmSignIn(challengeResponse: "123456")

        let replaced = try XCTUnwrap(try store.storedChallenge(work))
        XCTAssertEqual(Optional(replaced.state), .fake(.confirmSignInWithNewPassword(nil), session: "fake-session-2", username: "alice"))
        XCTAssertEqual(replaced.createdAt, TestClock.start.addingTimeInterval(60))

        let deletedBeforeTheStep = Flag()
        engine.scriptSignIn { [store, work] _, _ in
            if (try? store.readChallenge(work)) == .absent {
                deletedBeforeTheStep.raise()
            }
            throw AuthClientError.notAuthorized("Incorrect username or password.", "Check them.")
        }
        await assertThrowsAsync { try await client.signInForTest("alice") }

        XCTAssertTrue(deletedBeforeTheStep.isRaised, "a new sign-in deletes the superseded record first")
        XCTAssertEqual(try store.readChallenge(work), .absent)
    }

    /// - Given: a sign-in that stops on a step with no saved form (`confirmSignUp`), over an older record
    /// - When: the step returns
    /// - Then:
    ///    - the state is `.awaitingChallenge(.confirmSignUp)` in memory, and no record is stored
    func testAStepWithNoSavedFormLeavesNoRecord() async throws {
        try store.putChallenge(ChallengeRecord(createdAt: TestClock.start, state: .fake(.confirmSignInWithTOTPCode)!), for: work)
        let (client, engine) = try await challenged(.confirmSignUp(nil))

        XCTAssertEqual(engine.resumeCalls.count, 1, "the restore before the sign-in resumed the older record")

        XCTAssertEqual(try store.readChallenge(work), .absent)
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .awaitingChallenge(.confirmSignUp(nil)))
    }

    /// - Given: a session waiting on a saved challenge, three times over
    /// - When: it is signed out; signed out with a purge; purged with no call on the client
    /// - Then:
    ///    - each time the record is gone
    func testSignOutPurgeAndDeletionDeleteTheRecord() async throws {
        var (client, _) = try await challenged()
        _ = await client.signOut()
        XCTAssertEqual(try store.readChallenge(work), .absent, "sign-out")

        (client, _) = try await challenged()
        _ = await client.signOut(options: .init(purgeStoredSession: true))
        XCTAssertEqual(try store.readChallenge(work), .absent, "purge")

        (client, _) = try await challenged()
        try await AmplifyCognitoClient.purgeStoredSession(
            sessionId: work,
            configuration: ClientFixtures.configuration,
            accessGroup: nil,
            dependencies: harness.dependencies
        )
        XCTAssertEqual(try store.readChallenge(work), .absent, "purgeStoredSession")
    }

    // MARK: Resumed after the app was closed

    /// The design's promise (§4.11): an interrupted sign-in survives the app being closed.
    ///
    /// - Given: a sign-in waiting on an SMS code, saved; the client released (the app closed)
    /// - When: a new client over the same keychain reads its state, then answers
    /// - Then:
    ///    - the state is `.awaitingChallenge(step)` with no event, and the engine resumed the saved record at the core's
    ///      epoch
    ///    - the answer completes the sign-in: `.signedIn`, and the record is gone
    func testANewClientResumesTheSignIn() async throws {
        var first: AmplifyCognitoClient?
        (first, _) = try await challenged(smsCode)
        let saved = try XCTUnwrap(try store.storedChallenge(work))

        let (client, engine) = try await relaunched(dropping: &first)
        let events = StreamRecorder(client.listenToAuthEvents())
        let state = await client.currentSessionState()

        XCTAssertEqual(state, .awaitingChallenge(smsCode))
        XCTAssertEqual(engine.resumeCalls.map(\.state), [saved.state])
        engine.scriptConfirmSignIn { _ in .done(payload: FakePayload.signedIn().data) }
        let done = try await client.confirmSignIn(challengeResponse: "123456")

        XCTAssertEqual(done.nextStep, .done)
        await events.waitFor(1)
        XCTAssertEqual(events.received, [.signedIn])
        XCTAssertEqual(try store.readChallenge(work), .absent)
        let after = await client.currentSessionState()
        XCTAssertEqual(after, .signedIn(alice))
    }

    /// The TOTP setup is resumed too: its shared secret is saved, device-only.
    ///
    /// - Given: a sign-in waiting on a TOTP setup, saved; the app closed
    /// - When: a new client reads its state
    /// - Then:
    ///    - it is `.awaitingChallenge(.continueSignInWithTOTPSetup)` with the same secret and username
    func testATOTPSetupIsResumed() async throws {
        let setup = AuthClientSignInStep.continueSignInWithTOTPSetup(AuthClientTOTPSetupDetails(sharedSecret: "SECRET", username: "alice"))
        var first: AmplifyCognitoClient?
        (first, _) = try await challenged(setup)

        let (client, _) = try await relaunched(dropping: &first)

        let state = await client.currentSessionState()
        XCTAssertEqual(state, .awaitingChallenge(setup))
    }

    /// A guest session signing in keeps its identity across the relaunch.
    ///
    /// - Given: `work` stored as a guest, and a saved challenge
    /// - When: a client for `work` restores
    /// - Then:
    ///    - the challenge is resumed over the guest: `.awaitingChallenge`
    func testAChallengeIsResumedOverAGuest() async throws {
        try store.write(FakePayload.guest(identityId: "us-east-1:guest").record(), for: work, expecting: nil)
        try store.putChallenge(ChallengeRecord(createdAt: TestClock.start, state: .fake(.confirmSignInWithTOTPCode)!), for: work)

        let client = try harness.client(work)

        let state = await client.currentSessionState()
        XCTAssertEqual(state, .awaitingChallenge(.confirmSignInWithTOTPCode))
    }

    /// - Given: a saved challenge, the app closed
    /// - When: a new client starts a new sign-in instead of answering (the app's choice, §4.11)
    /// - Then:
    ///    - the resumed attempt is superseded and its record deleted; the new sign-in's step is saved in its place
    func testANewSignInSupersedesAResumedOne() async throws {
        var first: AmplifyCognitoClient?
        (first, _) = try await challenged()
        let resumed = try XCTUnwrap(try store.storedChallenge(work))
        let (client, engine) = try await relaunched(dropping: &first)
        _ = await client.currentSessionState()
        let deletedBeforeTheStep = Flag()
        engine.scriptSignIn { [store, work] _, _ in
            if (try? store.readChallenge(work)) == .absent {
                deletedBeforeTheStep.raise()
            }
            return .challenge(.confirmSignInWithPassword)
        }

        _ = try await client.signInForTest("alice")

        XCTAssertTrue(deletedBeforeTheStep.isRaised, "the resumed attempt's record is deleted before the new step")
        let replaced = try XCTUnwrap(try store.storedChallenge(work))
        XCTAssertNotEqual(replaced.state.session, resumed.state.session, "the new sign-in has a Cognito session of its own")
        XCTAssertEqual(Optional(replaced.state), .fake(.confirmSignInWithPassword, session: "fake-session-2", username: "alice"))
        XCTAssertEqual(engine.supersededCount, 1)
    }

    // MARK: The restore's rules

    /// Past the 15-minute ceiling, the record is deleted on read.
    ///
    /// - Given: a saved challenge created 15 minutes and 1 second before the clock
    /// - When: a client restores
    /// - Then:
    ///    - nothing is resumed, the state is `.signedOut`, and the record is gone
    func testARecordPastTheCeilingIsDeletedNotResumed() async throws {
        try store.putChallenge(
            ChallengeRecord(createdAt: TestClock.start.addingTimeInterval(-901), state: .fake(.confirmSignInWithTOTPCode)!),
            for: work
        )
        let client = try harness.client(work)

        let state = await client.currentSessionState()

        XCTAssertEqual(state, .signedOut)
        XCTAssertEqual(harness.engine(for: work)?.resumeCalls.count, 0)
        XCTAssertEqual(try store.readChallenge(work), .absent)
    }

    /// - Given: a saved challenge created 14 minutes before the clock
    /// - When: a client restores
    /// - Then:
    ///    - it is resumed: within the ceiling the app decides, not the library
    func testARecordWithinTheCeilingIsResumed() async throws {
        try store.putChallenge(
            ChallengeRecord(createdAt: TestClock.start.addingTimeInterval(-14 * 60), state: .fake(.confirmSignInWithTOTPCode)!),
            for: work
        )
        let client = try harness.client(work)

        let state = await client.currentSessionState()

        XCTAssertEqual(state, .awaitingChallenge(.confirmSignInWithTOTPCode))
    }

    /// A record left beside a signed-in session is a leftover, never resumed.
    ///
    /// - Given: `work` signed in as alice, and a saved challenge (as a failed delete after the sign-in left it); and a
    ///   federated session with one
    /// - When: a client restores each
    /// - Then:
    ///    - each reports its own state, not `.awaitingChallenge`, and its record is gone
    func testALeftoverBesideASignedInSessionIsDeleted() async throws {
        let home = ClientFixtures.id("home")
        try harness.signIn(work)
        try store.write(FakePayload.federated().record(), for: home, expecting: nil)
        for sessionId in [work, home] {
            try store.putChallenge(ChallengeRecord(createdAt: TestClock.start, state: .fake(.confirmSignInWithTOTPCode)!), for: sessionId)
        }

        let signedIn = try harness.client(work)
        let federated = try harness.client(home)

        let signedInState = await signedIn.currentSessionState()
        let federatedState = await federated.currentSessionState()
        XCTAssertEqual(signedInState, .signedIn(alice))
        XCTAssertEqual(federatedState, .federated(identityId: "us-east-1:federated"))
        XCTAssertEqual(try store.readChallenge(work), .absent)
        XCTAssertEqual(try store.readChallenge(home), .absent)
    }

    /// - Given: corrupt bytes under `work`'s challenge account, and a newer schema's record under `home`'s
    /// - When: a client restores each
    /// - Then:
    ///    - neither is resumed; both are signed out
    ///    - the corrupt bytes are deleted; the newer record is left for its writer
    func testCorruptAndNewerRecordsAreNotResumed() async throws {
        let home = ClientFixtures.id("home")
        try store.putChallengeBytes(Data("corrupt".utf8), for: work)
        let newer = Data(#"{"schemaVersion":2,"createdAt":1,"passkey":{}}"#.utf8)
        try store.putChallengeBytes(newer, for: home)

        let first = try harness.client(work)
        let second = try harness.client(home)

        let firstState = await first.currentSessionState()
        let secondState = await second.currentSessionState()
        XCTAssertEqual(firstState, .signedOut)
        XCTAssertEqual(secondState, .signedOut)
        XCTAssertEqual(try store.readChallenge(work), .absent)
        XCTAssertEqual(try store.readChallenge(home), .unsupportedSchema(version: 2))
    }

    /// Unreadable is not absent: a failed read of the challenge record fails the restore, and a retry recovers.
    ///
    /// - Given: a saved challenge whose read fails
    /// - When: a client reads its state, then the failure clears and it reads again
    /// - Then:
    ///    - first `.unavailable`, never `.signedOut`
    ///    - then `.awaitingChallenge`
    func testAFailedReadFailsTheRestore() async throws {
        try store.putChallenge(ChallengeRecord(createdAt: TestClock.start, state: .fake(.confirmSignInWithTOTPCode)!), for: work)
        harness.keychain.failingReads(of: challengeAccount, with: errSecInteractionNotAllowed)
        let client = try harness.client(work)

        let failed = await client.currentSessionState()
        guard case .unavailable = failed else {
            return XCTFail("expected .unavailable, got \(failed)")
        }

        harness.keychain.clearFailures()
        let recovered = await client.currentSessionState()
        XCTAssertEqual(recovered, .awaitingChallenge(.confirmSignInWithTOTPCode))
    }

    /// An unreadable challenge record never makes a signed-in session unavailable.
    ///
    /// - Given: `work` signed in as alice, a leftover challenge record beside it, and reads of that record failing
    /// - When: a client restores
    /// - Then:
    ///    - the state is `.signedIn(alice)`, not `.unavailable`: a signed-in session's record is never read to decide
    ///      anything, only deleted if it can be
    ///    - nothing is written or deleted while the read fails
    func testAnUnreadableRecordBesideASignedInSessionIsIgnored() async throws {
        try harness.signIn(work)
        try store.putChallenge(ChallengeRecord(createdAt: TestClock.start, state: .fake(.confirmSignInWithTOTPCode)!), for: work)
        harness.keychain.failingReads(of: challengeAccount, with: errSecInteractionNotAllowed)
        harness.keychain.resetLogs()
        let client = try harness.client(work)

        let state = await client.currentSessionState()

        XCTAssertEqual(state, .signedIn(alice))
        XCTAssertFalse(harness.keychain.removedAccounts.contains(challengeAccount))
    }

    /// - Given: a saved challenge this build's engine refuses to resume
    /// - When: a client restores
    /// - Then:
    ///    - the state is `.signedOut`, and the record is deleted
    func testARecordThatCannotBeResumedIsDeleted() async throws {
        try store.putChallenge(ChallengeRecord(createdAt: TestClock.start, state: .fake(.confirmSignInWithTOTPCode)!), for: work)
        let client = try harness.client(work)
        try XCTUnwrap(harness.engine(for: work)).refuseResumes()

        let state = await client.currentSessionState()

        XCTAssertEqual(state, .signedOut)
        XCTAssertEqual(try store.readChallenge(work), .absent)
    }

    // MARK: Best effort, and its log lines

    /// A failed write never fails the sign-in: the challenge stays in memory.
    ///
    /// - Given: the keychain failing writes of `work`'s challenge account
    /// - When: a sign-in stops on a challenge
    /// - Then:
    ///    - the step is returned and the state is `.awaitingChallenge`, with no record stored
    ///    - exactly the write-failure line is logged, at `warn`, under `SessionRecordStore`, naming no session or user
    func testAFailedWriteIsLoggedAndTheSignInGoesOn() async throws {
        harness.keychain.failingSets(of: challengeAccount, with: errSecInteractionNotAllowed)

        let (client, _) = try await challenged()

        let state = await client.currentSessionState()
        XCTAssertEqual(state, .awaitingChallenge(.confirmSignInWithTOTPCode))
        XCTAssertEqual(try store.readChallenge(work), .absent)
        XCTAssertEqual(sink.lines(in: SessionRecordStore.ChallengeLog.category), [
            .init(level: .warn, content: SessionRecordStore.ChallengeLog.writeFailed)
        ])
        XCTAssertFalse(sink.anyContains(work.stringValue) || sink.anyContains("alice"))
    }

    /// A failed write deletes the previous step's record, so a relaunch cannot resume a step the user has passed.
    ///
    /// - Given: a pending TOTP code challenge, saved; then the keychain failing writes of its account
    /// - When: the answer leads to a new challenge (a new password), whose record cannot be written
    /// - Then:
    ///    - the new step is returned and is the state; the write-failure line is logged
    ///    - no record is left: not the TOTP step's, which the relaunch would otherwise resume
    func testAFailedWriteDeletesThePreviousStepsRecord() async throws {
        let (client, engine) = try await challenged()
        XCTAssertNotEqual(try store.readChallenge(work), .absent)
        harness.keychain.failingSets(of: challengeAccount, with: errSecInteractionNotAllowed)
        engine.scriptConfirmSignIn { _ in .challenge(.confirmSignInWithNewPassword(nil)) }

        let next = try await client.confirmSignIn(challengeResponse: "123456")

        XCTAssertEqual(next.nextStep, .confirmSignInWithNewPassword(nil))
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .awaitingChallenge(.confirmSignInWithNewPassword(nil)))
        XCTAssertEqual(try store.readChallenge(work), .absent)
        XCTAssertEqual(sink.lines(in: SessionRecordStore.ChallengeLog.category), [
            .init(level: .warn, content: SessionRecordStore.ChallengeLog.writeFailed)
        ])
    }

    /// - Given: a pending, saved challenge, and the keychain failing its delete
    /// - When: the answer completes the sign-in, and the client is then relaunched
    /// - Then:
    ///    - the sign-in succeeds, and the delete-failure line is logged
    ///    - the relaunched client finds the leftover beside the signed-in session and deletes it
    func testAFailedDeleteIsLoggedAndTheNextRestoreDeletesIt() async throws {
        var client: AmplifyCognitoClient?
        var engine: FakeSessionEngine
        (client, engine) = try await challenged()
        harness.keychain.failingRemovals(of: challengeAccount, with: errSecInteractionNotAllowed)
        engine.scriptConfirmSignIn { _ in .done(payload: FakePayload.signedIn().data) }

        let done = try await client?.confirmSignIn(challengeResponse: "123456")

        XCTAssertEqual(done?.nextStep, .done)
        XCTAssertEqual(sink.lines(in: SessionRecordStore.ChallengeLog.category), [
            .init(level: .warn, content: SessionRecordStore.ChallengeLog.deleteFailed)
        ])
        XCTAssertNotEqual(try store.readChallenge(work), .absent)

        harness.keychain.clearFailures()
        let (next, _) = try await relaunched(dropping: &client)
        let state = await next.currentSessionState()
        XCTAssertEqual(state, .signedIn(alice))
        XCTAssertEqual(try store.readChallenge(work), .absent)
    }

    /// - Given: an expired record whose delete fails at restore
    /// - When: a client restores
    /// - Then:
    ///    - the state is `.signedOut`, and the discard-failure line is logged
    func testAFailedDiscardIsLogged() async throws {
        try store.putChallenge(
            ChallengeRecord(createdAt: TestClock.start.addingTimeInterval(-3_600), state: .fake(.confirmSignInWithTOTPCode)!),
            for: work
        )
        harness.keychain.failingRemovals(of: challengeAccount, with: errSecInteractionNotAllowed)
        let client = try harness.client(work)

        let state = await client.currentSessionState()

        XCTAssertEqual(state, .signedOut)
        XCTAssertEqual(sink.lines(in: SessionRecordStore.ChallengeLog.category), [
            .init(level: .warn, content: SessionRecordStore.ChallengeLog.discardFailed)
        ])
    }

    /// Through the public listing: expired records are swept, by the client's clock.
    ///
    /// - Given: an expired record for a session the app never saved, and a fresh one
    /// - When: `storedSessions` runs
    /// - Then:
    ///    - neither session is listed; the expired record is gone and the fresh one kept
    func testStoredSessionsSweepsExpiredRecords() async throws {
        let orphan = ClientFixtures.id("orphan")
        try store.putChallenge(ChallengeRecord(createdAt: TestClock.start.addingTimeInterval(-901), state: .fake(.confirmSignInWithTOTPCode)!), for: orphan)
        try store.putChallenge(ChallengeRecord(createdAt: TestClock.start, state: .fake(.confirmSignInWithTOTPCode)!), for: work)

        let sessions = try await AmplifyCognitoClient.storedSessions(
            configuration: ClientFixtures.configuration,
            accessGroup: nil,
            includingSignedOut: true,
            dependencies: harness.dependencies
        )

        XCTAssertEqual(sessions, [])
        XCTAssertEqual(try store.readChallenge(orphan), .absent)
        XCTAssertNotEqual(try store.readChallenge(work), .absent)
    }
}

// MARK: - Log capture

/// Records every line logged through `AmplifyLogging` while it is registered.
final class CapturingLogSink: LogSinkBehavior, @unchecked Sendable {

    struct Line: Equatable {
        let level: LogLevel
        let content: String
    }

    let id = UUID().uuidString
    private let lock = NSLock()
    private var messages: [(name: String, line: Line)] = []

    func isEnabled(for logLevel: LogLevel) -> Bool {
        true
    }

    func emit(message: LogMessage) {
        lock.lock()
        defer { lock.unlock() }
        messages.append((message.name, Line(level: message.level, content: message.content)))
    }

    /// The lines logged under `category`, in order.
    func lines(in category: String) -> [Line] {
        lock.lock()
        defer { lock.unlock() }
        return messages.filter { $0.name == category }.map(\.line)
    }

    func anyContains(_ text: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return messages.contains { $0.name == SessionRecordStore.ChallengeLog.category && $0.line.content.contains(text) }
    }
}
