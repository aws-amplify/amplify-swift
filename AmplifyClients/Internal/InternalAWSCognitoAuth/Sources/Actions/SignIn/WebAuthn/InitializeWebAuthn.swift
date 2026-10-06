//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(macOS) || os(visionOS)
import Foundation

package struct InitializeWebAuthn: Action {
    package let identifier = "InitializeWebAuthn"
    package let username: String
    package let respondToAuthChallenge: RespondToAuthChallenge
    package let presentationAnchor: EnginePresentationAnchor?

    package func execute(
        withDispatcher dispatcher: EventDispatcher,
        environment: Environment
    ) async {
        logVerbose("\(#fileID) Starting execution", environment: environment)
        do {
            guard let credentialOptions = respondToAuthChallenge.parameters?["CREDENTIAL_REQUEST_OPTIONS"] else {
                let event = WebAuthnEvent(
                    eventType: .fetchCredentialOptions(.init(
                        username: username,
                        challenge: respondToAuthChallenge,
                        presentationAnchor: presentationAnchor
                    ))
                )
                logVerbose("\(#fileID) Sending event \(event)", environment: environment)
                await dispatcher.send(event)
                return
            }
            let options = try CredentialAssertionOptions(from: credentialOptions)
            let event = WebAuthnEvent(
                eventType: .assertCredentials(options, .init(
                    username: username,
                    challenge: respondToAuthChallenge,
                    presentationAnchor: presentationAnchor
                ))
            )
            logVerbose("\(#fileID) Sending event \(event)", environment: environment)
            await dispatcher.send(event)
        } catch let error as SignInError {
            logVerbose("\(#fileID) Raised error \(error)", environment: environment)
            let webAuthnError = WebAuthnError.service(error: error)
            let event = WebAuthnEvent(
                eventType: .error(webAuthnError, respondToAuthChallenge)
            )
            await dispatcher.send(event)
        } catch {
            logVerbose("\(#fileID) Caught error \(error)", environment: environment)
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
        if let authError = error as? EngineAuthErrorConvertible {
            return .service(error: authError.engineError)
        }
        return .unknown(
            message: "Unable to initiate WebAuthn flow",
            error: error
        )
    }
}

extension InitializeWebAuthn: CustomDebugDictionaryConvertible {
    package var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "username": username.maskedForLog(),
            "respondToAuthChallenge": respondToAuthChallenge.debugDictionary
        ]
    }
}

extension InitializeWebAuthn: CustomDebugStringConvertible {
    package var debugDescription: String {
        debugDictionary.debugDescription
    }
}
#endif
