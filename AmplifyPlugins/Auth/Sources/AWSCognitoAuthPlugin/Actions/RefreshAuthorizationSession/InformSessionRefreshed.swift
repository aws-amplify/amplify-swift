//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Foundation

struct InformSessionRefreshed: Action {

    let identifier = "InformSessionRefreshed"

    let credentials: AmplifyCredentials

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) {

        logVerbose("\(#fileID) Starting execution", environment: environment)
        let event = AuthorizationEvent(eventType: .refreshed(credentials))
        logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
        dispatcher.send(event)
    }
}

extension InformSessionRefreshed: DefaultLogger { }

extension InformSessionRefreshed: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "credentials": credentials.debugDescription
        ]
    }
}

extension InformSessionRefreshed: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
