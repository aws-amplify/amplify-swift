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

            guard let eventType = isFetchAuthSessionEvent(event)?.eventType else {
                return .from(oldState)
            }
            switch oldState {

            case .notStarted:
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
                
                switch eventType {
                case .fetchedIdentityID(let identityID):
                    let action = FetchAuthAWSCredentials(
                        loginsMap: loginsmapProvider.loginsMap,
                        identityID: identityID)
                    return .init(newState: .fetchingAWSCredentials(identityID, loginsmapProvider),
                                 actions: [action])
                case .throwError(let error):
                    let action = InformSessionError(error: error)
                    return .init(newState: .error(error), actions: [action])
                default:
                    return .from(oldState)
                }

            case .fetchingAWSCredentials:

                switch eventType {
                case .fetchedAWSCredentials(let identityID, let credentials):
                    let action = InformSessionFetched(
                        identityID: identityID,
                        credetentials: credentials)
                    return .init(newState: .fetched(identityID, credentials), actions: [action])
                case .throwError(let error):
                    let action = InformSessionError(error: error)
                    return .init(newState: .error(error), actions: [action])
                default:
                    return .from(oldState)
                }
            case .fetched, error:
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
