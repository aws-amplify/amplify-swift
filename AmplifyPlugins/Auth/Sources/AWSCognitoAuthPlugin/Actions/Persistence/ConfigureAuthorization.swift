//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct ConfigureAuthorization: Action {

    let identifier = "ConfigureAuthorization"

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) {

        let timer = LoggingTimer(identifier).start("### Starting execution")
        // Send Authorization configured event to move the Auth state to configured
        let authorizationConfiguredEvent = AuthEvent(eventType: .authorizationConfigured)
        timer.note("### sending event \(authorizationConfiguredEvent.type)")
        dispatcher.send(authorizationConfiguredEvent)
    }
}

extension ConfigureAuthorization: DefaultLogger { }

extension ConfigureAuthorization: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier
        ]
    }
}

extension ConfigureAuthorization: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
