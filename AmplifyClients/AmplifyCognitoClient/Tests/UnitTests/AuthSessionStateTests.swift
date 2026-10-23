//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyFoundation
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

final class AuthSessionStateTests: XCTestCase {

    private struct Underlying: Error, Equatable {
        let code: Int
    }

    /// One value of every `AuthSessionState` case.
    private static let oneOfEach: [AuthSessionState] = [
        .signedIn(AuthClientUser(username: "alice", userId: "sub-1")),
        .federated(identityId: "us-east-1:federated"),
        .signedOut,
        .guest,
        .awaitingChallenge(.confirmSignInWithTOTPCode),
        .unavailable(.locked),
        .failed(.configuration("bad config", "fix it"))
    ]

    /// Exhaustive on purpose: a new state case does not compile until `oneOfEach` is revisited.
    private static func name(of state: AuthSessionState) -> String {
        switch state {
        case .signedIn: return "signedIn"
        case .federated: return "federated"
        case .signedOut: return "signedOut"
        case .guest: return "guest"
        case .awaitingChallenge: return "awaitingChallenge"
        case .unavailable: return "unavailable"
        case .failed: return "failed"
        }
    }

    /// Every `AuthClientError` case, by name. `errorCase(of:)` and `sample(of:)` keep it complete.
    private enum ErrorCase: CaseIterable {
        case configuration, storageUnavailable, sessionExpired, notSignedIn, invalidSessionID, challengeExpired
        case browserBusy, sessionConfigurationMismatch, validation, service, notAuthorized, invalidState
        case userCancelled, webAuthnCeremonyFailed, unexpectedIdentity, unknown
    }

    /// Exhaustive on purpose, with no `default`: a new `AuthClientError` case does not compile until it is
    /// given an `ErrorCase`, and then `sample(of:)` does not compile until it is given a sample.
    private static func errorCase(of error: AuthClientError) -> ErrorCase {
        switch error {
        case .configuration: return .configuration
        case .storageUnavailable: return .storageUnavailable
        case .sessionExpired: return .sessionExpired
        case .notSignedIn: return .notSignedIn
        case .invalidSessionID: return .invalidSessionID
        case .challengeExpired: return .challengeExpired
        case .browserBusy: return .browserBusy
        case .sessionConfigurationMismatch: return .sessionConfigurationMismatch
        case .validation: return .validation
        case .service: return .service
        case .notAuthorized: return .notAuthorized
        case .invalidState: return .invalidState
        case .userCancelled: return .userCancelled
        case .webAuthnCeremonyFailed: return .webAuthnCeremonyFailed
        case .unexpectedIdentity: return .unexpectedIdentity
        case .unknown: return .unknown
        }
    }

    /// One value of `errorCase`, with the same strings as every other, so only the case and its structured
    /// payload tell them apart.
    private static func sample(of errorCase: ErrorCase) -> AuthClientError {
        switch errorCase {
        case .configuration: return .configuration("d", "s")
        case .storageUnavailable: return .storageUnavailable(.locked, "d", "s")
        case .sessionExpired: return .sessionExpired("d", "s")
        case .notSignedIn: return .notSignedIn("d", "s")
        case .invalidSessionID: return .invalidSessionID("d", "s")
        case .challengeExpired: return .challengeExpired("d", "s")
        case .browserBusy: return .browserBusy(holder: .default, "d", "s")
        case .sessionConfigurationMismatch: return .sessionConfigurationMismatch(.default, "d", "s")
        case .validation: return .validation(field: "f", "d", "s")
        case .service: return .service(.userNotFound, "d", "s")
        case .notAuthorized: return .notAuthorized("d", "s")
        case .invalidState: return .invalidState("d", "s")
        case .userCancelled: return .userCancelled("d", "s")
        case .webAuthnCeremonyFailed: return .webAuthnCeremonyFailed(.failed, "d", "s")
        case .unexpectedIdentity: return .unexpectedIdentity(expected: "alice", returned: AuthClientUser(username: "bob", userId: "sub-bob"), "d", "s")
        case .unknown: return .unknown("d", "s")
        }
    }

    /// One value of every `AuthClientError` case, from `sample(of:)`.
    private static func oneOfEachError() -> [AuthClientError] {
        ErrorCase.allCases.map(sample(of:))
    }

    // MARK: - The case matrix

