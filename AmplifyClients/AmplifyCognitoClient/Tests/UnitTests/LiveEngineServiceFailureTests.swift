//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(UnknownAWSHTTPServiceError) import AWSClientRuntime
import AWSCognitoIdentity
import AWSCognitoIdentityProvider
import Foundation
import InternalAWSCognitoAuth
import SmithyHTTPAPI
import SmithyRetriesAPI
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// A failure Cognito reports as its own (either pool's `InternalErrorException`, or an error status the SDK does not
/// model), which the plugin reports as `AuthError.unknown`, is `.service` with no code in every call, with a recovery
/// suggestion that fits it: never the engine's "This should not happen … file an issue" text.
final class LiveEngineServiceFailureTests: XCTestCase {

    private var harness: LiveEngineHarness!

    override func setUp() {
        super.setUp()
        harness = LiveEngineHarness()
    }

    override func tearDown() {
        harness = nil
        super.tearDown()
    }

    /// - Given: `InitiateAuth`, `SignUp`, `ForgotPassword`, `GetTokensFromRefreshToken`, `GetUser` and
    ///   `ListDevices` failing with the user pool's `InternalErrorException`, and `GetId` with the identity pool's
    /// - When: the live engine signs in, signs up, resets a password, refreshes a session, reads the user's
    ///   attributes, MFA preference and devices, fetches guest credentials and federates
    /// - Then:
    ///    - each throws `.service` with no code, Cognito's message in the description and the retry suggestion; none
    ///      asks for a bug report
    func testACognitoInternalErrorSuggestsARetry() async throws {
        let engine = try harness.engine()
        let payload = try await harness.signedInPayload(on: engine)
        harness.cognito.always("InitiateAuth") { (_: InitiateAuthInput) -> InitiateAuthOutput in
            throw AWSCognitoIdentityProvider.InternalErrorException(message: "boom")
        }
        harness.cognito.always("SignUp") { (_: SignUpInput) -> SignUpOutput in
            throw AWSCognitoIdentityProvider.InternalErrorException(message: "boom")
        }
        harness.cognito.always("ForgotPassword") { (_: ForgotPasswordInput) -> ForgotPasswordOutput in
            throw AWSCognitoIdentityProvider.InternalErrorException(message: "boom")
        }
        harness.cognito.always("GetUser") { (_: GetUserInput) -> GetUserOutput in
            throw AWSCognitoIdentityProvider.InternalErrorException(message: "boom")
        }
        harness.cognito.always("ListDevices") { (_: ListDevicesInput) -> ListDevicesOutput in
            throw AWSCognitoIdentityProvider.InternalErrorException(message: "boom")
        }
        harness.cognito.always("GetTokensFromRefreshToken") { (_: GetTokensFromRefreshTokenInput) -> GetTokensFromRefreshTokenOutput in
            throw AWSCognitoIdentityProvider.InternalErrorException(message: "boom")
        }
        harness.cognito.always("GetId") { (_: GetIdInput) -> GetIdOutput in
            throw AWSCognitoIdentity.InternalErrorException(message: "boom")
        }

        let signUp = EngineSignUpRequest(
            username: "carol",
            password: "Password1!",
            userAttributes: [:],
            validationData: [:],
            clientMetadata: [:]
        )
        let operations: [(String, () async throws -> Void)] = [
            ("signIn", { _ = try await engine.signIn(.srp(), current: nil) }),
            ("signUp", { _ = try await engine.signUp(signUp) }),
            ("resetPassword", { _ = try await engine.resetPassword(username: "carol", clientMetadata: [:]) }),
            ("refresh", { _ = try await engine.refresh(payload, force: true) }),
            ("fetchUserAttributes", { _ = try await engine.fetchUserAttributes(payload) }),
            ("fetchMFAPreference", { _ = try await engine.fetchMFAPreference(payload) }),
            ("fetchDevices", { _ = try await engine.fetchDevices(payload) }),
            ("fetchGuestCredentials", { _ = try await engine.fetchGuestCredentials(current: nil) }),
            ("federateToIdentityPool", {
                _ = try await engine.federateToIdentityPool(
                    EngineFederationRequest(token: "token", provider: .facebook, developerProvidedIdentityId: nil),
                    current: nil
                )
            })
        ]
        for (name, body) in operations {
            await assertThrowsAsync(body) { error in
                Self.assertCodelessService(error, suggesting: AuthClientError.serviceFaultSuggestion, name)
                XCTAssertTrue(Self.mapped(error)?.errorDescription.contains("boom") == true, "\(name): \(error)")
            }
        }
    }

