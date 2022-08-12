//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

struct InitializeRefreshSession: Action {

    let identifier = "InitializeRefreshSession"

    let existingCredentials: AmplifyCredentials

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) {

        logVerbose("\(#fileID) Starting execution", environment: environment)

        let event: RefreshSessionEvent

        switch existingCredentials {
        case .userPoolOnly(signedInData: let signedInData):
            event = .init(eventType: .refreshCognitoUserPool(signedInData))

        case .identityPoolOnly(let identityID, _):
            event = .init(eventType: .refreshUnAuthAWSCredentials(identityID))

        case .identityPoolWithFederation:
            fatalError("Federation not implemented")

        case .userPoolAndIdentityPool(let signedInData, let identityID, _):
            event = .init(eventType: .refreshCognitoUserPoolWithIdentityId(signedInData, identityID))

        case .noCredentials:
            event = .init(eventType: .throwError(.noCredentialsToRefresh))
        }

        logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
        dispatcher.send(event)
    }
}

extension InitializeRefreshSession: DefaultLogger { }

extension InitializeRefreshSession: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "existingCredentials": existingCredentials.debugDescription
        ]
    }
}

extension InitializeRefreshSession: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
