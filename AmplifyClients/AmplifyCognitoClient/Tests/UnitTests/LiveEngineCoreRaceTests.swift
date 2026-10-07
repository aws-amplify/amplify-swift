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

/// Races between the core and the live engine that only show with both real.
final class LiveEngineCoreRaceTests: XCTestCase {

    /// A sign-out's engine cancel never ends a sign-in that began after the sign-out moved the epoch.
    ///
    /// - Given: alice's sign-in waiting on an SMS code, an engine whose first cancel is held on a gate, and
    ///   bob's sign-in with `GetId` held on a second gate
    /// - When:
    ///    - the session signs out (its engine cancel is held), bob signs in and reaches `GetId`, the cancel is
    ///      let go, then `GetId` is
    /// - Then:
    ///    - bob's sign-in finishes `.done`, with no raw `CancellationError`, and the session is signed in as
    ///      bob
    ///    - bob's refresh token was never revoked, and it is the one committed
    ///
    func testASignOutsCancelDoesNotEndALaterSignIn() async throws {
        let live = LiveEngineHarness()
        let cancelGate = Gate()
        let engine = CancelHoldingEngine(base: try live.engine(), gate: cancelGate)
        let clientHarness = ClientHarness()
        let base = clientHarness.dependencies
        let dependencies = SessionCoreDependencies(
            registry: base.registry,
            gates: base.gates,
            makeStore: base.makeStore,
            makeClients: base.makeClients,
            makeEngine: { _ in engine },
            makeRevoker: base.makeRevoker,
            scheduleRestore: base.scheduleRestore,
            bounds: base.bounds,
            now: { Date() }
        )
        let work = ClientFixtures.id("work")
        let client = try AmplifyCognitoClient(
            configuration: ClientFixtures.configuration,
            options: .init(sessionId: work),
            dependencies: dependencies
        )
        live.scriptSRP(then: LiveEngineFixtures.challenge(.smsMfa, parameters: LiveEngineFixtures.smsParameters))
        let first = try await client.signIn(username: "alice", password: "password")
        guard case .confirmSignInWithSMSMFACode = first.nextStep else {
            return XCTFail("expected alice's SMS challenge, got \(first.nextStep)")
        }
        live.scriptSignOut()

        let signOut = Task { await client.signOut() }
        await cancelGate.waitForArrivals(1)
        let getId = Gate()
        live.scriptSRP("bob")
        live.cognito.once("GetId") { (_: GetIdInput) in
            await getId.pass()
            return GetIdOutput(identityId: LiveEngineFixtures.identityId)
        }
        live.cognito.always("GetCredentialsForIdentity") { (input: GetCredentialsForIdentityInput) in
            GetCredentialsForIdentityOutput(credentials: LiveEngineFixtures.awsCredentials(), identityId: input.identityId)
        }
        let second = Task { try await client.signIn(username: "bob", password: "password") }
        await getId.waitForArrivals(1)
        await cancelGate.open()
        _ = await signOut.value
        await getId.open()
        let result = await second.result

        guard case .success(let signedIn) = result else {
            return XCTFail("bob's sign-in should finish, got \(result)")
        }
        XCTAssertEqual(signedIn.nextStep, .done)
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedIn(AuthClientUser(username: "bob", userId: "sub-bob")))
        let revoked = live.cognito.inputs("RevokeToken", as: RevokeTokenInput.self).map(\.token)
        XCTAssertFalse(revoked.contains("refresh-bob-v1"), "bob's committed refresh token was revoked")
        let record = try XCTUnwrap(clientHarness.storedRecord(work))
        XCTAssertEqual(try engine.userPoolTokens(in: XCTUnwrap(record.credentials))?.refreshToken, "refresh-bob-v1")
    }

    /// A confirmation that reaches the engine after a sign-out moved the epoch, but before its cancel
    /// arrived, never answers the old attempt.
    ///
    /// - Given: alice's sign-in waiting on an SMS code, and an engine whose first cancel is held on a gate
    /// - When:
    ///    - the session signs out (its engine cancel is held), then the code is answered, then the cancel is
    ///      let go
    /// - Then:
    ///    - the confirmation throws `invalidState` and sends nothing to Cognito; the session stays signed out
    ///
    func testAConfirmationAfterASignOutNeverAnswersTheOldAttempt() async throws {
        let live = LiveEngineHarness()
        let cancelGate = Gate()
        let engine = CancelHoldingEngine(base: try live.engine(), gate: cancelGate)
        let clientHarness = ClientHarness()
        let client = try Self.client(over: engine, harness: clientHarness)
        live.scriptSRP(then: LiveEngineFixtures.challenge(.smsMfa, parameters: LiveEngineFixtures.smsParameters))
        let first = try await client.signIn(username: "alice", password: "password")
        guard case .confirmSignInWithSMSMFACode = first.nextStep else {
            return XCTFail("expected alice's SMS challenge, got \(first.nextStep)")
        }
        live.cognito.clearCalls()

        let signOut = Task { await client.signOut() }
        await cancelGate.waitForArrivals(1)
        let confirm = await authClientError { try await client.confirmSignIn(challengeResponse: "123456") }
        await cancelGate.open()
        _ = await signOut.value

        XCTAssertEqual(confirm?.kind, .invalidState)
        XCTAssertEqual(live.cognito.operations, [], "the old attempt's answer was sent")
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedOut)
    }

    static func client(over engine: any SessionEngine, harness clientHarness: ClientHarness) throws -> AmplifyCognitoClient {
        let base = clientHarness.dependencies
        let dependencies = SessionCoreDependencies(
            registry: base.registry,
            gates: base.gates,
            makeStore: base.makeStore,
            makeClients: base.makeClients,
            makeEngine: { _ in engine },
            makeRevoker: base.makeRevoker,
            scheduleRestore: base.scheduleRestore,
            bounds: base.bounds,
            now: { Date() }
        )
        return try AmplifyCognitoClient(
            configuration: ClientFixtures.configuration,
            options: .init(sessionId: ClientFixtures.id("work")),
            dependencies: dependencies
        )
    }
}

