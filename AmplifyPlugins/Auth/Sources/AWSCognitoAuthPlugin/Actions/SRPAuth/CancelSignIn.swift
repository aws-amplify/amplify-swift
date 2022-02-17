//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

struct CancelSignIn: Action {
    let identifier = "CancelSignIn"

    func execute(withDispatcher dispatcher: EventDispatcher,
                 environment: Environment)
    {

        Amplify.Logging.verbose("Starting execution")

        guard let environment = environment as? AuthEnvironment else {
            let message = AuthPluginErrorConstants.configurationError
            let error = AuthenticationError.configuration(message: message)
            let event = AuthenticationEvent(eventType: .error(error))
            dispatcher.send(event)
            Amplify.Logging.verbose("Sending event")
            return
        }
        let event = AuthenticationEvent(eventType: .cancelSignIn(environment.configuration))
        dispatcher.send(event)
        Amplify.Logging.verbose("Sending event")

    }
}

extension CancelSignIn: DefaultLogger { }

extension CancelSignIn: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier
        ]
    }
}

extension CancelSignIn: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
