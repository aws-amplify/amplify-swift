//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

package struct BuildRevokeTokenError: Action {

    package var identifier: String = "BuildRevokeTokenError"

    package let signedInData: SignedInData
    package let hostedUIError: EngineHostedUISignOutFailure?
    package let globalSignOutError: EngineGlobalSignOutFailure

    package func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) async {
        logVerbose("\(#fileID) Starting execution", environment: environment)
        let revokeTokenError = EngineRevokeTokenFailure(
            refreshToken: signedInData.cognitoUserPoolTokens.refreshToken,
            error: .service("", "", nil)
        )
        let event = SignOutEvent(eventType: .signOutLocally(
            signedInData,
            hostedUIError: hostedUIError,
            globalSignOutError: globalSignOutError,
            revokeTokenError: revokeTokenError
        ))
        logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
        await dispatcher.send(event)
    }

}

extension BuildRevokeTokenError: CustomDebugDictionaryConvertible {
    package var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "signedInData": signedInData.debugDictionary
        ]
    }
}

extension BuildRevokeTokenError: CustomDebugStringConvertible {
    package var debugDescription: String {
        debugDictionary.debugDescription
    }
}
