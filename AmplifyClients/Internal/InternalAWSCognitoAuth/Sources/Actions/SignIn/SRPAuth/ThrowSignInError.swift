//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

package struct ThrowSignInError: Action {
    package let identifier = "ThrowSignInError"

    package let error: Error

    package func execute(
        withDispatcher dispatcher: EventDispatcher,
        environment: Environment
    ) async {

        logVerbose("\(#fileID) Starting execution", environment: environment)
        let event = AuthenticationEvent(
            eventType: .error(.service(message: "\(error)", error: error)))
        logVerbose("\(#fileID) Sending event \(event)", environment: environment)
        await dispatcher.send(event)

    }
}

extension ThrowSignInError: CustomDebugDictionaryConvertible {
    package var debugDictionary: [String: Any] {
        [
            "identifier": identifier
        ]
    }
}

extension ThrowSignInError: CustomDebugStringConvertible {
    package var debugDescription: String {
        debugDictionary.debugDescription
    }
}
