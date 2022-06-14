//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct ValidateCredentialsAndConfiguration: Action {

    let identifier = "ValidateCredentialsAndConfiguration"

    let authConfiguration: AuthConfiguration

    let cachedCredentials: AmplifyCredentials

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) {

        logVerbose("\(#fileID) Starting execution", environment: environment)
        var event: StateMachineEvent
        switch authConfiguration {
        case .identityPools:
            event = AuthEvent(eventType: .configureAuthorization(authConfiguration,
                                                                 cachedCredentials))
        default:
            event = AuthEvent(eventType: .configureAuthentication(authConfiguration,
                                                                  cachedCredentials))
        }
        logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
        dispatcher.send(event)
    }
}

extension ValidateCredentialsAndConfiguration: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "configuration": authConfiguration
        ]
    }
}

extension ValidateCredentialsAndConfiguration: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
