//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentity
import AWSCognitoIdentityProvider
import Foundation
import InternalAWSCognitoAuth
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// The live engine's cancel semantics, its per-operation machines side by
/// side, and two engines in parallel. Every wait is on a gate or an arrival, never on time.
final class LiveEngineConcurrencyTests: XCTestCase {

    private var harness: LiveEngineHarness!

    override func setUp() {
        super.setUp()
        harness = LiveEngineHarness()
    }

    override func tearDown() {
        harness.cognito.assertConsumed()
        harness = nil
        super.tearDown()
    }

    // MARK: Cancel

    /// A cancel ends a sign-in still waiting on Cognito promptly, without waiting for Cognito.
    ///
    /// - Given: a sign-in whose `InitiateAuth` is held on a gate
    /// - When:
    ///    - `cancelPendingSignIn` runs while it is held
    /// - Then:
    ///    - the cancel returns, and the sign-in throws `CancellationError`, both before the gate opens
    ///    - nothing is pending
    ///
    func testACancelEndsASignInStillWaitingOnCognito() async throws {
        let engine = try harness.engine()
        let gate = Gate()
        harness.cognito.once("InitiateAuth") { (_: InitiateAuthInput) in
            await gate.pass()
            return LiveEngineFixtures.passwordVerifier()
        }
        let signIn = Task { try await engine.signIn(.srp(), current: nil) }
        await gate.waitForArrivals(1)

        await engine.cancelPendingSignIn()
        let result = await signIn.result

        guard case .failure(let error) = result, error is CancellationError else {
            return XCTFail("expected CancellationError, got \(result)")
        }
        let pending = await engine.pendingChallenge
        XCTAssertNil(pending)
        await gate.open()
    }

    /// A cancel stops a first sign-in step's machine, so nothing it started carries on to sign in behind the
    /// sign-out.
    ///
    /// - Given: a first sign-in whose `InitiateAuth` is held on one gate and whose `RespondToAuthChallenge`
    ///   would be held on a second
    /// - When:
    ///    - `cancelPendingSignIn` runs while `InitiateAuth` is held, then the first gate opens
    /// - Then:
    ///    - by the time the cancel returns, the step's machine is signed out (the cancel reached it)
    ///    - `InitiateAuth`'s answer, once released, starts nothing: `RespondToAuthChallenge` never arrives, and
    ///      the operation's slot is never written
    ///
    func testACancelStopsAFirstStepsMachine() async throws {
        let stopped = StoppedOperations()
        let engine = try harness.engine(onStepCancelled: { stopped.append($0) })
        let initiate = Gate()
        let respond = Gate()
        let answered = Counter()
        harness.cognito.once("InitiateAuth") { (_: InitiateAuthInput) in
            await initiate.pass()
            _ = await answered.increment()
            return LiveEngineFixtures.passwordVerifier()
        }
        harness.cognito.always("RespondToAuthChallenge") { (_: RespondToAuthChallengeInput) in
            await respond.pass()
            return LiveEngineFixtures.signedIn()
        }
        let signIn = Task { try await engine.signIn(.srp(), current: nil) }
        await initiate.waitForArrivals(1)

        await engine.cancelPendingSignIn()

        let operation = try XCTUnwrap(stopped.all.first)
        guard case .configured(.signedOut, _, _) = await operation.authMachine.currentState else {
            return XCTFail("the cancel should have reached the step's machine")
        }
        await initiate.open()
        _ = await signIn.result
        await waitUntil("InitiateAuth answered") { await answered.value == 1 }
        // The answer is dispatched to a machine that is signed out, which ignores it. Give it the chance to
        // start anything before checking that it did not.
        for _ in 0 ..< 200 {
            await Task.yield()
        }
        XCTAssertEqual(harness.cognito.operations, ["InitiateAuth"])
        let arrivals = await respond.arrivalCount
        XCTAssertEqual(arrivals, 0)
        XCTAssertEqual(operation.slot.current, .untouched(nil))
        await respond.open()
    }

