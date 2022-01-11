//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import hierarchical_state_machine_swift

struct ConfigureUserPoolToken: Command {

    let identifier = "ConfigureUserPoolToken"

    public func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) {

        let timer = LoggingTimer(identifier).start("### Starting execution")

        //TODO: Implementation

        let event = FetchUserPoolTokensEvent(eventType: .fetch)
        timer.stop("### sending event \(event.type)")
        dispatcher.send(event)
    }
}

extension ConfigureUserPoolToken: DefaultLogger { }

extension ConfigureUserPoolToken: CustomDebugDictionaryConvertible {
    public var debugDictionary: [String: Any] {
        [
            "identifier": identifier
        ]
    }
}

extension ConfigureUserPoolToken: CustomDebugStringConvertible {
    public var debugDescription: String {
        debugDictionary.debugDescription
    }
}
