//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

package struct InitializeFederationToIdentityPool: Action {

    package var identifier: String = "InitializeFederationToIdentityPool"

    package let federatedToken: FederatedToken
    package let developerProvidedIdentityId: IdentityID?

    package func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) async {
        logVerbose("\(#fileID) Starting execution", environment: environment)
        let authProviderLoginsMap = AuthProviderLoginsMap(federatedToken: federatedToken)
        let event: FetchAuthSessionEvent

        if let developerProvidedIdentityId {
            event = FetchAuthSessionEvent.init(
                eventType: .fetchAWSCredentials(
                    developerProvidedIdentityId,
                    authProviderLoginsMap
                ))
        } else {
            event = FetchAuthSessionEvent.init(
                eventType: .fetchAuthenticatedIdentityID(authProviderLoginsMap))
        }

        logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
        await dispatcher.send(event)
    }
}

extension InitializeFederationToIdentityPool: CustomDebugDictionaryConvertible {
    package var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "federatedToken": federatedToken.debugDictionary
        ]
    }
}

extension InitializeFederationToIdentityPool: CustomDebugStringConvertible {
    package var debugDescription: String {
        debugDictionary.debugDescription
    }
}
