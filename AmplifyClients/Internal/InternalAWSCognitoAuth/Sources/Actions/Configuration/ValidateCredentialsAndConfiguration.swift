//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

package struct ValidateCredentialsAndConfiguration: Action {

    package let identifier = "ValidateCredentialsAndConfiguration"

    package let authConfiguration: AuthConfiguration

    package let cachedCredentials: AmplifyCredentials

    package func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) async {

        logVerbose("\(#fileID) Starting execution", environment: environment)
        var event: StateMachineEvent
        switch authConfiguration {
        case .identityPools:
            event = AuthEvent(eventType: .configureAuthorization(
                authConfiguration,
                cachedCredentials
            ))
        default:
            event = AuthEvent(eventType: .configureAuthentication(
                authConfiguration,
                cachedCredentials
            ))
        }
        logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
        await dispatcher.send(event)
    }
}

extension ValidateCredentialsAndConfiguration: CustomDebugDictionaryConvertible {
    package var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "configuration": authConfiguration
        ]
    }
}

extension ValidateCredentialsAndConfiguration: CustomDebugStringConvertible {
    package var debugDescription: String {
        debugDictionary.debugDescription
    }
}
