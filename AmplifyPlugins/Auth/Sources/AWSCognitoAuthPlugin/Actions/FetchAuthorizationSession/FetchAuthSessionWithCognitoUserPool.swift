//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Foundation

struct FetchAuthSessionWithCognitoUserPool: Action {

    let identifier = "InitializeFetchAuthSession"

    let storedCredentials: AmplifyCredentials

    let cognitoToken: LoginsMapProvider

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) {

        logVerbose("\(#fileID) Starting execution", environment: environment)
        let event: FetchAuthSessionEvent
        switch storedCredentials {
        case .noCredentials:
            // No stored credentials, try to fetch identity ID for guest user.
            event = FetchAuthSessionEvent(eventType: .fetchAuthenticatedIdentityID(cognitoToken))
        default:
            // TODO: Fix fetch authsession with user pool token for already existing credentials
            fatalError("Not implemented")
        }
        logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
        dispatcher.send(event)
    }
}

extension FetchAuthSessionWithCognitoUserPool: DefaultLogger { }

extension FetchAuthSessionWithCognitoUserPool: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier
        ]
    }
}

extension FetchAuthSessionWithCognitoUserPool: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
