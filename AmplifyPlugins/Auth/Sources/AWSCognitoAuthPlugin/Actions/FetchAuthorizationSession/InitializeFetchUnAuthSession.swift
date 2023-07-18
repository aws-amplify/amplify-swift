//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

struct InitializeFetchUnAuthSession: Action {

    let identifier = "InitializeFetchUnAuthSession"

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) async {

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
        await dispatcher.send(event)
    }
}

extension InitializeFetchUnAuthSession: DefaultLogger {
    public static var log: Logger {
        Amplify.Logging.logger(forCategory: CategoryType.auth.displayName, forNamespace: String(describing: self))
    }
    
    public var log: Logger {
        Self.log
    }
}

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
