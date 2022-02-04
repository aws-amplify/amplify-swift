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
        let timer = LoggingTimer(identifier).start("### Starting execution")

        let event = SRPSignInEvent(id: UUID().uuidString, eventType: .initiateSRP(signInEventData))

        timer.stop("### sending SRPSignInEvent.invoked")
        dispatcher.send(event)
    }

}

extension StartSRPFlow: DefaultLogger { }

extension StartSRPFlow: CustomDebugDictionaryConvertible {
    public var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "signInEventData": signInEventData.debugDictionary
        ]
    }
}

extension StartSRPFlow: CustomDebugStringConvertible {
    public var debugDescription: String {
        debugDictionary.debugDescription
    }
}
