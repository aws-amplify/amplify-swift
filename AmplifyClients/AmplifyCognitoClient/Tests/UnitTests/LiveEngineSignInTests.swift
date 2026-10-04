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

/// The live engine's sign-in over scripted Cognito: every flow, the
/// challenges, and the seam's rules for the pending attempt.
final class LiveEngineSignInTests: XCTestCase {

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

    // MARK: Configuring an operation

    /// Configuring an operation makes no Cognito call and no keychain call, for every payload kind.
    ///
    /// - Given: an operation seeded with each frozen payload fixture, and one seeded with nothing
    /// - When:
    ///    - it is configured
    /// - Then:
    ///    - it reaches `.configured`, with the kind's authentication state
    ///    - no Cognito operation was called, and the keychain was neither read nor written
    ///
    func testConfigureMakesNoCognitoOrKeychainCalls() async throws {
        let resources = try harness.resources()
        for seed in try EnginePayloadFixtures.caseNames.map(EnginePayloadFixtures.data) + [nil] {
            let operation = try resources.makeOperation(seed: seed)

            let (authentication, _) = try await operation.configure(resources.authConfiguration)

            switch try seed.map(AmplifyCredentials.decoded) {
            case .userPoolOnly?, .userPoolAndIdentityPool?:
                guard case .signedIn = authentication else {
                    return XCTFail("a user pool payload should configure signed in, got \(authentication)")
                }
            case .identityPoolWithFederation?:
                guard case .federatedToIdentityPool = authentication else {
                    return XCTFail("a federated payload should configure federated, got \(authentication)")
                }
            case .identityPoolOnly?, .noCredentials?, nil:
                guard case .signedOut = authentication else {
                    return XCTFail("a guest or empty payload should configure signed out, got \(authentication)")
                }
            }
        }
        XCTAssertEqual(harness.cognito.operations, [])
        XCTAssertEqual(harness.keychain.readAccounts, [])
        XCTAssertFalse(harness.keychain.hasMutations)
    }

    // MARK: SRP

    /// The SRP happy path with both pools: the plugin's call sequence, and a payload for the user.
    ///
    /// - Given: Cognito scripted for SRP and the identity pool
    /// - When:
    ///    - alice signs in with no flow given (the configuration's `USER_SRP_AUTH`)
    /// - Then:
    ///    - the result is `.done` with a `userPoolAndIdentityPool` payload for alice, her identity and AWS
    ///      credentials
    ///    - the calls are `InitiateAuth` (`USER_SRP_AUTH`, `SRP_A`), `RespondToAuthChallenge`
    ///      (`PASSWORD_VERIFIER`), `GetId` with alice's id token as the login, `GetCredentialsForIdentity`
    ///    - nothing is pending
    ///
    func testSRPSignInFollowsThePluginsCallSequence() async throws {
        let engine = try harness.engine()
        harness.scriptSRP()
        harness.scriptIdentityPool()

        let result = try await engine.signIn(.srp(), current: nil)

        guard case .done(let payload) = result else {
            return XCTFail("expected .done, got \(result)")
        }
        let credentials = try AmplifyCredentials.decoded(payload)
        guard case .userPoolAndIdentityPool(let signedIn, let identityId, let aws) = credentials else {
            return XCTFail("expected user pool and identity pool credentials, got \(credentials)")
        }
        XCTAssertEqual(signedIn.username, "alice")
        XCTAssertEqual(signedIn.userId, "sub-alice")
        XCTAssertEqual(signedIn.cognitoUserPoolTokens.refreshToken, "refresh-alice-v1")
        XCTAssertEqual(identityId, LiveEngineFixtures.identityId)
        XCTAssertEqual(aws.accessKeyId, "AKID-v1")
        XCTAssertEqual(
            harness.cognito.operations,
            ["InitiateAuth", "RespondToAuthChallenge", "GetId", "GetCredentialsForIdentity"]
        )
        let initiate = try XCTUnwrap(harness.cognito.inputs("InitiateAuth", as: InitiateAuthInput.self).first)
        XCTAssertEqual(initiate.authFlow, .userSrpAuth)
        XCTAssertEqual(initiate.authParameters?["USERNAME"], "alice")
        XCTAssertNotNil(initiate.authParameters?["SRP_A"])
        XCTAssertEqual(initiate.clientId, ClientFixtures.userPool.appClientId)
        let respond = try XCTUnwrap(harness.cognito.inputs("RespondToAuthChallenge", as: RespondToAuthChallengeInput.self).first)
        XCTAssertEqual(respond.challengeName, .passwordVerifier)
        XCTAssertEqual(respond.session, "srp-session")
        XCTAssertEqual(respond.challengeResponses?["USERNAME"], "alice", "the USERNAME Cognito's challenge named")
        XCTAssertFalse(respond.challengeResponses?["PASSWORD_CLAIM_SIGNATURE"]?.isEmpty ?? true)
        XCTAssertNotNil(respond.challengeResponses?["PASSWORD_CLAIM_SECRET_BLOCK"])
        XCTAssertFalse(respond.challengeResponses?["TIMESTAMP"]?.isEmpty ?? true)
        let getId = try XCTUnwrap(harness.cognito.inputs("GetId", as: GetIdInput.self).first)
        XCTAssertEqual(getId.identityPoolId, StorageFixtures.identityPoolId)
        XCTAssertEqual(getId.logins?.values.first, LiveEngineFixtures.jwt("alice", use: "id"))
        let pending = await engine.pendingChallenge
        XCTAssertNil(pending)
    }

