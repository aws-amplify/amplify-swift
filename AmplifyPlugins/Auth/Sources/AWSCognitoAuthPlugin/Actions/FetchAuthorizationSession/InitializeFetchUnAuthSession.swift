//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Foundation

struct InitializeFetchUnAuthSession: Action {

    let identifier = "InitializeFetchUnAuthSession"

    let storedCredentials: AmplifyCredentials

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) {

        logVerbose("\(#fileID) Starting execution", environment: environment)
        let configuration = (environment as? AuthEnvironment)?.configuration

        let event: FetchAuthSessionEvent
        switch configuration {
        case .userPools:
            // If only user pool is configured then we do not have any unauthsession
            event = .init(eventType: .throwError(.noIdentityPool))
        default:
            event = .init(eventType: .fetchUnAuthIdentityID)
        }
        logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
        dispatcher.send(event)
    }
}

extension InitializeFetchUnAuthSession: DefaultLogger { }

extension InitializeFetchUnAuthSession: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier
        ]
    }
}

extension InitializeFetchUnAuthSession: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