    /// A cancel that arrives after Cognito issued the tokens returns them, for the core to revoke, rather
    /// than dropping them.
    ///
    /// - Given: a sign-in past SRP (the user pool tokens issued) whose `GetId` is held on a gate
    /// - When:
    ///    - `cancelPendingSignIn` runs while it is held
    /// - Then:
    ///    - the sign-in returns `.done` with alice's user pool tokens, including the refresh token
    ///    - the engine revokes none of them: the core revokes what a cancelled step hands back
    ///
    func testACancelAfterTheTokensWereIssuedReturnsThem() async throws {
        let stopped = StoppedOperations()
        let engine = try harness.engine(onStepCancelled: { stopped.append($0) })
        let gate = Gate()
        harness.scriptSRP()
        harness.cognito.once("GetId") { (_: GetIdInput) in
            await gate.pass()
            return GetIdOutput(identityId: LiveEngineFixtures.identityId)
        }
        let signIn = Task { try await engine.signIn(.srp(), current: nil) }
        await gate.waitForArrivals(1)

        await engine.cancelPendingSignIn()
        let result = try await signIn.value

        guard case .done(let payload) = result else {
            return XCTFail("expected the issued tokens, got \(result)")
        }
        let credentials = try AmplifyCredentials.decoded(payload)
        XCTAssertEqual(credentials.signedInData?.username, "alice")
        XCTAssertEqual(credentials.signedInData?.cognitoUserPoolTokens.refreshToken, "refresh-alice-v1")
        // Handed back, so the core revokes it: the engine itself revokes nothing, and nothing twice.
        try await XCTUnwrap(stopped.all.first).tokenTap.revocationsFinished()
        XCTAssertEqual(harness.cognito.inputs("RevokeToken", as: RevokeTokenInput.self).count, 0)
        await gate.open()
    }

    /// Tokens a call already in flight returns after the cancel are revoked, not orphaned, even when the
    /// cancelled step finishes, and settles its tap, before the cancel is done.
    ///
    /// - Given: a sign-in past `InitiateAuth` whose `RespondToAuthChallenge` (the one that issues the tokens)
    ///   is held on a gate, and an engine whose cancel waits, after cancelling the step's task, until that step
    ///   has finished
    /// - When:
    ///    - `cancelPendingSignIn` runs while the answer is held, then the gate opens and Cognito answers with
    ///      tokens
    /// - Then:
    ///    - the sign-in throws `CancellationError`, and the engine revokes the refresh token that answer
    ///      carried, which the signed-out machine ignored
    ///
    func testTokensACallInFlightReturnsAfterACancelAreRevoked() async throws {
        let stopped = StoppedOperations()
        let finished = Gate(isOpen: true)
        let engine = try harness.engine(
            onStepCancelled: { stopped.append($0) },
            whileStopping: { await finished.waitForArrivals(1) }
        )
        let respond = Gate()
        harness.cognito.once("InitiateAuth") { (_: InitiateAuthInput) in LiveEngineFixtures.passwordVerifier() }
        harness.cognito.once("RespondToAuthChallenge") { (_: RespondToAuthChallengeInput) in
            await respond.pass()
            return LiveEngineFixtures.signedIn()
        }
        harness.scriptSignOut()
        let signIn = Task { () -> Result<EngineStepResult, Error> in
            let result: Result<EngineStepResult, Error>
            do {
                result = try .success(await engine.signIn(.srp(), current: nil))
            } catch {
                result = .failure(error)
            }
            await finished.pass()
            return result
        }
        await respond.waitForArrivals(1)

        await engine.cancelPendingSignIn()
        let result = await signIn.value
        await respond.open()

        guard case .failure(let error) = result, error is CancellationError else {
            return XCTFail("expected CancellationError, got \(result)")
        }
        let operation = try XCTUnwrap(stopped.all.first)
        await waitUntil("the in-flight answer reached the tap") {
            harness.cognito.operations.contains("RevokeToken")
        }
        await operation.tokenTap.revocationsFinished()
        XCTAssertEqual(harness.cognito.inputs("RevokeToken", as: RevokeTokenInput.self).map(\.token), ["refresh-alice-v1"])
        XCTAssertEqual(
            harness.cognito.inputs("RevokeToken", as: RevokeTokenInput.self).first?.clientId,
            ClientFixtures.userPool.appClientId
        )
    }