    /// A payload the live engine produces is what the plugin's own credential store reads.
    ///
    /// - Given: a payload from a live sign-in, a refresh and a guest fetch
    /// - When:
    ///    - each is stored as it is under the plugin's session account, and retrieved with the plugin's
    ///      `AWSCognitoAuthCredentialStore`
    /// - Then:
    ///    - each is retrieved as exactly the credentials the payload decodes to, none of them signed out
    ///
    func testProducedPayloadsAreReadByThePluginsStore() async throws {
        let engine = try harness.engine()
        let signedIn = try await harness.signedInPayload(on: engine)
        harness.scriptRefresh()
        let refreshed = try await engine.refresh(signedIn)
        let guest = try await engine.fetchGuestCredentials(current: nil)

        for payload in [signedIn, refreshed, guest] {
            let kind = try engine.describe(payload).kind
            let read = try harness.retrievedByThePlugin(payload)

            XCTAssertNotEqual(read, .noCredentials, "the plugin should read a produced \(kind) payload as signed in")
            XCTAssertEqual(read, try AmplifyCredentials.decoded(payload), "\(kind)")
        }
    }

    /// A sign-in whose identity pool step fails throws, and revokes the refresh token Cognito already issued.
    ///
    /// - Given: SRP succeeding, then `GetId` failing with the identity pool's `InternalErrorException`
    /// - When:
    ///    - alice signs in
    /// - Then:
    ///    - it throws the mapped error, nothing is pending, and `RevokeToken` was called with the issued
    ///      refresh token
    ///
    func testAFailedIdentityStepRevokesTheIssuedTokens() async throws {
        let engine = try harness.engine()
        harness.scriptSRP()
        harness.cognito.once("GetId") { (_: GetIdInput) -> GetIdOutput in
            throw AWSCognitoIdentity.InternalErrorException(message: "boom")
        }
        harness.scriptSignOut()

        await assertThrowsAsync({ try await engine.signIn(.srp(), current: nil) }) { error in
            // The engine's mapping of an identity pool `InternalErrorException`, as the plugin's.
            guard case .unknown(let description, _, _) = authError(error) else {
                return XCTFail("expected the engine's unknown error, got \(error)")
            }
            XCTAssertTrue(description.contains("boom"), description)
        }

        let pending = await engine.pendingChallenge
        XCTAssertNil(pending)
        XCTAssertEqual(harness.cognito.inputs("RevokeToken", as: RevokeTokenInput.self).map(\.token), ["refresh-alice-v1"])
    }

    /// The user pool alone: the sign-in finishes with a user-pool-only payload and no identity pool call.
    ///
    /// - Given: a user-pool-only configuration, and SRP scripted
    /// - When:
    ///    - alice signs in
    /// - Then:
    ///    - the payload is `userPoolOnly`, and only the two user pool calls were made
    ///
    func testUserPoolOnlySignInMakesNoIdentityPoolCall() async throws {
        harness = LiveEngineHarness(configuration: ClientFixtures.userPoolOnlyConfiguration)
        let engine = try harness.engine()
        harness.scriptSRP()

        let result = try await engine.signIn(.srp(), current: nil)

        guard case .done(let payload) = result, case .userPoolOnly = try AmplifyCredentials.decoded(payload) else {
            return XCTFail("expected a user-pool-only payload, got \(result)")
        }
        XCTAssertEqual(harness.cognito.operations, ["InitiateAuth", "RespondToAuthChallenge"])
    }

    // MARK: Other flows

    /// `USER_PASSWORD_AUTH`: one `InitiateAuth` with the password.
    ///
    /// - Given: `InitiateAuth` answering tokens
    /// - When:
    ///    - alice signs in with `.userPassword` and client metadata
    /// - Then:
    ///    - `InitiateAuth` carries `USER_PASSWORD_AUTH`, the username, the password and the metadata
    ///    - the result is `.done`
    ///
    func testUserPasswordFlowSendsThePassword() async throws {
        let engine = try harness.engine()
        harness.cognito.once("InitiateAuth") { (_: InitiateAuthInput) in
            InitiateAuthOutput(authenticationResult: LiveEngineFixtures.tokens(), challengeParameters: [:])
        }
        harness.scriptIdentityPool()

        let result = try await engine.signIn(
            EngineSignInRequest(username: "alice", password: "pw", authFlowType: .userPassword, clientMetadata: ["k": "v"]),
            current: nil
        )

        guard case .done = result else {
            return XCTFail("expected .done, got \(result)")
        }
        let initiate = try XCTUnwrap(harness.cognito.inputs("InitiateAuth", as: InitiateAuthInput.self).first)
        XCTAssertEqual(initiate.authFlow, .userPasswordAuth)
        XCTAssertEqual(initiate.authParameters?["USERNAME"], "alice")
        XCTAssertEqual(initiate.authParameters?["PASSWORD"], "pw")
        XCTAssertEqual(initiate.clientMetadata, ["k": "v"])
    }

