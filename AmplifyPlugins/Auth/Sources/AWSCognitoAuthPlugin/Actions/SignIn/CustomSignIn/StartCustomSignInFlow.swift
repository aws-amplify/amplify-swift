//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct StartCustomSignInFlow: Action {

    var identifier: String = "StartCustomSignInFlow"

    let signInEventData: SignInEventData

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) {
        logVerbose("\(#fileID) Start execution", environment: environment)
        let event = SignInEvent(id: UUID().uuidString, eventType: .initiateCustomSignIn(signInEventData))
        logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
        dispatcher.send(event)
    }
}

extension StartCustomSignInFlow: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "signInEventData": signInEventData.debugDictionary
        ]
    }
}

extension StartCustomSignInFlow: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
