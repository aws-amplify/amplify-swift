//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import Foundation
import InternalAWSCognitoAuth
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// The live engine's sign-up, confirmation, code resend and auto sign-in over scripted Cognito:
/// the plugin's requests, its results, and the sign-up state the engine keeps per session (the seam's
/// "Sign-up" contract).
final class LiveEngineSignUpTests: XCTestCase {

    private var harness: LiveEngineHarness!

    override func setUp() {
        super.setUp()
        harness = LiveEngineHarness()
    }

    override func tearDown() {
        harness = nil
        super.tearDown()
    }

    // MARK: Sign-up

    /// The request carries what the plugin's does, and an unconfirmed user is `.confirmUser`.
    ///
    /// - Given: Cognito answers `SignUp` with an unconfirmed user, an email delivery and a session
    /// - When:
    ///    - carol signs up with a password, two attributes, validation data and client metadata
    /// - Then:
    ///    - one `SignUp` with the app client, username, password, the attributes by Cognito name, the
    ///      validation data and the client metadata
    ///    - the result is `.confirmUser` with the delivery details and the `sub`, and `userId` is the `sub`
    ///    - there is no auto-sign-in session
    ///
    func testSignUpSendsThePluginsRequest() async throws {
        let engine = try harness.engine()
        harness.cognito.once("SignUp") { (_: SignUpInput) in
            SignUpOutput(
                codeDeliveryDetails: .init(attributeName: "email", deliveryMedium: .email, destination: "c***@e***"),
                session: "sign-up-session",
                userConfirmed: false,
                userSub: "sub-carol"
            )
        }

        let result = try await engine.signUp(EngineSignUpRequest(
            username: "carol",
            password: "Password1!",
            userAttributes: ["email": "carol@example.com", "custom:team": "blue"],
            validationData: ["v": "1"],
            clientMetadata: ["app": "test"]
        ))

        XCTAssertEqual(result, AuthClientSignUpResult(
            .confirmUser(AuthClientCodeDeliveryDetails(destination: .email("c***@e***"), attributeKey: .email), nil, "sub-carol"),
            userId: "sub-carol"
        ))
        XCTAssertFalse(result.isSignUpComplete)
        let input = try XCTUnwrap(harness.cognito.inputs("SignUp", as: SignUpInput.self).first)
        XCTAssertEqual(harness.cognito.operations, ["SignUp"])
        XCTAssertEqual(input.clientId, ClientFixtures.configuration.userPool?.appClientId)
        XCTAssertEqual(input.username, "carol")
        XCTAssertEqual(input.password, "Password1!")
        let attributes = (input.userAttributes ?? []).reduce(into: [String: String]()) { $0[$1.name ?? ""] = $1.value }
        XCTAssertEqual(attributes, ["custom:team": "blue", "email": "carol@example.com"])
        XCTAssertEqual(input.validationData?.first { $0.name == "v" }?.value, "1")
        XCTAssertEqual(input.clientMetadata, ["app": "test"])
        let hasSession = await engine.hasAutoSignInSession
        XCTAssertFalse(hasSession)
    }

    /// Empty options are omitted, and a confirmed user without a session is `.done`.
    ///
    /// - Given: Cognito answers `SignUp` with a confirmed user and no session
    /// - When:
    ///    - carol signs up without a password (passwordless) and with no options
    /// - Then:
    ///    - `SignUp` has no password and no client metadata, and no validation data of the caller's
    ///    - the result is `.done` with the `sub`, and there is no auto-sign-in session
    ///
    func testSignUpOmitsEmptyOptions() async throws {
        let engine = try harness.engine()
        harness.cognito.once("SignUp") { (_: SignUpInput) in
            SignUpOutput(userConfirmed: true, userSub: "sub-carol")
        }

        let result = try await engine.signUp(EngineSignUpRequest(
            username: "carol",
            password: nil,
            userAttributes: [:],
            validationData: [:],
            clientMetadata: [:]
        ))

        XCTAssertEqual(result, AuthClientSignUpResult(.done, userId: "sub-carol"))
        XCTAssertTrue(result.isSignUpComplete)
        let input = try XCTUnwrap(harness.cognito.inputs("SignUp", as: SignUpInput.self).first)
        XCTAssertNil(input.password)
        XCTAssertNil(input.clientMetadata)
        XCTAssertFalse(input.validationData?.contains { !$0.name!.hasPrefix("cognito:") } ?? false)
        let hasSession = await engine.hasAutoSignInSession
        XCTAssertFalse(hasSession)
        XCTAssertEqual(harness.cognito.operations, ["SignUp"])
    }

    /// A confirmed user with a session is `.completeAutoSignIn`, and the engine keeps it for `autoSignIn`.
    ///
    /// - Given: Cognito answers `SignUp` with a confirmed user and a session
    /// - When:
    ///    - carol signs up
    /// - Then:
    ///    - the result is `.completeAutoSignIn` with the session, complete
    ///    - the engine holds an auto-sign-in session
    ///
    func testAConfirmedSignUpWithASessionCompletesAutoSignIn() async throws {
        let engine = try harness.engine()
        harness.cognito.once("SignUp") { (_: SignUpInput) in
            SignUpOutput(session: "auto-session", userConfirmed: true, userSub: "sub-carol")
        }

        let result = try await engine.signUp(.carol)

        XCTAssertEqual(result, AuthClientSignUpResult(.completeAutoSignIn("auto-session"), userId: nil))
        XCTAssertTrue(result.isSignUpComplete)
        let hasSession = await engine.hasAutoSignInSession
        XCTAssertTrue(hasSession)
        XCTAssertEqual(harness.cognito.operations, ["SignUp"])
    }

    /// Cognito's refusal is mapped as the plugin maps it.
    ///
    /// - Given: Cognito answers `SignUp` with `UsernameExistsException`
    /// - When:
    ///    - carol signs up
    /// - Then:
    ///    - it throws `.service(.usernameExists)`
    ///
    func testAnExistingUsernameIsUsernameExists() async throws {
        let engine = try harness.engine()
        harness.cognito.once("SignUp") { (_: SignUpInput) -> SignUpOutput in
            throw UsernameExistsException(message: "User already exists")
        }

        await assertThrowsAsync({ try await engine.signUp(.carol) }) { error in
            guard case .service(.usernameExists?, _, _, _) = authError(error) else {
                return XCTFail("\(error)")
            }
        }
        XCTAssertEqual(harness.cognito.operations, ["SignUp"])
    }

    // MARK: Confirmation

