//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

package struct CancelSignOut: Action {

    package var identifier: String = "CancelSignOut"

    package let signedInData: SignedInData?

    package func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) async {
        logVerbose("\(#fileID) Starting execution", environment: environment)
        let event = AuthenticationEvent(eventType: .cancelSignOut(signedInData))
        logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
        await dispatcher.send(event)
    }

}

extension CancelSignOut: CustomDebugDictionaryConvertible {
    package var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "signedInData": signedInData?.debugDictionary ?? "NA"
        ]
    }
}

extension CancelSignOut: CustomDebugStringConvertible {
    package var debugDescription: String {
        debugDictionary.debugDescription
    }
}
