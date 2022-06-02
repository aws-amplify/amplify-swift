//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

struct AuthorizationSessionEstablished: Action {

    let identifier = "AuthorizationSessionEstablished"

    let credentials: AmplifyCredentials

    func execute(withDispatcher dispatcher: EventDispatcher,
                 environment: Environment) {
        logVerbose("\(#fileID) Starting execution", environment: environment)
        let event = AuthorizationEvent(
            eventType: .fetchedAuthSession(credentials))
        logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
        dispatcher.send(event)
    }
}

extension AuthorizationSessionEstablished: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier
        ]
    }
}

extension AuthorizationSessionEstablished: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