    /// - Given: alice's sign-in stopped on an SMS MFA challenge, and the answer's `RespondToAuthChallenge` failing
    ///   with the user pool's `InternalErrorException`
    /// - When: the code is answered
    /// - Then:
    ///    - it throws `.service` with no code and the retry suggestion, never a bug report, as the confirm path maps it
    func testACognitoInternalErrorAnsweringAChallengeSuggestsARetry() async throws {
        let engine = try harness.engine()
        harness.scriptSRP(then: LiveEngineFixtures.challenge(.smsMfa, parameters: LiveEngineFixtures.smsParameters))
        harness.cognito.once("RespondToAuthChallenge") { (_: RespondToAuthChallengeInput) -> RespondToAuthChallengeOutput in
            throw AWSCognitoIdentityProvider.InternalErrorException(message: "boom")
        }
        let first = try await engine.signIn(.srp(), current: nil)
        guard case .challenge(.confirmSignInWithSMSMFACode) = first else {
            return XCTFail("expected an SMS MFA challenge, got \(first)")
        }

        await assertThrowsAsync({ try await engine.confirmSignIn(.answer("123456"), current: nil) }) { error in
            Self.assertCodelessService(error, suggesting: AuthClientError.serviceFaultSuggestion, "confirmSignIn")
        }
    }

    /// The sign-in flows whose Cognito failure the engine reports as its authentication error
    /// (`ThrowSignInError`): `USER_AUTH`, auto sign-in, and the device SRP answers of a sign-in on a remembered device.
    ///
    /// - Given: the user pool's `InternalErrorException` from `InitiateAuth` for `USER_AUTH` (with the password factor,
    ///   and with no preference) and for an auto sign-in after carol's sign-up, and from the `DEVICE_SRP_AUTH` answer,
    ///   then the `DEVICE_PASSWORD_VERIFIER` answer, of a sign-in with alice's device record
    /// - When: the live engine signs in, and signs in automatically
    /// - Then:
    ///    - each throws `.service` with no code, Cognito's message in the description and the retry suggestion; none
    ///      asks for a bug report
    func testACognitoInternalErrorInTheOtherSignInFlowsSuggestsARetry() async throws {
        let rows: [(String, (LiveEngineHarness, LiveSessionEngine) async throws -> Void)] = [
            ("USER_AUTH, password", { harness, engine in
                harness.cognito.always("InitiateAuth") { (_: InitiateAuthInput) -> InitiateAuthOutput in
                    throw AWSCognitoIdentityProvider.InternalErrorException(message: "boom")
                }
                _ = try await engine.signIn(.flow(.userAuth(preferredFirstFactor: .password)), current: nil)
            }),
            ("USER_AUTH, no preference", { harness, engine in
                harness.cognito.always("InitiateAuth") { (_: InitiateAuthInput) -> InitiateAuthOutput in
                    throw AWSCognitoIdentityProvider.InternalErrorException(message: "boom")
                }
                _ = try await engine.signIn(.flow(.userAuth(preferredFirstFactor: nil), password: nil), current: nil)
            }),
            ("autoSignIn", { harness, engine in
                harness.cognito.once("SignUp") { (_: SignUpInput) in
                    SignUpOutput(session: "sign-up-session", userConfirmed: false, userSub: "sub")
                }
                harness.cognito.once("ConfirmSignUp") { (_: ConfirmSignUpInput) in ConfirmSignUpOutput(session: "auto-session") }
                harness.cognito.always("InitiateAuth") { (_: InitiateAuthInput) -> InitiateAuthOutput in
                    throw AWSCognitoIdentityProvider.InternalErrorException(message: "boom")
                }
                _ = try await engine.signUp(.carol)
                _ = try await engine.confirmSignUp(EngineConfirmSignUpRequest(
                    username: "carol",
                    confirmationCode: "123456",
                    clientMetadata: [:],
                    forceAliasCreation: nil
                ))
                _ = try await engine.autoSignIn(current: nil)
            }),
            ("DEVICE_SRP_AUTH", { harness, engine in
                try Self.scriptDeviceSignIn(on: harness, failingAnswer: 1)
                _ = try await engine.signIn(.srp(), current: nil)
            }),
            ("DEVICE_PASSWORD_VERIFIER", { harness, engine in
                try Self.scriptDeviceSignIn(on: harness, failingAnswer: 2)
                _ = try await engine.signIn(.srp(), current: nil)
            })
        ]
        for (name, body) in rows {
            let fresh = LiveEngineHarness()
            harness = fresh
            let engine = try fresh.engine()
            await assertThrowsAsync({ try await body(fresh, engine) }) { error in
                Self.assertCodelessService(error, suggesting: AuthClientError.serviceFaultSuggestion, name)
                XCTAssertTrue(Self.mapped(error)?.errorDescription.contains("boom") == true, "\(name): \(error)")
            }
        }
    }

