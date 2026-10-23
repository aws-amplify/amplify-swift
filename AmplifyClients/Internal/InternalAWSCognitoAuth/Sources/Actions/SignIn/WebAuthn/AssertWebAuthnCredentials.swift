//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(macOS) || os(visionOS)
import Foundation

@available(iOS 17.4, macOS 13.5, visionOS 1.0, *)
package struct AssertWebAuthnCredentials: Action {
    package let identifier = "AssertWebAuthnCredentials"
    package let username: String
    package let options: CredentialAssertionOptions
    package let respondToAuthChallenge: RespondToAuthChallenge
    package let presentationAnchor: EnginePresentationAnchor?

    private let credentialAsserter: CredentialAsserterProtocol
    private let logger: any EngineScopedLogger

    /// - Parameters:
    ///   - logger: the machine's, which the platform asserter and the caller's ceremony log through.
    ///   - asserterFactory: makes the asserter of the plugin's path; `nil` makes `PlatformWebAuthnCredentials`.
    package init(
        username: String,
        options: CredentialAssertionOptions,
        respondToAuthChallenge: RespondToAuthChallenge,
        presentationAnchor: EnginePresentationAnchor?,
        logger: any EngineScopedLogger,
        asserterFactory: ((EnginePresentationAnchor?) -> CredentialAsserterProtocol)? = nil
    ) {
        self.username = username
        self.options = options
        self.respondToAuthChallenge = respondToAuthChallenge
        self.presentationAnchor = presentationAnchor
        self.logger = logger
        self.credentialAsserter = asserterFactory?(presentationAnchor)
            ?? PlatformWebAuthnCredentials(presentationAnchor: presentationAnchor, logger: logger)
    }

    package func execute(
        withDispatcher dispatcher: EventDispatcher,
        environment: Environment
    ) async {
        logVerbose("\(#fileID) Starting execution", environment: environment)
        do {
            let payload: String
            if let ceremony = (environment as? AuthEnvironment)?.webAuthnSignInCeremony.ceremony {
                // The caller runs the ceremony (AmplifyCognitoClient: its window, under its sheet lease).
                payload = try await ceremony.assert(options, logger: logger)
            } else {
                payload = try await credentialAsserter.assert(with: options).stringify()
            }
            let event = WebAuthnEvent(eventType: .verifyCredentialsAndSignIn(
                payload,
                .init(
                    username: username,
                    challenge: respondToAuthChallenge,
                    presentationAnchor: presentationAnchor
                )
            ))
            logVerbose("\(#fileID) Sending event \(event)", environment: environment)
            await dispatcher.send(event)
        } catch {
            logVerbose("\(#fileID) Raised error \(error)", environment: environment)
            let event = WebAuthnEvent(
                eventType: .error(Self.webAuthnError(from: error), respondToAuthChallenge)
            )
            await dispatcher.send(event)
        }
    }

    /// The assertion's failure as the WebAuthn state machine carries it.
    static func webAuthnError(from error: Error) -> WebAuthnError {
        if let webAuthnError = error as? WebAuthnError {
            return webAuthnError
        }
        if let authError = error as? EngineAuthErrorConvertible {
            return .service(error: authError.engineError)
        }
        return .unknown(
            message: "Unable to assert WebAuthn credentials",
            error: error
        )
    }
}

@available(iOS 17.4, macOS 13.5, visionOS 1.0, *)
extension AssertWebAuthnCredentials: CustomDebugDictionaryConvertible {
    package var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "respondToAuthChallenge": respondToAuthChallenge.debugDictionary,
            "username": username.maskedForLog(),
            "options": options.debugDictionary
        ]
    }
}

@available(iOS 17.4, macOS 13.5, visionOS 1.0, *)
extension AssertWebAuthnCredentials: CustomDebugStringConvertible {
    package var debugDescription: String {
        debugDictionary.debugDescription
    }
}
#endif