    /// A cancel reaches the machine even when the caller's own task is cancelled: the
    /// core's sign-out may run on a cancelled task.
    ///
    /// - Given: a pending SMS challenge whose confirmation's `RespondToAuthChallenge` is held on a gate
    /// - When:
    ///    - `cancelPendingSignIn` is called from a task that is already cancelled
    /// - Then:
    ///    - the confirmation's machine is signed out by the time the cancel returns
    ///
    func testACancelFromACancelledTaskStillStopsTheMachine() async throws {
        let stopped = StoppedOperations()
        let engine = try harness.engine(onStepCancelled: { stopped.append($0) })
        let respond = Gate()
        harness.scriptSRP(then: LiveEngineFixtures.challenge(.smsMfa, parameters: LiveEngineFixtures.smsParameters))
        harness.cognito.once("RespondToAuthChallenge") { (_: RespondToAuthChallengeInput) in
            await respond.pass()
            return LiveEngineFixtures.challenge(.smsMfa, parameters: LiveEngineFixtures.smsParameters)
        }
        _ = try await engine.signIn(.srp(), current: nil)
        let confirm = Task { try await engine.confirmSignIn(.answer("123456"), current: nil) }
        await respond.waitForArrivals(1)

        let canceller = Task {
            while !Task.isCancelled {
                await Task.yield()
            }
            await engine.cancelPendingSignIn()
        }
        canceller.cancel()
        await canceller.value

        let operation = try XCTUnwrap(stopped.all.first)
        guard case .configured(.signedOut, _, _) = await operation.authMachine.currentState else {
            return XCTFail("a cancel from a cancelled task should still reach the machine")
        }
        await respond.open()
        _ = await confirm.result
        let pending = await engine.pendingChallenge
        XCTAssertNil(pending)
    }

    /// A confirmation in flight whose tokens Cognito issued before the cancel hands them back, and the engine
    /// revokes nothing itself: the core revokes them once.
    ///
    /// - Given: a pending SMS challenge, an answer Cognito accepts with tokens, and `GetId` held on a gate
    /// - When:
    ///    - `cancelPendingSignIn` runs while `GetId` is held
    /// - Then:
    ///    - the confirmation returns `.done` with alice's tokens, and the engine sent no `RevokeToken`
    ///
    func testACancelledConfirmationsIssuedTokensAreRevokedOnce() async throws {
        let stopped = StoppedOperations()
        let engine = try harness.engine(onStepCancelled: { stopped.append($0) })
        let getId = Gate()
        harness.scriptSRP(then: LiveEngineFixtures.challenge(.smsMfa, parameters: LiveEngineFixtures.smsParameters))
        harness.cognito.once("RespondToAuthChallenge") { (_: RespondToAuthChallengeInput) in LiveEngineFixtures.signedIn() }
        harness.cognito.once("GetId") { (_: GetIdInput) in
            await getId.pass()
            return GetIdOutput(identityId: LiveEngineFixtures.identityId)
        }
        _ = try await engine.signIn(.srp(), current: nil)
        let confirm = Task { try await engine.confirmSignIn(.answer("123456"), current: nil) }
        await getId.waitForArrivals(1)

        await engine.cancelPendingSignIn()
        let result = try await confirm.value

        guard case .done(let payload) = result else {
            return XCTFail("expected the issued tokens, got \(result)")
        }
        XCTAssertEqual(try engine.userPoolTokens(in: payload)?.refreshToken, "refresh-alice-v1")
        try await XCTUnwrap(stopped.all.first).tokenTap.revocationsFinished()
        XCTAssertEqual(harness.cognito.inputs("RevokeToken", as: RevokeTokenInput.self).count, 0)
        await getId.open()
    }

