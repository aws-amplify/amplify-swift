//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

struct InitiateSignOut: Action {

    var identifier: String = "InitiateSignOut"

    let signedInData: SignedInData
    let signOutEventData: SignOutEventData

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) {
        logVerbose("Starting execution", environment: environment)

        let event: SignOutEvent
        if signOutEventData.globalSignOut {
            event = SignOutEvent(eventType: .signOutGlobally(signedInData))
        } else {
            event = SignOutEvent(eventType: .revokeToken(signedInData))
        }
        logVerbose("Sending event \(event.type)", environment: environment)
        dispatcher.send(event)
    }

}

extension InitiateSignOut: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "signOutEventData": signOutEventData.debugDictionary,
            "singedInData": signedInData.debugDictionary
        ]
    }
}

extension InitiateSignOut: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}

