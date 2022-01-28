//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation


struct LoadPersistedAuthorization: Command {

    let identifier = "LoadPersistedAuthorization"

    let authConfiguration: AuthConfiguration

    public func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) {

        let timer = LoggingTimer(identifier).start("### Starting execution")
        
        // Send Authorization configured event to move the Auth state to configured
        let authorizationConfiguredEvent = AuthEvent(eventType: .authorizationConfigured)
        timer.note("### sending event \(authorizationConfiguredEvent.type)")
        dispatcher.send(authorizationConfiguredEvent)

    }
}

extension LoadPersistedAuthorization: DefaultLogger { }

extension LoadPersistedAuthorization: CustomDebugDictionaryConvertible {
    public var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "configuration": authConfiguration
        ]
    }
}

extension LoadPersistedAuthorization: CustomDebugStringConvertible {
    public var debugDescription: String {
        debugDictionary.debugDescription
    }
}
