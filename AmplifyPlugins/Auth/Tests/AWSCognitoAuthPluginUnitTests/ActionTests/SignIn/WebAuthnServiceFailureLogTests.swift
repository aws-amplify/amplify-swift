//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(macOS) || os(visionOS)
import Amplify
import AWSCognitoIdentityProvider
import XCTest
@testable import AWSCognitoAuthPlugin
@testable import InternalAWSCognitoAuth

/// A passkey sign-in step whose `RespondToAuthChallenge` fails keeps the SDK's exception for the client's mapping
/// (`WebAuthnError.ServiceFailure`), but the plugin's verbose "Auth state change" line prints the state as it did when
/// the step kept only the engine error, and its `AuthError` is unchanged.
@available(iOS 17.4, macOS 13.5, visionOS 1.0, *)
final class WebAuthnServiceFailureLogTests: XCTestCase {

    private let challenge = RespondToAuthChallenge(
        challenge: .webAuthn,
        availableChallenges: [],
        username: "alice",
        session: "session",
        parameters: [:]
    )

    private let exception = NotAuthorizedException(message: "Incorrect")

    /// The state line's body as the plugin printed it before the steps kept the exception, when the step's error was the
    /// exception's engine error (captured with those steps' earlier code).
    private static let printedState = #"""
    {
        "AuthState.configured" =     {
            "AuthenticationState.signingIn" =         {
                "SignInState.signingInWithWebAuthn" =             {
                    signingInWithWebAuthn =                 {
                        "WebAuthnSignInState.error" =                     {
                            Error = "InternalAWSCognitoAuth.SignInError.webAuthn(InternalAWSCognitoAuth.WebAuthnError.service(\#
    error: AuthError: Incorrect\nRecovery suggestion: Check whether the given values are correct and the user is \#
    authorized to perform the operation))";
                        };
                    };
                };
            };
            "AuthorizationState.configured" =         {
            };
            "SignUpState.notStarted" =         {
            };
        };
    }
    """#

    /// - Given: `RespondToAuthChallenge` failing with `NotAuthorizedException("Incorrect")`
    /// - When: `FetchCredentialOptions` runs, and its error is put in the state the plugin logs
    /// - Then:
    ///    - the state prints as the pinned text, and exactly as it does with only the engine error in the step
    ///    - the plugin's `AuthError` is the same as that engine error's
    ///    - the error carries the exception as its cause
    func testAFailedCredentialOptionsRequestPrintsTheStateAsBefore() async throws {
        let action = FetchCredentialOptions(username: "alice", respondToAuthChallenge: challenge, presentationAnchor: nil)

        let error = try await failure(of: action)

        try assertUnchanged(error)
    }

    /// - Given: `RespondToAuthChallenge` failing with `NotAuthorizedException("Incorrect")`
    /// - When: `VerifyWebAuthnCredential` runs, and its error is put in the state the plugin logs
    /// - Then:
    ///    - the state prints as the pinned text, and exactly as it does with only the engine error in the step
    ///    - the plugin's `AuthError` is the same as that engine error's
    ///    - the error carries the exception as its cause
    func testAFailedVerificationPrintsTheStateAsBefore() async throws {
        let action = VerifyWebAuthnCredential(username: "alice", credentials: "{}", respondToAuthChallenge: challenge)

        let error = try await failure(of: action)

        try assertUnchanged(error)
    }

    /// - Given: a `ServiceFailure` made from `NotAuthorizedException("Incorrect")`
    /// - When: it is printed every way, and reflected
    /// - Then:
    ///    - each form is its engine error's: `description`, `debugDescription`, interpolation, `dump`, and the mirror's
    ///      children
    func testAServiceFailurePrintsAsItsEngineError() {
        let failure = WebAuthnError.ServiceFailure(exception)
        let engineError = exception.engineError

        XCTAssertEqual(String(describing: failure), String(describing: engineError))
        XCTAssertEqual(String(reflecting: failure), String(reflecting: engineError))
        XCTAssertEqual("\(failure)", "\(engineError)")
        var dumpedFailure = ""
        dump(failure, to: &dumpedFailure)
        var dumpedEngineError = ""
        dump(engineError, to: &dumpedEngineError)
        XCTAssertEqual(dumpedFailure, dumpedEngineError)
        XCTAssertEqual(
            Mirror(reflecting: failure).children.map { "\($0.label ?? "") \($0.value)" },
            Mirror(reflecting: engineError).children.map { "\($0.label ?? "") \($0.value)" }
        )
        XCTAssertTrue(failure.cause is NotAuthorizedException)
    }

    // MARK: Support

    private func failure(of action: Action) async throws -> WebAuthnError {
        let identityProvider = MockIdentityProvider(mockRespondToAuthChallengeResponse: { [exception] _ in
            throw exception
        })
        let environment = Defaults.makeDefaultAuthEnvironment(userPoolFactory: { identityProvider })
        let events = TestBox<[WebAuthnEvent]>([])
        await action.execute(
            withDispatcher: MockDispatcher { event in
                if let event = event as? WebAuthnEvent {
                    events.with { $0.append(event) }
                }
            },
            environment: environment
        )
        guard case .error(let error, _)? = events.get().first?.eventType else {
            XCTFail("expected an .error event, got \(events.get())")
            throw NoErrorEvent()
        }
        return error
    }

    /// The state the plugin logs for `error`, printed as its "Auth state change" line prints it.
    private func printed(_ error: WebAuthnError) -> String {
        let state = AuthState.configured(
            .signingIn(.signingInWithWebAuthn(.error(.webAuthn(error), challenge))),
            .configured,
            .notStarted
        )
        return "\(state)"
    }

    private func assertUnchanged(_ error: WebAuthnError, file: StaticString = #filePath, line: UInt = #line) throws {
        let before = WebAuthnError.service(error: exception.engineError)
        XCTAssertEqual(printed(error), Self.printedState, file: file, line: line)
        XCTAssertEqual(printed(error), printed(before), file: file, line: line)
        let authError = SignInError.webAuthn(error).authError
        let authErrorBefore = SignInError.webAuthn(before).authError
        XCTAssertEqual(String(reflecting: authError), String(reflecting: authErrorBefore), file: file, line: line)
        if case .notAuthorized = authError {} else {
            XCTFail("expected notAuthorized, got \(authError)", file: file, line: line)
        }
        guard case .service(let failure as WebAuthnError.ServiceFailure) = error else {
            return XCTFail("expected a ServiceFailure, got \(error)", file: file, line: line)
        }
        XCTAssertTrue(failure.cause is NotAuthorizedException, "\(failure.cause)", file: file, line: line)
    }
}

private struct NoErrorEvent: Error {}
#endif
