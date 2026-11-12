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

/// A network failure (no network, a DNS failure, a refused connection, a timeout), whose request may or may not have
/// reached Cognito, is reported by every operation as `.service` with no code and the client's network texts, as a
/// refresh reports it: never `.unknown` with an empty description and a "this is a bug" suggestion.
final class LiveEngineNetworkFailureTests: XCTestCase {

    private var harness: LiveEngineHarness!

    /// The failures the SDK's URL loading reports for an unreachable endpoint, and a POSIX one.
    private let networkErrors: [(String, Error)] = [
        ("DNS failure", URLError(.cannotFindHost)),
        ("refused connection", URLError(.cannotConnectToHost)),
        ("timeout", URLError(.timedOut)),
        ("offline", URLError(.notConnectedToInternet)),
        ("POSIX refused", NSError(domain: NSPOSIXErrorDomain, code: Int(ECONNREFUSED)))
    ]

    override func setUp() {
        super.setUp()
        harness = LiveEngineHarness()
    }

    override func tearDown() {
        harness = nil
        super.tearDown()
    }

    /// - Given: each network failure, thrown by `InitiateAuth`, `SignUp`, `ForgotPassword` and `GetId`
    /// - When: a sign-in, a sign-up, a password reset and a federation run through a client over the live engine
    /// - Then:
    ///    - each throws `.service` with no code, the network description and suggestion, and the network error
    ///      itself underneath, never the engine's error over it; none is `.unknown` or asks for a bug report
    func testAnOperationThatCannotReachCognitoIsARetryableServiceError() async throws {
        for (name, failure) in networkErrors {
            harness = LiveEngineHarness()
            harness.cognito.always("InitiateAuth") { (_: InitiateAuthInput) -> InitiateAuthOutput in throw failure }
            harness.cognito.always("SignUp") { (_: SignUpInput) -> SignUpOutput in throw failure }
            harness.cognito.always("ForgotPassword") { (_: ForgotPasswordInput) -> ForgotPasswordOutput in throw failure }
            harness.cognito.always("GetId") { (_: GetIdInput) -> GetIdOutput in throw failure }
            let clientHarness = ClientHarness()
            let client = try makeClient(over: clientHarness)

            let operations: [(String, () async throws -> Void)] = [
                ("signIn", { _ = try await client.signIn(username: "alice", password: "password") }),
                ("signUp", { _ = try await client.signUp(username: "carol", password: "Password1!") }),
                ("resetPassword", { _ = try await client.resetPassword(for: "carol") }),
                ("federateToIdentityPool", { _ = try await client.federateToIdentityPool(withProviderToken: "token", for: .facebook) })
            ]
            for (operation, body) in operations {
                let label = "\(operation), \(name)"
                do {
                    try await body()
                    XCTFail("\(label): expected an error")
                } catch let error as AuthClientError {
                    assertNetworkFailure(error, failure, label)
                } catch {
                    XCTFail("\(label): expected an AuthClientError, got \(error)")
                }
            }
            let state = await client.currentSessionState()
            XCTAssertEqual(state, .signedOut, name)
        }
    }

    /// A sign-in that reaches something but can't read its answer, or that App Transport Security refuses, is a
    /// readable service error, as a refresh reports it: never `.unknown` with an empty description.
    ///
    /// - Given: `InitiateAuth` failing in turn with URL loading's `badServerResponse` (-1011), `cannotParseResponse`
    ///   (-1017) and `appTransportSecurityRequiresSecureConnection` (-1022), and with a body that is not JSON
    /// - When: a client over the live engine signs in
    /// - Then:
    ///    - each throws `.service` with no code and a description that isn't empty and isn't the network one: the
    ///      unreadable responses "The service returned a response that could not be read." with the retry
    ///      suggestion, the refusal "The service request failed." with the network-or-service suggestion; no
    ///      suggestion asks for a bug report, and the session stays signed out
    func testASignInThatReachesSomethingUnreadableIsAReadableServiceError() async throws {
        let unreadable = (AuthClientError.unreadableResponseDescription, AuthClientError.unreadableServiceResponseSuggestion)
        let failed = (AuthClientError.emptyServiceFailureDescription, AuthClientError.clientServiceSuggestion)
        let cases: [(String, Error, (String, String))] = [
            ("-1011", URLError(.badServerResponse), unreadable),
            ("-1017", URLError(.cannotParseResponse), unreadable),
            ("-1022", URLError(.appTransportSecurityRequiresSecureConnection), failed),
            ("not JSON", NSError(domain: NSCocoaErrorDomain, code: NSPropertyListReadCorruptError), unreadable)
        ]
        for (name, failure, expected) in cases {
            harness = LiveEngineHarness()
            harness.cognito.always("InitiateAuth") { (_: InitiateAuthInput) -> InitiateAuthOutput in throw failure }
            let client = try makeClient(over: ClientHarness())

            do {
                _ = try await client.signIn(username: "alice", password: "password")
                XCTFail("\(name): expected an error")
            } catch AuthClientError.service(nil, let description, let suggestion, _) {
                XCTAssertEqual(description, expected.0, name)
                XCTAssertEqual(suggestion, expected.1, name)
                XCTAssertFalse(suggestion.contains("bug"), name)
            } catch {
                XCTFail("\(name): expected a service error with no code, got \(error)")
            }
            let state = await client.currentSessionState()
            XCTAssertEqual(state, .signedOut, name)
        }
    }

