//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

struct InitiateSignOut: Action {

    var identifier: String = "InitiateSignOut"

    let signedInData: SignedInData
    let signOutEventData: SignOutEventData

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) async {
        logVerbose("\(#fileID) Starting execution", environment: environment)
        let updatedSignedInData = await getUpdatedSignedInData(environment: environment)
        let event: SignOutEvent
        if case .hostedUI(let options) = signedInData.signInMethod,
           options.preferPrivateSession == false {
            event = SignOutEvent(eventType: .invokeHostedUISignOut(signOutEventData,
                                                                   updatedSignedInData))
        } else if signOutEventData.globalSignOut {
            event = SignOutEvent(eventType: .signOutGlobally(updatedSignedInData))
        } else {
            event = SignOutEvent(eventType: .revokeToken(updatedSignedInData))
        }
        logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
        await dispatcher.send(event)
    }

    private func getUpdatedSignedInData(
        environment: Environment
    ) async -> SignedInData {
        let credentialStoreClient = (environment as? AuthEnvironment)?.credentialsClient
        do {
            let data = try await credentialStoreClient?.fetchData(
                type: .amplifyCredentials
            )
            guard case .amplifyCredentials(let credentials) = data else {
                return signedInData
            }

            // Update SignedInData based on credential type
            switch credentials {
            case .userPoolOnly(let updatedSignedInData):
                return updatedSignedInData
            case .userPoolAndIdentityPool(let updatedSignedInData, _, _):
                return updatedSignedInData
            case .identityPoolOnly, .identityPoolWithFederation, .noCredentials:
                return signedInData
            }
        } catch {
            let logger = (environment as? LoggerProvider)?.logger
            logger?.error("Unable to update credentials with error: \(error)")
            return signedInData
        }
    }

}

extension InitiateSignOut: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "signOutEventData": signOutEventData.debugDictionary,
            "signedInData": signedInData.debugDictionary
        ]
    }
}

extension InitiateSignOut: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
