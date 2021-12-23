//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import hierarchical_state_machine_swift

struct LoadPersistedAuthorization: Command {

    let identifier = "LoadPersistedAuthorization"

    let authConfiguration: AuthConfiguration

    public func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) {
  
        let timer = LoggingTimer(identifier).start("### Starting execution")
        
        //TODO: Implementation - If persisted authorization exists, validate otherwise fetch

        let event = AuthorizationEvent(eventType: .fetchAuthSession(authConfiguration))
        //OR
        //let event = AuthorizationEvent(eventType: .validateSession(authConfiguration))
        timer.stop("### sending event \(event.type)")
        dispatcher.send(event)
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
