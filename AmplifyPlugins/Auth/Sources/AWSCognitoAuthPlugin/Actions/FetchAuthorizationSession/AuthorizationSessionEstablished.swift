//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPluginsCore

struct AuthorizationSessionEstablished: Action {

    let identifier = "AuthorizationSessionEstablished"

    let cognitoSession: AWSAuthCognitoSession

    func execute(withDispatcher dispatcher: EventDispatcher,
                 environment: Environment) {
        let authorizationSessionEvent = AuthorizationEvent(eventType: .fetchedAuthSession(cognitoSession))
        dispatcher.send(authorizationSessionEvent)
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
