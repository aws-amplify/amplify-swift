//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct SignOutLocally: Action {

    var identifier: String = "SignOutLocally"
    let hostedUIError: AWSCognitoHostedUIError?
    let globalSignOutError: AWSCognitoGlobalSignOutError?
    let revokeTokenError: AWSCognitoRevokeTokenError?

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) async {
        logVerbose("\(#fileID) Starting execution", environment: environment)

        let credentialStoreClient = (environment as? AuthEnvironment)?.credentialStoreClientFactory()

        let event: StateMachineEvent
        do {
            try await credentialStoreClient?.deleteData(type: .amplifyCredentials)
            event = SignOutEvent(eventType: .signedOutSuccess(
                hostedUIError: hostedUIError,
                globalSignOutError: globalSignOutError,
                revokeTokenError: revokeTokenError))

        } catch {
            let signOutError = AuthenticationError.unknown(
                message: "Unable to clear credential store: \(error)")
            event = SignOutEvent(eventType: .signedOutFailure(signOutError))
            logError("\(#fileID) Sending event \(event.type) with error \(error)", environment: environment)
        }
        logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
        await dispatcher.send(event)
    }
}

extension SignOutLocally: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier
        ]
    }
}

extension SignOutLocally: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
