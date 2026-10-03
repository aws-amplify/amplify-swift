//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

package struct InitializeTOTPSetup: Action {

    package var identifier: String = "InitializeTOTPSetup"
    package let authResponse: RespondToAuthChallenge

    package func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) async {
        logVerbose("\(#fileID) Start execution", environment: environment)
        let event = SetUpTOTPEvent(
            id: UUID().uuidString,
            eventType: .setUpTOTP(authResponse)
        )
        logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
        await dispatcher.send(event)
    }
}

extension InitializeTOTPSetup: CustomDebugDictionaryConvertible {
    package var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "challengeName": authResponse.challenge.rawValue,
            "session": authResponse.session?.maskedForLog() ?? "",
            "challengeParameters": authResponse.parameters ?? [:]
        ]
    }
}

extension InitializeTOTPSetup: CustomDebugStringConvertible {
    package var debugDescription: String {
        debugDictionary.debugDescription
    }
}
