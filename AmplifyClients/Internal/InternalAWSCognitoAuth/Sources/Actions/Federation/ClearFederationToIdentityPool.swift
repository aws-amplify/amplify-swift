//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

package struct ClearFederationToIdentityPool: Action {

    package var identifier: String = "ClearFederationToIdentityPool"

    package func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) async {
        logVerbose("\(#fileID) Starting execution", environment: environment)

        let credentialStoreClient = (environment as? AuthEnvironment)?.credentialsClient

        let event: StateMachineEvent
        do {
            // Check if we have credentials are of type federation, otherwise throw an error
            if case .amplifyCredentials(let credentials) = try await credentialStoreClient?.fetchData(
                type: .amplifyCredentials),
               case .identityPoolWithFederation = credentials {

                try await credentialStoreClient?.deleteData(type: .amplifyCredentials)
                event = AuthenticationEvent.init(eventType: .clearedFederationToIdentityPool)
            } else {
                let error = AuthenticationError.service(message: "Unable to find credentials to clear for federation.", error: nil)
                event = AuthenticationEvent.init(eventType: .error(error))
                logError("\(#fileID) Sending event \(event.type) with error \(error)", environment: environment)
            }

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
    package var debugDictionary: [String: Any] {
        [
            "identifier": identifier
        ]
    }
}

extension ClearFederationToIdentityPool: CustomDebugStringConvertible {
    package var debugDescription: String {
        debugDictionary.debugDescription
    }
}
