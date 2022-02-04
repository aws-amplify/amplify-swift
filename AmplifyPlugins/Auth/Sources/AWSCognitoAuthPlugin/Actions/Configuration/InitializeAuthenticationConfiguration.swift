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
                        environment: Environment) {
        let timer = LoggingTimer(identifier).start("### Starting execution")
        let event = AuthenticationEvent(eventType: .configure(configuration, cognitoCredentials))
        timer.stop("### sending \(event.type)")
        dispatcher.send(event)
    }
}

extension InitializeAuthenticationConfiguration: DefaultLogger { }

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
