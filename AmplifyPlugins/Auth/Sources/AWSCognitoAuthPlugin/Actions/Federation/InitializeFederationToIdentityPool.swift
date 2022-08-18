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

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) {
        logVerbose("\(#fileID) Starting execution", environment: environment)
        let authProviderLoginsMap = AuthProviderLoginsMap(federatedToken: federatedToken)
        let event = FetchAuthSessionEvent.init(
            eventType: .fetchAuthenticatedIdentityID(authProviderLoginsMap))
        logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
        dispatcher.send(event)
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
