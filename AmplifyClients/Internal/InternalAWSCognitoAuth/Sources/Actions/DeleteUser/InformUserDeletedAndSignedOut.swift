//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

package struct InformUserDeletedAndSignedOut: Action {

    package let identifier = "InformUserDeletedAndSignedOut"

    package let result: Result<SignedOutData, EngineAuthError>

    package func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) async {

        logVerbose("\(#fileID) Starting execution", environment: environment)

        let event = switch result {
        case .success(let signedOutData):
            DeleteUserEvent(eventType: .userSignedOutAndDeleted(signedOutData))
        case .failure(let error):
            DeleteUserEvent(eventType: .throwError(error))
        }

        logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
        await dispatcher.send(event)
    }
}

extension InformUserDeletedAndSignedOut: CustomDebugDictionaryConvertible {
    package var debugDictionary: [String: Any] {
        [
            "identifier": identifier
        ]
    }
}

extension InformUserDeletedAndSignedOut: CustomDebugStringConvertible {
    package var debugDescription: String {
        debugDictionary.debugDescription
    }
}
