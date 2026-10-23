//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

package struct InitializeAuthenticationConfiguration: Action {

    package let identifier = "InitializeAuthenticationConfiguration"

    package let configuration: AuthConfiguration
    package let storedCredentials: AmplifyCredentials

    package func execute(
        withDispatcher dispatcher: EventDispatcher,
        environment: Environment
    ) async {
        logVerbose("\(#fileID) Starting execution", environment: environment)
        let event = AuthenticationEvent(eventType: .configure(configuration, storedCredentials))
        logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
        await dispatcher.send(event)
    }
}

extension InitializeAuthenticationConfiguration: CustomDebugDictionaryConvertible {
    package var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "configuration": configuration,
            "cachedCredentials": storedCredentials.debugDescription
        ]
    }
}

extension InitializeAuthenticationConfiguration: CustomDebugStringConvertible {
    package var debugDescription: String {
        debugDictionary.debugDescription
    }
}
