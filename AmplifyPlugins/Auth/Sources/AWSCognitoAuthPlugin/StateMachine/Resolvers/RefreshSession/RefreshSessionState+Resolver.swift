//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

extension RefreshSessionState {

    struct Resolver: StateMachineResolver {

        var defaultState: RefreshSessionState = .notStarted

        func resolve(oldState: RefreshSessionState,
                     byApplying event: StateMachineEvent) -> StateResolution<RefreshSessionState> {

            switch oldState {
            case .notStarted:

                if case .refreshCognitoUserPool(let tokens) = event.isRefreshSessionEvent {
                    let action = RefreshUserPoolTokens(existingTokens: tokens)
                    return .init(newState: .refreshingUserPoolToken(tokens), actions: [action])
                }

                if case .refreshCognitoUserPoolWithIdentityId(
                    let tokens,
                    let identityID) = event.isRefreshSessionEvent {
                    let action = RefreshUserPoolTokens(existingTokens: tokens)
                    return .init(newState: .refreshingUserPoolTokenWithIdentity(tokens, identityID),
                                 actions: [action])
                }
                if case .refreshUnAuthAWSCredentials(let identityID) = event.isRefreshSessionEvent {
                    let provider = UnAuthLoginsMapProvider()
                    let action = FetchAuthAWSCredentials(loginsMap: provider.loginsMap,
                                                         identityID: identityID)
                    return .init(newState: .refreshingUnAuthAWSCredentials(identityID),
                                 actions: [action])
                }

                if case .refreshAWSCredentialsWithUserPool(
                    let identityID,
                    let tokens,
                    let provider) = event.isRefreshSessionEvent {
                    let action = FetchAuthAWSCredentials(loginsMap: provider.loginsMap,
                                                         identityID: identityID)
                    return .init(newState: .refreshingAWSCredentialsWithUserPoolTokens(
                        tokens,
                        identityID
                    ), actions: [action])
                }
                return .from(oldState)

            case .refreshingUserPoolToken:

                if case .refreshedCognitoUserPool(let tokens) = event.isRefreshSessionEvent {
                    let credentials = AmplifyCredentials.userPoolOnly(tokens: tokens)
                    let action = InformSessionRefreshed(credentials: credentials)
                    return .init(newState: .refreshed(credentials), actions: [action])
                }

                if case .refreshIdentityInfo(let tokens, _) = event.isRefreshSessionEvent {
                    let action = InitializeFetchAuthSessionWithUserPool(tokens: tokens)
                    return .init(newState: .fetchingAuthSessionWithUserPool(.notStarted, tokens),
                                 actions: [action])
                }
                return .from(oldState)

            case .refreshingUserPoolTokenWithIdentity(_, let identityID):
                if case .refreshedCognitoUserPool(let tokens) = event.isRefreshSessionEvent {
                    let credentials = AmplifyCredentials.userPoolOnly(tokens: tokens)
                    let action = InformSessionRefreshed(credentials: credentials)
                    return .init(newState: .refreshed(credentials), actions: [action])
                }
                if case .refreshIdentityInfo(let tokens, let provider) = event.isRefreshSessionEvent {
                    let action = FetchAuthAWSCredentials(loginsMap: provider.loginsMap,
                                                         identityID: identityID)
                    return .init(newState: .refreshingAWSCredentialsWithUserPoolTokens(
                        tokens,
                        identityID), actions: [action])
                }
                return .from(oldState)
            case .fetchingAuthSessionWithUserPool(let fetchSessionState, let tokens):
                if case .fetched(let identityID,
                                 let credentials) = event.isAuthorizationEvent {
                    let credentials = AmplifyCredentials.userPoolAndIdentityPool(
                        tokens: tokens,
                        identityID: identityID,
                        credentials: credentials)
                    let action = InformSessionRefreshed(credentials: credentials)
                    return .init(newState: .refreshed(credentials), actions: [action])
                }
                let resolver = FetchAuthSessionState.Resolver()
                let resolution = resolver.resolve(oldState: fetchSessionState, byApplying: event)
                return .init(newState: .fetchingAuthSessionWithUserPool(
                    resolution.newState,
                    tokens), actions: resolution.actions)

            case .refreshed:
                return .from(oldState)

            case .refreshingUnAuthAWSCredentials:
                if case .fetchedAWSCredentials(
                    let identityID,
                    let credentials) = event.isFetchSessionEvent {
                    let amplifyCredentials = AmplifyCredentials.identityPoolOnly(
                        identityID: identityID,
                        credentials: credentials)
                    return .init(newState: .refreshed(amplifyCredentials))
                }

                return .from(oldState)
            case .refreshingAWSCredentialsWithUserPoolTokens(let tokens, _):
                if case .fetchedAWSCredentials(
                    let identityID,
                    let credentials) = event.isFetchSessionEvent {
                    let amplifyCredentials = AmplifyCredentials.userPoolAndIdentityPool(
                        tokens: tokens,
                        identityID: identityID,
                        credentials: credentials)
                    let action = InformSessionRefreshed(credentials: amplifyCredentials)
                    return .init(newState: .refreshed(amplifyCredentials), actions: [action])
                }
                return .from(oldState)
            }
        }
    }

}
