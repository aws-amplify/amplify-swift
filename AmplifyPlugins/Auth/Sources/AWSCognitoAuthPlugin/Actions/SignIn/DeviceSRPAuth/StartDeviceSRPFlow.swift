//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct StartDeviceSRPFlow: Action {

    var identifier: String = "StartDeviceSRPFlow"

    let username: Username
    let authResponse: SignInResponseBehavior

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) async {
        logVerbose("\(#fileID) Start execution", environment: environment)
        let event = SignInEvent(id: UUID().uuidString, eventType: .respondDeviceSRPChallenge(
            username, authResponse))
        logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
        await dispatcher.send(event)
    }
}

extension StartDeviceSRPFlow: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "username": username.masked(),
            "signInResponse": authResponse
        ]
    }
}

extension StartDeviceSRPFlow: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
