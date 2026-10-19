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

/// A request that never reaches Cognito (no network, a DNS failure, a refused connection, a timeout) is reported by
/// every operation as `.service` with no code and the client's network texts, as a refresh reports it: never
/// `.unknown` with an empty description and a "this is a bug" suggestion.
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

    /// - Given: each network failure, thrown by `InitiateAuth`, `SignUp` and `ForgotPassword`
    /// - When: a sign-in, a sign-up and a password reset run through a client over the live engine
    /// - Then:
    ///    - each throws `.service` with no code, the network description and suggestion, and the network error
    ///      underneath; none is `.unknown` or asks for a bug report
    func testAnOperationThatCannotReachCognitoIsARetryableServiceError() async throws {
        for (name, failure) in networkErrors {
            harness = LiveEngineHarness()
            harness.cognito.always("InitiateAuth") { (_: InitiateAuthInput) -> InitiateAuthOutput in throw failure }
            harness.cognito.always("SignUp") { (_: SignUpInput) -> SignUpOutput in throw failure }
            harness.cognito.always("ForgotPassword") { (_: ForgotPasswordInput) -> ForgotPasswordOutput in throw failure }
            let clientHarness = ClientHarness()
            let client = try makeClient(over: clientHarness)

            let operations: [(String, () async throws -> Void)] = [
                ("signIn", { _ = try await client.signIn(username: "alice", password: "password") }),
                ("signUp", { _ = try await client.signUp(username: "carol", password: "Password1!") }),
                ("resetPassword", { _ = try await client.resetPassword(for: "carol") })
            ]
            for (operation, body) in operations {
                let label = "\(operation), \(name)"
                do {
                    try await body()
                    XCTFail("\(label): expected an error")
                } catch let error as AuthClientError {
                    assertNetworkFailure(error, label)
                } catch {
                    XCTFail("\(label): expected an AuthClientError, got \(error)")
                }
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
    ///    - the outcome's revoke error is `.service` with no code and the network texts: its description is not empty
    func testARevokeThatCannotReachCognitoHasTheNetworkText() async throws {
        for (name, failure) in networkErrors {
            harness = LiveEngineHarness()
            let engine = try harness.engine()
            let payload = try await harness.signedInPayload(on: engine)
            harness.cognito.always("RevokeToken") { (_: RevokeTokenInput) -> RevokeTokenOutput in throw failure }

            let outcome = try await engine.revoke(payload, global: false)

            let revokeError = try XCTUnwrap(outcome.revokeError, name)
            assertNetworkFailure(revokeError, name, checkingUnderlying: false)
        }
    }

    private func assertNetworkFailure(
        _ error: AuthClientError,
        _ label: String,
        checkingUnderlying: Bool = true,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard case .service(nil, let description, let suggestion, let underlying) = error else {
            return XCTFail("\(label): expected a service error with no code, got \(error)", file: file, line: line)
        }
        XCTAssertEqual(description, AuthClientError.networkFailureDescription, label, file: file, line: line)
        XCTAssertEqual(suggestion, AuthClientError.clientServiceSuggestion, label, file: file, line: line)
        XCTAssertFalse(suggestion.contains("bug"), label, file: file, line: line)
        if checkingUnderlying {
            // The network error itself, or the engine's error over it.
            let network = (underlying as? EngineAuthError)?.underlyingError ?? underlying
            XCTAssertTrue(AuthClientError.isNetworkFailure(network), "\(label): \(String(describing: underlying))", file: file, line: line)
        }
    }
}