    /// Custom auth without SRP: the custom challenge, then its answer.
    ///
    /// - Given: `InitiateAuth` answering `CUSTOM_CHALLENGE`, and the answer accepted
    /// - When:
    ///    - alice signs in with `.customWithoutSRP`, then confirms with the answer
    /// - Then:
    ///    - the sign-in stops on `.confirmSignInWithCustomChallenge` with Cognito's parameters, pending
    ///    - the confirmation sends `ANSWER` and finishes `.done`, with nothing pending
    ///
    func testCustomAuthStopsOnTheCustomChallenge() async throws {
        let engine = try harness.engine()
        harness.cognito.once("InitiateAuth") { (_: InitiateAuthInput) in
            LiveEngineFixtures.initiateChallenge(.customChallenge, parameters: ["question": "colour?"])
        }
        harness.cognito.once("RespondToAuthChallenge") { (_: RespondToAuthChallengeInput) in LiveEngineFixtures.signedIn() }
        harness.scriptIdentityPool()

        let first = try await engine.signIn(.flow(.customWithoutSRP, password: nil), current: nil)

        XCTAssertEqual(first, .challenge(.confirmSignInWithCustomChallenge(["question": "colour?"])))
        let pending = await engine.pendingChallenge
        XCTAssertEqual(pending, .confirmSignInWithCustomChallenge(["question": "colour?"]))
        let initiate = try XCTUnwrap(harness.cognito.inputs("InitiateAuth", as: InitiateAuthInput.self).first)
        XCTAssertEqual(initiate.authFlow, .customAuth)

        let second = try await engine.confirmSignIn(.answer("blue"), current: nil)

        guard case .done = second else {
            return XCTFail("expected .done, got \(second)")
        }
        let respond = try XCTUnwrap(harness.cognito.inputs("RespondToAuthChallenge", as: RespondToAuthChallengeInput.self).first)
        XCTAssertEqual(respond.challengeName, .customChallenge)
        XCTAssertEqual(respond.challengeResponses?["ANSWER"], "blue")
        XCTAssertEqual(respond.session, "challenge-session")
        let after = await engine.pendingChallenge
        XCTAssertNil(after)
    }

    /// `USER_AUTH` with a preferred first factor: Cognito's one-time code challenge.
    ///
    /// - Given: `InitiateAuth` answering `EMAIL_OTP`
    /// - When:
    ///    - alice signs in with `.userAuth(preferredFirstFactor: .emailOTP)` and no password
    /// - Then:
    ///    - `InitiateAuth` carries `USER_AUTH` and `PREFERRED_CHALLENGE` `EMAIL_OTP`
    ///    - the sign-in stops on `.confirmSignInWithOTP`, and the code finishes it
    ///
    func testUserAuthWithAPreferredFirstFactor() async throws {
        let engine = try harness.engine()
        harness.cognito.once("InitiateAuth") { (_: InitiateAuthInput) in
            LiveEngineFixtures.initiateChallenge(.emailOtp, parameters: [
                "CODE_DELIVERY_DELIVERY_MEDIUM": "EMAIL",
                "CODE_DELIVERY_DESTINATION": "a***@e***"
            ])
        }
        harness.cognito.once("RespondToAuthChallenge") { (_: RespondToAuthChallengeInput) in LiveEngineFixtures.signedIn() }
        harness.scriptIdentityPool()

        let first = try await engine.signIn(.flow(.userAuth(preferredFirstFactor: .emailOTP), password: nil), current: nil)

        guard case .challenge(.confirmSignInWithOTP(let details)) = first else {
            return XCTFail("expected an OTP challenge, got \(first)")
        }
        XCTAssertEqual(details.destination, .email("a***@e***"))
        let initiate = try XCTUnwrap(harness.cognito.inputs("InitiateAuth", as: InitiateAuthInput.self).first)
        XCTAssertEqual(initiate.authFlow, .userAuth)
        XCTAssertEqual(initiate.authParameters?["PREFERRED_CHALLENGE"], "EMAIL_OTP")

        let second = try await engine.confirmSignIn(.answer("123456"), current: nil)

        guard case .done = second else {
            return XCTFail("expected .done, got \(second)")
        }
        let respond = try XCTUnwrap(harness.cognito.inputs("RespondToAuthChallenge", as: RespondToAuthChallengeInput.self).first)
        XCTAssertEqual(respond.challengeName, .emailOtp)
        XCTAssertEqual(respond.challengeResponses?["EMAIL_OTP_CODE"], "123456")
    }

    /// `USER_AUTH` with no preference: the first-factor selection.
    ///
    /// - Given: `InitiateAuth` answering `SELECT_CHALLENGE` with password and email OTP available
    /// - When:
    ///    - alice signs in with `.userAuth(preferredFirstFactor: nil)`
    /// - Then:
    ///    - the sign-in stops on `.continueSignInWithFirstFactorSelection` with both factors
    ///
    func testUserAuthWithoutAPreferenceOffersTheFirstFactors() async throws {
        let engine = try harness.engine()
        harness.cognito.once("InitiateAuth") { (_: InitiateAuthInput) in
            InitiateAuthOutput(
                availableChallenges: [.password, .emailOtp],
                challengeName: .selectChallenge,
                challengeParameters: [:],
                session: "select-session"
            )
        }

        let result = try await engine.signIn(.flow(.userAuth(preferredFirstFactor: nil), password: nil), current: nil)

        XCTAssertEqual(result, .challenge(.continueSignInWithFirstFactorSelection([.password, .emailOTP])))
    }

    // MARK: Challenges and the pending attempt