    /// A cancel drops a pending challenge; answering it afterwards is `invalidState`.
    ///
    /// - Given: a sign-in waiting on an SMS code
    /// - When:
    ///    - `cancelPendingSignIn` runs, then the code is answered
    /// - Then:
    ///    - nothing is pending, and the answer throws `invalidState` without calling Cognito
    ///
    func testACancelDropsThePendingChallenge() async throws {
        let engine = try harness.engine()
        harness.scriptSRP(then: LiveEngineFixtures.challenge(.smsMfa, parameters: LiveEngineFixtures.smsParameters))
        _ = try await engine.signIn(.srp(), current: nil)
        harness.cognito.clearCalls()

        await engine.cancelPendingSignIn()

        let pending = await engine.pendingChallenge
        XCTAssertNil(pending)
        await assertThrowsAsync({ try await engine.confirmSignIn(.answer("123456"), current: nil) }) { error in
            guard case .invalidState = authError(error) else {
                return XCTFail("expected invalidState, got \(error)")
            }
        }
        XCTAssertEqual(harness.cognito.operations, [])
    }

    /// A confirmation in flight ends on a cancel, and never comes back as a challenge.
    ///
    /// - Given: a pending SMS challenge, and the answer's `RespondToAuthChallenge` held on a gate, scripted
    ///   to answer with another challenge
    /// - When:
    ///    - `cancelPendingSignIn` runs while the answer is held, then the gate opens
    /// - Then:
    ///    - the confirmation throws `CancellationError`, and nothing is pending afterwards
    ///
    func testACancelledConfirmationNeverBecomesTheChallenge() async throws {
        let engine = try harness.engine()
        let gate = Gate()
        harness.scriptSRP(then: LiveEngineFixtures.challenge(.smsMfa, parameters: LiveEngineFixtures.smsParameters))
        harness.cognito.once("RespondToAuthChallenge") { (_: RespondToAuthChallengeInput) in
            await gate.pass()
            return LiveEngineFixtures.challenge(.softwareTokenMfa)
        }
        _ = try await engine.signIn(.srp(), current: nil)
        let confirm = Task { try await engine.confirmSignIn(.answer("123456"), current: nil) }
        await gate.waitForArrivals(1)

        await engine.cancelPendingSignIn()
        await gate.open()
        let result = await confirm.result

        guard case .failure(let error) = result, error is CancellationError else {
            return XCTFail("expected CancellationError, got \(result)")
        }
        let pending = await engine.pendingChallenge
        XCTAssertNil(pending)
    }

    // MARK: Session operations beside a pending challenge

    /// A session operation builds its own machines: it neither waits for nor disturbs a pending challenge.
    ///
    /// - Given: a sign-in waiting on an SMS code
    /// - When:
    ///    - guest credentials are fetched, then the code is answered
    /// - Then:
    ///    - the guest fetch succeeds, the challenge is still pending, and the answer finishes the sign-in
    ///
    func testAGuestFetchDoesNotDisturbAPendingChallenge() async throws {
        let engine = try harness.engine()
        harness.scriptSRP(then: LiveEngineFixtures.challenge(.smsMfa, parameters: LiveEngineFixtures.smsParameters))
        harness.cognito.once("RespondToAuthChallenge") { (_: RespondToAuthChallengeInput) in LiveEngineFixtures.signedIn() }
        harness.scriptIdentityPool()
        _ = try await engine.signIn(.srp(), current: nil)

        let guest = try await engine.fetchGuestCredentials(current: nil)

        XCTAssertEqual(try engine.describe(guest).kind, .guest)
        let pending = await engine.pendingChallenge
        guard case .confirmSignInWithSMSMFACode = pending else {
            return XCTFail("the challenge should still be pending, got \(String(describing: pending))")
        }
        let result = try await engine.confirmSignIn(.answer("123456"), current: guest)
        guard case .done = result else {
            return XCTFail("expected .done, got \(result)")
        }
    }

