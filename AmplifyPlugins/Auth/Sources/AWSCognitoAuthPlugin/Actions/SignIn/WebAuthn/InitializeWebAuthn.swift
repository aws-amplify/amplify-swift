//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

struct InitializeWebAuthn: Action {
    let identifier = "InitializeWebAuthn"

    let username: String
    let respondToAuthChallenge: RespondToAuthChallenge

    init(username: String, respondToAuthChallenge: RespondToAuthChallenge) {
        self.username = username
        self.respondToAuthChallenge = respondToAuthChallenge
    }

    func execute(withDispatcher dispatcher: EventDispatcher,
                 environment: Environment) async {
        logVerbose("\(#fileID) Starting execution", environment: environment)
        do {
            let userPoolEnv = try environment.userPoolEnvironment()
            let authEnv = try environment.authEnvironment()
            let asfDeviceId = try await CognitoUserPoolASF.asfDeviceID(
                for: username,
                credentialStoreClient: authEnv.credentialsClient)

            let webAuthnEvent: WebAuthnEvent
            // credentials options is a json
            // Sample:  "{\"challenge\":\"vde3h8WwZJjW1xZph3t8qQ\",\"timeout\":180000,\"rpId\":\"webauthn-test.hsinghvq.people.aws.dev\",\"allowCredentials\":[{\"type\":\"public-key\",\"id\":\"hP0cxpqhgN1K0R4pICOOOA\",\"transports\":[\"internal\",\"hybrid\"]}],\"userVerification\":\"required\"}"
            if let credentialOptions = respondToAuthChallenge.parameters?["CREDENTIAL_REQUEST_OPTIONS"] {
                fatalError("throw assert credential event with \(credentialOptions)")
                webAuthnEvent = .init(eventType: .assertCredentials)
            } else {
                fatalError("throw fetch credential options event")
                webAuthnEvent = .init(eventType: .fetchCredentialOptions)
            }
            logVerbose("\(#fileID) Sending event \(webAuthnEvent)", environment: environment)
            await dispatcher.send(webAuthnEvent)
        } catch let error as SignInError {
            logVerbose("\(#fileID) Raised error \(error)", environment: environment)
            let event = SignInEvent(eventType: .throwAuthError(error))
            await dispatcher.send(event)
        } catch {
            logVerbose("\(#fileID) Caught error \(error)", environment: environment)
            let authError = SignInError.service(error: error)
            let event = SignInEvent(
                eventType: .throwAuthError(authError)
            )
            await dispatcher.send(event)
        }

    }

}

extension InitializeWebAuthn: DefaultLogger { }

extension InitializeWebAuthn: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "respondToAuthChallenge": respondToAuthChallenge.debugDictionary,
            "username": username.masked()
        ]
    }
}

extension InitializeWebAuthn: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