    #if os(iOS) || os(macOS) || os(visionOS)
    /// A passkey sign-in's own calls: answering the `WEB_AUTHN` selection for the credential options, and answering
    /// `WEB_AUTHN` with the sheet's credential.
    ///
    /// - Given: a passkey sheet that presents nothing, and the user pool's `InternalErrorException` from the
    ///   `RespondToAuthChallenge` that sends the credential, after `InitiateAuth` preferring `WEB_AUTHN`; and from the
    ///   one that answers the first-factor selection with `WEB_AUTHN`
    /// - When: alice signs in with the preference and a window; and signs in with no preference and selects `WEB_AUTHN`
    /// - Then:
    ///    - each throws `.service` with no code, Cognito's message in the description and the retry suggestion; none
    ///      asks for a bug report
    func testACognitoInternalErrorInAPasskeySignInSuggestsARetry() async throws {
        guard #available(iOS 17.4, macOS 13.5, visionOS 1.0, *) else {
            throw XCTSkip("Passkeys need iOS 17.4, macOS 13.5 or visionOS 1.0")
        }
        let window = await WebAuthnFixtures.window()
        let anchor = await MainActor.run { EnginePresentationAnchorBox(window) }
        let context = EngineCeremonyContext(anchor: anchor, ceremony: WebAuthnCredentialOperations.runCeremonyDirectly)
        let rows: [(String, (LiveEngineHarness, LiveSessionEngine) async throws -> Void)] = [
            ("credential", { harness, engine in
                harness.cognito.once("InitiateAuth") { (_: InitiateAuthInput) in
                    LiveEngineFixtures.initiateChallenge(.webAuthn, parameters: ["CREDENTIAL_REQUEST_OPTIONS": WebAuthnFixtures.requestOptions])
                }
                harness.cognito.once("RespondToAuthChallenge") { (_: RespondToAuthChallengeInput) -> RespondToAuthChallengeOutput in
                    throw AWSCognitoIdentityProvider.InternalErrorException(message: "boom")
                }
                _ = try await engine.signIn(EngineSignInRequest(
                    username: "alice",
                    password: nil,
                    authFlowType: .userAuth(preferredFirstFactor: .webAuthn),
                    clientMetadata: [:],
                    webAuthn: context
                ), current: nil)
            }),
            ("selection", { harness, engine in
                harness.cognito.once("InitiateAuth") { (_: InitiateAuthInput) in
                    InitiateAuthOutput(
                        availableChallenges: [.password, .webAuthn],
                        challengeName: .selectChallenge,
                        challengeParameters: [:],
                        session: "select-session"
                    )
                }
                harness.cognito.once("RespondToAuthChallenge") { (_: RespondToAuthChallengeInput) -> RespondToAuthChallengeOutput in
                    throw AWSCognitoIdentityProvider.InternalErrorException(message: "boom")
                }
                let first = try await engine.signIn(EngineSignInRequest(
                    username: "alice",
                    password: nil,
                    authFlowType: .userAuth(preferredFirstFactor: nil),
                    clientMetadata: [:],
                    webAuthn: context
                ), current: nil)
                guard case .challenge(.continueSignInWithFirstFactorSelection) = first else {
                    throw FixtureError(description: "expected the first-factor selection, got \(first)")
                }
                var answer = EngineConfirmSignInRequest.answer("WEB_AUTHN")
                answer.webAuthn = context
                _ = try await engine.confirmSignIn(answer, current: nil)
            })
        ]
        for (name, body) in rows {
            let fresh = LiveEngineHarness()
            harness = fresh
            let engine = try fresh.engine(sheet: FakePasskeySheet())
            await assertThrowsAsync({ try await body(fresh, engine) }) { error in
                Self.assertCodelessService(error, suggesting: AuthClientError.serviceFaultSuggestion, name)
                XCTAssertTrue(Self.mapped(error)?.errorDescription.contains("boom") == true, "\(name): \(error)")
            }
            fresh.cognito.assertConsumed()
        }
    }
    #endif

    /// - Given: `InitiateAuth` and `GetId` failing with an error status the SDK does not model, of 500, 503 and 400
    /// - When: the live engine signs in, and federates
    /// - Then:
    ///    - each throws `.service` with no code and the status in the description; the 5xx statuses suggest a retry, the 400
    ///      says the service refused the request with an error the client does not recognise; none asks for a bug
    ///      report
    func testAnErrorStatusTheSDKDoesNotModelSuggestsARetryOrNamesTheRefusal() async throws {
        let cases: [(HTTPStatusCode, String)] = [
            (.internalServerError, AuthClientError.serviceFaultSuggestion),
            (.serviceUnavailable, AuthClientError.serviceFaultSuggestion),
            (.badRequest, AuthClientError.unrecognisedServiceErrorSuggestion)
        ]
        for (status, expected) in cases {
            harness = LiveEngineHarness()
            let failure = UnknownAWSHTTPServiceError(
                httpResponse: HTTPResponse(body: .empty, statusCode: status),
                message: "fixture message",
                requestID: nil,
                requestID2: nil,
                typeName: nil
            )
            harness.cognito.always("InitiateAuth") { (_: InitiateAuthInput) -> InitiateAuthOutput in throw failure }
            harness.cognito.always("GetId") { (_: GetIdInput) -> GetIdOutput in throw failure }
            let engine = try harness.engine()

            let operations: [(String, () async throws -> Void)] = [
                ("signIn", { _ = try await engine.signIn(.srp(), current: nil) }),
                ("federateToIdentityPool", {
                    _ = try await engine.federateToIdentityPool(
                        EngineFederationRequest(token: "token", provider: .facebook, developerProvidedIdentityId: nil),
                        current: nil
                    )
                })
            ]
            for (operation, body) in operations {
                let label = "\(operation), \(status.rawValue)"
                await assertThrowsAsync(body) { error in
                    Self.assertCodelessService(error, suggesting: expected, label)
                    XCTAssertTrue(Self.mapped(error)?.errorDescription.contains("\(status.rawValue)") == true, "\(label): \(error)")
                }
            }
        }
    }

    /// The calls whose engine error the client gets from the engine's state or a passkey operation, with the
    /// exception beside it: `deleteUser`, a sign-out's revoke and global sign-out, and the passkey credential calls.
    ///
    /// - Given: `DeleteUser`, `ListWebAuthnCredentials`, `DeleteWebAuthnCredential`, `RevokeToken` and
    ///   `GlobalSignOut` failing with the user pool's `InternalErrorException`, then with an error status the SDK
    ///   does not model (500)
    /// - When: the live engine deletes the user, lists and deletes a passkey, and signs out, locally and globally
    /// - Then:
    ///    - the deletion and the passkey calls throw `.service` with no code, the retry suggestion and Cognito's
    ///      message or the status in the description, never a bug report
    ///    - the sign-out's revoke error and global sign-out error are `.service` with no code and the same
    ///      description, with the sign-out's not-retried suggestion
    func testACognitoFailureInTheCallsTheEngineCarriesTheCauseForIsAServiceError() async throws {
        let unmodelled = UnknownAWSHTTPServiceError(
            httpResponse: HTTPResponse(body: .empty, statusCode: .internalServerError),
            message: "fixture message",
            requestID: nil,
            requestID2: nil,
            typeName: nil
        )
        let failures: [(String, Error, String)] = [
            ("internal error", AWSCognitoIdentityProvider.InternalErrorException(message: "boom"), "boom"),
            ("unmodelled 500", unmodelled, "500")
        ]
        for (label, failure, shown) in failures {
            harness = LiveEngineHarness()
            let engine = try harness.engine()
            let payload = try await harness.signedInPayload(on: engine)
            harness.cognito.always("DeleteUser") { (_: DeleteUserInput) -> DeleteUserOutput in throw failure }
            harness.cognito.always("ListWebAuthnCredentials") { (_: ListWebAuthnCredentialsInput) -> ListWebAuthnCredentialsOutput in
                throw failure
            }
            harness.cognito.always("DeleteWebAuthnCredential") { (_: DeleteWebAuthnCredentialInput) -> DeleteWebAuthnCredentialOutput in
                throw failure
            }
            harness.cognito.always("RevokeToken") { (_: RevokeTokenInput) -> RevokeTokenOutput in throw failure }
            harness.cognito.always("GlobalSignOut") { (_: GlobalSignOutInput) -> GlobalSignOutOutput in throw failure }

            let operations: [(String, () async throws -> Void)] = [
                ("deleteUser", { try await engine.deleteUser(payload) }),
                ("listWebAuthnCredentials", {
                    _ = try await engine.listWebAuthnCredentials(payload, pageSize: 20, nextToken: nil)
                }),
                ("deleteWebAuthnCredential", { try await engine.deleteWebAuthnCredential(payload, credentialId: "credential") })
            ]
            for (name, body) in operations {
                await assertThrowsAsync(body) { error in
                    Self.assertCodelessService(error, suggesting: AuthClientError.serviceFaultSuggestion, "\(name), \(label)")
                    XCTAssertTrue(Self.mapped(error)?.errorDescription.contains(shown) == true, "\(name), \(label): \(error)")
                }
            }

            let local = try await engine.revoke(payload, global: false)
            let revokeError = try XCTUnwrap(local.revokeError, label)
            Self.assertCodelessService(revokeError, suggesting: AuthClientError.revokeNotRetriedSuggestion, "revoke, \(label)")
            XCTAssertTrue(revokeError.errorDescription.contains(shown), "revoke, \(label): \(revokeError)")

            let global = try await engine.revoke(payload, global: true)
            let globalSignOutError = try XCTUnwrap(global.globalSignOutError, label)
            Self.assertCodelessService(
                globalSignOutError,
                suggesting: AuthClientError.globalSignOutNotRetriedSuggestion,
                "globalSignOut, \(label)"
            )
            XCTAssertTrue(globalSignOutError.errorDescription.contains(shown), "globalSignOut, \(label): \(globalSignOutError)")
        }
    }

    #if os(iOS) || os(macOS) || os(visionOS)
    /// The passkey associate call, whose `CompleteWebAuthnRegistration` is sent after the ceremony.
    ///
    /// - Given: alice signed in over the live engine with a passkey sheet that presents nothing, Cognito answering
    ///   `StartWebAuthnRegistration`, and `CompleteWebAuthnRegistration` failing with the user pool's
    ///   `InternalErrorException`, then with an error status the SDK does not model (500)
    /// - When: the live engine associates a passkey
    /// - Then:
    ///    - the ceremony ran once, and associate throws `.service` with no code, the retry suggestion and Cognito's
    ///      message or the status in the description, never a bug report
    func testACognitoFailureCompletingAPasskeyAssociationIsAServiceError() async throws {
        guard #available(iOS 17.4, macOS 13.5, visionOS 1.0, *) else {
            throw XCTSkip("Passkeys need iOS 17.4, macOS 13.5 or visionOS 1.0")
        }
        let unmodelled = UnknownAWSHTTPServiceError(
            httpResponse: HTTPResponse(body: .empty, statusCode: .internalServerError),
            message: "fixture message",
            requestID: nil,
            requestID2: nil,
            typeName: nil
        )
        let failures: [(String, Error, String)] = [
            ("internal error", AWSCognitoIdentityProvider.InternalErrorException(message: "boom"), "boom"),
            ("unmodelled 500", unmodelled, "500")
        ]
        for (label, failure, shown) in failures {
            harness = LiveEngineHarness()
            let sheet = FakePasskeySheet()
            let engine = try harness.engine(sheet: sheet)
            let payload = try await harness.signedInPayload(on: engine)
            harness.cognito.once("StartWebAuthnRegistration") { (_: StartWebAuthnRegistrationInput) in
                WebAuthnFixtures.startRegistration()
            }
            harness.cognito.always("CompleteWebAuthnRegistration") {
                (_: CompleteWebAuthnRegistrationInput) -> CompleteWebAuthnRegistrationOutput in
                throw failure
            }
            let window = await WebAuthnFixtures.window()
            let anchor = await MainActor.run { EnginePresentationAnchorBox(window) }
            let context = EngineCeremonyContext(anchor: anchor, ceremony: WebAuthnCredentialOperations.runCeremonyDirectly)

            await assertThrowsAsync({ try await engine.associateWebAuthnCredential(payload, context: context) }) { error in
                Self.assertCodelessService(error, suggesting: AuthClientError.serviceFaultSuggestion, "associate, \(label)")
                XCTAssertTrue(Self.mapped(error)?.errorDescription.contains(shown) == true, "associate, \(label): \(error)")
            }
            XCTAssertEqual(sheet.started, 1, label)
            XCTAssertTrue(harness.cognito.operations.contains("CompleteWebAuthnRegistration"), label)
        }
    }
    #endif

    /// Through the real SDK client: Cognito's answers with a 5xx status and an empty body, or with an error type the
    /// SDK does not model, are the unmodelled-status error the mapping keys on.
    ///
    /// - Given: an engine over the session's real SDK clients, with no retries, whose HTTP engine answers every
    ///   request with a 500 and an empty body, then with a 400 and an error type the SDK does not model
    /// - When:
    ///    - alice signs in with `USER_PASSWORD_AUTH`
    /// - Then:
    ///    - the 500 is `.service` with no code and the retry suggestion, the 400 `.service` with no code, the
    ///      unrecognised-refusal suggestion and the service's message; neither asks for a bug report
    func testCognitosUnmodelledAnswersThroughTheSDKAreMapped() async throws {
        let cases: [(StatusAnswerHTTPClient, String)] = [
            (StatusAnswerHTTPClient(statusCode: 500, body: Data()), AuthClientError.serviceFaultSuggestion),
            (
                StatusAnswerHTTPClient(
                    statusCode: 400,
                    body: Data(#"{"__type":"FixtureUnmodelledException","message":"fixture refusal"}"#.utf8)
                ),
                AuthClientError.unrecognisedServiceErrorSuggestion
            )
        ]
        for (http, expected) in cases {
            let configuration = ClientFixtures.userPoolOnlyConfiguration
            let clients = try CognitoServiceClients(
                configuration: configuration,
                configureUserPoolClient: { config in
                    config.retryStrategyOptions = RetryStrategyOptions(
                        backoffStrategy: config.retryStrategyOptions.backoffStrategy,
                        maxRetriesBase: 0
                    )
                },
                baseHTTPClientEngine: http
            )
            let keychain = TestKeychain()
            let engine = LiveSessionEngine(resources: EngineResources(
                authConfiguration: AuthConfiguration(client: configuration),
                clients: clients,
                devices: DeviceRecordIO(store: keychain.deviceStore(for: SessionStorageNamespace(
                    pools: configuration.poolNamespace,
                    accessGroup: nil
                ))),
                analytics: LazyUserPoolAnalytics(pinpointAppId: nil),
                makeAdvancedSecurity: FixedDeviceASF.factory
            ))

            await assertThrowsAsync({ try await engine.signIn(.flow(.userPassword), current: nil) }) { error in
                Self.assertCodelessService(error, suggesting: expected, "\(http.statusCode)")
                if http.statusCode == 400 {
                    XCTAssertTrue(Self.mapped(error)?.errorDescription.contains("fixture refusal") == true, "\(error)")
                }
            }
        }
    }

    // MARK: Helpers

    /// Scripts a sign-in on alice's remembered device: her device record, `InitiateAuth` answering the password
    /// verifier, its answer `DEVICE_SRP_AUTH`, and that answer `DEVICE_PASSWORD_VERIFIER`. Answer `failingAnswer`
    /// of the device's two (1: `DEVICE_SRP_AUTH`, 2: `DEVICE_PASSWORD_VERIFIER`) fails with the user pool's
    /// `InternalErrorException`.
    private static func scriptDeviceSignIn(on harness: LiveEngineHarness, failingAnswer: Int) throws {
        let device = DeviceMetadata.metadata(.init(deviceKey: "us-east-1_device-alice", deviceGroupKey: "group-alice"))
        try harness.keychain.deviceStore(for: harness.namespace).saveDeviceMetadata(device, for: "alice")
        harness.cognito.once("InitiateAuth") { (_: InitiateAuthInput) in LiveEngineFixtures.passwordVerifier("alice") }
        harness.cognito.once("RespondToAuthChallenge") { (_: RespondToAuthChallengeInput) in
            LiveEngineFixtures.challenge(.deviceSrpAuth, session: "device-srp-session")
        }
        if failingAnswer == 2 {
            let verifier = LiveEngineFixtures.passwordVerifier("alice").challengeParameters ?? [:]
            harness.cognito.once("RespondToAuthChallenge") { (_: RespondToAuthChallengeInput) in
                LiveEngineFixtures.challenge(.devicePasswordVerifier, parameters: verifier, session: "device-verifier-session")
            }
        }
        harness.cognito.once("RespondToAuthChallenge") { (_: RespondToAuthChallengeInput) -> RespondToAuthChallengeOutput in
            throw AWSCognitoIdentityProvider.InternalErrorException(message: "boom")
        }
    }

    /// The client error a live engine call threw: itself, or the one a session operation carries.
    private static func mapped(_ error: Error) -> AuthClientError? {
        if case SessionEngineError.service(let mapped) = error {
            return mapped
        }
        return error as? AuthClientError
    }

    private static func assertCodelessService(
        _ error: Error,
        suggesting expected: String,
        _ label: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let mapped = mapped(error), case .service(nil, _, let suggestion, let underlying) = mapped else {
            return XCTFail("\(label): expected .service with no code, got \(error)", file: file, line: line)
        }
        XCTAssertTrue(underlying is EngineAuthError, "\(label): \(String(describing: underlying))", file: file, line: line)
        XCTAssertEqual(suggestion, expected, label, file: file, line: line)
        XCTAssertFalse(suggestion.contains("bug"), label, file: file, line: line)
        XCTAssertFalse(suggestion.contains("file an issue"), label, file: file, line: line)
    }
}

/// Answers every request with one HTTP status and body, as Cognito's JSON protocol does.
private struct StatusAnswerHTTPClient: HTTPClient {

    /// The status, by value: `HTTPStatusCode` is not `Sendable`.
    let statusCode: Int
    let body: Data

    func send(request: SmithyHTTPAPI.HTTPRequest) async throws -> SmithyHTTPAPI.HTTPResponse {
        HTTPResponse(
            headers: Headers(["Content-Type": "application/x-amz-json-1.1"]),
            body: .data(body),
            statusCode: HTTPStatusCode(rawValue: statusCode) ?? .internalServerError
        )
    }
}
