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
/// model) stays `.unknown`, as the plugin reports it, with a recovery suggestion that fits it: never the engine's
/// "This should not happen … file an issue" text.
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

    /// - Given: `InitiateAuth`, `ForgotPassword` and `GetTokensFromRefreshToken` failing with the user pool's
    ///   `InternalErrorException`, and `GetId` with the identity pool's
    /// - When: the live engine signs in, resets a password, refreshes a session, fetches guest credentials and
    ///   federates
    /// - Then:
    ///    - each throws `.unknown` with Cognito's message in the description and the retry suggestion; none asks for
    ///      a bug report
    func testACognitoInternalErrorSuggestsARetry() async throws {
        let engine = try harness.engine()
        let payload = try await harness.signedInPayload(on: engine)
        harness.cognito.always("InitiateAuth") { (_: InitiateAuthInput) -> InitiateAuthOutput in
            throw AWSCognitoIdentityProvider.InternalErrorException(message: "boom")
        }
        harness.cognito.always("ForgotPassword") { (_: ForgotPasswordInput) -> ForgotPasswordOutput in
            throw AWSCognitoIdentityProvider.InternalErrorException(message: "boom")
        }
        harness.cognito.always("GetTokensFromRefreshToken") { (_: GetTokensFromRefreshTokenInput) -> GetTokensFromRefreshTokenOutput in
            throw AWSCognitoIdentityProvider.InternalErrorException(message: "boom")
        }
        harness.cognito.always("GetId") { (_: GetIdInput) -> GetIdOutput in
            throw AWSCognitoIdentity.InternalErrorException(message: "boom")
        }

        let operations: [(String, () async throws -> Void)] = [
            ("signIn", { _ = try await engine.signIn(.srp(), current: nil) }),
            ("resetPassword", { _ = try await engine.resetPassword(username: "carol", clientMetadata: [:]) }),
            ("refresh", { _ = try await engine.refresh(payload, force: true) }),
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
                Self.assertUnknown(error, suggesting: AuthClientError.serviceFaultSuggestion, name)
                XCTAssertTrue(Self.mapped(error)?.errorDescription.contains("boom") == true, "\(name): \(error)")
            }
        }
    }

    /// - Given: alice's sign-in stopped on an SMS MFA challenge, and the answer's `RespondToAuthChallenge` failing
    ///   with the user pool's `InternalErrorException`
    /// - When: the code is answered
    /// - Then:
    ///    - it throws `.unknown` with the retry suggestion, never a bug report, as the confirm path maps it
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
            Self.assertUnknown(error, suggesting: AuthClientError.serviceFaultSuggestion, "confirmSignIn")
        }
    }

    /// - Given: `InitiateAuth` and `GetId` failing with an error status the SDK does not model, of 500, 503 and 400
    /// - When: the live engine signs in, and federates
    /// - Then:
    ///    - each throws `.unknown` with the status in the description; the 5xx statuses suggest a retry, the 400
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
                    Self.assertUnknown(error, suggesting: expected, label)
                    XCTAssertTrue(Self.mapped(error)?.errorDescription.contains("\(status.rawValue)") == true, "\(label): \(error)")
                }
            }
        }
    }

    /// Through the real SDK client: Cognito's answers with a 5xx status and an empty body, or with an error type the
    /// SDK does not model, are the unmodelled-status error the mapping keys on.
    ///
    /// - Given: an engine over the session's real SDK clients, with no retries, whose HTTP engine answers every
    ///   request with a 500 and an empty body, then with a 400 and an error type the SDK does not model
    /// - When:
    ///    - alice signs in with `USER_PASSWORD_AUTH`
    /// - Then:
    ///    - the 500 is `.unknown` with the retry suggestion, the 400 `.unknown` with the unrecognised-refusal
    ///      suggestion and the service's message; neither asks for a bug report
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
                Self.assertUnknown(error, suggesting: expected, "\(http.statusCode)")
                if http.statusCode == 400 {
                    XCTAssertTrue(Self.mapped(error)?.errorDescription.contains("fixture refusal") == true, "\(error)")
                }
            }
        }
    }

    // MARK: Helpers

    /// The client error a live engine call threw: itself, or the one a session operation carries.
    private static func mapped(_ error: Error) -> AuthClientError? {
        if case SessionEngineError.service(let mapped) = error {
            return mapped
        }
        return error as? AuthClientError
    }

    private static func assertUnknown(
        _ error: Error,
        suggesting expected: String,
        _ label: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let mapped = mapped(error), case .unknown(_, let suggestion, _) = mapped else {
            return XCTFail("\(label): expected .unknown, got \(error)", file: file, line: line)
        }
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
