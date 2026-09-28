//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// The fake engine is what every session-core test stands on, so its own behaviour is pinned here.
final class FakeSessionEngineTests: XCTestCase {

    private func makeEngine() throws -> FakeSessionEngine {
        let configuration = try AuthClientConfiguration(
            userPool: .init(poolId: StorageFixtures.userPoolId, appClientId: "app-client-1", region: "us-east-1"),
            identityPool: .init(poolId: StorageFixtures.identityPoolId, region: "us-east-1")
        )
        let clients = try CognitoServiceClients(configuration: configuration, configureUserPoolClient: nil)
        return FakeSessionEngine(context: SessionEngineContext(
            sessionId: .default,
            configuration: configuration,
            namespace: StorageFixtures.namespace,
            clients: clients
        ))
    }

    /// - Given: signed-in, user-pool-only and guest payloads, and bytes that are not a payload
    /// - When: the fake reads them
    /// - Then:
    ///    - it describes each, vends AWS credentials and tokens only where the payload has them, reports
    ///      staleness as scripted, and throws for bytes it cannot read
    func testReadsPayloadsWithoutTheNetwork() throws {
        let engine = try makeEngine()
        let alice = FakePayload.signedIn("alice", stale: true)
        let poolOnly = FakePayload.signedIn("bob", kind: .userPoolOnly)
        let guest = FakePayload.guest()

        XCTAssertEqual(
            try engine.describe(alice.data),
            CredentialSummary(kind: .userPoolAndIdentityPool, username: "alice", userId: "sub-alice")
        )
        XCTAssertEqual(try engine.awsCredentials(in: alice.data), alice.awsCredentials)
        XCTAssertEqual(try engine.accessToken(in: alice.data), "access-alice-v1")
        XCTAssertTrue(try engine.needsRefresh(alice.data, at: TestClock.start))
        XCTAssertNil(try engine.awsCredentials(in: poolOnly.data))
        XCTAssertNil(try engine.accessToken(in: guest.data))
        XCTAssertNotNil(try engine.awsCredentials(in: guest.data))
        XCTAssertThrowsError(try engine.describe(Data("not a payload".utf8)))
        XCTAssertEqual(engine.describeCount, 2)
    }

    /// - Given: a stale payload
    /// - When: the fake refreshes it, then refreshes with a script, then revokes
    /// - Then:
    ///    - the default refresh returns the payload one version on and fresh
    ///    - a script replaces it; every call is counted with its payload
    func testRefreshAndRevokeAreScriptedAndCounted() async throws {
        let engine = try makeEngine()
        let stale = FakePayload.signedIn(stale: true)

        let refreshed = try await engine.refresh(stale.data)
        XCTAssertEqual(FakePayload.decode(refreshed), stale.refreshed)

        engine.scriptRefresh { _ in throw SessionEngineError.refreshTokenInvalid }
        await assertThrowsAsync({ try await engine.refresh(stale.data) }) { error in
            guard case SessionEngineError.refreshTokenInvalid = error else {
                return XCTFail("\(error)")
            }
        }
        _ = try await engine.revoke(stale.data, global: false)

        XCTAssertEqual(engine.refreshCalls, [stale.data, stale.data])
        XCTAssertEqual(engine.revokeCalls, [stale.data])
    }

    /// - Given: a fake whose refreshes are held on a latch
    /// - When: a refresh starts
    /// - Then:
    ///    - it waits at the latch, and completes only once the latch opens
    func testLatchHoldsARefreshOpen() async throws {
        let engine = try makeEngine()
        let latch = Gate()
        engine.holdRefreshes(on: latch)

        let refresh = Task { try await engine.refresh(FakePayload.signedIn(stale: true).data) }
        await latch.waitForArrivals(1)
        XCTAssertEqual(engine.refreshCalls.count, 1)

        await latch.open()
        let refreshed = try await refresh.value
        XCTAssertEqual(FakePayload.decode(refreshed)?.version, 2)
    }

    /// - Given: a fake with a pending challenge
    /// - When: the pending sign-in is cancelled
    /// - Then:
    ///    - the challenge clears and the cancellation is counted
    func testPendingChallengeClearsOnCancel() async throws {
        let engine = try makeEngine()
        engine.setPendingChallenge(.confirmSignInWithTOTPCode)
        let pending = await engine.pendingChallenge
        XCTAssertEqual(pending, .confirmSignInWithTOTPCode)

        await engine.cancelPendingSignIn()

        let cleared = await engine.pendingChallenge
        XCTAssertNil(cleared)
        XCTAssertEqual(engine.cancelPendingSignInCount, 1)
    }

    static func request(_ username: String, password: String? = "password") -> EngineSignInRequest {
        EngineSignInRequest(username: username, password: password, authFlowType: nil, clientMetadata: [:])
    }

    static func answer(_ response: String) -> EngineConfirmSignInRequest {
        EngineConfirmSignInRequest(challengeResponse: response, userAttributes: [:], clientMetadata: [:], friendlyDeviceName: nil)
    }

    /// - Given: an unscripted fake
    /// - When: it signs in, and reads the payload's user pool tokens
    /// - Then:
    ///    - the sign-in is done as the request's user, recorded with its request, and leaves nothing pending
    func testDefaultSignInCompletesAsTheRequestedUser() async throws {
        let engine = try makeEngine()

        let result = try await engine.signIn(Self.request("bob"), current: nil)

        guard case .done(let payload) = result else {
            return XCTFail("\(result)")
        }
        XCTAssertEqual(FakePayload.decode(payload)?.username, "bob")
        XCTAssertEqual(try engine.userPoolTokens(in: payload)?.accessToken, "access-bob-v1")
        XCTAssertEqual(engine.signInCalls.map(\.request), [Self.request("bob")])
        let pending = await engine.pendingChallenge
        XCTAssertNil(pending)
    }

