//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

package struct InitializeFetchUnAuthSession: Action {

    package let identifier = "InitializeFetchUnAuthSession"

    package func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) async {

        logVerbose("\(#fileID) Starting execution", environment: environment)
        let configuration = (environment as? AuthEnvironment)?.configuration

        let event: FetchAuthSessionEvent = switch configuration {
        case .userPools:
            // If only user pool is configured then we do not have any unauthsession
            .init(eventType: .throwError(.noIdentityPool))
        default:
            .init(eventType: .fetchUnAuthIdentityID)
        }
        logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
        await dispatcher.send(event)
    }
}

extension InitializeFetchUnAuthSession: CustomDebugDictionaryConvertible {
    package var debugDictionary: [String: Any] {
        [
            "identifier": identifier
        ]
    }
}

extension InitializeFetchUnAuthSession: CustomDebugStringConvertible {
    package var debugDescription: String {
        debugDictionary.debugDescription
    }
}
