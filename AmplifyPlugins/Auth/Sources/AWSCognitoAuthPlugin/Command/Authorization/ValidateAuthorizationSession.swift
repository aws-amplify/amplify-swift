//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import hierarchical_state_machine_swift

struct ValidateAuthorizationSession: Command {

    let identifier = "ValidateAuthorizationSession"

    let authConfiguration: AuthConfiguration

    public func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) {
        let timer = LoggingTimer(identifier).start("### Starting execution")
        
        //TODO: Implementation - Either session is valid or fetch the session again.

        let authorizationEvent = AuthorizationEvent(eventType: .sessionIsValid)
        timer.stop("### sending \(authorizationEvent.type)")
        dispatcher.send(authorizationEvent)
    }
}

extension ValidateAuthorizationSession: DefaultLogger { }

extension ValidateAuthorizationSession: CustomDebugDictionaryConvertible {
    public var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "configuration": authConfiguration
        ]
    }
}

extension ValidateAuthorizationSession: CustomDebugStringConvertible {
    public var debugDescription: String {
        debugDictionary.debugDescription
    }
}
