//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

package struct SignInComplete: Action {

    package var identifier: String = "SignInComplete"

    package let signedInData: SignedInData

    package func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) async {
        logVerbose("\(#fileID) Starting execution", environment: environment)
        let event = AuthenticationEvent(eventType: .signInCompleted(signedInData))
        logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
        await dispatcher.send(event)
    }
}

extension SignInComplete: CustomDebugDictionaryConvertible {
    package var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "singedInData": signedInData.debugDictionary
        ]
    }
}

extension SignInComplete: CustomDebugStringConvertible {
    package var debugDescription: String {
        debugDictionary.debugDescription
    }
}
