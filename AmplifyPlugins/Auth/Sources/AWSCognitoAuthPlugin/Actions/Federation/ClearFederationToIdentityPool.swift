//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct ClearFederationToIdentityPool: Action {

    var identifier: String = "ClearFederationToIdentityPool"

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) async {
        logVerbose("\(#fileID) Starting execution", environment: environment)

        let credentialStoreClient = (environment as? AuthEnvironment)?.credentialsClient

        let event: StateMachineEvent
        do {
            try await credentialStoreClient?.deleteData(type: .amplifyCredentials)
            event = AuthenticationEvent.init(eventType: .clearedFederationToIdentityPool)

        } catch {
            let error = AuthenticationError.unknown(message: "Unable to clear credential store: \(error)")
            event = AuthenticationEvent.init(eventType: .error(error))
            logError("\(#fileID) Sending event \(event.type) with error \(error)", environment: environment)
        }
        logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
        await dispatcher.send(event)
    }
}

extension ClearFederationToIdentityPool: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier
        ]
    }
}

extension ClearFederationToIdentityPool: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
