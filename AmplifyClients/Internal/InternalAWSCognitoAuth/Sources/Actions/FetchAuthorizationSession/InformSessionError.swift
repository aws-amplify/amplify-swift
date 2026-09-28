//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentity
import AWSCognitoIdentityProvider
import Foundation

package struct InformSessionError: Action {

    package let identifier = "InformSessionError"

    package let error: FetchSessionError

    package func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) async {

        logVerbose("\(#fileID) Starting execution", environment: environment)
        let event: AuthorizationEvent = switch error {
        case .service(let serviceError):
            if serviceError is AWSCognitoIdentityProvider.NotAuthorizedException {
                .init(eventType: .throwError(
                    .sessionExpired(error: serviceError)))
            } else {
                .init(eventType: .receivedSessionError(error))
            }
        default:
            .init(eventType: .receivedSessionError(error))
        }

        logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
        await dispatcher.send(event)
    }
}

extension InformSessionError: CustomDebugDictionaryConvertible {
    package var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "error": error
        ]
    }
}

extension InformSessionError: CustomDebugStringConvertible {
    package var debugDescription: String {
        debugDictionary.debugDescription
    }
}
