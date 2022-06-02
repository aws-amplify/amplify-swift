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

                if case .refreshCognitoUserPool(let tokens,
                                                let identityID) = isRefreshSessionEvent(event) {
                    let action = RefreshUserPoolTokens(exitingTokens: tokens,
                                                       identityID: identityID)
                    return .init(newState: .refreshingUserPoolToken(tokens, identityID),
                                 actions: [action])
                }

                if case .refreshUnAuthAWSCredentials(let identityID) = isRefreshSessionEvent(event) {
                    let provider = UnAuthLoginsMapProvider()
                    let action = FetchAuthAWSCredentials(loginsMap: provider.loginsMap,
                                                         identityID: identityID)
                    return .init(newState: .refreshingUnAuthAWSCredentials(identityID),
                                 actions: [action])
                }

                if case .refreshAWSCredentialsWithUserPool(
                    let identityID,
                    let tokens,
                    let provider) = isRefreshSessionEvent(event) {
                    let action = FetchAuthAWSCredentials(loginsMap: provider.loginsMap,
                                                         identityID: identityID)
                    return .init(newState: .refreshingAWSCredentialsWithUserPoolTokens(
                        tokens,
                        identityID
                    ), actions: [action])
                }
                return .from(oldState)

            case .refreshingUserPoolToken:

                if case .refreshedCognitoUserPool(let tokens) = isRefreshSessionEvent(event) {
                    return .from(.refreshed(.userPoolOnly(tokens: tokens)))
                }

                if case .fetchIdentityInfo(let tokens) = isRefreshSessionEvent(event) {
                    let action = InitializeFetchAuthSessionWithUserPool(tokens: tokens)
                    return .init(newState: .fetchingAuthSessionWithUserPool(.notStarted, tokens),
                                 actions: [action])
                }
                if case .refreshAWSCredentialsWithUserPool(
                    let identityID,
                    let tokens,
                    let provider) = isRefreshSessionEvent(event) {
                    let action = FetchAuthAWSCredentials(loginsMap: provider.loginsMap,
                                                         identityID: identityID)
                    return .init(newState: .refreshingAWSCredentialsWithUserPoolTokens(
                        tokens,
                        identityID),
                                 actions: [action])
                }
                return .from(oldState)

            case .fetchingAuthSessionWithUserPool(let fetchSessionState, let tokens):
                if case .fetched(let identityID,
                                 let credentials) = isAuthorizationEvent(event) {
                    let amplifyCredentials = AmplifyCredentials.userPoolAndIdentityPool(
                        tokens: tokens,
                        identityID: identityID,
                        credentials: credentials)
                    return .init(newState: .refreshed(amplifyCredentials))
                }
                let resolver = FetchAuthSessionState.Resolver()
                let resolution = resolver.resolve(oldState: fetchSessionState, byApplying: event)
                return .init(newState: .fetchingAuthSessionWithUserPool(resolution.newState, tokens),
                             actions: resolution.actions)

            case .refreshed:
                return .from(oldState)

            case .refreshingUnAuthAWSCredentials:
                if case .fetchedAWSCredentials(
                    let identityID,
                    let credentials) = isFetchSessionEvent(event) {
                    let amplifyCredentials = AmplifyCredentials.identityPoolOnly(
                        identityID: identityID,
                        credentials: credentials)
                    return .init(newState: .refreshed(amplifyCredentials))
                }

                return .from(oldState)
            case .refreshingAWSCredentialsWithUserPoolTokens(let tokens, _):
                if case .fetchedAWSCredentials(
                    let identityID,
                    let credentials) = isFetchSessionEvent(event) {
                    let amplifyCredentials = AmplifyCredentials.userPoolAndIdentityPool(
                        tokens: tokens,
                        identityID: identityID,
                        credentials: credentials)
                    return .init(newState: .refreshed(amplifyCredentials))
                }
                return .from(oldState)
            }
        }

        private func isRefreshSessionEvent(_ event: StateMachineEvent)
        -> RefreshSessionEvent.EventType? {
            guard let refreshSessionEvent = (event as? RefreshSessionEvent)?.eventType else {
                return nil
            }
            return refreshSessionEvent
        }

        private func isAuthorizationEvent(_ event: StateMachineEvent)
        -> AuthorizationEvent.EventType? {
            guard let authZEvent = (event as? AuthorizationEvent)?.eventType else {
                return nil
            }
            return authZEvent
        }

        private func isFetchSessionEvent(_ event: StateMachineEvent)
        -> FetchAuthSessionEvent.EventType? {
            guard let refreshSessionEvent = (event as? FetchAuthSessionEvent)?.eventType else {
                return nil
            }
            return refreshSessionEvent
        }
    }

}