    /// The confirmation sends the session of the sign-up it confirms, and its options.
    ///
    /// - Given: carol's sign-up returned `.confirmUser` with a session; Cognito answers `ConfirmSignUp` with a
    ///   new session
    /// - When:
    ///    - carol's sign-up is confirmed with client metadata and `forceAliasCreation`
    /// - Then:
    ///    - `ConfirmSignUp` has the username, code, sign-up's session, client metadata and
    ///      `forceAliasCreation`
    ///    - the result is `.completeAutoSignIn` with the new session, and the engine keeps it
    ///
    func testConfirmSignUpSendsTheSignUpsSession() async throws {
        let engine = try harness.engine()
        scriptUnconfirmedSignUp(session: "sign-up-session")
        harness.cognito.once("ConfirmSignUp") { (_: ConfirmSignUpInput) in
            ConfirmSignUpOutput(session: "auto-session")
        }
        _ = try await engine.signUp(.carol)

        let result = try await engine.confirmSignUp(EngineConfirmSignUpRequest(
            username: "carol",
            confirmationCode: "123456",
            clientMetadata: ["app": "test"],
            forceAliasCreation: true
        ))

        XCTAssertEqual(result, AuthClientSignUpResult(.completeAutoSignIn("auto-session")))
        let input = try XCTUnwrap(harness.cognito.inputs("ConfirmSignUp", as: ConfirmSignUpInput.self).first)
        XCTAssertEqual(input.username, "carol")
        XCTAssertEqual(input.confirmationCode, "123456")
        XCTAssertEqual(input.session, "sign-up-session")
        XCTAssertEqual(input.clientMetadata, ["app": "test"])
        XCTAssertEqual(input.forceAliasCreation, true)
        let hasSession = await engine.hasAutoSignInSession
        XCTAssertTrue(hasSession)
        XCTAssertEqual(harness.cognito.operations, ["SignUp", "ConfirmSignUp"])
    }

    /// Only a matching username gets the session (`AWSAuthConfirmSignUpTask`), and a confirmation without a
    /// session in the answer is `.done`.
    ///
    /// - Given: carol's sign-up returned `.confirmUser` with a session
    /// - When:
    ///    - dave's sign-up is confirmed, with no options
    /// - Then:
    ///    - `ConfirmSignUp` has no session and no client metadata, and the result is `.done`
    ///    - there is no auto-sign-in session
    ///
    func testConfirmSignUpOfAnotherUsernameSendsNoSession() async throws {
        let engine = try harness.engine()
        scriptUnconfirmedSignUp(session: "sign-up-session")
        harness.cognito.once("ConfirmSignUp") { (_: ConfirmSignUpInput) in ConfirmSignUpOutput() }
        _ = try await engine.signUp(.carol)

        let result = try await engine.confirmSignUp(.code("123456", for: "dave"))

        XCTAssertEqual(result, AuthClientSignUpResult(.done))
        let input = try XCTUnwrap(harness.cognito.inputs("ConfirmSignUp", as: ConfirmSignUpInput.self).first)
        XCTAssertNil(input.session)
        XCTAssertNil(input.clientMetadata)
        XCTAssertNil(input.forceAliasCreation)
        let hasSession = await engine.hasAutoSignInSession
        XCTAssertFalse(hasSession)
        XCTAssertEqual(harness.cognito.operations, ["SignUp", "ConfirmSignUp"])
    }

    /// A wrong code keeps the session for a retry; a success ends the sign-up's wait for confirmation.
    ///
    /// - Given: carol's sign-up returned `.confirmUser` with a session; Cognito answers `ConfirmSignUp` with
    ///   `CodeMismatchException`, then success, then success
    /// - When:
    ///    - carol's sign-up is confirmed with a wrong code, then the right one, then again
    /// - Then:
    ///    - the first throws `.service(.codeMismatch)`; the first two send the sign-up's session
    ///    - the third, after the success, sends none
    ///
    func testAWrongCodeKeepsTheSessionForARetry() async throws {
        let engine = try harness.engine()
        scriptUnconfirmedSignUp(session: "sign-up-session")
        harness.cognito.once("ConfirmSignUp") { (_: ConfirmSignUpInput) -> ConfirmSignUpOutput in
            throw CodeMismatchException(message: "Invalid verification code provided, please try again.")
        }
        harness.cognito.always("ConfirmSignUp") { (_: ConfirmSignUpInput) in ConfirmSignUpOutput() }
        _ = try await engine.signUp(.carol)

        await assertThrowsAsync({ try await engine.confirmSignUp(.code("000000", for: "carol")) }) { error in
            guard case .service(.codeMismatch?, _, _, _) = authError(error) else {
                return XCTFail("\(error)")
            }
        }
        _ = try await engine.confirmSignUp(.code("123456", for: "carol"))
        _ = try await engine.confirmSignUp(.code("123456", for: "carol"))

        let sessions = harness.cognito.inputs("ConfirmSignUp", as: ConfirmSignUpInput.self).map(\.session)
        XCTAssertEqual(sessions, ["sign-up-session", "sign-up-session", nil])
        XCTAssertEqual(harness.cognito.operations, ["SignUp", "ConfirmSignUp", "ConfirmSignUp", "ConfirmSignUp"])
    }

    /// A failed sign-up ends the earlier sign-up's wait for confirmation, as the plugin's state moves to
    /// `.error` with the failed request's data.
    ///
    /// - Given: carol's sign-up returned `.confirmUser` with a session, and a second sign-up of carol fails
    /// - When:
    ///    - carol's sign-up is confirmed
    /// - Then:
    ///    - `ConfirmSignUp` has no session
    ///
    func testAFailedSignUpEndsTheWaitForConfirmation() async throws {
        let engine = try harness.engine()
        scriptUnconfirmedSignUp(session: "sign-up-session")
        harness.cognito.once("SignUp") { (_: SignUpInput) -> SignUpOutput in
            throw UsernameExistsException(message: "User already exists")
        }
        harness.cognito.once("ConfirmSignUp") { (_: ConfirmSignUpInput) in ConfirmSignUpOutput() }
        _ = try await engine.signUp(.carol)
        await assertThrowsAsync({ try await engine.signUp(.carol) }) { error in
            guard case .service(.usernameExists?, _, _, _) = authError(error) else {
                return XCTFail("\(error)")
            }
        }

        _ = try await engine.confirmSignUp(.code("123456", for: "carol"))

        XCTAssertEqual(harness.cognito.inputs("ConfirmSignUp", as: ConfirmSignUpInput.self).map(\.session), [nil])
        XCTAssertEqual(harness.cognito.operations, ["SignUp", "SignUp", "ConfirmSignUp"])
    }

