//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

struct CancelSignUp: Action {
    let identifier = "CancelSignUp"

    func execute(withDispatcher dispatcher: EventDispatcher,
                 environment: Environment) {

        logVerbose("\(#fileID) Starting execution", environment: environment)

        guard let environment = environment as? AuthEnvironment else {
            let message = AuthPluginErrorConstants.configurationError
            let error = AuthenticationError.configuration(message: message)
            let event = AuthenticationEvent(eventType: .error(error))
            logVerbose("\(#fileID) Sending event \(event)", environment: environment)
            dispatcher.send(event)
            return
        }
        let event = AuthenticationEvent(eventType: .cancelSignUp)
        logVerbose("\(#fileID) Sending event \(event)", environment: environment)
        dispatcher.send(event)
    }
}

extension CancelSignUp: DefaultLogger { }

extension CancelSignUp: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier
        ]
    }
}

extension CancelSignUp: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
