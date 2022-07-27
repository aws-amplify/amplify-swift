//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct SignOutLocally: Action {

    var identifier: String = "SignOutLocally"

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) {
        logVerbose("\(#fileID) Starting execution", environment: environment)

        let credentialStoreClient = (environment as? AuthEnvironment)?.credentialStoreClientFactory()

        Task {
            let event: StateMachineEvent
            do {
                try await credentialStoreClient?.deleteData(type: .amplifyCredentials)
                event = SignOutEvent(eventType: .signedOutSuccess)

            } catch {
                let signOutError = AuthenticationError.unknown(message: "Unable to clear credential store: \(error)")
                event = SignOutEvent(eventType: .signedOutFailure(signOutError))
                logError("\(#fileID) Sending event \(event.type) with error \(error)", environment: environment)
            }
            logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
            dispatcher.send(event)

        }
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