    // MARK: Auto sign-in

    /// Auto sign-in is `USER_AUTH` with the sign-up's username, client metadata and session, and the
    /// session survives it, so a second call reaches Cognito again (AS-3).
    ///
    /// - Given: carol's confirmation returned `.completeAutoSignIn` (with client metadata); Cognito answers
    ///   `InitiateAuth` with tokens, then `NotAuthorizedException`
    /// - When:
    ///    - `autoSignIn` runs twice
    /// - Then:
    ///    - the first is `.done` with a payload for carol; its `InitiateAuth` is `USER_AUTH` with
    ///      `USERNAME` carol, the confirmation's session and client metadata
    ///    - the second reaches Cognito and throws `.notAuthorized`; the auto-sign-in session is still held
    ///
    func testAutoSignInSendsTheSessionAndKeepsIt() async throws {
        let engine = try harness.engine()
        harness.scriptIdentityPool()
        scriptUnconfirmedSignUp(session: "sign-up-session")
        harness.cognito.once("ConfirmSignUp") { (_: ConfirmSignUpInput) in ConfirmSignUpOutput(session: "auto-session") }
        harness.cognito.once("InitiateAuth") { (_: InitiateAuthInput) in
            InitiateAuthOutput(authenticationResult: LiveEngineFixtures.tokens("carol"), challengeParameters: [:])
        }
        harness.cognito.once("InitiateAuth") { (_: InitiateAuthInput) -> InitiateAuthOutput in
            throw AWSCognitoIdentityProvider.NotAuthorizedException(message: "Invalid session for the user.")
        }
        _ = try await engine.signUp(.carol)
        _ = try await engine.confirmSignUp(EngineConfirmSignUpRequest(
            username: "carol",
            confirmationCode: "123456",
            clientMetadata: ["app": "test"],
            forceAliasCreation: nil
        ))

        let result = try await engine.autoSignIn(current: nil)

        guard case .done(let payload) = result else {
            return XCTFail("expected .done, got \(result)")
        }
        XCTAssertEqual(try AmplifyCredentials.decoded(payload).signedInData?.username, "carol")
        let input = try XCTUnwrap(harness.cognito.inputs("InitiateAuth", as: InitiateAuthInput.self).first)
        XCTAssertEqual(input.authFlow, .userAuth)
        XCTAssertEqual(input.authParameters?["USERNAME"], "carol")
        XCTAssertEqual(input.session, "auto-session")
        XCTAssertEqual(input.clientMetadata, ["app": "test"])

        await assertThrowsAsync({ try await engine.autoSignIn(current: nil) }) { error in
            guard case .notAuthorized = authError(error) else {
                return XCTFail("\(error)")
            }
        }
        XCTAssertEqual(harness.cognito.operations.count(where: { $0 == "InitiateAuth" }), 2)
        let hasSession = await engine.hasAutoSignInSession
        XCTAssertTrue(hasSession)
        XCTAssertEqual(harness.cognito.operations, ["SignUp", "ConfirmSignUp", "InitiateAuth", "GetId", "GetCredentialsForIdentity", "InitiateAuth"])
    }

    /// Any later sign-up ends the auto-sign-in session an earlier one left, whatever its outcome, as every
    /// sign-up moves the plugin's one `SignUpState`: `autoSignIn` never signs in an earlier user.
    ///
    /// - Given: carol's sign-up returned `.completeAutoSignIn`
    /// - When:
    ///    - dave's sign-up returns `.confirmUser`; then, after a new `.completeAutoSignIn` for carol, erin's
    ///      throws; then, after another, frank's returns `.done` (no session)
    /// - Then:
    ///    - after each, there is no auto-sign-in session, and `autoSignIn` throws "Not in a signed up state…"
    ///      without a request
    ///
    func testALaterSignUpEndsTheAutoSignInSession() async throws {
        let engine = try harness.engine()
        let later: [(String, @Sendable (SignUpInput) async throws -> SignUpOutput)] = [
            ("dave", { _ in SignUpOutput(session: "dave-session", userConfirmed: false, userSub: "sub-dave") }),
            ("erin", { _ in throw InvalidPasswordException(message: "Password did not conform with policy") }),
            ("frank", { _ in SignUpOutput(userConfirmed: true, userSub: "sub-frank") })
        ]
        for (username, answer) in later {
            harness.cognito.once("SignUp") { (_: SignUpInput) in
                SignUpOutput(session: "auto-session", userConfirmed: true, userSub: "sub-carol")
            }
            harness.cognito.once("SignUp", answer)
            _ = try await engine.signUp(.carol)
            let ready = await engine.hasAutoSignInSession
            XCTAssertTrue(ready)

            do {
                _ = try await engine.signUp(EngineSignUpRequest.named(username))
                XCTAssertNotEqual(username, "erin", "erin's sign-up should fail")
            } catch {
                XCTAssertEqual(username, "erin", "\(username)'s sign-up should not fail: \(error)")
            }

            let held = await engine.hasAutoSignInSession
            XCTAssertFalse(held, "after \(username)'s sign-up")
            await assertNotSignedUp(engine)
        }
        XCTAssertEqual(harness.cognito.operations, Array(repeating: "SignUp", count: 6))
    }

    /// The later sign-up that fails is mapped as usual (`invalidPassword`), and ends the earlier session.
    ///
    /// - Given: carol's sign-up returned `.completeAutoSignIn`
    /// - When:
    ///    - erin's sign-up fails with `InvalidPasswordException`
    /// - Then:
    ///    - it throws `.service(.invalidPassword)`, and `autoSignIn` throws "Not in a signed up state…"
    ///
    func testAFailedLaterSignUpIsMappedAndEndsTheSession() async throws {
        let engine = try harness.engine()
        harness.cognito.once("SignUp") { (_: SignUpInput) in
            SignUpOutput(session: "auto-session", userConfirmed: true, userSub: "sub-carol")
        }
        harness.cognito.once("SignUp") { (_: SignUpInput) -> SignUpOutput in
            throw InvalidPasswordException(message: "Password did not conform with policy")
        }
        _ = try await engine.signUp(.carol)

        await assertThrowsAsync({ try await engine.signUp(EngineSignUpRequest.named("erin")) }) { error in
            guard case .service(.invalidPassword?, _, _, _) = authError(error) else {
                return XCTFail("\(error)")
            }
        }
        await assertNotSignedUp(engine)
        XCTAssertEqual(harness.cognito.operations, ["SignUp", "SignUp"])
    }

