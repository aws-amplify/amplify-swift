//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import AWSCognitoIdentityProvider

struct FetchCredentialOptions: Action {
    let identifier = "FetchCredentialOptions"

//    let username: String
//    let respondToAuthChallenge: RespondToAuthChallenge?

//    init(username: String,
//         respondToAuthChallenge: RespondToAuthChallenge?) {
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


            fatalError("Implement me")
            let webAuthnEvent: WebAuthnEvent = .init(eventType: .assertCredentials)
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

extension FetchCredentialOptions: DefaultLogger { }

extension FetchCredentialOptions: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
//            "username": username.masked()
        ]
    }
}

extension FetchCredentialOptions: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
