//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

package struct StartMigrateAuthFlow: Action {

    package var identifier: String = "StartMigrateAuthFlow"

    package let signInEventData: SignInEventData
    package let deviceMetadata: DeviceMetadata
    package let respondToAuthChallenge: RespondToAuthChallenge?

    package func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) async {
        logVerbose("\(#fileID) Start execution", environment: environment)
        let event = SignInEvent(id: UUID().uuidString, eventType: .initiateMigrateAuth(signInEventData, deviceMetadata, respondToAuthChallenge))
        logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
        await dispatcher.send(event)
    }
}

extension StartMigrateAuthFlow: CustomDebugDictionaryConvertible {
    package var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "signInEventData": signInEventData.debugDictionary
        ]
    }
}

extension StartMigrateAuthFlow: CustomDebugStringConvertible {
    package var debugDescription: String {
        debugDictionary.debugDescription
    }
}