    /// A failed confirmation ends an earlier auto-sign-in session, as the plugin's state moves to `.error`.
    ///
    /// - Given: carol's sign-up returned `.completeAutoSignIn`
    /// - When:
    ///    - dave's confirmation fails with `CodeMismatchException`
    /// - Then:
    ///    - there is no auto-sign-in session, and `autoSignIn` throws "Not in a signed up state…"
    ///
    func testAFailedConfirmationEndsTheAutoSignInSession() async throws {
        let engine = try harness.engine()
        harness.cognito.once("SignUp") { (_: SignUpInput) in
            SignUpOutput(session: "auto-session", userConfirmed: true, userSub: "sub-carol")
        }
        harness.cognito.once("ConfirmSignUp") { (_: ConfirmSignUpInput) -> ConfirmSignUpOutput in
            throw CodeMismatchException(message: "Invalid verification code provided, please try again.")
        }
        _ = try await engine.signUp(.carol)

        await assertThrowsAsync({ try await engine.confirmSignUp(.code("000000", for: "dave")) }) { error in
            guard case .service(.codeMismatch?, _, _, _) = authError(error) else {
                return XCTFail("\(error)")
            }
        }

        let held = await engine.hasAutoSignInSession
        XCTAssertFalse(held)
        await assertNotSignedUp(engine)
        XCTAssertEqual(harness.cognito.operations, ["SignUp", "ConfirmSignUp"])
    }

    /// While a later sign-up waits for Cognito there is nothing to auto sign in, and of two sign-ups the
    /// one started last decides the state.
    ///
    /// - Given: carol's sign-up returned `.completeAutoSignIn`; dave's sign-up is held at Cognito
    /// - When:
    ///    - `autoSignIn` is called while dave's waits; then erin's sign-up returns `.completeAutoSignIn`, and
    ///      dave's is released and returns `.confirmUser`
    /// - Then:
    ///    - the first `autoSignIn` throws "Not in a signed up state…" with no request
    ///    - afterwards the auto-sign-in session is erin's, the last started, and `autoSignIn` signs erin in
    ///
    func testASignUpInProgressEndsTheAutoSignInSession() async throws {
        let engine = try harness.engine()
        harness.scriptIdentityPool()
        let latch = Gate()
        harness.cognito.once("SignUp") { (_: SignUpInput) in
            SignUpOutput(session: "carol-session", userConfirmed: true, userSub: "sub-carol")
        }
        harness.cognito.once("SignUp") { (_: SignUpInput) in
            await latch.pass()
            return SignUpOutput(session: "dave-session", userConfirmed: false, userSub: "sub-dave")
        }
        harness.cognito.once("SignUp") { (_: SignUpInput) in
            SignUpOutput(session: "erin-session", userConfirmed: true, userSub: "sub-erin")
        }
        harness.cognito.once("InitiateAuth") { (_: InitiateAuthInput) in
            InitiateAuthOutput(authenticationResult: LiveEngineFixtures.tokens("erin"), challengeParameters: [:])
        }
        _ = try await engine.signUp(.carol)
        let dave = Task { try await engine.signUp(EngineSignUpRequest.named("dave")) }
        await latch.waitForArrivals(1)

        await assertNotSignedUp(engine)
        _ = try await engine.signUp(EngineSignUpRequest.named("erin"))
        await latch.open()
        _ = try await dave.value

        let result = try await engine.autoSignIn(current: nil)

        guard case .done(let payload) = result else {
            return XCTFail("expected .done, got \(result)")
        }
        XCTAssertEqual(try AmplifyCredentials.decoded(payload).signedInData?.username, "erin")
        let input = try XCTUnwrap(harness.cognito.inputs("InitiateAuth", as: InitiateAuthInput.self).first)
        XCTAssertEqual(input.authParameters?["USERNAME"], "erin")
        XCTAssertEqual(input.session, "erin-session")
        XCTAssertEqual(harness.cognito.operations, ["SignUp", "SignUp", "SignUp", "InitiateAuth", "GetId", "GetCredentialsForIdentity"])
    }

    /// A sign-up that starts while `autoSignIn` supersedes a pending sign-in is seen before the step is sent:
    /// the state is read again after the `await`, as the plugin's `sendAutoSignInEvent` reads it again.
    ///
    /// - Given: carol's sign-up returned `.completeAutoSignIn`, so `autoSignIn` passed its first check; then
    ///   dave's sign-up starts and is held at Cognito (the interleaving the `await` allows)
    /// - When:
    ///    - `autoSignIn` continues after superseding (`autoSignInAfterSuperseding`), while dave's waits and
    ///      again after dave's returns `.confirmUser`
    /// - Then:
    ///    - both throw "Not in a signed up state…", and no `InitiateAuth` is sent
    ///
    func testAutoSignInReadsTheStateAgainAfterSuperseding() async throws {
        let engine = try harness.engine()
        let latch = Gate()
        harness.cognito.once("SignUp") { (_: SignUpInput) in
            SignUpOutput(session: "carol-session", userConfirmed: true, userSub: "sub-carol")
        }
        harness.cognito.once("SignUp") { (_: SignUpInput) in
            await latch.pass()
            return SignUpOutput(session: "dave-session", userConfirmed: false, userSub: "sub-dave")
        }
        _ = try await engine.signUp(.carol)
        let ready = await engine.hasAutoSignInSession
        XCTAssertTrue(ready)
        let dave = Task { try await engine.signUp(EngineSignUpRequest.named("dave")) }
        await latch.waitForArrivals(1)

        await assertThrowsAsync({ try await engine.autoSignInAfterSuperseding(current: nil, epoch: 0) }) { error in
            guard case .invalidState(let description, _, _) = authError(error) else {
                return XCTFail("\(error)")
            }
            XCTAssertTrue(description.hasPrefix("Not in a signed up state."), description)
        }
        await latch.open()
        _ = try await dave.value
        await assertThrowsAsync({ try await engine.autoSignInAfterSuperseding(current: nil, epoch: 0) }) { error in
            guard case .invalidState = authError(error) else {
                return XCTFail("\(error)")
            }
        }

        XCTAssertEqual(harness.cognito.operations, ["SignUp", "SignUp"])
    }