    // MARK: Parallel

    /// Two sessions' engines refresh in parallel: neither waits for the other.
    ///
    /// - Given: two engines, each with a signed-in payload, and `GetTokensFromRefreshToken` held on one gate
    ///   shared by both
    /// - When:
    ///    - both refresh at once
    /// - Then:
    ///    - both refreshes reach Cognito before the gate opens, and both then finish with their own user's
    ///      tokens
    ///
    func testTwoEnginesRefreshInParallel() async throws {
        let other = LiveEngineHarness()
        let alice = try harness.engine()
        let bob = try other.engine()
        let alicePayload = try await harness.signedInPayload("alice", on: alice)
        let bobPayload = try await other.signedInPayload("bob", on: bob)
        let gate = Gate()
        for (each, username) in [(harness!, "alice"), (other, "bob")] {
            each.cognito.always("GetTokensFromRefreshToken") { (_: GetTokensFromRefreshTokenInput) in
                await gate.pass()
                return GetTokensFromRefreshTokenOutput(authenticationResult: LiveEngineFixtures.tokens(username, version: 2))
            }
        }

        async let aliceRefresh = alice.refresh(alicePayload)
        async let bobRefresh = bob.refresh(bobPayload)
        await gate.waitForArrivals(2)
        await gate.open()
        let (aliceRefreshed, bobRefreshed) = try await (aliceRefresh, bobRefresh)

        XCTAssertEqual(try alice.userPoolTokens(in: aliceRefreshed)?.refreshToken, "refresh-alice-v2")
        XCTAssertEqual(try bob.userPoolTokens(in: bobRefreshed)?.refreshToken, "refresh-bob-v2")
    }

    /// Two operations on one engine run side by side too: session operations are not serialized by the
    /// engine (the core's gates and flights do that).
    ///
    /// - Given: one engine, a signed-in payload, and `GetTokensFromRefreshToken` held on a gate
    /// - When:
    ///    - two refreshes of the payload start at once
    /// - Then:
    ///    - both reach Cognito before the gate opens, and both finish
    ///
    func testOneEnginesSessionOperationsRunSideBySide() async throws {
        let engine = try harness.engine()
        let payload = try await harness.signedInPayload(on: engine)
        let gate = Gate()
        harness.cognito.always("GetTokensFromRefreshToken") { (_: GetTokensFromRefreshTokenInput) in
            await gate.pass()
            return GetTokensFromRefreshTokenOutput(authenticationResult: LiveEngineFixtures.tokens(version: 2))
        }

        async let first = engine.refresh(payload)
        async let second = engine.refresh(payload)
        await gate.waitForArrivals(2)
        await gate.open()
        _ = try await (first, second)
    }

    /// Two operations back to back share nothing but the per-user records.
    ///
    /// - Given: a sign-in, then a refresh, a global sign-out and a guest fetch on the same engine
    /// - When:
    ///    - each runs after the previous finished
    /// - Then:
    ///    - the calls are exactly the plugin's for each operation in turn, with no repeated configure-time
    ///      call between them
    ///
    func testOperationsBackToBackMakeOnlyTheirOwnCalls() async throws {
        let engine = try harness.engine()
        let payload = try await harness.signedInPayload(on: engine)
        harness.scriptRefresh()
        harness.scriptSignOut()

        let refreshed = try await engine.refresh(payload)
        _ = try await engine.revoke(refreshed, global: true)
        _ = try await engine.fetchGuestCredentials(current: nil)

        XCTAssertEqual(harness.cognito.operations, [
            "InitiateAuth", "RespondToAuthChallenge", "GetId", "GetCredentialsForIdentity",
            "GetTokensFromRefreshToken", "GetCredentialsForIdentity",
            "GlobalSignOut", "RevokeToken",
            "GetId", "GetCredentialsForIdentity"
        ])
        XCTAssertEqual(harness.cognito.inputs("RevokeToken", as: RevokeTokenInput.self).first?.token, "refresh-alice-v2")
    }
}
