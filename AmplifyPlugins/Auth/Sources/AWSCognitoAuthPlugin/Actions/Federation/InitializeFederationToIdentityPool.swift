//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct InitializeFederationToIdentityPool: Action {

    var identifier: String = "InitializeFederationToIdentityPool"

    let federatedToken: FederatedToken
    let developerProvidedIdentityId: IdentityID?

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) async {
        logVerbose("\(#fileID) Starting execution", environment: environment)
        let authProviderLoginsMap = AuthProviderLoginsMap(federatedToken: federatedToken)
        let event: FetchAuthSessionEvent

        if let developerProvidedIdentityId = developerProvidedIdentityId {
            event = FetchAuthSessionEvent.init(
                eventType: .fetchAWSCredentials(
                    developerProvidedIdentityId,
                    authProviderLoginsMap))
        } else {
            event = FetchAuthSessionEvent.init(
                eventType: .fetchAuthenticatedIdentityID(authProviderLoginsMap))
        }

        logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
        await dispatcher.send(event)
    }
}

extension InitializeFederationToIdentityPool: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "federatedToken": federatedToken.debugDictionary
        ]
    }
}

extension InitializeFederationToIdentityPool: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
