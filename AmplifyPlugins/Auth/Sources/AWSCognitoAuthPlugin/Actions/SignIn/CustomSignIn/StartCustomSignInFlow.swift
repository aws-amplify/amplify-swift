//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct StartCustomSignInFlow: Action {

    var identifier: String = "StartCustomSignInFlow"

    let signInEventData: SignInEventData

    let deviceMetadata: DeviceMetadata

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) async {
        logVerbose("\(#fileID) Start execution", environment: environment)
        let event = SignInEvent(id: UUID().uuidString, eventType: .initiateCustomSignIn(signInEventData, deviceMetadata))
        logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
        await dispatcher.send(event)
    }
}

extension StartCustomSignInFlow: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "signInEventData": signInEventData.debugDictionary
        ]
    }
}

extension StartCustomSignInFlow: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
