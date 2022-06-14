//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

struct InitializeFetchAuthSessionWithUserPool: Action {

    let identifier = "InitializeFetchAuthSessionWithUserPool"

    let tokens: AWSCognitoUserPoolTokens

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) {

        logVerbose("\(#fileID) Starting execution", environment: environment)
        let configuration = (environment as? AuthEnvironment)?.configuration

        let event: FetchAuthSessionEvent
        switch configuration {
        case .userPools:
            // If only user pool is configured then we do not have any unauthsession
            event = .init(eventType: .throwError(.noIdentityPool))
        case .userPoolsAndIdentityPools(let userPoolData, _):
            let region = userPoolData.region
            let poolId = userPoolData.poolId
            let loginsMapProvider = CognitoUserPoolLoginsMap(idToken: tokens.idToken,
                                                             region: region,
                                                             poolId: poolId)
            event = .init(eventType: .fetchAuthenticatedIdentityID(loginsMapProvider))
        default:
            // TODO: Handle error
            fatalError("Should not reach here")

        }
        logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
        dispatcher.send(event)
    }
}

extension InitializeFetchAuthSessionWithUserPool: DefaultLogger { }

extension InitializeFetchAuthSessionWithUserPool: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier
        ]
    }
}

extension InitializeFetchAuthSessionWithUserPool: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