/// The live engine, with its first `cancelPendingSignIn` held on a gate: the moment between the core
/// moving its epoch and the engine hearing of it.
final class CancelHoldingEngine: SessionEngine, SessionEngineForwarding, @unchecked Sendable {

    let base: LiveSessionEngine
    let gate: Gate
    private let held = Counter()

    init(base: LiveSessionEngine, gate: Gate) {
        self.base = base
        self.gate = gate
    }

    var forwardingBase: any SessionEngine { base }

    func describe(_ payload: Data) throws -> CredentialSummary { try base.describe(payload) }
    func awsCredentials(in payload: Data) throws -> CognitoAWSCredentials? { try base.awsCredentials(in: payload) }
    func accessToken(in payload: Data) throws -> String? { try base.accessToken(in: payload) }
    func userPoolTokens(in payload: Data) throws -> AuthClientUserPoolTokens? { try base.userPoolTokens(in: payload) }
    func needsRefresh(_ payload: Data, at now: Date) throws -> Bool { try base.needsRefresh(payload, at: now) }
    func userPoolTokensNeedRefresh(_ payload: Data, at now: Date) throws -> Bool {
        try base.userPoolTokensNeedRefresh(payload, at: now)
    }

    func signIn(_ request: EngineSignInRequest, current: Data?, epoch: UInt64) async throws -> EngineStepResult {
        try await base.signIn(request, current: current, epoch: epoch)
    }

    func confirmSignIn(_ request: EngineConfirmSignInRequest, current: Data?, epoch: UInt64) async throws -> EngineStepResult {
        try await base.confirmSignIn(request, current: current, epoch: epoch)
    }

    func refresh(_ payload: Data, force: Bool) async throws -> Data { try await base.refresh(payload, force: force) }
    func fetchGuestCredentials(current: Data?) async throws -> Data { try await base.fetchGuestCredentials(current: current) }
    func deleteUser(_ payload: Data) async throws { try await base.deleteUser(payload) }

    var pendingChallenge: AuthClientSignInStep? {
        get async { await base.pendingChallenge }
    }

    func cancelPendingSignIn(before epoch: UInt64) async {
        if await held.increment() == 1 {
            await gate.pass()
        }
        await base.cancelPendingSignIn(before: epoch)
    }
}
