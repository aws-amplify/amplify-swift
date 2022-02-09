//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct InitiateSignOut: Action {

    var identifier: String = "InitiateSignOut"

    let signedInData: SignedInData
    let signOutEventData: SignOutEventData

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) {
        let timer = LoggingTimer(identifier).start("### Starting execution")
        
        let event: SignOutEvent
        if signOutEventData.globalSignOut {
            event = SignOutEvent(eventType: .signOutGlobally(signedInData))
        } else {
            event = SignOutEvent(eventType: .revokeToken(signedInData))
        }
        
        timer.stop("### sending \(event.type)")
        dispatcher.send(event)
    }

}

extension InitiateSignOut: DefaultLogger { }

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

