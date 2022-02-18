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
    let cognitoCredentials: CognitoCredentials?

    func execute(withDispatcher dispatcher: EventDispatcher,
                        environment: Environment)
    {
        logVerbose("\(#fileID) Starting execution", environment: environment)
        let event = AuthenticationEvent(eventType: .configure(configuration, cognitoCredentials))
        logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
        dispatcher.send(event)
    }
}

extension InitializeAuthenticationConfiguration: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "configuration": configuration
        ]
    }
}

extension InitializeAuthenticationConfiguration: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
