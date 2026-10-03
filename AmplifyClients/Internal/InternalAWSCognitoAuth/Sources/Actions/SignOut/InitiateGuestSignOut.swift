//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

package struct InitiateGuestSignOut: Action {

    package var identifier: String = "InitiateGuestSignOut"

    package let signOutEventData: SignOutEventData

    package func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) async {
        logVerbose("\(#fileID) Starting execution", environment: environment)

        let event = SignOutEvent(eventType: .signOutGuest)
        logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
        await dispatcher.send(event)
    }

}

extension InitiateGuestSignOut: CustomDebugDictionaryConvertible {
    package var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "signOutEventData": signOutEventData.debugDictionary
        ]
    }
}

extension InitiateGuestSignOut: CustomDebugStringConvertible {
    package var debugDescription: String {
        debugDictionary.debugDescription
    }
}
