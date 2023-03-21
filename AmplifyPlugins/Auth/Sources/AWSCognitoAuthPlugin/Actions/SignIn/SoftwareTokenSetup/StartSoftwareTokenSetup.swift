//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct StartSoftwareTokenSetup: Action {

    var identifier: String = "StartSoftwareTokenSetup"

    let authResponse: SignInResponseBehavior

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) async {
        logVerbose("\(#fileID) Start execution", environment: environment)
        let event = SetupSoftwareTokenEvent(
            id: UUID().uuidString,
            eventType: .associateSoftwareToken(authResponse))
        logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
        await dispatcher.send(event)
    }
}

extension StartSoftwareTokenSetup: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier
        ]
    }
}

extension StartSoftwareTokenSetup: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
