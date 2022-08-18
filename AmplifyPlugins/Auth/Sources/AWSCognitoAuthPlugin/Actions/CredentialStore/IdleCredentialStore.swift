//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct IdleCredentialStore: Action {

    let identifier = "IdleCredentialStore"

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) async {

        logVerbose("\(#fileID) Starting execution", environment: environment)
        let event = CredentialStoreEvent(eventType: .moveToIdleState)
        logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
        await dispatcher.send(event)
    }
}

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