    /// A client of `work` over this test's live engine.
    private func makeClient(over clientHarness: ClientHarness) throws -> AmplifyCognitoClient {
        let base = clientHarness.dependencies
        let harness = harness!
        let dependencies = SessionCoreDependencies(
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
        return try AmplifyCognitoClient(
            configuration: ClientFixtures.configuration,
            options: .init(sessionId: ClientFixtures.id("work")),
            dependencies: dependencies
        )
    }

    /// - Given: alice signed in, and `RevokeToken` failing with each network failure
    /// - When: the session is revoked, as a sign-out does
    /// - Then:
    ///    - the outcome's revoke error is `.service` with no code, a description that says the token may not have
    ///      been revoked because of a network problem, and stays valid unless the request reached the service or a
    ///      global sign-out succeeded, and a suggestion that keeps the sign-out's context: the revoke is not retried
    func testARevokeThatCannotReachCognitoHasTheNetworkText() async throws {
        for (name, failure) in networkErrors {
            harness = LiveEngineHarness()
            let engine = try harness.engine()
            let payload = try await harness.signedInPayload(on: engine)
            harness.cognito.always("RevokeToken") { (_: RevokeTokenInput) -> RevokeTokenOutput in throw failure }

            let outcome = try await engine.revoke(payload, global: false)

            let revokeError = try XCTUnwrap(outcome.revokeError, name)
            assertIsTheNetworkError(revokeError.underlyingError, failure, name)
            guard case .service(nil, let description, let suggestion, _) = revokeError else {
                XCTFail("\(name): expected a service error with no code, got \(revokeError)")
                continue
            }
            XCTAssertEqual(description, SignOutTexts.revokeNetworkFailure, name)
            XCTAssertEqual(suggestion, SignOutTexts.revokeNotRetried, name)
        }
    }

    /// - Given: alice signed in, and `GlobalSignOut` failing with each network failure
    /// - When: the session is signed out globally, as a sign-out does
    /// - Then:
    ///    - the outcome's global sign-out error is `.service` with no code, the network description, and a suggestion
    ///      that keeps the sign-out's context: the global sign-out is not retried, and the user's other sessions stay
    ///      signed in unless the request reached the service
    func testAGlobalSignOutThatCannotReachCognitoSaysItIsNotRetried() async throws {
        for (name, failure) in networkErrors {
            harness = LiveEngineHarness()
            let engine = try harness.engine()
            let payload = try await harness.signedInPayload(on: engine)
            harness.cognito.always("GlobalSignOut") { (_: GlobalSignOutInput) -> GlobalSignOutOutput in throw failure }

            let outcome = try await engine.revoke(payload, global: true)

            let globalError = try XCTUnwrap(outcome.globalSignOutError, name)
            assertIsTheNetworkError(globalError.underlyingError, failure, name)
            guard case .service(nil, let description, let suggestion, _) = globalError else {
                XCTFail("\(name): expected a service error with no code, got \(globalError)")
                continue
            }
            XCTAssertEqual(description, "A network problem stopped the request. It may not have reached the service.", name)
            XCTAssertEqual(suggestion, SignOutTexts.globalSignOutNotRetried, name)
        }
    }

    /// The passkey credential calls report a network failure as every other call does, not through the engine's
    /// "This should not happen" fallback.
    ///
    /// - Given: alice signed in, and `ListWebAuthnCredentials` and `DeleteWebAuthnCredential` failing with each
    ///   network failure
    /// - When: the live engine lists and deletes her passkeys
    /// - Then:
    ///    - each throws `.service` with no code, the network description and suggestion, and the network error itself
    ///      underneath
    func testAPasskeyCallThatCannotReachCognitoIsARetryableServiceError() async throws {
        for (name, failure) in networkErrors {
            harness = LiveEngineHarness()
            let engine = try harness.engine()
            let payload = try await harness.signedInPayload(on: engine)
            harness.cognito.always("ListWebAuthnCredentials") { (_: ListWebAuthnCredentialsInput) -> ListWebAuthnCredentialsOutput in
                throw failure
            }
            harness.cognito.always("DeleteWebAuthnCredential") { (_: DeleteWebAuthnCredentialInput) -> DeleteWebAuthnCredentialOutput in
                throw failure
            }

            let operations: [(String, () async throws -> Void)] = [
                ("listWebAuthnCredentials", { _ = try await engine.listWebAuthnCredentials(payload, pageSize: 10, nextToken: nil) }),
                ("deleteWebAuthnCredential", { try await engine.deleteWebAuthnCredential(payload, credentialId: "credential") })
            ]
            for (operation, body) in operations {
                let label = "\(operation), \(name)"
                await assertThrowsAsync(body) { error in
                    guard let error = error as? AuthClientError else {
                        return XCTFail("\(label): expected an AuthClientError, got \(error)")
                    }
                    self.assertNetworkFailure(error, failure, label)
                }
            }
        }
    }

    /// A response that is not JSON (an HTML error page from the service's edge) reads the same on a refresh and on a
    /// sign-out's revoke as on a sign-in.
    ///
    /// - Given: alice signed in, and `GetTokensFromRefreshToken` and `RevokeToken` failing with Foundation's error for
    ///   a body that is not JSON
    /// - When: her session is refreshed, then revoked as a sign-out does
    /// - Then:
    ///    - the refresh throws `.service` with no code, "The service returned a response that could not be read." and
    ///      the retry suggestion
    ///    - the revoke error is `.service` with no code, the same description, and the suggestion that the revoke is
    ///      not retried
    func testAResponseThatIsNotJSONIsUnreadableOnARefreshAndARevoke() async throws {
        let notJSON = NSError(domain: NSCocoaErrorDomain, code: NSPropertyListReadCorruptError)
        let engine = try harness.engine()
        let payload = try await harness.signedInPayload(on: engine)
        harness.cognito.always("GetTokensFromRefreshToken") { (_: GetTokensFromRefreshTokenInput) -> GetTokensFromRefreshTokenOutput in
            throw notJSON
        }
        harness.cognito.always("RevokeToken") { (_: RevokeTokenInput) -> RevokeTokenOutput in throw notJSON }

        await assertThrowsAsync({ _ = try await engine.refresh(payload, force: true) }) { error in
            let mapped: AuthClientError? = if case SessionEngineError.service(let mapped) = error { mapped } else { error as? AuthClientError }
            guard case .service(nil, let description, let suggestion, _) = mapped else {
                return XCTFail("expected a service error with no code, got \(error)")
            }
            XCTAssertEqual(description, AuthClientError.unreadableResponseDescription)
            XCTAssertEqual(suggestion, AuthClientError.unreadableServiceResponseSuggestion)
        }

        let outcome = try await engine.revoke(payload, global: false)

        guard case .service(nil, let description, let suggestion, _) = outcome.revokeError else {
            return XCTFail("expected a service error with no code, got \(String(describing: outcome.revokeError))")
        }
        XCTAssertEqual(description, AuthClientError.unreadableResponseDescription)
        XCTAssertEqual(suggestion, SignOutTexts.revokeNotRetried)
    }

    private func assertNetworkFailure(
        _ error: AuthClientError,
        _ failure: Error,
        _ label: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard case .service(nil, let description, let suggestion, let underlying) = error else {
            return XCTFail("\(label): expected a service error with no code, got \(error)", file: file, line: line)
        }
        XCTAssertEqual(description, "A network problem stopped the request. It may not have reached the service.", label, file: file, line: line)
        XCTAssertEqual(suggestion, AuthClientError.clientServiceSuggestion, label, file: file, line: line)
        XCTAssertFalse(suggestion.contains("bug"), label, file: file, line: line)
        assertIsTheNetworkError(underlying, failure, label, file: file, line: line)
    }

    /// Asserts `underlying` is the network error `failure` itself, as an app matches it
    /// (`AuthClientError.service(nil, _, _, let error as URLError)`), never the engine's error over it.
    private func assertIsTheNetworkError(
        _ underlying: Error?,
        _ failure: Error,
        _ label: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertFalse(underlying is EngineAuthError, "\(label): \(String(describing: underlying))", file: file, line: line)
        let error = underlying as NSError?
        XCTAssertEqual(error?.domain, (failure as NSError).domain, label, file: file, line: line)
        XCTAssertEqual(error?.code, (failure as NSError).code, label, file: file, line: line)
        if let expected = failure as? URLError {
            XCTAssertEqual((underlying as? URLError)?.code, expected.code, label, file: file, line: line)
        }
    }
}

/// The sign-out's network texts, spelled out, so a test fails when one changes.
enum SignOutTexts {
    static let revokeNetworkFailure = "The refresh token may not have been revoked: a network problem stopped the request, "
        + "which may not have reached the service. Unless it did, or a global sign-out succeeded, the refresh token stays "
        + "valid until it expires."
    static let revokeNotRetried = "The session was signed out on this device, and the revoke will not be retried. To end "
        + "the refresh token on the server, sign in again and sign out with globalSignOut: true."
    static let globalSignOutNotRetried = "The session was signed out on this device, and the global sign-out will not be "
        + "retried: unless the request reached the service, the user's other sessions stay signed in until their tokens "
        + "expire. To sign them out, sign in again and sign out with globalSignOut: true."
}
