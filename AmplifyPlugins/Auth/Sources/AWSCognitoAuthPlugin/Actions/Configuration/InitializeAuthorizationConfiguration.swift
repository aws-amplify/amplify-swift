//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct InitializeAuthorizationConfiguration: Action {

    let identifier = "InitializeAuthorizationConfiguration"

    func execute(withDispatcher dispatcher: EventDispatcher,
                        environment: Environment) {
        // ATM this is a no-op action
        let timer = LoggingTimer(identifier).start("### Starting execution")
        let authorizationEvent = AuthorizationEvent(eventType: .configure)
        timer.stop("### sending \(authorizationEvent.type)")
        dispatcher.send(authorizationEvent)
    }
}

extension InitializeAuthorizationConfiguration: DefaultLogger { }

extension InitializeAuthorizationConfiguration: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier
        ]
    }
}

extension InitializeAuthorizationConfiguration: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
