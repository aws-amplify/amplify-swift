//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient
import XCTest

/// Custom authentication through the client (CA-1 … CA-3): the plugin's
/// `AuthCustomSignInTests`, which run on a backend with the custom-auth triggers and their answer in the
/// credentials file.
///
/// The default backend (`SandboxPool.standard`) carries the custom-auth triggers (the sandbox's P-5b):
/// define-auth-challenge answers `SRP_A → PASSWORD_VERIFIER → CUSTOM_CHALLENGE`, or `CUSTOM_CHALLENGE`
/// alone, create-auth-challenge publishes `challenge: fixed-answer`, and the verify trigger accepts the
/// answer the plugin's test takes from the default credentials file, `custom_challenge_answer`. Each test
/// signs up its own user. The answer is a secret: it is never printed, and the recorder never keeps a
/// challenge answer.
final class CustomAuthTests: ClientIntegrationTestCase {

    private static let pool = SandboxPool.standard

    /// What the create-auth-challenge trigger publishes with every custom challenge (not a secret).
    private static let publicChallenge = ["challenge": "fixed-answer"]

    private var answer: String!

    override func setUp() async throws {
        try await super.setUp()
        answer = try IntegrationTestEnvironment.credentials().requireCustomChallengeAnswer().value
    }

    /// `customWithSRP`: SRP, then the custom challenge (CA-1; the plugin's
    /// `testSuccessfulSignInWithCustomAuthSRP`).
    ///
    /// - Given: a fresh user on the pool with the custom-auth triggers, and the recorder installed
    /// - When:
    ///    - the user signs in with `customWithSRP` and the password
    ///    - and confirms with the custom challenge's answer
    /// - Then:
    ///    - the sign-in returns `.confirmSignInWithCustomChallenge` with the trigger's public parameters,
    ///      and the session waits on it
    ///    - it began with `InitiateAuth` `CUSTOM_AUTH` and answered only `PASSWORD_VERIFIER`: the custom
    ///      challenge came after the password was verified
    ///    - the confirmation answers `CUSTOM_CHALLENGE`, returns `.done`, and the session is signed in as
    ///      the user
    ///
    func testSuccessfulSignInWithCustomAuthSRP() async throws {
        let user = try await makeFreshUser(on: Self.pool)
        let recorder = RecordingHTTPClient()
        let client = try makeClient("ca-1", pool: Self.pool, configureUserPoolClient: recorder.configureUserPoolClient)

        let result = try await client.signIn(
            username: user.username,
            password: user.password,
            options: .init(authFlowType: .customWithSRP)
        )

        try assertCustomChallenge(result.nextStep)
        let pending = await client.currentSessionState()
        XCTAssertTrue(pending.pendingStep.map(Self.isCustomChallenge) == true, pending.redactedDescription)
        let signInRequests = recorder.answered
        XCTAssertEqual(signInRequests.compactMap(\.operation), ["InitiateAuth", "RespondToAuthChallenge"])
        XCTAssertEqual(signInRequests.first?.authFlow, "CUSTOM_AUTH")
        XCTAssertEqual(signInRequests.compactMap(\.challengeName), ["PASSWORD_VERIFIER"])

        recorder.reset()
        let confirmed = try await client.confirmSignIn(challengeResponse: answer)

        XCTAssertStep(confirmed.nextStep, .done)
        XCTAssertEqual(recorder.answered.compactMap(\.challengeName), ["CUSTOM_CHALLENGE"])
        try await assertSignedIn(client, as: user)
    }

