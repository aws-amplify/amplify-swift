//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct StartSRPFlow: Action {

    var identifier: String = "StartSRPFlow"

    let signInEventData: SignInEventData

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) {
        logVerbose("\(#fileID) Start execution", environment: environment)
        let event = SRPSignInEvent(id: UUID().uuidString, eventType: .initiateSRP(signInEventData))
        logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
        dispatcher.send(event)
    }
}

extension StartSRPFlow: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "signInEventData": signInEventData.debugDictionary
        ]
    }
}

extension StartSRPFlow: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
