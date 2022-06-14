//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSPluginsCore
import Amplify

extension FetchAuthSessionState {
    
    struct Resolver: StateMachineResolver {
        
        var defaultState: FetchAuthSessionState = .notStarted
        
        func resolve(oldState: FetchAuthSessionState,
                     byApplying event: StateMachineEvent)
        -> StateResolution<FetchAuthSessionState> {
            
            switch oldState {
                
            case .notStarted:
                guard let eventType = isFetchAuthSessionEvent(event)?.eventType else {
                    return .from(oldState)
                }
                switch eventType {
                    
                case .fetchUnAuthIdentityID:
                    return .init(newState: .fetchingIdentityID(UnAuthLoginsMapProvider()),
                                 actions: [FetchAuthIdentityId()])
                    
                case .fetchAuthenticatedIdentityID(let provider):
                    return .init(newState: .fetchingIdentityID(provider),
                                 actions: [FetchAuthIdentityId(loginsMap: provider.loginsMap)])
                    
                default:
                    return .from(oldState)
                }
                
            case .fetchingIdentityID(let loginsmapProvider):
                guard let eventType = isFetchAuthSessionEvent(event)?.eventType,
                      case .fetchedIdentityID(let identityID) = eventType else {
                    return .from(oldState)
                }
                let action = FetchAuthAWSCredentials(
                    loginsMap: loginsmapProvider.loginsMap,
                    identityID: identityID)
                return .init(newState: .fetchingAWSCredentials(identityID, loginsmapProvider),
                             actions: [action])
                
            case .fetchingAWSCredentials:
                if case .fetchedAWSCredentials(
                    let identityID,
                    let credentials) = isFetchAuthSessionEvent(event)?.eventType {
                    let action = InformSessionFetched(identityID: identityID,
                                                      credetentials: credentials)
                    return .init(newState: .fetched(identityID, credentials), actions: [action])
                }
                return .from(oldState)
            case .fetched:
                return .from(oldState)
            }
        }
        
        private func isFetchAuthSessionEvent(_ event: StateMachineEvent) -> FetchAuthSessionEvent? {
            guard let fetchAuthSessionEvent = event as? FetchAuthSessionEvent else {
                return nil
            }
            return fetchAuthSessionEvent
        }
    }
}
