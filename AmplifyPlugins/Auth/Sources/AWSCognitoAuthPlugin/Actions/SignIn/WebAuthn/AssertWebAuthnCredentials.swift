//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(macOS) || os(visionOS)
import Amplify
import Foundation

@available(iOS 17.4, macOS 13.5, visionOS 1.0, *)
struct AssertWebAuthnCredentials: Action {
    let identifier = "AssertWebAuthnCredentials"
    let username: String
    let options: CredentialAssertionOptions
    let respondToAuthChallenge: RespondToAuthChallenge
    let presentationAnchor: AuthUIPresentationAnchor?

    private let credentialAsserter: CredentialAsserterProtocol

    init(
        username: String,
        options: CredentialAssertionOptions,
        respondToAuthChallenge: RespondToAuthChallenge,
        presentationAnchor: AuthUIPresentationAnchor?,
        asserterFactory: (AuthUIPresentationAnchor?) -> CredentialAsserterProtocol = { anchor in
            PlatformWebAuthnCredentials(presentationAnchor: anchor)
        }
    ) {
        self.username = username
        self.options = options
        self.respondToAuthChallenge = respondToAuthChallenge
        self.presentationAnchor = presentationAnchor
        self.credentialAsserter = asserterFactory(presentationAnchor)
    }

    func execute(
        withDispatcher dispatcher: EventDispatcher,
        environment: Environment
    ) async {
        logVerbose("\(#fileID) Starting execution", environment: environment)
        do {
            let payload = try await credentialAsserter.assert(with: options)
            let event = WebAuthnEvent(eventType: .verifyCredentialsAndSignIn(
                try payload.stringify(),
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
                eventType: .error(webAuthnError(from: error), respondToAuthChallenge)
            )
            await dispatcher.send(event)
        }
    }

    private func webAuthnError(from error: Error) -> WebAuthnError {
        if let webAuthnError = error as? WebAuthnError {
            return webAuthnError
        }
        if let authError = error as? AuthErrorConvertible {
            return .service(error: authError.authError)
        }
        return .unknown(
            message: "Unable to assert WebAuthn credentials",
            error: error
        )
    }
}

@available(iOS 17.4, macOS 13.5, visionOS 1.0, *)
extension AssertWebAuthnCredentials: DefaultLogger { }

@available(iOS 17.4, macOS 13.5, visionOS 1.0, *)
extension AssertWebAuthnCredentials: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "respondToAuthChallenge": respondToAuthChallenge.debugDictionary,
            "username": username.masked(),
            "options": options.debugDictionary
        ]
    }
}

@available(iOS 17.4, macOS 13.5, visionOS 1.0, *)
extension AssertWebAuthnCredentials: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
#endif