    /// `customWithSRP`, sign out, then `userSRP` on the same session (CA-2; the plugin's
    /// `testRuntimeAuthFlowSwitch`).
    ///
    /// - Given: a fresh user on the pool with the custom-auth triggers, and the recorder installed
    /// - When:
    ///    - the user signs in with `customWithSRP`, answers the custom challenge the trigger adds after
    ///      the password, and signs out
    ///    - then signs in again on the same client and session with `userSRP`
    /// - Then:
    ///    - the first sign-in starts `CUSTOM_AUTH`, answers `PASSWORD_VERIFIER`, reaches
    ///      `.confirmSignInWithCustomChallenge`, then `.done` after exactly `CUSTOM_CHALLENGE`
    ///    - the sign-out is complete and leaves the session signed out
    ///    - the second sign-in returns `.done` with no step: one `InitiateAuth` `USER_SRP_AUTH`, then
    ///      exactly `PASSWORD_VERIFIER` and the remembered device's `DEVICE_SRP_AUTH` and
    ///      `DEVICE_PASSWORD_VERIFIER`, with no custom challenge; the session is signed in as the user
    ///
    func testRuntimeAuthFlowSwitch() async throws {
        let user = try await makeFreshUser(on: Self.pool)
        let recorder = RecordingHTTPClient()
        let client = try makeClient("ca-2", pool: Self.pool, configureUserPoolClient: recorder.configureUserPoolClient)

        let custom = try await client.signIn(
            username: user.username,
            password: user.password,
            options: .init(authFlowType: .customWithSRP)
        )
        try assertCustomChallenge(custom.nextStep)
        let customRequests = recorder.answered
        XCTAssertEqual(customRequests.compactMap(\.operation), ["InitiateAuth", "RespondToAuthChallenge"])
        XCTAssertEqual(customRequests.first?.authFlow, "CUSTOM_AUTH")
        XCTAssertEqual(customRequests.compactMap(\.challengeName), ["PASSWORD_VERIFIER"])
        recorder.reset()
        let confirmed = try await client.confirmSignIn(challengeResponse: answer)
        XCTAssertStep(confirmed.nextStep, .done)
        XCTAssertEqual(recorder.answered.compactMap(\.challengeName), ["CUSTOM_CHALLENGE"])
        try await assertSignedIn(client, as: user)

        let signOut = await client.signOut()
        XCTAssertSignOutComplete(signOut)
        guard signOut == .complete else {
            return
        }
        let signedOut = await client.currentSessionState()
        XCTAssertState(signedOut, .signedOut)

        recorder.reset()
        let srp = try await client.signIn(
            username: user.username,
            password: user.password,
            options: .init(authFlowType: .userSRP)
        )

        XCTAssertStep(srp.nextStep, .done)
        // The pool remembers every device, so the SRP sign-in also proves the device the first one confirmed.
        let srpRequests = recorder.answered
        XCTAssertEqual(srpRequests.filter { $0.operation == "InitiateAuth" }.map(\.authFlow), ["USER_SRP_AUTH"])
        XCTAssertEqual(srpRequests.first?.operation, "InitiateAuth")
        XCTAssertEqual(
            srpRequests.compactMap(\.challengeName),
            ["PASSWORD_VERIFIER", "DEVICE_SRP_AUTH", "DEVICE_PASSWORD_VERIFIER"]
        )
        try await assertSignedIn(client, as: user)
    }

    /// `customWithoutSRP`: the custom challenge alone (CA-3; the plugin's
    /// `testSuccessfulSignInWithCustomAuth`).
    ///
    /// - Given: a fresh user on the pool with the custom-auth triggers, and the recorder installed
    /// - When:
    ///    - the user signs in with `customWithoutSRP`
    ///    - and confirms with the custom challenge's answer
    /// - Then:
    ///    - the sign-in returns `.confirmSignInWithCustomChallenge` with the trigger's public parameters,
    ///      after a single `InitiateAuth` `CUSTOM_AUTH` and no password step
    ///    - the confirmation answers `CUSTOM_CHALLENGE`, returns `.done`, and the session is signed in as
    ///      the user
    ///
    func testSuccessfulSignInWithCustomAuth() async throws {
        let user = try await makeFreshUser(on: Self.pool)
        let recorder = RecordingHTTPClient()
        let client = try makeClient("ca-3", pool: Self.pool, configureUserPoolClient: recorder.configureUserPoolClient)

        let result = try await client.signIn(
            username: user.username,
            password: user.password,
            options: .init(authFlowType: .customWithoutSRP)
        )

        try assertCustomChallenge(result.nextStep)
        XCTAssertEqual(recorder.answered.compactMap(\.operation), ["InitiateAuth"])
        XCTAssertEqual(recorder.answered.first?.authFlow, "CUSTOM_AUTH")

        recorder.reset()
        let confirmed = try await client.confirmSignIn(challengeResponse: answer)

        XCTAssertStep(confirmed.nextStep, .done)
        XCTAssertEqual(recorder.answered.compactMap(\.challengeName), ["CUSTOM_CHALLENGE"])
        try await assertSignedIn(client, as: user)
    }

    // MARK: - Helpers

    private static func isCustomChallenge(_ step: AuthClientSignInStep) -> Bool {
        if case .confirmSignInWithCustomChallenge = step {
            return true
        }
        return false
    }

    /// Asserts the custom-challenge step, with the trigger's public parameters. Prints case names only.
    private func assertCustomChallenge(
        _ step: AuthClientSignInStep,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        guard case .confirmSignInWithCustomChallenge(let parameters) = step else {
            XCTFail("the step is \(step.caseName), expected confirmSignInWithCustomChallenge", file: file, line: line)
            throw HarnessError.malformedFixture("no custom challenge")
        }
        XCTAssertEqual(
            parameters?["challenge"],
            Self.publicChallenge["challenge"],
            "the custom challenge should carry the trigger's public parameter",
            file: file,
            line: line
        )
    }

    /// Asserts the session is signed in as `user`, printing no username or sub.
    private func assertSignedIn(
        _ client: AmplifyCognitoClient,
        as user: FreshUser,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        let current = try await client.getCurrentUser()
        XCTAssertTrue(current.username == user.username, "signed in as another user", file: file, line: line)
        XCTAssertTrue(current.userId == user.userSub, "signed in with another sub", file: file, line: line)
        let state = await client.currentSessionState()
        XCTAssertState(state, .signedIn(current), file: file, line: line)
    }
}