    /// - Given: one value of each of the seven cases, named through an exhaustive switch
    /// - When: every pair is compared
    /// - Then:
    ///    - each value equals itself and differs from every other case, so no case (in particular
    ///      `.guest` or `.unavailable`) collapses into `.signedOut`
    func testEveryCaseEqualsItselfAndDiffersFromEveryOther() {
        XCTAssertEqual(
            Self.oneOfEach.map(Self.name(of:)),
            ["signedIn", "federated", "signedOut", "guest", "awaitingChallenge", "unavailable", "failed"]
        )
        for (index, state) in Self.oneOfEach.enumerated() {
            for (otherIndex, other) in Self.oneOfEach.enumerated() {
                if index == otherIndex {
                    XCTAssertEqual(state, other, "\(Self.name(of: state)) should equal itself")
                } else {
                    XCTAssertNotEqual(state, other, "\(Self.name(of: state)) vs \(Self.name(of: other))")
                }
            }
        }
    }

    // MARK: - Payload-carrying cases

    /// - Given: `.signedIn` with the same user, and with users differing in either field
    /// - When: they are compared
    /// - Then:
    ///    - only the same user compares equal
    func testSignedInComparesTheUser() {
        let alice = AuthClientUser(username: "alice", userId: "sub-1")
        XCTAssertEqual(AuthSessionState.signedIn(alice), .signedIn(AuthClientUser(username: "alice", userId: "sub-1")))
        XCTAssertNotEqual(AuthSessionState.signedIn(alice), .signedIn(AuthClientUser(username: "bob", userId: "sub-1")))
        XCTAssertNotEqual(AuthSessionState.signedIn(alice), .signedIn(AuthClientUser(username: "alice", userId: "sub-2")))
    }

    /// - Given: `.federated` with the same identity and a different one
    /// - When: they are compared
    /// - Then:
    ///    - only the same identity compares equal
    func testFederatedComparesTheIdentity() {
        XCTAssertEqual(AuthSessionState.federated(identityId: "us-east-1:a"), .federated(identityId: "us-east-1:a"))
        XCTAssertNotEqual(AuthSessionState.federated(identityId: "us-east-1:a"), .federated(identityId: "us-east-1:b"))
    }

    /// - Given: `.awaitingChallenge` with the same step, a different step, and the same step with
    ///   a different payload
    /// - When: they are compared
    /// - Then:
    ///    - only the identical step compares equal
    func testAwaitingChallengeComparesTheStep() {
        let email = AuthClientCodeDeliveryDetails(destination: .email("a***"))
        let sms = AuthClientCodeDeliveryDetails(destination: .sms("+1***"))
        XCTAssertEqual(AuthSessionState.awaitingChallenge(.confirmSignInWithOTP(email)), .awaitingChallenge(.confirmSignInWithOTP(email)))
        XCTAssertNotEqual(AuthSessionState.awaitingChallenge(.confirmSignInWithOTP(email)), .awaitingChallenge(.confirmSignInWithOTP(sms)))
        XCTAssertNotEqual(AuthSessionState.awaitingChallenge(.confirmSignInWithTOTPCode), .awaitingChallenge(.done))
    }

    /// - Given: `.unavailable` with each `StorageUnavailableReason`
    /// - When: they are compared
    /// - Then:
    ///    - only the same reason compares equal, so "wait" (`locked`) stays distinct from
    ///      "misconfigured" (`denied`)
    func testUnavailableComparesTheReason() {
        let reasons: [StorageUnavailableReason] = [.locked, .interrupted, .denied]
        for reason in reasons {
            for other in reasons {
                XCTAssertEqual(AuthSessionState.unavailable(reason) == .unavailable(other), reason == other)
            }
        }
    }

    // MARK: - The `.failed` rule

    /// - Given: two `.failed` states whose errors are the same case with the same strings
    /// - When: they are compared
    /// - Then:
    ///    - they are equal
    func testFailedEqualWhenSameCaseAndStrings() {
        XCTAssertEqual(
            AuthSessionState.failed(.configuration("bad config", "fix it")),
            .failed(.configuration("bad config", "fix it"))
        )
    }

    /// The rule is not payload-blind: every `AuthClientError` case, given identical strings,
    /// is still a different failure.
    ///
    /// - Given: one error of every `AuthClientError` case, built through exhaustive switches, all carrying the
    ///   same description and suggestion
    /// - When: each pair is wrapped in `.failed` and compared
    /// - Then:
    ///    - every sample is of the case it was built for
    ///    - each equals itself and differs from every other case
    func testFailedDistinguishesEveryErrorCase() {
        let errors = Self.oneOfEachError()
        XCTAssertEqual(errors.map(Self.errorCase(of:)), ErrorCase.allCases)
        for (index, error) in errors.enumerated() {
            for (otherIndex, other) in errors.enumerated() {
                XCTAssertEqual(
                    AuthSessionState.failed(error) == .failed(other),
                    index == otherIndex,
                    "\(error) vs \(other)"
                )
            }
        }
    }

