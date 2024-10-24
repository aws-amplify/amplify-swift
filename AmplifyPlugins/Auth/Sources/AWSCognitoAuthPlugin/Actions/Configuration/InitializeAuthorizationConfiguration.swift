//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct InitializeAuthorizationConfiguration: Action {

    let identifier = "InitializeAuthorizationConfiguration"

    let storedCredentials: AmplifyCredentials

    func execute(
        withDispatcher dispatcher: EventDispatcher,
        environment: Environment
    ) async {
        // ATM this is a no-op action
        logVerbose("\(#fileID) Starting execution", environment: environment)
        var event = switch storedCredentials {
        case .noCredentials:
            AuthorizationEvent(eventType: .configure)
        default:
            AuthorizationEvent(eventType: .cachedCredentialsAvailable(storedCredentials))
        }
        logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
        await dispatcher.send(event)
    }
}

extension InitializeAuthorizationConfiguration: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier
        ]
    }
}

extension InitializeAuthorizationConfiguration: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
