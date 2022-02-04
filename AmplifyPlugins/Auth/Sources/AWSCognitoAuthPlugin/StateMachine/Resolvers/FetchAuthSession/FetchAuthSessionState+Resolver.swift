//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSPluginsCore
import Amplify

public extension FetchAuthSessionState {

    struct Resolver: StateMachineResolver {

        public var defaultState: FetchAuthSessionState = .initializingFetchAuthSession

        func resolve(oldState: FetchAuthSessionState,
                     byApplying event: StateMachineEvent) -> StateResolution<FetchAuthSessionState> {

            switch oldState {
            case .initializingFetchAuthSession:
                guard let fetchAuthSessionEvent = isFetchAuthSessionEvent(event) else {
                    return .from(.initializingFetchAuthSession)
                }
                return resolveInitializeFetchUserAuthSession(byApplying: fetchAuthSessionEvent,
                                                             from: oldState)

            case .fetchingUserPoolTokens(let userPoolTokenState):
                let fetchUserPoolTokenResolver = FetchUserPoolTokensState.Resolver()
                let fetchUserPoolTokenResolution = fetchUserPoolTokenResolver.resolve(
                    oldState: userPoolTokenState, byApplying: event)
                guard let fetchAuthSessionEvent = isFetchAuthSessionEvent(event) else {
                    let fetchAuthSessionState = FetchAuthSessionState.fetchingUserPoolTokens(
                        fetchUserPoolTokenResolution.newState)
                    return .init(newState: fetchAuthSessionState, actions: fetchUserPoolTokenResolution.actions)
                }
                return resolveFetchingUserTokensState(byApplying: fetchAuthSessionEvent,
                                                      from: oldState)
            case .fetchingIdentity(let fetchIdentityState):
                let fetchIdentityResolver = FetchIdentityState.Resolver()
                let fetchIdentityResolution = fetchIdentityResolver.resolve(
                    oldState: fetchIdentityState, byApplying: event)
                guard let fetchAuthSessionEvent = isFetchAuthSessionEvent(event) else {
                    let fetchAuthSessionState = FetchAuthSessionState.fetchingIdentity(
                        fetchIdentityResolution.newState)
                    return .init(newState: fetchAuthSessionState, actions: fetchIdentityResolution.actions)
                }
                return resolveFetchingIdentityState(byApplying: fetchAuthSessionEvent,
                                                    from: oldState)
            case .fetchingAWSCredentials(let awsCredentialState):
                let fetchAWSCredentialResolver = FetchAWSCredentialsState.Resolver()
                let fetchAWSCredentialResolution = fetchAWSCredentialResolver.resolve(
                    oldState: awsCredentialState, byApplying: event)
                guard let fetchAuthSessionEvent = isFetchAuthSessionEvent(event) else {
                    let fetchAuthSessionState = FetchAuthSessionState.fetchingAWSCredentials(
                        fetchAWSCredentialResolution.newState)
                    return .init(newState: fetchAuthSessionState, actions: fetchAWSCredentialResolution.actions)
                }
                return resolveFetchingAWSCredentialsState(byApplying: fetchAuthSessionEvent,
                                                          from: oldState)
            case .sessionEstablished:
                return .from(oldState)
            }
        }

        private func resolveInitializeFetchUserAuthSession(
            byApplying fetchAuthSessionEvent: FetchAuthSessionEvent,
            from oldState: FetchAuthSessionState) -> StateResolution<FetchAuthSessionState> {
            switch fetchAuthSessionEvent.eventType {
            case .fetchUserPoolTokens(let cognitoSession):
                let newState = FetchAuthSessionState.fetchingUserPoolTokens(FetchUserPoolTokensState.configuring)
                let action = ConfigureUserPoolToken(cognitoSession: cognitoSession)
                return .init(newState: newState, actions: [action])
            case .fetchIdentity(let cognitoSession):
                let newState = FetchAuthSessionState.fetchingIdentity(FetchIdentityState.configuring)
                let action = ConfigureFetchIdentity(cognitoSession: cognitoSession)
                return .init(newState: newState, actions: [action])
            default:
                return .from(oldState)
            }
        }

        private func resolveFetchingUserTokensState(
            byApplying fetchAuthSessionEvent: FetchAuthSessionEvent,
            from oldState: FetchAuthSessionState) -> StateResolution<FetchAuthSessionState> {
            guard case .fetchingUserPoolTokens = oldState else {
                return .from(oldState)
            }
            switch fetchAuthSessionEvent.eventType {
            case .fetchIdentity(let cognitoSession):
                let newState = FetchAuthSessionState.fetchingIdentity( FetchIdentityState.configuring)
                let action = ConfigureFetchIdentity(cognitoSession: cognitoSession)
                return .init(newState: newState, actions: [action])
            default:
                return .from(oldState)
            }
        }

        private func resolveFetchingIdentityState(
            byApplying fetchAuthSessionEvent: FetchAuthSessionEvent,
            from oldState: FetchAuthSessionState) -> StateResolution<FetchAuthSessionState> {
            guard case .fetchingIdentity = oldState else {
                return .from(oldState)
            }
            switch fetchAuthSessionEvent.eventType {
            case .fetchAWSCredentials(let cognitoSession):
                let newState = FetchAuthSessionState.fetchingAWSCredentials(FetchAWSCredentialsState.configuring)
                let action = ConfigureFetchAWSCredentials(cognitoSession: cognitoSession)
                return .init(newState: newState, actions: [action])
            default:
                return .from(oldState)
            }
        }

        private func resolveFetchingAWSCredentialsState(
            byApplying fetchAuthSessionEvent: FetchAuthSessionEvent,
            from oldState: FetchAuthSessionState) -> StateResolution<FetchAuthSessionState> {
            guard case .fetchingAWSCredentials = oldState else {
                return .from(oldState)
            }
            switch fetchAuthSessionEvent.eventType {
            case .fetchedAuthSession(let cognitoSession):
                let newState = FetchAuthSessionState.sessionEstablished
                let action = AuthorizationSessionEstablished(cognitoSession: cognitoSession)
                return .init(newState: newState, actions: [action])
            default:
                return .from(oldState)
            }
        }

        private func isFetchAuthSessionEvent(_ event: StateMachineEvent) -> FetchAuthSessionEvent? {
            guard let authEvent = event as? FetchAuthSessionEvent else {
                return nil
            }
            return authEvent
        }

    }
}
