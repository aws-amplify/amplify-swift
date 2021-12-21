//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import hierarchical_state_machine_swift

public struct InitializeAuthenticationConfiguration: Command {

    public let identifier = "InitializeAuthenticationConfiguration"

    public let configuration: AuthConfiguration

    public func execute(withDispatcher dispatcher: EventDispatcher,
                        environment: Environment)
    {
        let timer = LoggingTimer(identifier).start("### Starting execution")
        let event = AuthenticationEvent(eventType: .configure(configuration))
        timer.stop("### sending \(event.type)")
        dispatcher.send(event)
    }
}

extension InitializeAuthenticationConfiguration: DefaultLogger { }

extension InitializeAuthenticationConfiguration: CustomDebugDictionaryConvertible {
    public var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "configuration": configuration
        ]
    }
}

extension InitializeAuthenticationConfiguration: CustomDebugStringConvertible {
    public var debugDescription: String {
        debugDictionary.debugDescription
    }
}