    /// - Given: `.failed` errors of one case that differ only in description, or only in
    ///   recovery suggestion
    /// - When: they are compared
    /// - Then:
    ///    - they are unequal
    func testFailedComparesDescriptionAndSuggestion() {
        XCTAssertNotEqual(AuthSessionState.failed(.unknown("a", "s")), .failed(.unknown("b", "s")))
        XCTAssertNotEqual(AuthSessionState.failed(.unknown("d", "a")), .failed(.unknown("d", "b")))
    }

    /// - Given: `.failed` errors of one case that differ only in their structured payload: the
    ///   storage reason, the busy holder, the mismatched session, the validation field, the service
    ///   code, the ceremony failure, and the expected or returned user of an unexpected identity
    /// - When: they are compared
    /// - Then:
    ///    - each pair is unequal, and a pair with equal payloads is equal
    func testFailedComparesStructuredPayload() throws {
        let work = try SessionID.named("work")
        XCTAssertNotEqual(
            AuthSessionState.failed(.storageUnavailable(.locked, "d", "s")),
            .failed(.storageUnavailable(.denied, "d", "s"))
        )
        XCTAssertNotEqual(
            AuthSessionState.failed(.browserBusy(holder: .default, "d", "s")),
            .failed(.browserBusy(holder: work, "d", "s"))
        )
        XCTAssertNotEqual(
            AuthSessionState.failed(.sessionConfigurationMismatch(.default, "d", "s")),
            .failed(.sessionConfigurationMismatch(work, "d", "s"))
        )
        XCTAssertNotEqual(
            AuthSessionState.failed(.validation(field: "appName", "d", "s")),
            .failed(.validation(field: "accountName", "d", "s"))
        )
        XCTAssertNotEqual(
            AuthSessionState.failed(.service(.userNotFound, "d", "s")),
            .failed(.service(.codeMismatch, "d", "s"))
        )
        XCTAssertNotEqual(
            AuthSessionState.failed(.service(.userNotFound, "d", "s")),
            .failed(.service(nil, "d", "s"))
        )
        XCTAssertNotEqual(
            AuthSessionState.failed(.webAuthnCeremonyFailed(.failed, "d", "s")),
            .failed(.webAuthnCeremonyFailed(.credentialAlreadyExists, "d", "s"))
        )
        let bob = AuthClientUser(username: "bob", userId: "sub-bob")
        XCTAssertNotEqual(
            AuthSessionState.failed(.unexpectedIdentity(expected: "alice", returned: bob, "d", "s")),
            .failed(.unexpectedIdentity(expected: nil, returned: bob, "d", "s"))
        )
        XCTAssertNotEqual(
            AuthSessionState.failed(.unexpectedIdentity(expected: "alice", returned: bob, "d", "s")),
            .failed(.unexpectedIdentity(expected: "alice", returned: AuthClientUser(username: "bob", userId: "sub-other"), "d", "s"))
        )
        XCTAssertEqual(
            AuthSessionState.failed(.browserBusy(holder: work, "d", "s")),
            .failed(.browserBusy(holder: try SessionID.named("work"), "d", "s"))
        )
        XCTAssertEqual(
            AuthSessionState.failed(.unexpectedIdentity(expected: "alice", returned: bob, "d", "s")),
            .failed(.unexpectedIdentity(expected: "alice", returned: AuthClientUser(username: "bob", userId: "sub-bob"), "d", "s"))
        )
    }

    /// The one documented blind spot: `any Error` has no equality, so the underlying error is
    /// not compared. This pins that, so a change to the rule is a deliberate one.
    ///
    /// - Given: `.failed` errors identical except for the underlying error (different, and absent)
    /// - When: they are compared
    /// - Then:
    ///    - they are equal
    func testFailedIgnoresUnderlyingError() {
        XCTAssertEqual(
            AuthSessionState.failed(.unknown("d", "s", Underlying(code: 1))),
            .failed(.unknown("d", "s", Underlying(code: 2)))
        )
        XCTAssertEqual(
            AuthSessionState.failed(.unknown("d", "s", Underlying(code: 1))),
            .failed(.unknown("d", "s"))
        )
    }
}
