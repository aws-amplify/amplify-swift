//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

package struct SignOutLocally: Action {

    package var identifier: String = "SignOutLocally"
    package let hostedUIError: EngineHostedUISignOutFailure?
    package let globalSignOutError: EngineGlobalSignOutFailure?
    package let revokeTokenError: EngineRevokeTokenFailure?

    package func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) async {
        logVerbose("\(#fileID) Starting execution", environment: environment)

        let credentialStoreClient = (environment as? AuthEnvironment)?.credentialsClient

        let event: StateMachineEvent
        do {
            try await credentialStoreClient?.deleteData(type: .amplifyCredentials)
            event = SignOutEvent(eventType: .signedOutSuccess(
                hostedUIError: hostedUIError,
                globalSignOutError: globalSignOutError,
                revokeTokenError: revokeTokenError
            ))

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
    package var debugDictionary: [String: Any] {
        [
            "identifier": identifier
        ]
    }
}

extension SignOutLocally: CustomDebugStringConvertible {
    package var debugDescription: String {
        debugDictionary.debugDescription
    }
}