    /// When the auto-sign-in session is gone by the time the engine runs (a sign-up started after the core's
    /// check), the pending sign-in from the earlier epoch is ended, not kept: `confirmSignIn` at the new epoch
    /// could never answer it, so no challenge is left that nothing can confirm.
    ///
    /// - Given: alice's sign-in waits on an SMS code at epoch 1, and the engine holds no auto-sign-in session
    /// - When:
    ///    - `autoSignIn(current: nil, epoch: 2)` is called
    /// - Then:
    ///    - it throws "Not in a signed up state…", and no challenge is pending, so `confirmSignIn` at epoch 2
    ///      has nothing to answer
    ///
    func testAutoSignInWithoutASessionEndsAnEarlierAttempt() async throws {
        let engine = try harness.engine()
        harness.scriptSRP(then: LiveEngineFixtures.challenge(.smsMfa, parameters: LiveEngineFixtures.smsParameters))
        _ = try await engine.signIn(.srp(), current: nil, epoch: 1)
        let before = await engine.pendingChallenge
        XCTAssertNotNil(before)

        await assertThrowsAsync({ try await engine.autoSignIn(current: nil, epoch: 2) }) { error in
            guard case .invalidState(let description, _, _) = authError(error) else {
                return XCTFail("\(error)")
            }
            XCTAssertTrue(description.hasPrefix("Not in a signed up state."), description)
        }

        let after = await engine.pendingChallenge
        XCTAssertNil(after)
        await assertThrowsAsync({ try await engine.confirmSignIn(.answer("123456"), current: nil, epoch: 2) }) { error in
            guard case .invalidState = authError(error) else {
                return XCTFail("\(error)")
            }
        }
        XCTAssertEqual(harness.cognito.operations, ["InitiateAuth", "RespondToAuthChallenge"])
    }

    // MARK: Auto sign-in on the sign-in seam

    /// An auto sign-in that reaches a challenge keeps it as the pending attempt, at its epoch: a
    /// confirmation at that epoch completes it.
    ///
    /// - Given: carol's sign-up returned `.completeAutoSignIn`; Cognito answers the auto sign-in's
    ///   `InitiateAuth` with an SMS challenge, and the answer with carol's tokens
    /// - When:
    ///    - `autoSignIn(current: nil, epoch: 3)`, then `confirmSignIn` at epoch 3
    /// - Then:
    ///    - the auto sign-in is `.challenge(.confirmSignInWithSMSMFACode)` and it is the pending challenge
    ///    - the confirmation is `.done` with a payload for carol, and nothing is pending any more
    ///
    func testAnAutoSignInChallengeIsConfirmedAtItsEpoch() async throws {
        let engine = try harness.engine()
        harness.scriptIdentityPool()
        harness.cognito.once("SignUp") { (_: SignUpInput) in
            SignUpOutput(session: "auto-session", userConfirmed: true, userSub: "sub-carol")
        }
        harness.cognito.once("InitiateAuth") { (_: InitiateAuthInput) in
            LiveEngineFixtures.initiateChallenge(.smsMfa, parameters: LiveEngineFixtures.smsParameters)
        }
        harness.cognito.once("RespondToAuthChallenge") { (_: RespondToAuthChallengeInput) in
            LiveEngineFixtures.signedIn("carol")
        }
        _ = try await engine.signUp(.carol)

        let step = try await engine.autoSignIn(current: nil, epoch: 3)

        guard case .challenge(.confirmSignInWithSMSMFACode) = step else {
            return XCTFail("expected the SMS challenge, got \(step)")
        }
        let pending = await engine.pendingChallenge
        XCTAssertNotNil(pending)
        let confirmed = try await engine.confirmSignIn(.answer("123456"), current: nil, epoch: 3)
        guard case .done(let payload) = confirmed else {
            return XCTFail("expected .done, got \(confirmed)")
        }
        XCTAssertEqual(try AmplifyCredentials.decoded(payload).signedInData?.username, "carol")
        let after = await engine.pendingChallenge
        XCTAssertNil(after)
        XCTAssertEqual(
            harness.cognito.operations,
            ["SignUp", "InitiateAuth", "RespondToAuthChallenge", "GetId", "GetCredentialsForIdentity"]
        )
    }

    /// An auto sign-in in flight belongs to its epoch: a cancel for an earlier epoch leaves it, a cancel for
    /// a later one ends it, stops its machine, and revokes the refresh token its in-flight call returns,
    /// once. So the operation is the one `run` tracks, and the step carries the epoch it was given.
    ///
    /// - Given: carol's sign-up returned `.completeAutoSignIn`; the auto sign-in's `InitiateAuth`, which
    ///   answers with carol's tokens, is held on a gate; `autoSignIn` runs at epoch 3
    /// - When:
    ///    - `cancelPendingSignIn(before: 3)` runs, then `cancelPendingSignIn(before: 4)`, then the gate opens
    /// - Then:
    ///    - the first stops nothing; the second stops the step's machine (signed out) and the auto sign-in
    ///      throws `CancellationError`
    ///    - the refresh token the released call returns is revoked exactly once, and nothing is pending
    ///
    func testACancelForALaterEpochEndsAnAutoSignInAndRevokesItsLateTokens() async throws {
        let stopped = StoppedOperations()
        let engine = try harness.engine(onStepCancelled: { stopped.append($0) })
        let initiate = Gate()
        harness.scriptSignOut()
        harness.cognito.once("SignUp") { (_: SignUpInput) in
            SignUpOutput(session: "auto-session", userConfirmed: true, userSub: "sub-carol")
        }
        harness.cognito.once("InitiateAuth") { (_: InitiateAuthInput) in
            await initiate.pass()
            return InitiateAuthOutput(authenticationResult: LiveEngineFixtures.tokens("carol"), challengeParameters: [:])
        }
        _ = try await engine.signUp(.carol)
        let autoSignIn = Task { try await engine.autoSignIn(current: nil, epoch: 3) }
        await initiate.waitForArrivals(1)

        await engine.cancelPendingSignIn(before: 3)
        XCTAssertTrue(stopped.all.isEmpty, "a cancel for an earlier epoch ended the auto sign-in")

        await engine.cancelPendingSignIn(before: 4)

        let operation = try XCTUnwrap(stopped.all.first)
        guard case .configured(.signedOut, _, _) = await operation.authMachine.currentState else {
            return XCTFail("the cancel should have reached the auto sign-in's machine")
        }
        await initiate.open()
        let result = await autoSignIn.result
        guard case .failure(let error) = result, error is CancellationError else {
            return XCTFail("expected CancellationError, got \(result)")
        }
        await waitUntil("the late answer reached the tap") {
            harness.cognito.operations.contains("RevokeToken")
        }
        await operation.tokenTap.revocationsFinished()
        XCTAssertEqual(harness.cognito.inputs("RevokeToken", as: RevokeTokenInput.self).map(\.token), ["refresh-carol-v1"])
        let pending = await engine.pendingChallenge
        XCTAssertNil(pending)
        XCTAssertEqual(stopped.all.count, 1)
    }