    /// - Given: a fake whose sign-in stops on a challenge
    /// - When: a second sign-in starts, then a confirmation answers it
    /// - Then:
    ///    - the challenge is pending after the first; the second supersedes it; the confirmation completes
    ///      as the second sign-in's user and clears it
    func testChallengeIsRetainedSupersededAndConfirmed() async throws {
        let engine = try makeEngine()
        engine.scriptSignIn { _, _ in .challenge(.confirmSignInWithTOTPCode) }

        _ = try await engine.signIn(Self.request("alice"), current: nil)
        let first = await engine.pendingChallenge
        XCTAssertEqual(first, .confirmSignInWithTOTPCode)

        _ = try await engine.signIn(Self.request("carol"), current: nil)
        XCTAssertEqual(engine.supersededCount, 1)

        let result = try await engine.confirmSignIn(Self.answer("123456"), current: nil)
        guard case .done(let payload) = result else {
            return XCTFail("\(result)")
        }
        XCTAssertEqual(FakePayload.decode(payload)?.username, "carol")
        let cleared = await engine.pendingChallenge
        XCTAssertNil(cleared)
    }

    /// - Given: a fake with nothing pending, then one with a pending challenge
    /// - When: a confirmation fails retryably, then terminally
    /// - Then:
    ///    - with nothing pending it throws `invalidState` without running the script; a retryable failure
    ///      keeps the challenge; a terminal one clears it
    func testConfirmationFailuresFollowTheSeamContract() async throws {
        let engine = try makeEngine()
        await assertThrowsAsync({ try await engine.confirmSignIn(Self.answer("1"), current: nil) }) { error in
            guard case .invalidState = error as? AuthClientError else {
                return XCTFail("\(error)")
            }
        }

        engine.setPendingChallenge(.confirmSignInWithTOTPCode)
        engine.scriptConfirmSignIn { _ in
            throw FakeRetryable(error: AuthClientError.service(.codeMismatch, "wrong", "retry"))
        }
        await assertThrowsAsync { try await engine.confirmSignIn(Self.answer("2"), current: nil) }
        let kept = await engine.pendingChallenge
        XCTAssertEqual(kept, .confirmSignInWithTOTPCode)

        engine.scriptConfirmSignIn { _ in throw AuthClientError.challengeExpired("expired", "restart") }
        await assertThrowsAsync { try await engine.confirmSignIn(Self.answer("3"), current: nil) }
        let dropped = await engine.pendingChallenge
        XCTAssertNil(dropped)
        XCTAssertEqual(engine.confirmSignInCalls.map(\.challengeResponse), ["1", "2", "3"])
    }

    /// - Given: an unscripted fake, then scripted ones
    /// - When: it fetches guest credentials, deletes a user and revokes globally
    /// - Then:
    ///    - each call is recorded; the defaults succeed; a revoke script's outcome is returned, with the
    ///      global flag recorded
    func testGuestDeleteAndRevokeAreScriptedAndCounted() async throws {
        let engine = try makeEngine()
        let alice = FakePayload.signedIn()

        let guest = try await engine.fetchGuestCredentials(current: nil)
        XCTAssertEqual(try engine.describe(guest).kind, .guest)
        XCTAssertEqual(try engine.describe(guest).identityId, "us-east-1:guest")
        try await engine.deleteUser(alice.data)
        XCTAssertEqual(engine.deleteUserCalls, [alice.data])

        let failure = EngineSignOutOutcome(globalSignOutError: .service(.network, "global failed", "retry"))
        engine.scriptRevokeOutcome { _, global in global ? failure : .complete }
        let local = try await engine.revoke(alice.data, global: false)
        let global = try await engine.revoke(alice.data, global: true)

        XCTAssertEqual(local, .complete)
        XCTAssertEqual(global, failure)
        XCTAssertEqual(engine.revokeGlobalFlags, [false, true])
        XCTAssertEqual(engine.guestFetchCount, 1)
    }

    /// The fake's sign-up state follows the live engine's: every sign-up ends an earlier auto-sign-in
    /// session when it starts, and of two concurrent ones the one started last decides.
    ///
    /// - Given: a fake whose sign-up for dave is held and answers `.completeAutoSignIn`, and for erin answers
    ///   `.confirmUser`
    /// - When:
    ///    - dave's sign-up starts, erin's runs, then dave's is released
    /// - Then:
    ///    - there is no auto-sign-in session: dave's older result does not set it
    ///
    func testTheNewestSignUpDecidesTheAutoSignInSession() async throws {
        let engine = try makeEngine()
        let latch = Gate()
        engine.scriptPhase5(.signUp) { call in
            guard case .signUp(let request) = call, request.username == "dave" else {
                return AuthClientSignUpResult(.confirmUser())
            }
            await latch.pass()
            return AuthClientSignUpResult(.completeAutoSignIn("session-dave"))
        }
        let daveRequest = Self.signUpRequest("dave")
        let dave = Task { try await engine.signUp(daveRequest) }
        await latch.waitForArrivals(1)
        _ = try await engine.signUp(Self.signUpRequest("erin"))
        await latch.open()
        _ = try await dave.value

        let held = await engine.hasAutoSignInSession
        XCTAssertFalse(held)
    }

    private static func signUpRequest(_ username: String) -> EngineSignUpRequest {
        EngineSignUpRequest(username: username, password: nil, userAttributes: [:], validationData: [:], clientMetadata: [:])
    }
}
