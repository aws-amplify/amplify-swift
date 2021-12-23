//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import hierarchical_state_machine_swift

struct InitializeAuthConfiguration: Command {

    let identifier = "InitializeAuthConfiguration"

    let authConfiguration: AuthConfiguration

    public func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) {
        let timer = LoggingTimer(identifier).start("### Starting execution")

        var event: StateMachineEvent
        switch authConfiguration {
        case .identityPools:
            event = AuthEvent(eventType: .configureAuthorization(authConfiguration))
        default:
            event = AuthEvent(eventType: .configureAuthentication(authConfiguration))
        }
        timer.stop("### sending event \(event.type)")
        dispatcher.send(event)
    }
}

extension InitializeAuthConfiguration: DefaultLogger { }

extension InitializeAuthConfiguration: CustomDebugDictionaryConvertible {
    public var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "configuration": authConfiguration
        ]
    }
}

extension InitializeAuthConfiguration: CustomDebugStringConvertible {
    public var debugDescription: String {
        debugDictionary.debugDescription
    }
}
