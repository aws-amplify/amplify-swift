//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct IdleCredentialStore: Action {

    let identifier = "IdleCredentialStore"

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) {
        let timer = LoggingTimer(identifier).start("### Starting execution")
        let event = CredentialStoreEvent(eventType: .moveToIdleState)
        timer.stop("### sending event \(event.type)")
        dispatcher.send(event)
    }
}

extension IdleCredentialStore: DefaultLogger { }

extension IdleCredentialStore: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier
        ]
    }
}

extension IdleCredentialStore: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
