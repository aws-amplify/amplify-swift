//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import hierarchical_state_machine_swift

public extension FetchAuthSessionState {
    
    struct Resolver: StateMachineResolver {
        
        public var defaultState: FetchAuthSessionState = .determiningUserState
        
        public func resolve(oldState: FetchAuthSessionState,
                            byApplying event: StateMachineEvent) -> StateResolution<FetchAuthSessionState>
        {
            

            switch oldState {
            case .determiningUserState:
                guard let fetchAuthSessionEvent = isFetchAuthSessionEvent(event) else {
                    return .from(.determiningUserState)
                }
                return resolveDeterminingUserState(byApplying: fetchAuthSessionEvent,
                                                   from: oldState)

            case .fetchingUserPoolTokens(let userPoolTokenState):
                let fetchUserPoolTokenResolver = FetchUserPoolTokensState.Resolver()
                let fetchUserPoolTokenResolution = fetchUserPoolTokenResolver.resolve(
                    oldState: userPoolTokenState, byApplying: event)
                guard let fetchAuthSessionEvent = isFetchAuthSessionEvent(event) else {
                    let fetchAuthSessionState = FetchAuthSessionState.fetchingUserPoolTokens(
                        fetchUserPoolTokenResolution.newState)
                    return .init(newState: fetchAuthSessionState, commands: fetchUserPoolTokenResolution.commands)
                }
                return resolveFetchingUserTokensState(byApplying: fetchAuthSessionEvent,
                                                      from: oldState)
            case .fetchingIdentity(let fetchIdentityState):
                let fetchIdentityResolver = FetchIdentityState.Resolver()
                let fetchIdentityResolution = fetchIdentityResolver.resolve(
                    oldState:fetchIdentityState, byApplying: event)
                guard let fetchAuthSessionEvent = isFetchAuthSessionEvent(event) else {
                    let fetchAuthSessionState = FetchAuthSessionState.fetchingIdentity(
                        fetchIdentityResolution.newState)
                    return .init(newState: fetchAuthSessionState, commands: fetchIdentityResolution.commands)
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
                    return .init(newState: fetchAuthSessionState, commands: fetchAWSCredentialResolution.commands)
                }
                return resolveFetchingAWSCredentialsState(byApplying: fetchAuthSessionEvent,
                                                          from: oldState)
            case .sessionEstablished:
                return .from(oldState)
            default:
                return .from(oldState)
            }
        }
        
        private func resolveDeterminingUserState(
            byApplying fetchAuthSessionEvent: FetchAuthSessionEvent,
            from oldState: FetchAuthSessionState) -> StateResolution<FetchAuthSessionState> {

                switch fetchAuthSessionEvent.eventType {
                case .fetchUserPoolTokens:
                    let newState = FetchAuthSessionState.fetchingUserPoolTokens(FetchUserPoolTokensState.configuring)
                    let command = ConfigureUserPoolToken()
                    return .init(newState: newState, commands: [command])
                case .fetchIdentity:
                    let newState = FetchAuthSessionState.fetchingIdentity(FetchIdentityState.configuring)
                    let command = ConfigureFetchIdentity()
                    return .init(newState: newState, commands: [command])
                default:
                    return .from(oldState)
                }
        }

        private func resolveFetchingUserTokensState(
            byApplying fetchAuthSessionEvent: FetchAuthSessionEvent,
            from oldState: FetchAuthSessionState) -> StateResolution<FetchAuthSessionState> {
                
                switch fetchAuthSessionEvent.eventType {
                case .fetchIdentity:
                    let newState = FetchAuthSessionState.fetchingIdentity(FetchIdentityState.configuring)
                    let command = ConfigureFetchIdentity()
                    return .init(newState: newState, commands: [command])
                case .fetchedAuthSession:
                    let newState = FetchAuthSessionState.sessionEstablished
                    return .init(newState: newState, commands: [])
                default:
                    return .from(oldState)
                }
        }
        
        private func resolveFetchingIdentityState(
            byApplying fetchAuthSessionEvent: FetchAuthSessionEvent,
            from oldState: FetchAuthSessionState) -> StateResolution<FetchAuthSessionState> {
                
                switch fetchAuthSessionEvent.eventType {
                case .fetchAWSCredentials:
                    let newState = FetchAuthSessionState.fetchingAWSCredentials(FetchAWSCredentialsState.configuring)
                    let command = ConfigureFetchAWSCredentials()
                    return .init(newState: newState, commands: [command])
                default:
                    return .from(oldState)
                }
        }

        private func resolveFetchingAWSCredentialsState(
            byApplying fetchAuthSessionEvent: FetchAuthSessionEvent,
            from oldState: FetchAuthSessionState) -> StateResolution<FetchAuthSessionState> {
                
                switch fetchAuthSessionEvent.eventType {
                case .fetchedAuthSession:
                    let newState = FetchAuthSessionState.sessionEstablished
                    let command = AuthorizationSessionEstablished()
                    return .init(newState: newState, commands: [command])
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

