//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

struct InitiateGuestSignOut: Action {

    var identifier: String = "InitiateGuestSignOut"

    let signOutEventData: SignOutEventData

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) async {
        logVerbose("\(#fileID) Starting execution", environment: environment)

        let event = SignOutEvent(eventType: .signOutGuest)
        logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
        await dispatcher.send(event)
    }

}

extension InitiateGuestSignOut: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "signOutEventData": signOutEventData.debugDictionary
        ]
    }
}

extension InitiateGuestSignOut: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
