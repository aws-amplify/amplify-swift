//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct InitializeAuthorizationConfiguration: Command {

    let identifier = "InitializeAuthorizationConfiguration"

    let configuration: AuthConfiguration

    func execute(withDispatcher dispatcher: EventDispatcher,
                        environment: Environment)
    {
        // ATM this is a no-op command
        let timer = LoggingTimer(identifier).start("### Starting execution")
        let authorizationEvent = AuthorizationEvent(eventType: .configure(configuration))
        timer.stop("### sending \(authorizationEvent.type)")
        dispatcher.send(authorizationEvent)
    }
}

extension InitializeAuthorizationConfiguration: DefaultLogger { }

extension InitializeAuthorizationConfiguration: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "configuration": configuration
        ]
    }
}

extension InitializeAuthorizationConfiguration: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
