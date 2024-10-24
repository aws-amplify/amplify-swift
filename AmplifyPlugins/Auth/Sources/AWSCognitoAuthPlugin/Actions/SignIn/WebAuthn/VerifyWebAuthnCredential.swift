//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

struct VerifyWebAuthnCredential: Action {
    let identifier = "VerifyWebAuthnCredential"

    //    let username: String
    //    let respondToAuthChallenge: RespondToAuthChallenge
    //
    //    init(username: String, respondToAuthChallenge: RespondToAuthChallenge) {
    //        self.username = username
    //        self.respondToAuthChallenge = respondToAuthChallenge
    //    }

    func execute(withDispatcher dispatcher: EventDispatcher,
                 environment: Environment) async {
        logVerbose("\(#fileID) Starting execution", environment: environment)
        do {
            let userPoolEnv = try environment.userPoolEnvironment()
            let authEnv = try environment.authEnvironment()
            //            let asfDeviceId = try await CognitoUserPoolASF.asfDeviceID(
            //                for: username,
            //                credentialStoreClient: authEnv.credentialsClient)

            fatalError("Implement verifying")
            let webAuthnEvent: WebAuthnEvent = .init(eventType: .signedIn)
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

extension VerifyWebAuthnCredential: DefaultLogger { }

extension VerifyWebAuthnCredential: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            //            "respondToAuthChallenge": respondToAuthChallenge.debugDictionary,
            //            "username": username.masked()
        ]
    }
}

extension VerifyWebAuthnCredential: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
