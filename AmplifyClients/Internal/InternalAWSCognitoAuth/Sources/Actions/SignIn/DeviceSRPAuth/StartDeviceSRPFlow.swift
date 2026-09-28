//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

package struct StartDeviceSRPFlow: Action {

    package var identifier: String = "StartDeviceSRPFlow"

    package let username: Username
    package let authResponse: SignInResponseBehavior

    package func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) async {
        logVerbose("\(#fileID) Start execution", environment: environment)
        let event = SignInEvent(id: UUID().uuidString, eventType: .respondDeviceSRPChallenge(
            username, authResponse
        ))
        logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
        await dispatcher.send(event)
    }
}

extension StartDeviceSRPFlow: CustomDebugDictionaryConvertible {
    package var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "username": username.maskedForLog(),
            "signInResponse": authResponse
        ]
    }
}

extension StartDeviceSRPFlow: CustomDebugStringConvertible {
    package var debugDescription: String {
        debugDictionary.debugDescription
    }
}
