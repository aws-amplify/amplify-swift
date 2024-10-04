//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct InitializeTOTPSetup: Action {

    var identifier: String = "InitializeTOTPSetup"
    let authResponse: RespondToAuthChallenge

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) async {
        logVerbose("\(#fileID) Start execution", environment: environment)
        let event = SetUpTOTPEvent(
            id: UUID().uuidString,
            eventType: .setUpTOTP(authResponse))
        logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
        await dispatcher.send(event)
    }
}

extension InitializeTOTPSetup: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "challengeName": authResponse.challenge.rawValue,
            "session": authResponse.session?.masked() ?? "",
            "challengeParameters": authResponse.parameters ?? [:]
        ]
    }
}

extension InitializeTOTPSetup: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
