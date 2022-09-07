//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

struct BuildRevokeTokenError: Action {

    var identifier: String = "BuildRevokeTokenError"

    let signedInData: SignedInData
    let hostedUIError: AWSCognitoHostedUIError?
    let globalSignOutError: AWSCognitoGlobalSignOutError

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) async {
        logVerbose("\(#fileID) Starting execution", environment: environment)
        let revokeTokenError = AWSCognitoRevokeTokenError(
            refreshToken: signedInData.cognitoUserPoolTokens.refreshToken,
            error: .service("", "", nil))
        let event = SignOutEvent(eventType: .signOutLocally(
            signedInData,
            hostedUIError: hostedUIError,
            globalSignOutError: globalSignOutError,
            revokeTokenError: revokeTokenError))
        logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
        await dispatcher.send(event)
    }

}

extension BuildRevokeTokenError: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "signedInData": signedInData.debugDictionary
        ]
    }
}

extension BuildRevokeTokenError: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
