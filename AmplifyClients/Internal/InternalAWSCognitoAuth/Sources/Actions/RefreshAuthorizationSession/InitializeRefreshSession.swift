//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

package struct InitializeRefreshSession: Action {

    package let identifier = "InitializeRefreshSession"

    package let existingCredentials: AmplifyCredentials

    package let isForceRefresh: Bool

    package func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) async {

        logVerbose("\(#fileID) Starting execution", environment: environment)

        let event: RefreshSessionEvent

        switch existingCredentials {
        case .userPoolOnly(signedInData: let signedInData):
            event = .init(eventType: .refreshCognitoUserPool(signedInData))

        case .identityPoolOnly(let identityID, _):
            event = .init(eventType: .refreshUnAuthAWSCredentials(identityID))

        case .identityPoolWithFederation:
            event = .init(eventType: .throwError(.federationNotSupportedDuringRefresh))

        case .userPoolAndIdentityPool(let signedInData, let identityID, _):
            guard let config = (environment as? AuthEnvironment)?.userPoolConfigData else {
                event = .init(eventType: .throwError(.noUserPool))
                logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
                await dispatcher.send(event)
                return
            }
            let tokens = signedInData.cognitoUserPoolTokens
            let provider = CognitoUserPoolLoginsMap(
                idToken: tokens.idToken,
                region: config.region,
                poolId: config.poolId
            )
            if isForceRefresh ||
                tokens.doesExpire(in: AmplifyCredentials.expiryBufferInSeconds) {
                event = .init(eventType: .refreshCognitoUserPoolWithIdentityId(signedInData, identityID))
            } else {
                event = .init(eventType: .refreshAWSCredentialsWithUserPool(
                    identityID,
                    signedInData,
                    provider
                ))
            }

        case .noCredentials:
            event = .init(eventType: .throwError(.noCredentialsToRefresh))
        }

        logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
        await dispatcher.send(event)
    }
}

extension InitializeRefreshSession: CustomDebugDictionaryConvertible {
    package var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "isForceRefresh": isForceRefresh ? "true" : "false",
            "existingCredentials": existingCredentials.debugDescription
        ]
    }
}

extension InitializeRefreshSession: CustomDebugStringConvertible {
    package var debugDescription: String {
        debugDictionary.debugDescription
    }
}
