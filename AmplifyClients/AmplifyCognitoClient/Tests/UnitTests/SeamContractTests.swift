//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// The seam's sign-in contract over `FakeSessionEngine`: the cases in `SeamContractCases`, which
/// `LiveEngineSeamContractTests` runs over the live engine, so the fake the core's tests use and the engine
/// the app uses keep the same rules.
final class FakeEngineSeamContractTests: XCTestCase {

    private func driver() throws -> SeamContractDriver {
        try FakeSeamContractDriver()
    }

    /// A confirmation with nothing pending is refused.
    ///
    /// - Given: an engine with nothing pending
    /// - When: an answer is sent
    /// - Then: it throws `invalidState("There is no sign-in in progress for this session", …)`
    func testNothingPendingIsInvalidState() async throws {
        try await SeamContractCases.nothingPendingIsInvalidState(driver())
    }

    /// A challenge is returned and retained as the pending attempt.
    ///
    /// - Given: a sign-in that stops on a new-password challenge
    /// - When: it runs
    /// - Then: the challenge is returned and reported by `pendingChallenge`
    func testAChallengeIsRetained() async throws {
        try await SeamContractCases.aChallengeIsRetained(driver())
    }

    /// A retryable rejection keeps the attempt; the retry finishes.
    ///
    /// - Given: a pending new-password challenge whose first answer is rejected as an invalid password
    /// - When: the user answers, then answers again
    /// - Then: the first throws `.service(.invalidPassword)` and keeps the attempt; the second finishes
    func testARetryableRejectionKeepsTheAttempt() async throws {
        try await SeamContractCases.aRetryableRejectionKeepsTheAttempt(driver())
    }

    /// An expired challenge session drops the attempt.
    ///
    /// - Given: a pending challenge whose session has expired
    /// - When: the user answers
    /// - Then: it throws `challengeExpired`, the attempt is dropped, and a later answer is `invalidState`
    func testAnExpiredSessionDropsTheAttempt() async throws {
        try await SeamContractCases.anExpiredSessionDropsTheAttempt(driver())
    }

    /// A new sign-in supersedes the pending attempt.
    ///
    /// - Given: a pending challenge for alice
    /// - When: bob signs in
    /// - Then: bob's sign-in finishes and nothing is pending
    func testANewSignInSupersedes() async throws {
        try await SeamContractCases.aNewSignInSupersedes(driver())
    }

    /// A cancel drops the pending attempt.
    ///
    /// - Given: a pending challenge
    /// - When: `cancelPendingSignIn` runs
    /// - Then: nothing is pending, and a later answer is `invalidState`
    func testACancelDropsTheAttempt() async throws {
        try await SeamContractCases.aCancelDropsTheAttempt(driver())
    }
}

/// The same contract over the live engine and scripted Cognito.
final class LiveEngineSeamContractTests: XCTestCase {

    private var live: LiveSeamContractDriver?

    private func driver() throws -> SeamContractDriver {
        let driver = try LiveSeamContractDriver()
        live = driver
        return driver
    }

    override func tearDown() {
        live?.harness.cognito.assertConsumed()
        live = nil
        super.tearDown()
    }

    /// A confirmation with nothing pending is refused.
    ///
    /// - Given: an engine with nothing pending
    /// - When: an answer is sent
    /// - Then: it throws `invalidState("There is no sign-in in progress for this session", …)`
    func testNothingPendingIsInvalidState() async throws {
        try await SeamContractCases.nothingPendingIsInvalidState(driver())
    }

    /// A challenge is returned and retained as the pending attempt.
    ///
    /// - Given: SRP answered with `NEW_PASSWORD_REQUIRED`
    /// - When: alice signs in
    /// - Then: the challenge is returned and reported by `pendingChallenge`
    func testAChallengeIsRetained() async throws {
        try await SeamContractCases.aChallengeIsRetained(driver())
    }

    /// A retryable rejection keeps the attempt; the retry finishes.
    ///
    /// - Given: a pending new-password challenge, and Cognito rejecting the first answer with
    ///   `InvalidPasswordException`
    /// - When: the user answers, then answers again
    /// - Then: the first throws `.service(.invalidPassword)` and keeps the attempt; the second finishes
    func testARetryableRejectionKeepsTheAttempt() async throws {
        try await SeamContractCases.aRetryableRejectionKeepsTheAttempt(driver())
    }

    /// An expired challenge session drops the attempt.
    ///
    /// - Given: a pending challenge, and Cognito rejecting the answer with the expired-session
    ///   `NotAuthorizedException`
    /// - When: the user answers
    /// - Then: it throws `challengeExpired`, the attempt is dropped, and a later answer is `invalidState`
    func testAnExpiredSessionDropsTheAttempt() async throws {
        try await SeamContractCases.anExpiredSessionDropsTheAttempt(driver())
    }

    /// A new sign-in supersedes the pending attempt.
    ///
    /// - Given: a pending challenge for alice
    /// - When: bob signs in
    /// - Then: bob's sign-in finishes and nothing is pending
    func testANewSignInSupersedes() async throws {
        try await SeamContractCases.aNewSignInSupersedes(driver())
    }

    /// A cancel drops the pending attempt.
    ///
    /// - Given: a pending challenge
    /// - When: `cancelPendingSignIn` runs
    /// - Then: nothing is pending, and a later answer is `invalidState`
    func testACancelDropsTheAttempt() async throws {
        try await SeamContractCases.aCancelDropsTheAttempt(driver())
    }
}