    /// A wrong code keeps the attempt; the right one finishes it (the seam's retryable rule).
    ///
    /// - Given: SRP answered with `SMS_MFA`, then `CodeMismatchException`, then tokens
    /// - When:
    ///    - alice signs in, answers a wrong code, then the right one
    /// - Then:
    ///    - the sign-in stops on `.confirmSignInWithSMSMFACode`
    ///    - the wrong code throws `.service(.codeMismatch)`, and the challenge is still pending
    ///    - the right code finishes `.done`, and nothing is pending
    ///    - nothing is revoked: the right code's tokens are the session's
    ///
    func testAWrongCodeKeepsTheAttemptAndTheRightOneFinishesIt() async throws {
        let engine = try harness.engine()
        harness.scriptSRP(then: LiveEngineFixtures.challenge(.smsMfa, parameters: LiveEngineFixtures.smsParameters))
        harness.cognito.once("RespondToAuthChallenge") { (_: RespondToAuthChallengeInput) -> RespondToAuthChallengeOutput in
            throw CodeMismatchException(message: "Invalid code provided, please try again.")
        }
        harness.cognito.once("RespondToAuthChallenge") { (_: RespondToAuthChallengeInput) in LiveEngineFixtures.signedIn() }
        harness.scriptIdentityPool()

        let first = try await engine.signIn(.srp(), current: nil)

        guard case .challenge(.confirmSignInWithSMSMFACode(let details, _)) = first else {
            return XCTFail("expected an SMS MFA challenge, got \(first)")
        }
        XCTAssertEqual(details.destination, .sms("+1******1234"))

        await assertThrowsAsync({ try await engine.confirmSignIn(.answer("000000"), current: nil) }) { error in
            guard case .service(.codeMismatch?, _, _, _) = authError(error) else {
                return XCTFail("expected .service(.codeMismatch), got \(error)")
            }
        }
        let stillPending = await engine.pendingChallenge
        guard case .confirmSignInWithSMSMFACode = stillPending else {
            return XCTFail("a wrong code should keep the challenge pending, got \(String(describing: stillPending))")
        }

        let last = try await engine.confirmSignIn(.answer("123456"), current: nil)

        guard case .done = last else {
            return XCTFail("expected .done, got \(last)")
        }
        let codes = harness.cognito.inputs("RespondToAuthChallenge", as: RespondToAuthChallengeInput.self)
            .compactMap { $0.challengeResponses?["SMS_MFA_CODE"] }
        XCTAssertEqual(codes, ["000000", "123456"])
        let after = await engine.pendingChallenge
        XCTAssertNil(after)
        // The wrong code kept the attempt, so its tap too: the right code's tokens are the session's, never
        // revoked (a failed step's tap is cancelled only when the attempt is dropped).
        try await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertEqual(harness.cognito.inputs("RevokeToken", as: RevokeTokenInput.self).count, 0)
    }

    /// A failure that keeps the attempt still revokes what its answer was issued.
    ///
    /// - Given: SRP answered with `SMS_MFA`; the first answer's result holds a refresh token but no ID or
    ///   access token ("Response did not contain signIn info"); the second answer's holds alice's tokens
    /// - When:
    ///    - alice answers twice
    /// - Then:
    ///    - the first answer throws and keeps the challenge pending; its refresh token is revoked exactly once
    ///    - the second finishes `.done`, and its refresh token is never revoked
    ///
    func testAKeptAttemptFailureRevokesTheTokenItsAnswerWasIssued() async throws {
        let engine = try harness.engine()
        harness.scriptSRP(then: LiveEngineFixtures.challenge(.smsMfa, parameters: LiveEngineFixtures.smsParameters))
        harness.cognito.once("RespondToAuthChallenge") { (_: RespondToAuthChallengeInput) in
            RespondToAuthChallengeOutput(
                authenticationResult: .init(expiresIn: 3_600, refreshToken: "refresh-orphan", tokenType: "Bearer"),
                challengeParameters: [:]
            )
        }
        harness.cognito.once("RespondToAuthChallenge") { (_: RespondToAuthChallengeInput) in LiveEngineFixtures.signedIn() }
        harness.cognito.always("RevokeToken") { (_: RevokeTokenInput) in RevokeTokenOutput() }
        harness.scriptIdentityPool()
        func revoked() -> [String] {
            harness.cognito.inputs("RevokeToken", as: RevokeTokenInput.self).compactMap(\.token)
        }

        _ = try await engine.signIn(.srp(), current: nil)
        do {
            _ = try await engine.confirmSignIn(.answer("111111"), current: nil)
            XCTFail("an answer without ID and access tokens should fail")
        } catch {}
        let stillPending = await engine.pendingChallenge
        XCTAssertNotNil(stillPending, "the failure keeps the attempt")
        await waitUntil("the orphaned refresh token is revoked") { revoked() == ["refresh-orphan"] }

        let last = try await engine.confirmSignIn(.answer("123456"), current: nil)

        guard case .done = last else {
            return XCTFail("expected .done, got \(last)")
        }
        try await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertEqual(revoked(), ["refresh-orphan"], "revoked exactly once, and the session's token never")
    }

    /// An expired challenge session is `challengeExpired`, and drops the attempt.
    ///
    /// - Given: a sign-in waiting on an SMS code, and Cognito rejecting the answer with the expired-session
    ///   `NotAuthorizedException`
    /// - When:
    ///    - alice answers
    /// - Then:
    ///    - it throws `challengeExpired`, and nothing is pending
    ///
    func testAnExpiredChallengeSessionDropsTheAttempt() async throws {
        let engine = try harness.engine()
        harness.scriptSRP(then: LiveEngineFixtures.challenge(.smsMfa, parameters: LiveEngineFixtures.smsParameters))
        harness.cognito.once("RespondToAuthChallenge") { (_: RespondToAuthChallengeInput) -> RespondToAuthChallengeOutput in
            throw AWSCognitoIdentityProvider.NotAuthorizedException(message: "Invalid session for the user, session is expired.")
        }
        _ = try await engine.signIn(.srp(), current: nil)

        await assertThrowsAsync({ try await engine.confirmSignIn(.answer("123456"), current: nil) }) { error in
            guard case .challengeExpired = authError(error) else {
                return XCTFail("expected challengeExpired, got \(error)")
            }
        }
        let pending = await engine.pendingChallenge
        XCTAssertNil(pending)
    }