    /// A later confirmation replaces the auto-sign-in session with its own.
    ///
    /// - Given: carol's sign-up returned `.completeAutoSignIn`; dave's sign-up returned `.confirmUser`
    /// - When:
    ///    - dave's confirmation returns `.completeAutoSignIn`, and `autoSignIn` is called
    /// - Then:
    ///    - `autoSignIn` signs dave in with his confirmation's session
    ///
    func testALaterConfirmationReplacesTheAutoSignInSession() async throws {
        let engine = try harness.engine()
        harness.scriptIdentityPool()
        harness.cognito.once("SignUp") { (_: SignUpInput) in
            SignUpOutput(session: "carol-session", userConfirmed: true, userSub: "sub-carol")
        }
        scriptUnconfirmedSignUp(session: "dave-sign-up-session")
        harness.cognito.once("ConfirmSignUp") { (_: ConfirmSignUpInput) in ConfirmSignUpOutput(session: "dave-session") }
        harness.cognito.once("InitiateAuth") { (_: InitiateAuthInput) in
            InitiateAuthOutput(authenticationResult: LiveEngineFixtures.tokens("dave"), challengeParameters: [:])
        }
        _ = try await engine.signUp(.carol)
        _ = try await engine.signUp(EngineSignUpRequest.named("dave"))
        _ = try await engine.confirmSignUp(.code("123456", for: "dave"))

        _ = try await engine.autoSignIn(current: nil)

        let input = try XCTUnwrap(harness.cognito.inputs("InitiateAuth", as: InitiateAuthInput.self).first)
        XCTAssertEqual(input.authParameters?["USERNAME"], "dave")
        XCTAssertEqual(input.session, "dave-session")
        XCTAssertEqual(
            harness.cognito.inputs("ConfirmSignUp", as: ConfirmSignUpInput.self).map(\.session),
            ["dave-sign-up-session"]
        )
        XCTAssertEqual(harness.cognito.operations, ["SignUp", "SignUp", "ConfirmSignUp", "InitiateAuth", "GetId", "GetCredentialsForIdentity"])
    }

    /// The auto-sign-in session survives a sign-in and a cancel, as the plugin's sign-up state does.
    ///
    /// - Given: carol's sign-up returned `.completeAutoSignIn`
    /// - When:
    ///    - alice signs in to a challenge and it is cancelled
    /// - Then:
    ///    - the auto-sign-in session is still held
    ///
    func testTheAutoSignInSessionSurvivesASignInAndACancel() async throws {
        let engine = try harness.engine()
        harness.scriptSRP(then: LiveEngineFixtures.challenge(.smsMfa, parameters: LiveEngineFixtures.smsParameters))
        harness.cognito.once("SignUp") { (_: SignUpInput) in
            SignUpOutput(session: "auto-session", userConfirmed: true, userSub: "sub-carol")
        }
        _ = try await engine.signUp(.carol)

        _ = try await engine.signIn(.srp(), current: nil)
        await engine.cancelPendingSignIn()

        let held = await engine.hasAutoSignInSession
        XCTAssertTrue(held)
        XCTAssertEqual(harness.cognito.operations, ["SignUp", "InitiateAuth", "RespondToAuthChallenge"])
    }

    /// Without a sign-up to complete, `autoSignIn` throws the plugin's error and sends nothing.
    ///
    /// - Given: a fresh engine
    /// - When:
    ///    - `autoSignIn` is called
    /// - Then:
    ///    - it throws `invalidState` with "Not in a signed up state…", and no request is made
    ///
    func testAutoSignInWithoutASignUpIsRefused() async throws {
        let engine = try harness.engine()

        await assertThrowsAsync({ try await engine.autoSignIn(current: nil) }) { error in
            guard case .invalidState(let description, _, _) = authError(error) else {
                return XCTFail("\(error)")
            }
            XCTAssertTrue(description.hasPrefix("Not in a signed up state."), description)
        }
        XCTAssertEqual(harness.cognito.operations, [])
    }

    /// Auto sign-in supersedes a sign-in waiting on a challenge, as the plugin cancels it.
    ///
    /// - Given: alice's sign-in waits on an SMS code, and carol's sign-up returned `.completeAutoSignIn`
    /// - When:
    ///    - `autoSignIn` is called
    /// - Then:
    ///    - it is `.done` for carol, and no challenge is pending any more
    ///
    func testAutoSignInSupersedesAPendingSignIn() async throws {
        let engine = try harness.engine()
        harness.scriptIdentityPool()
        harness.scriptSRP(then: LiveEngineFixtures.challenge(.smsMfa, parameters: LiveEngineFixtures.smsParameters))
        harness.cognito.once("SignUp") { (_: SignUpInput) in
            SignUpOutput(session: "auto-session", userConfirmed: true, userSub: "sub-carol")
        }
        harness.cognito.once("InitiateAuth") { (_: InitiateAuthInput) in
            InitiateAuthOutput(authenticationResult: LiveEngineFixtures.tokens("carol"), challengeParameters: [:])
        }
        _ = try await engine.signIn(.srp(), current: nil)
        let before = await engine.pendingChallenge
        XCTAssertNotNil(before)
        _ = try await engine.signUp(.carol)

        let result = try await engine.autoSignIn(current: nil)

        guard case .done(let payload) = result else {
            return XCTFail("expected .done, got \(result)")
        }
        XCTAssertEqual(try AmplifyCredentials.decoded(payload).signedInData?.username, "carol")
        let after = await engine.pendingChallenge
        XCTAssertNil(after)
        XCTAssertEqual(harness.cognito.operations, ["InitiateAuth", "RespondToAuthChallenge", "SignUp", "InitiateAuth", "GetId", "GetCredentialsForIdentity"])
    }

    // MARK: Resending the code

    /// The resend carries the plugin's request and maps the delivery details.
    ///
    /// - Given: Cognito answers `ResendConfirmationCode` with an email delivery
    /// - When:
    ///    - the code is resent for carol, with and without client metadata
    /// - Then:
    ///    - each request has the app client and username, and the client metadata as given (`[:]` for none,
    ///      as the plugin sends)
    ///    - the result is the email destination and the `email` attribute
    ///
    func testResendSignUpCodeSendsThePluginsRequest() async throws {
        let engine = try harness.engine()
        harness.cognito.always("ResendConfirmationCode") { (_: ResendConfirmationCodeInput) in
            ResendConfirmationCodeOutput(
                codeDeliveryDetails: .init(attributeName: "email", deliveryMedium: .email, destination: "c***@e***")
            )
        }

        let withMetadata = try await engine.resendSignUpCode(username: "carol", clientMetadata: ["app": "test"])
        let without = try await engine.resendSignUpCode(username: "carol", clientMetadata: [:])

        let expected = AuthClientCodeDeliveryDetails(destination: .email("c***@e***"), attributeKey: .email)
        XCTAssertEqual(withMetadata, expected)
        XCTAssertEqual(without, expected)
        let inputs = harness.cognito.inputs("ResendConfirmationCode", as: ResendConfirmationCodeInput.self)
        XCTAssertEqual(inputs.map(\.username), ["carol", "carol"])
        XCTAssertEqual(inputs.map(\.clientId), Array(repeating: ClientFixtures.configuration.userPool?.appClientId, count: 2))
        XCTAssertEqual(inputs.map(\.clientMetadata), [["app": "test"], [:]])
        XCTAssertNil(inputs.first?.secretHash)
        XCTAssertEqual(harness.cognito.operations, ["ResendConfirmationCode", "ResendConfirmationCode"])
    }

