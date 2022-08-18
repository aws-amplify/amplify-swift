//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct InitializeAuthenticationConfiguration: Action {

    let identifier = "InitializeAuthenticationConfiguration"

    let configuration: AuthConfiguration
    let storedCredentials: AmplifyCredentials

    func execute(withDispatcher dispatcher: EventDispatcher,
                        environment: Environment) async {
        logVerbose("\(#fileID) Starting execution", environment: environment)
        let event = AuthenticationEvent(eventType: .configure(configuration, storedCredentials))
        logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
        await dispatcher.send(event)
    }
}

extension InitializeAuthenticationConfiguration: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "configuration": configuration,
            "cachedCredentials": storedCredentials.debugDescription
        ]
    }
}

extension InitializeAuthenticationConfiguration: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