    /// A message-less `NotAuthorizedException` from the identity pool, after the challenge was answered, is
    /// not an expired challenge: the expired check needs the user pool's own rejection of the answer.
    ///
    /// - Given: a sign-in waiting on an SMS code; the answer accepted, then `GetCredentialsForIdentity` failing
    ///   with the identity pool's `NotAuthorizedException` and no message
    /// - When:
    ///    - alice answers
    /// - Then:
    ///    - it throws `notAuthorized`, not `challengeExpired`, and the issued tokens are revoked
    ///
    func testAnIdentityPoolRejectionAfterTheAnswerIsNotAnExpiredChallenge() async throws {
        let engine = try harness.engine()
        harness.scriptSRP(then: LiveEngineFixtures.challenge(.smsMfa, parameters: LiveEngineFixtures.smsParameters))
        harness.cognito.once("RespondToAuthChallenge") { (_: RespondToAuthChallengeInput) in LiveEngineFixtures.signedIn() }
        harness.cognito.once("GetId") { (_: GetIdInput) in GetIdOutput(identityId: LiveEngineFixtures.identityId) }
        harness.cognito.once("GetCredentialsForIdentity") { (_: GetCredentialsForIdentityInput) -> GetCredentialsForIdentityOutput in
            throw AWSCognitoIdentity.NotAuthorizedException(message: nil)
        }
        harness.scriptSignOut()
        _ = try await engine.signIn(.srp(), current: nil)

        await assertThrowsAsync({ try await engine.confirmSignIn(.answer("123456"), current: nil) }) { error in
            guard case .notAuthorized = authError(error) else {
                return XCTFail("expected notAuthorized, got \(error)")
            }
        }
        XCTAssertEqual(harness.cognito.inputs("RevokeToken", as: RevokeTokenInput.self).map(\.token), ["refresh-alice-v1"])
    }

    /// A new password, with attributes: the `userAttributes.` prefix `RespondToAuthChallenge` expects.
    ///
    /// - Given: SRP answered with `NEW_PASSWORD_REQUIRED`
    /// - When:
    ///    - alice signs in, then confirms a new password with an email and a custom attribute
    /// - Then:
    ///    - the sign-in stops on `.confirmSignInWithNewPassword`
    ///    - the answer carries `NEW_PASSWORD`, `userAttributes.email` and `userAttributes.custom:team`
    ///
    func testNewPasswordSendsPrefixedAttributes() async throws {
        let engine = try harness.engine()
        harness.scriptSRP(then: LiveEngineFixtures.challenge(.newPasswordRequired, parameters: ["requiredAttributes": "[]"]))
        harness.cognito.once("RespondToAuthChallenge") { (_: RespondToAuthChallengeInput) in LiveEngineFixtures.signedIn() }
        harness.scriptIdentityPool()

        let first = try await engine.signIn(.srp(), current: nil)

        guard case .challenge(.confirmSignInWithNewPassword) = first else {
            return XCTFail("expected a new-password challenge, got \(first)")
        }

        let result = try await engine.confirmSignIn(
            .answer("NewPassw0rd!", attributes: ["email": "alice@example.com", "custom:team": "blue"]),
            current: nil
        )

        guard case .done = result else {
            return XCTFail("expected .done, got \(result)")
        }

        let respond = try XCTUnwrap(harness.cognito.inputs("RespondToAuthChallenge", as: RespondToAuthChallengeInput.self).last)
        XCTAssertEqual(respond.challengeName, .newPasswordRequired)
        XCTAssertEqual(respond.challengeResponses?["NEW_PASSWORD"], "NewPassw0rd!")
        XCTAssertEqual(respond.challengeResponses?["userAttributes.email"], "alice@example.com")
        XCTAssertEqual(respond.challengeResponses?["userAttributes.custom:team"], "blue")
        XCTAssertNil(respond.challengeResponses?["email"])
    }

