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
                     byApplying event: StateMachineEvent) -> StateResolution<FetchAuthSessionState> {

            switch oldState {

            case .notStarted:
                if case .fetchUnAuthIdentityID = isFetchAuthSessionEvent(event)?.eventType {
                    let action = FetchIdentityId()
                    return .init(newState: .fetchingIdentityID(UnAuthLoginsMapProvider()),
                                 actions: [action])
                }
                return .from(oldState)
            case .fetchingIdentityID(let loginsmapProvider):
                if case .fetchedIdentityID(let identityID) = isFetchAuthSessionEvent(event)?.eventType {
                    let action = FetchAuthAWSCredentials(loginsMap: [:], identityID: identityID)
                    return .init(newState: .fetchingAWSCredentials(identityID, loginsmapProvider),
                                 actions: [action])
                } else if case .throwError(let fetchError) = isFetchAuthSessionEvent(event)?.eventType,
                          case .notAuthorized = fetchError {
                    let credentials = AmplifyCredentials.noCredentials
                    return .init(newState: .waitingToStore(credentials))
                }
                return .from(oldState)
            case .fetchingAWSCredentials:
                if case .fetchedAWSCredentials(
                    let identityID,
                    let credentials) = isFetchAuthSessionEvent(event)?.eventType {

                    let amplifyCredentials = AmplifyCredentials.identityPoolOnly(
                        identityID: identityID,
                        credentials: credentials)
                    return .init(newState: .waitingToStore(amplifyCredentials))
                }
                return .from(oldState)
            case .fetched:
                fatalError()
            case .waitingToStore:
                if case .receivedCachedCredentials(let cachedCredentials) = isAuthEvent(event)?.eventType {
                    let action = AuthorizationSessionEstablished(credentials: cachedCredentials)
                    return .init(newState: .fetched(cachedCredentials), actions: [action])
                }
                return .from(oldState)
            }
        }

        private func isFetchAuthSessionEvent(_ event: StateMachineEvent) -> FetchAuthSessionEvent? {
            guard let fetchAuthSessionEvent = event as? FetchAuthSessionEvent else {
                return nil
            }
            return fetchAuthSessionEvent
        }

        private func isAuthEvent(_ event: StateMachineEvent) -> AuthEvent? {
            guard let authEvent = event as? AuthEvent else {
                return nil
            }
            return authEvent
        }
    }
}
