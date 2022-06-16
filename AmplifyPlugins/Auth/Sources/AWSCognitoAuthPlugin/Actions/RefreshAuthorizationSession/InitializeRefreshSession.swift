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
    
    let isForceRefresh: Bool
    
    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) {
        
        logVerbose("\(#fileID) Starting execution", environment: environment)
        
        let event: RefreshSessionEvent
        
        switch existingCredentials {
        case .userPoolOnly(let tokens):
            event = .init(eventType: .refreshCognitoUserPool(tokens))
            
        case .identityPoolOnly(let identityID, _):
            event = .init(eventType: .refreshUnAuthAWSCredentials(identityID))
            
        case .identityPoolWithFederation:
            fatalError("Federation not implemented")
            
        case .userPoolAndIdentityPool(let tokens, let identityID, _):
            guard let config = (environment as? AuthEnvironment)?.userPoolConfigData else {
                //TODO: Fix error
                fatalError("fix here")
            }
            let provider = CognitoUserPoolLoginsMap(idToken: tokens.idToken,
                                                    region: config.region,
                                                    poolId: config.poolId)
            if isForceRefresh ||
                tokens.doesExpire(in: FetchAuthSessionOperationHelper.expiryBufferInSeconds) {
                event = .init(eventType: .refreshCognitoUserPoolWithIdentityId(tokens, identityID))
            } else {
                event = .init(eventType: .refreshAWSCredentialsWithUserPool(identityID,
                                                                            tokens,
                                                                            provider))
            }
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
            "isForceRefresh": isForceRefresh ? "true": "false",
            "existingCredentials": existingCredentials.debugDescription
        ]
    }
}

extension InitializeRefreshSession: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
