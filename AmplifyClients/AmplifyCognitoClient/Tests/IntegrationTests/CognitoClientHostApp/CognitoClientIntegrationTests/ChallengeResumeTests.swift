//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient
import Foundation
import XCTest

/// Design §4.11 against real Cognito and the real keychain: a sign-in interrupted on an MFA challenge
/// survives the app being closed. "Closed" is modelled as a test can model it: the client is released, the registry
/// holds no live session for it, and a new client is built with the same session ID over the same keychain, so
/// everything it knows comes from storage.
///
/// Failure messages name only step and state cases, never a code, a secret, a session string or a username.
final class ChallengeResumeTests: ClientMFATestCase {

    /// A fresh U-DEF user with TOTP enrolled and enabled, signed out, and the session ID the test signs in on.
    private func totpUser(_ tag: String) async throws -> (user: FreshUser, secret: TOTPSecret, sessionId: SessionID) {
        let (client, user) = try await signedInFreshUser(tag)
        let secret = try await enrollTOTP(client, user)
        try await client.updateMFAPreference(sms: nil, totp: .enabled)
        XCTAssertSignOutComplete(await client.signOut())
        return (user, secret, client.sessionId)
    }

    /// The session's challenge record, read from the real keychain.
    private func challengeRecord(_ sessionId: SessionID, pool: SandboxPool = .standard) throws -> SessionRecordStore.ChallengeRead {
        let configuration = try IntegrationTestEnvironment.configuration(pool)
        let store = SessionRecordStore(namespace: SessionStorageNamespace(pools: configuration.poolNamespace, accessGroup: nil))
        return try store.readChallenge(sessionId)
    }

    /// "The app was closed": waits until no client holds `sessionId`, then builds a new one over the same keychain.
    private func relaunch(_ sessionId: SessionID, pool: SandboxPool = .standard) async throws -> AmplifyCognitoClient {
        try await SessionCleanup.waitUntilReleased([sessionId])
        return try AmplifyCognitoClient(
            configuration: IntegrationTestEnvironment.configuration(pool),
            options: .init(sessionId: sessionId)
        )
    }

    /// Signs `user` in on a client for `sessionId`, which is released when this returns: the app closed mid-sign-in.
    private func signInThenClose(
        _ user: FreshUser,
        on sessionId: SessionID,
        pool: SandboxPool = .standard
    ) async throws -> AuthClientSignInStep {
        let client = try AmplifyCognitoClient(
            configuration: IntegrationTestEnvironment.configuration(pool),
            options: .init(sessionId: sessionId)
        )
        return try await client.signIn(username: user.username, password: user.password).nextStep
    }

    /// CR-1: the TOTP code is answered in a new client.
    ///
    /// - Given: a fresh user with TOTP MFA, signed out
    /// - When:
    ///    - the user signs in, which stops on the TOTP code, and the client is released
    ///    - a new client for the same session reads its state, then answers with a fresh code
    /// - Then:
    ///    - a challenge record is stored while the sign-in waits
    ///    - the new client reports `.awaitingChallenge(.confirmSignInWithTOTPCode)`
    ///    - the answer is `.done`, the session is signed in as the user, and the record is gone
    ///
    func testATOTPSignInResumesInANewClient() async throws {
        let (user, secret, sessionId) = try await totpUser("cr-1")

        let step = try await signInThenClose(user, on: sessionId)

        XCTAssertStep(step, .confirmSignInWithTOTPCode)
        guard case .record = try challengeRecord(sessionId) else {
            return XCTFail("a challenge record should be stored while the sign-in waits")
        }
        let client = try await relaunch(sessionId)
        let resumed = await client.currentSessionState()
        XCTAssertState(resumed, .awaitingChallenge(.confirmSignInWithTOTPCode))

        let confirmed = try await client.confirmSignIn(challengeResponse: TOTP.freshCode(secret: secret))

        XCTAssertStep(confirmed.nextStep, .done)
        try await assertSignedIn(user, on: client)
        XCTAssertTrue(try challengeRecord(sessionId) == .absent, "no challenge record is left")
    }