    /// An answer without delivery details is the plugin's `unknown`; a refusal is mapped.
    ///
    /// - Given: Cognito answers `ResendConfirmationCode` with no details, then `LimitExceededException`
    /// - When:
    ///    - the code is resent twice
    /// - Then:
    ///    - the first throws `.unknown("Unable to get Auth code delivery details")`
    ///    - the second throws `.service(.limitExceeded)`
    ///
    func testResendSignUpCodeFailures() async throws {
        let engine = try harness.engine()
        harness.cognito.once("ResendConfirmationCode") { (_: ResendConfirmationCodeInput) in
            ResendConfirmationCodeOutput()
        }
        harness.cognito.once("ResendConfirmationCode") { (_: ResendConfirmationCodeInput) -> ResendConfirmationCodeOutput in
            throw LimitExceededException(message: "Attempt limit exceeded, please try after some time.")
        }

        await assertThrowsAsync({ try await engine.resendSignUpCode(username: "carol", clientMetadata: [:]) }) { error in
            guard case .unknown(let description, _, _) = authError(error) else {
                return XCTFail("\(error)")
            }
            XCTAssertEqual(description, "Unable to get Auth code delivery details")
        }
        await assertThrowsAsync({ try await engine.resendSignUpCode(username: "carol", clientMetadata: [:]) }) { error in
            guard case .service(.limitExceeded?, _, _, _) = authError(error) else {
                return XCTFail("\(error)")
            }
        }
        XCTAssertEqual(harness.cognito.operations, ["ResendConfirmationCode", "ResendConfirmationCode"])
    }

    // MARK: Configuration

    /// Without a user pool, every sign-up call throws `configuration` before any request.
    ///
    /// - Given: an engine over an identity-pool-only configuration
    /// - When:
    ///    - each sign-up call is made
    /// - Then:
    ///    - each throws `configuration`, and no request is made
    ///
    func testSignUpNeedsAUserPool() async throws {
        harness = LiveEngineHarness(configuration: ClientFixtures.identityPoolOnlyConfiguration)
        let engine = try harness.engine()
        let calls: [() async throws -> Any] = [
            { try await engine.signUp(.carol) },
            { try await engine.confirmSignUp(.code("1", for: "carol")) },
            { try await engine.resendSignUpCode(username: "carol", clientMetadata: [:]) },
            { try await engine.autoSignIn(current: nil) }
        ]
        for call in calls {
            await assertThrowsAsync({ try await call() }) { error in
                guard case .configuration = authError(error) else {
                    return XCTFail("\(error)")
                }
            }
        }
        XCTAssertEqual(harness.cognito.operations, [])
    }

    // MARK: Through the public API

    /// The whole flow over the live engine, per session: sign up, confirm, auto sign-in, sign out, and a
    /// second auto sign-in that reaches Cognito again (AS-2, AS-3).
    ///
    /// - Given: two clients over the live engine, `work` and `home`; Cognito scripted for an unconfirmed
    ///   sign-up, a confirmation with a session, `USER_AUTH` tokens then `NotAuthorizedException`, and sign-out
    /// - When:
    ///    - `work` signs carol up, confirms her and calls `autoSignIn`, then signs out and calls it again;
    ///      `home` calls `autoSignIn`
    /// - Then:
    ///    - `work`'s first `autoSignIn` is `.done`, commits carol's record and sends `.signedIn`
    ///    - after the sign-out, the second throws `.notAuthorized` from Cognito
    ///    - `home` has no sign-up: "Not in a signed up state…", and no request of its own
    ///
    func testTheFlowThroughThePublicAPI() async throws {
        let clientHarness = ClientHarness()
        let dependencies = liveDependencies(clientHarness)
        let work = ClientFixtures.id("work")
        let client = try AmplifyCognitoClient(
            configuration: ClientFixtures.configuration,
            options: .init(sessionId: work),
            dependencies: dependencies
        )
        let home = try AmplifyCognitoClient(
            configuration: ClientFixtures.configuration,
            options: .init(sessionId: ClientFixtures.id("home")),
            dependencies: dependencies
        )
        harness.scriptIdentityPool()
        harness.scriptSignOut()
        scriptUnconfirmedSignUp(session: "sign-up-session")
        harness.cognito.once("ConfirmSignUp") { (_: ConfirmSignUpInput) in ConfirmSignUpOutput(session: "auto-session") }
        harness.cognito.once("InitiateAuth") { (_: InitiateAuthInput) in
            InitiateAuthOutput(authenticationResult: LiveEngineFixtures.tokens("carol"), challengeParameters: [:])
        }
        harness.cognito.once("InitiateAuth") { (_: InitiateAuthInput) -> InitiateAuthOutput in
            throw AWSCognitoIdentityProvider.NotAuthorizedException(message: "Invalid session for the user.")
        }
        _ = await client.currentSessionState()
        let events = StreamRecorder(client.listenToAuthEvents())

        let signUp = try await client.signUp(username: "carol")
        let confirm = try await client.confirmSignUp(for: "carol", confirmationCode: "123456")
        let result = try await client.autoSignIn()

        XCTAssertEqual(signUp.nextStep, .confirmUser(nil, nil, "sub"))
        XCTAssertEqual(confirm.nextStep, .completeAutoSignIn("auto-session"))
        XCTAssertEqual(result, AuthClientSignInResult(nextStep: .done))
        let user = try await client.getCurrentUser()
        XCTAssertEqual(user.username, "carol")
        XCTAssertEqual(try clientHarness.storedRecord(work)?.username, "carol")
        await events.waitFor(1)
        XCTAssertEqual(events.received.first, .signedIn)

        _ = try await client.signOut()
        await assertThrowsAsync({ try await client.autoSignIn() }) { error in
            guard case .notAuthorized = authError(error) else {
                return XCTFail("\(error)")
            }
        }
        let initiateAuthCount = harness.cognito.operations.count(where: { $0 == "InitiateAuth" })
        XCTAssertEqual(initiateAuthCount, 2)

        await assertThrowsAsync({ try await home.autoSignIn() }) { error in
            guard case .invalidState(let description, _, _) = authError(error) else {
                return XCTFail("\(error)")
            }
            XCTAssertTrue(description.hasPrefix("Not in a signed up state."), description)
        }
        XCTAssertEqual(harness.cognito.operations.count(where: { $0 == "InitiateAuth" }), initiateAuthCount)
    }

