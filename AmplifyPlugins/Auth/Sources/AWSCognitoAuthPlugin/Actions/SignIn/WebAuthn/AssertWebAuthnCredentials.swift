//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(macOS)
import Amplify
import Foundation

@available(iOS 17.4, macOS 13.5, *)
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
            PlatformCredentialAsserter(presentationAnchor: anchor)
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
        } catch let error as WebAuthnError {
            logVerbose("\(#fileID) Raised error \(error)", environment: environment)
            let event = WebAuthnEvent(
                eventType: .error(error, respondToAuthChallenge)
            )
            await dispatcher.send(event)
        } catch {
            logVerbose("\(#fileID) Raised error \(error)", environment: environment)
            let webAuthnError = WebAuthnError.service(error: error)
            let event = WebAuthnEvent(
                eventType: .error(webAuthnError, respondToAuthChallenge)
            )
            await dispatcher.send(event)
        }
    }
}

@available(iOS 17.4, macOS 13.5, *)
extension AssertWebAuthnCredentials: DefaultLogger { }

@available(iOS 17.4, macOS 13.5, *)
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

@available(iOS 17.4, macOS 13.5, *)
extension AssertWebAuthnCredentials: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
#endif
