//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

package struct InitiateSignOut: Action {

    package var identifier: String = "InitiateSignOut"

    package let signedInData: SignedInData
    package let signOutEventData: SignOutEventData

    /// Whether the sign-out ends the user pool login the credential store holds, when it holds one, rather than
    /// `signedInData`. A cancelled sign-in passes `false`: it cancels from `.signedIn` only after the identity pool
    /// step failed, before its tokens were saved, so the store can hold only another login (under a keychain access
    /// group, another app's), and the tokens to revoke are the sign-in's own.
    var revokesSavedLogin = true

    package func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) async {
        logVerbose("\(#fileID) Starting execution", environment: environment)
        let updatedSignedInData = revokesSavedLogin
            ? await getUpdatedSignedInData(environment: environment)
            : signedInData
        let event: SignOutEvent
        // `signOutPresentsBrowser` is this branch's test (a hosted-UI sign-in that shared the browser's
        // cookies), shared with `AmplifyCognitoClient`, which decides from it whether a sign-out takes the
        // browser.
        if signedInData.signOutPresentsBrowser,
           !signOutEventData.skipHostedUISignOut {
            event = SignOutEvent(eventType: .invokeHostedUISignOut(
                signOutEventData,
                updatedSignedInData
            ))
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
    package var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "signOutEventData": signOutEventData.debugDictionary,
            "signedInData": signedInData.debugDictionary
        ]
    }
}

extension InitiateSignOut: CustomDebugStringConvertible {
    package var debugDescription: String {
        debugDictionary.debugDescription
    }
}