    /// A purge of the session's stored record leaves the auto-sign-in session, as the plugin's sign-up
    /// state is not touched by clearing credentials.
    ///
    /// - Given: a client over the live engine whose sign-up returned `.completeAutoSignIn`
    /// - When:
    ///    - the session's stored record is purged, then `autoSignIn` is called
    /// - Then:
    ///    - `autoSignIn` reaches Cognito with the sign-up's session and is `.done`
    ///
    func testTheAutoSignInSessionSurvivesAPurge() async throws {
        let clientHarness = ClientHarness()
        let dependencies = liveDependencies(clientHarness)
        let work = ClientFixtures.id("work")
        let client = try AmplifyCognitoClient(
            configuration: ClientFixtures.configuration,
            options: .init(sessionId: work),
            dependencies: dependencies
        )
        harness.scriptIdentityPool()
        harness.cognito.once("SignUp") { (_: SignUpInput) in
            SignUpOutput(session: "auto-session", userConfirmed: true, userSub: "sub-carol")
        }
        harness.cognito.once("InitiateAuth") { (_: InitiateAuthInput) in
            InitiateAuthOutput(authenticationResult: LiveEngineFixtures.tokens("carol"), challengeParameters: [:])
        }
        _ = try await client.signUp(username: "carol")

        try await AmplifyCognitoClient.purgeStoredSession(
            sessionId: work,
            configuration: ClientFixtures.configuration,
            accessGroup: nil,
            dependencies: dependencies
        )
        let result = try await client.autoSignIn()

        XCTAssertEqual(result, AuthClientSignInResult(nextStep: .done))
        let input = try XCTUnwrap(harness.cognito.inputs("InitiateAuth", as: InitiateAuthInput.self).first)
        XCTAssertEqual(input.session, "auto-session")
        XCTAssertEqual(harness.cognito.operations, ["SignUp", "InitiateAuth", "GetId", "GetCredentialsForIdentity"])
    }

    /// A confirmation that starts while another sign-up step is in progress sends no session (the second
    /// divergence: the plugin waits for the step instead), and the step started last decides the state.
    ///
    /// - Given: carol's sign-up returned `.confirmUser` with a session; dave's sign-up is held at Cognito
    /// - When:
    ///    - carol's sign-up is confirmed while dave's waits; then dave's is released
    /// - Then:
    ///    - `ConfirmSignUp` has no session, and the confirmation is `.done`
    ///    - carol's confirmation, started last, decides the state: no auto-sign-in session, and a confirmation
    ///      of dave sends no session either
    ///
    func testAConfirmationDuringAnotherStepSendsNoSession() async throws {
        let engine = try harness.engine()
        let latch = Gate()
        scriptUnconfirmedSignUp(session: "carol-session")
        harness.cognito.once("SignUp") { (_: SignUpInput) in
            await latch.pass()
            return SignUpOutput(session: "dave-session", userConfirmed: false, userSub: "sub-dave")
        }
        harness.cognito.always("ConfirmSignUp") { (_: ConfirmSignUpInput) in ConfirmSignUpOutput() }
        _ = try await engine.signUp(.carol)
        let dave = Task { try await engine.signUp(EngineSignUpRequest.named("dave")) }
        await latch.waitForArrivals(1)

        let confirmation = try await engine.confirmSignUp(.code("123456", for: "carol"))
        await latch.open()
        _ = try await dave.value
        _ = try await engine.confirmSignUp(.code("654321", for: "dave"))

        XCTAssertEqual(confirmation, AuthClientSignUpResult(.done))
        XCTAssertEqual(harness.cognito.inputs("ConfirmSignUp", as: ConfirmSignUpInput.self).map(\.session), [nil, nil])
        let held = await engine.hasAutoSignInSession
        XCTAssertFalse(held)
        XCTAssertEqual(harness.cognito.operations, ["SignUp", "SignUp", "ConfirmSignUp", "ConfirmSignUp"])
    }

    // MARK: Helpers

    /// The client dependencies of `clientHarness`, with this test's live engine.
    private func liveDependencies(_ clientHarness: ClientHarness) -> SessionCoreDependencies {
        let base = clientHarness.dependencies
        let harness = harness!
        return SessionCoreDependencies(
            registry: base.registry,
            gates: base.gates,
            makeStore: base.makeStore,
            makeClients: base.makeClients,
            makeEngine: { _ in try harness.engine() },
            makeRevoker: base.makeRevoker,
            scheduleRestore: base.scheduleRestore,
            bounds: base.bounds,
            now: { Date() }
        )
    }

    private func assertNotSignedUp(
        _ engine: LiveSessionEngine,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let before = harness.cognito.operations.count
        await assertThrowsAsync({ try await engine.autoSignIn(current: nil) }, file: file, line: line) { error in
            guard case .invalidState(let description, _, _) = authError(error) else {
                return XCTFail("\(error)", file: file, line: line)
            }
            XCTAssertTrue(description.hasPrefix("Not in a signed up state."), description, file: file, line: line)
        }
        XCTAssertEqual(harness.cognito.operations.count, before, "autoSignIn sent a request", file: file, line: line)
    }

    private func scriptUnconfirmedSignUp(session: String) {
        harness.cognito.once("SignUp") { (_: SignUpInput) in
            SignUpOutput(session: session, userConfirmed: false, userSub: "sub")
        }
    }
}

extension EngineSignUpRequest {

    static let carol = named("carol")

    static func named(_ username: String) -> EngineSignUpRequest {
        EngineSignUpRequest(
            username: username,
            password: "Password1!",
            userAttributes: [:],
            validationData: [:],
            clientMetadata: [:]
        )
    }
}

extension EngineConfirmSignUpRequest {

    static func code(_ code: String, for username: String) -> EngineConfirmSignUpRequest {
        EngineConfirmSignUpRequest(username: username, confirmationCode: code, clientMetadata: [:], forceAliasCreation: nil)
    }
}
