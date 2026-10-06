//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

package struct InformSessionRefreshed: Action {

    package let identifier = "InformSessionRefreshed"

    package let credentials: AmplifyCredentials

    package func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) async {

        logVerbose("\(#fileID) Starting execution", environment: environment)
        let event = AuthorizationEvent(eventType: .refreshed(credentials))
        logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
        await dispatcher.send(event)
    }
}

extension InformSessionRefreshed: CustomDebugDictionaryConvertible {
    package var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "credentials": credentials.debugDescription
        ]
    }
}

extension InformSessionRefreshed: CustomDebugStringConvertible {
    package var debugDescription: String {
        debugDictionary.debugDescription
    }
}