    /// CR-2: an emailed MFA code is answered in a new client.
    ///
    /// - Given: a fresh user with a verified email on U-REQ-E (MFA required, email), whose codes the code sink captures
    /// - When:
    ///    - the user signs in, which sends an email code and stops on it, and the client is released
    ///    - a new client for the same session answers with the captured code
    /// - Then:
    ///    - the new client reports `.awaitingChallenge(.confirmSignInWithOTP)` to an email destination
    ///    - the answer is `.done`, the session is signed in as the user, and the record is gone
    ///
    func testAnEmailMFASignInResumesInANewClient() async throws {
        try SandboxPools.pool(.mfaRequiredEmail).requireLive("email-mfa")
        let user = try await makeFreshUser(on: .mfaRequiredEmail)
        let sessionId = try makeSessionID("cr-2", pool: .mfaRequiredEmail)

        let (step, code) = try await CodeSink().code(for: user, .mfa) {
            try await self.signInThenClose(user, on: sessionId, pool: .mfaRequiredEmail)
        }

        guard case .confirmSignInWithOTP = step else {
            return XCTFail("the step is \(step.caseName), expected confirmSignInWithOTP")
        }
        let client = try await relaunch(sessionId, pool: .mfaRequiredEmail)
        let resumed = await client.currentSessionState()
        guard case .awaitingChallenge(.confirmSignInWithOTP(let delivery)) = resumed,
              case .email = delivery.destination else {
            return XCTFail("the state is \(resumed.redactedDescription), expected an email OTP challenge")
        }

        let confirmed = try await client.confirmSignIn(challengeResponse: code)

        XCTAssertStep(confirmed.nextStep, .done)
        try await assertSignedIn(user, on: client)
        XCTAssertTrue(try challengeRecord(sessionId, pool: .mfaRequiredEmail) == .absent, "no challenge record is left")
    }

    /// CR-3: the app chooses to start over (§4.11), superseding the saved sign-in.
    ///
    /// - Given: a fresh user with TOTP MFA whose sign-in stopped on the code, the app closed
    /// - When:
    ///    - a new client for the same session signs in again instead of answering, then answers that sign-in
    /// - Then:
    ///    - the new sign-in's challenge replaces the saved one: the stored session string is a different one
    ///    - the answer is `.done`, and no challenge record is left
    ///
    func testANewSignInSupersedesTheSavedOne() async throws {
        let (user, secret, sessionId) = try await totpUser("cr-3")
        _ = try await signInThenClose(user, on: sessionId)
        guard case .record(let saved) = try challengeRecord(sessionId) else {
            return XCTFail("a challenge record should be stored while the sign-in waits")
        }
        let client = try await relaunch(sessionId)
        let resumed = await client.currentSessionState()
        XCTAssertState(resumed, .awaitingChallenge(.confirmSignInWithTOTPCode))

        let again = try await client.signIn(username: user.username, password: user.password)

        XCTAssertStep(again.nextStep, .confirmSignInWithTOTPCode)
        guard case .record(let replaced) = try challengeRecord(sessionId) else {
            return XCTFail("the new sign-in's challenge should be stored")
        }
        XCTAssertTrue(replaced.state.session != saved.state.session, "the new sign-in has its own Cognito session")

        let confirmed = try await client.confirmSignIn(challengeResponse: TOTP.freshCode(secret: secret))

        XCTAssertStep(confirmed.nextStep, .done)
        XCTAssertTrue(try challengeRecord(sessionId) == .absent, "no challenge record is left")
    }

    /// Asserts `client` is signed in as `user`, printing neither.
    private func assertSignedIn(_ user: FreshUser, on client: AmplifyCognitoClient, file: StaticString = #filePath, line: UInt = #line) async throws {
        let current = try await client.getCurrentUser()
        XCTAssertTrue(current.username == user.username, "signed in as another user", file: file, line: line)
        let state = await client.currentSessionState()
        XCTAssertState(state, .signedIn(current), file: file, line: line)
    }
}