    /// An MFA selection, then the chosen factor's code.
    ///
    /// - Given: SRP answered with `SELECT_MFA_TYPE` (SMS and TOTP), then `SOFTWARE_TOKEN_MFA`, then tokens
    /// - When:
    ///    - alice signs in, selects TOTP, and answers the code
    /// - Then:
    ///    - the steps are `.continueSignInWithMFASelection([.sms, .totp])`, then `.confirmSignInWithTOTPCode`,
    ///      then `.done`
    ///
    func testMFASelectionThenTheChosenCode() async throws {
        let engine = try harness.engine()
        harness.scriptSRP(then: LiveEngineFixtures.challenge(
            .selectMfaType,
            parameters: ["MFAS_CAN_CHOOSE": #"["SMS_MFA","SOFTWARE_TOKEN_MFA"]"#]
        ))
        harness.cognito.once("RespondToAuthChallenge") { (_: RespondToAuthChallengeInput) in
            LiveEngineFixtures.challenge(.softwareTokenMfa)
        }
        harness.cognito.once("RespondToAuthChallenge") { (_: RespondToAuthChallengeInput) in LiveEngineFixtures.signedIn() }
        harness.scriptIdentityPool()

        let first = try await engine.signIn(.srp(), current: nil)
        XCTAssertEqual(first, .challenge(.continueSignInWithMFASelection([.sms, .totp])))

        let second = try await engine.confirmSignIn(.answer("SOFTWARE_TOKEN_MFA"), current: nil)
        XCTAssertEqual(second, .challenge(.confirmSignInWithTOTPCode))
        let pending = await engine.pendingChallenge
        XCTAssertEqual(pending, .confirmSignInWithTOTPCode)

        let last = try await engine.confirmSignIn(.answer("123456"), current: nil)
        guard case .done = last else {
            return XCTFail("expected .done, got \(last)")
        }
        let answers = harness.cognito.inputs("RespondToAuthChallenge", as: RespondToAuthChallengeInput.self).dropFirst()
        XCTAssertEqual(answers.map(\.challengeName), [.selectMfaType, .softwareTokenMfa])
        XCTAssertEqual(answers.first?.challengeResponses?["ANSWER"], "SOFTWARE_TOKEN_MFA")
        XCTAssertEqual(answers.last?.challengeResponses?["SOFTWARE_TOKEN_MFA_CODE"], "123456")
    }

    /// TOTP setup during sign-in: the shared secret, then the verification.
    ///
    /// - Given: SRP answered with `MFA_SETUP`, `AssociateSoftwareToken` answering a secret, and the code
    ///   verified
    /// - When:
    ///    - alice signs in, then confirms the code with a device name
    /// - Then:
    ///    - the sign-in stops on `.continueSignInWithTOTPSetup` with the secret and alice's username
    ///    - the confirmation verifies the code with the device name, then answers `MFA_SETUP`, and finishes
    ///
    func testTOTPSetupDuringSignIn() async throws {
        let engine = try harness.engine()
        harness.scriptSRP(then: LiveEngineFixtures.challenge(.mfaSetup, parameters: ["MFAS_CAN_SETUP": #"["SOFTWARE_TOKEN_MFA"]"#]))
        harness.cognito.once("AssociateSoftwareToken") { (_: AssociateSoftwareTokenInput) in
            AssociateSoftwareTokenOutput(secretCode: "SHARED-SECRET", session: "setup-session")
        }
        harness.cognito.once("VerifySoftwareToken") { (_: VerifySoftwareTokenInput) in
            VerifySoftwareTokenOutput(session: "verified-session", status: .success)
        }
        harness.cognito.once("RespondToAuthChallenge") { (_: RespondToAuthChallengeInput) in LiveEngineFixtures.signedIn() }
        harness.scriptIdentityPool()

        let first = try await engine.signIn(.srp(), current: nil)

        guard case .challenge(.continueSignInWithTOTPSetup(let details)) = first else {
            return XCTFail("expected a TOTP setup, got \(first)")
        }
        XCTAssertEqual(details.sharedSecret, "SHARED-SECRET")
        XCTAssertEqual(details.username, "alice")

        let last = try await engine.confirmSignIn(.answer("123456", friendlyDeviceName: "phone"), current: nil)

        guard case .done = last else {
            return XCTFail("expected .done, got \(last)")
        }
        let verify = try XCTUnwrap(harness.cognito.inputs("VerifySoftwareToken", as: VerifySoftwareTokenInput.self).first)
        XCTAssertEqual(verify.userCode, "123456")
        XCTAssertEqual(verify.friendlyDeviceName, "phone")
    }

    /// A failed TOTP verification keeps the setup pending; the next code finishes it.
    ///
    /// - Given: a sign-in stopped on a TOTP setup, and `VerifySoftwareToken` failing once with
    ///   `EnableSoftwareTokenMFAException`, then succeeding
    /// - When:
    ///    - alice answers a wrong code, then the right one
    /// - Then:
    ///    - the wrong code throws, and the setup is still pending with its secret
    ///    - the right code finishes `.done`
    ///
    func testAFailedTOTPVerificationKeepsTheSetup() async throws {
        let engine = try harness.engine()
        harness.scriptSRP(then: LiveEngineFixtures.challenge(.mfaSetup, parameters: ["MFAS_CAN_SETUP": #"["SOFTWARE_TOKEN_MFA"]"#]))
        harness.cognito.once("AssociateSoftwareToken") { (_: AssociateSoftwareTokenInput) in
            AssociateSoftwareTokenOutput(secretCode: "SHARED-SECRET", session: "setup-session")
        }
        harness.cognito.once("VerifySoftwareToken") { (_: VerifySoftwareTokenInput) -> VerifySoftwareTokenOutput in
            throw EnableSoftwareTokenMFAException(message: "Code mismatch")
        }
        harness.cognito.once("VerifySoftwareToken") { (_: VerifySoftwareTokenInput) in
            VerifySoftwareTokenOutput(session: "verified-session", status: .success)
        }
        harness.cognito.once("RespondToAuthChallenge") { (_: RespondToAuthChallengeInput) in LiveEngineFixtures.signedIn() }
        harness.scriptIdentityPool()
        _ = try await engine.signIn(.srp(), current: nil)

        await assertThrowsAsync({ try await engine.confirmSignIn(.answer("000000"), current: nil) }) { error in
            guard case .service(.softwareTokenMFANotEnabled?, _, _, _) = authError(error) else {
                return XCTFail("expected .service(.softwareTokenMFANotEnabled), got \(error)")
            }
        }
        let pending = await engine.pendingChallenge
        guard case .continueSignInWithTOTPSetup(let details) = pending else {
            return XCTFail("a failed verification should keep the setup pending, got \(String(describing: pending))")
        }
        XCTAssertEqual(details.sharedSecret, "SHARED-SECRET")

        let last = try await engine.confirmSignIn(.answer("123456"), current: nil)

        guard case .done = last else {
            return XCTFail("expected .done, got \(last)")
        }
        XCTAssertEqual(harness.cognito.inputs("VerifySoftwareToken", as: VerifySoftwareTokenInput.self).map(\.userCode), ["000000", "123456"])
    }

    #if os(iOS) || os(macOS) || os(visionOS)
    /// A WebAuthn step Cognito starts on a sign-in given no window is refused without presenting, and nothing
    /// is pending.
    ///
    /// - Given: `InitiateAuth` answering the `WEB_AUTHN` challenge with valid options
    /// - When:
    ///    - alice signs in with `USER_AUTH` and no preference, and no ceremony context
    /// - Then:
    ///    - it throws `.validation(field: "presentationAnchor")`, nothing is pending, and the challenge is never
    ///      answered
    ///
    func testAWebAuthnStepFromCognitoIsRefused() async throws {
        let engine = try harness.engine()
        harness.cognito.once("InitiateAuth") { (_: InitiateAuthInput) in
            LiveEngineFixtures.initiateChallenge(.webAuthn, parameters: ["CREDENTIAL_REQUEST_OPTIONS": WebAuthnFixtures.requestOptions])
        }

        await assertThrowsAsync({ try await engine.signIn(.flow(.userAuth(preferredFirstFactor: nil), password: nil), current: nil) }) { error in
            XCTAssertEqual(authError(error)?.kind, .validation(field: "presentationAnchor"))
        }
        let pending = await engine.pendingChallenge
        XCTAssertNil(pending)
        XCTAssertEqual(harness.cognito.operations, ["InitiateAuth"])
    }
    #endif

    /// An expired TOTP-setup session is `challengeExpired`, and drops the attempt: the setup's own call,
    /// `VerifySoftwareToken`, is what the user pool rejects.
    ///
    /// - Given: a sign-in stopped on a TOTP setup, and `VerifySoftwareToken` failing with the user pool's
    ///   expired-session `NotAuthorizedException`
    /// - When:
    ///    - alice answers the code
    /// - Then:
    ///    - it throws `challengeExpired`, and nothing is pending
    ///
    func testAnExpiredTOTPSetupSessionIsChallengeExpired() async throws {
        let engine = try harness.engine()
        harness.scriptSRP(then: LiveEngineFixtures.challenge(.mfaSetup, parameters: ["MFAS_CAN_SETUP": #"["SOFTWARE_TOKEN_MFA"]"#]))
        harness.cognito.once("AssociateSoftwareToken") { (_: AssociateSoftwareTokenInput) in
            AssociateSoftwareTokenOutput(secretCode: "SHARED-SECRET", session: "setup-session")
        }
        harness.cognito.once("VerifySoftwareToken") { (_: VerifySoftwareTokenInput) -> VerifySoftwareTokenOutput in
            throw AWSCognitoIdentityProvider.NotAuthorizedException(message: "Invalid session for the user, session is expired.")
        }
        _ = try await engine.signIn(.srp(), current: nil)

        await assertThrowsAsync({ try await engine.confirmSignIn(.answer("123456"), current: nil) }) { error in
            guard case .challengeExpired = authError(error) else {
                return XCTFail("expected challengeExpired, got \(error)")
            }
        }
        let pending = await engine.pendingChallenge
        XCTAssertNil(pending)
    }

    /// A confirmation with nothing pending is `invalidState`, and calls nothing.
    ///
    /// - Given: an engine with no sign-in
    /// - When:
    ///    - `confirmSignIn` is called
    /// - Then:
    ///    - it throws `invalidState("There is no sign-in in progress for this session", …)`, with no call
    ///
    func testConfirmWithNothingPendingIsInvalidState() async throws {
        let engine = try harness.engine()

        await assertThrowsAsync({ try await engine.confirmSignIn(.answer("123456"), current: nil) }) { error in
            guard case .invalidState(let description, _, _) = authError(error) else {
                return XCTFail("expected invalidState, got \(error)")
            }
            XCTAssertEqual(description, "There is no sign-in in progress for this session")
        }
        XCTAssertEqual(harness.cognito.operations, [])
    }

    /// A new sign-in supersedes the pending one.
    ///
    /// - Given: alice's sign-in waiting on an SMS code
    /// - When:
    ///    - bob signs in, and finishes
    /// - Then:
    ///    - bob's sign-in is `.done` for bob; nothing is pending; a confirmation afterwards is `invalidState`
    ///
    func testANewSignInSupersedesThePendingOne() async throws {
        let engine = try harness.engine()
        harness.scriptSRP(then: LiveEngineFixtures.challenge(.smsMfa, parameters: LiveEngineFixtures.smsParameters))
        _ = try await engine.signIn(.srp(), current: nil)
        harness.scriptSRP("bob")
        harness.scriptIdentityPool()

        let result = try await engine.signIn(.srp("bob"), current: nil)

        guard case .done(let payload) = result else {
            return XCTFail("expected .done, got \(result)")
        }
        XCTAssertEqual(try engine.describe(payload).username, "bob")
        let pending = await engine.pendingChallenge
        XCTAssertNil(pending)
        await assertThrowsAsync({ try await engine.confirmSignIn(.answer("123456"), current: nil) }) { error in
            guard case .invalidState = authError(error) else {
                return XCTFail("expected invalidState, got \(error)")
            }
        }
    }

    /// A wrong password fails the sign-in and leaves nothing pending.
    ///
    /// - Given: `RespondToAuthChallenge` rejecting the SRP proof with `NotAuthorizedException`
    /// - When:
    ///    - alice signs in
    /// - Then:
    ///    - it throws `.notAuthorized` with Cognito's message, and nothing is pending
    ///
    func testAWrongPasswordFailsAndLeavesNothingPending() async throws {
        let engine = try harness.engine()
        harness.cognito.once("InitiateAuth") { (_: InitiateAuthInput) in LiveEngineFixtures.passwordVerifier() }
        harness.cognito.once("RespondToAuthChallenge") { (_: RespondToAuthChallengeInput) -> RespondToAuthChallengeOutput in
            throw AWSCognitoIdentityProvider.NotAuthorizedException(message: "Incorrect username or password.")
        }

        await assertThrowsAsync({ try await engine.signIn(.srp(), current: nil) }) { error in
            guard case .notAuthorized(let description, _, _) = authError(error) else {
                return XCTFail("expected notAuthorized, got \(error)")
            }
            XCTAssertTrue(description.contains("Incorrect username or password."), description)
        }
        let pending = await engine.pendingChallenge
        XCTAssertNil(pending)
    }

    /// An unconfirmed user is the `.confirmSignUp` step, as in the plugin; confirming it is refused.
    ///
    /// - Given: `InitiateAuth` throwing `UserNotConfirmedException`
    /// - When:
    ///    - alice signs in, then calls `confirmSignIn`
    /// - Then:
    ///    - the sign-in returns `.challenge(.confirmSignUp(nil))`
    ///    - the confirmation throws the plugin's "Cannot use confirmSignIn in the current state" and
    ///      drops the attempt
    ///
    func testAnUnconfirmedUserIsTheConfirmSignUpStep() async throws {
        let engine = try harness.engine()
        harness.cognito.once("InitiateAuth") { (_: InitiateAuthInput) -> InitiateAuthOutput in
            throw UserNotConfirmedException(message: "User is not confirmed.")
        }

        let result = try await engine.signIn(.srp(), current: nil)

        XCTAssertEqual(result, .challenge(.confirmSignUp(nil)))
        await assertThrowsAsync({ try await engine.confirmSignIn(.answer("x"), current: nil) }) { error in
            guard case .invalidState(let description, _, _) = authError(error) else {
                return XCTFail("expected invalidState, got \(error)")
            }
            XCTAssertTrue(description.hasPrefix("Cannot use confirmSignIn in the current state."), description)
        }
        let pending = await engine.pendingChallenge
        XCTAssertNil(pending)
    }

    /// A required password reset is the `.resetPassword` step.
    ///
    /// - Given: `InitiateAuth` throwing `PasswordResetRequiredException`
    /// - When:
    ///    - alice signs in
    /// - Then:
    ///    - the result is `.challenge(.resetPassword(nil))`
    ///
    func testARequiredPasswordResetIsTheResetPasswordStep() async throws {
        let engine = try harness.engine()
        harness.cognito.once("InitiateAuth") { (_: InitiateAuthInput) -> InitiateAuthOutput in
            throw PasswordResetRequiredException(message: "Password reset required for the user")
        }

        let result = try await engine.signIn(.srp(), current: nil)

        XCTAssertEqual(result, .challenge(.resetPassword(nil)))
    }

    /// A guest session signs in from its guest payload.
    ///
    /// - Given: a guest payload
    /// - When:
    ///    - alice signs in with it as `current`
    /// - Then:
    ///    - the sign-in finishes signed in; the guest payload is only the operation's seed
    ///
    func testAGuestSignsInFromItsPayload() async throws {
        let engine = try harness.engine()
        harness.scriptIdentityPool()
        let guest = try await engine.fetchGuestCredentials(current: nil)
        harness.scriptSRP()

        let result = try await engine.signIn(.srp(), current: guest)

        guard case .done(let payload) = result else {
            return XCTFail("expected .done, got \(result)")
        }
        XCTAssertEqual(try engine.describe(payload).kind, .userPoolAndIdentityPool)
    }

    /// Without a user pool, a sign-in is a configuration error before anything runs.
    ///
    /// - Given: an identity-pool-only engine
    /// - When:
    ///    - `signIn` and `confirmSignIn` are called
    /// - Then:
    ///    - both throw `configuration`, and nothing is called
    ///
    func testSignInNeedsAUserPool() async throws {
        harness = LiveEngineHarness(configuration: ClientFixtures.identityPoolOnlyConfiguration)
        let engine = try harness.engine()

        await assertThrowsAsync({ try await engine.signIn(.srp(), current: nil) }) { error in
            guard case .configuration = authError(error) else {
                return XCTFail("expected configuration, got \(error)")
            }
        }
        await assertThrowsAsync({ try await engine.confirmSignIn(.answer("x"), current: nil) }) { error in
            guard case .configuration = authError(error) else {
                return XCTFail("expected configuration, got \(error)")
            }
        }
        XCTAssertEqual(harness.cognito.operations, [])
    }
}
