//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import hierarchical_state_machine_swift

public struct InitializeAuthorizationConfiguration: Command {

    public let identifier = "InitializeAuthorizationConfiguration"

    public let configuration: AuthConfiguration

    public func execute(withDispatcher dispatcher: EventDispatcher,
                        environment: Environment)
    {
        let timer = LoggingTimer(identifier).start("### Starting execution")
        let event = AuthEvent(eventType: .authorizationConfigured(configuration))
        timer.stop("### sending \(event.type)")
        dispatcher.send(event)
    }
}

extension InitializeAuthorizationConfiguration: DefaultLogger { }

extension InitializeAuthorizationConfiguration: CustomDebugDictionaryConvertible {
    public var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "configuration": configuration
        ]
    }
}

extension InitializeAuthorizationConfiguration: CustomDebugStringConvertible {
    public var debugDescription: String {
        debugDictionary.debugDescription
    }
}
