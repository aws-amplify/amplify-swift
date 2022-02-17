//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct InitializeAuthConfiguration: Action {

    let identifier = "InitializeAuthConfiguration"

    let authConfiguration: AuthConfiguration
    let storedCredentials: CognitoCredentials?

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) {

        logVerbose("Starting execution", environment: environment)

        var event: StateMachineEvent
        switch authConfiguration {
        case .identityPools:
            event = AuthEvent(eventType: .configureAuthorization(authConfiguration))
        default:
            event = AuthEvent(eventType: .configureAuthentication(authConfiguration, storedCredentials))
        }
        logVerbose("Sending event \(event.type)", environment: environment)
        dispatcher.send(event)
    }
}

extension InitializeAuthConfiguration: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "configuration": authConfiguration
        ]
    }
}

extension InitializeAuthConfiguration: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
