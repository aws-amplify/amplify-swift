//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation


public extension AuthorizationState {

    struct Resolver: StateMachineResolver {
        public typealias StateType = AuthorizationState
        public let defaultState = AuthorizationState.notConfigured

        public init() { }

        func resolve(
            oldState: StateType,
            byApplying event: StateMachineEvent
        ) -> StateResolution<StateType> {

            switch oldState {
            case .notConfigured:
                guard let authZEvent = isAuthorizationEvent(event) else {
                    return .from(oldState)
                }
                return resolveNotConfigured(byApplying: authZEvent)
            case .configured, .sessionEstablished, .error:
                guard case .fetchAuthSession = isAuthorizationEvent(event)?.eventType else {
                    return .from(oldState)
                }
                return resolveFetchAuthSessionEvent()
            case .fetchingAuthSession(let fetchAuthSessionState):
                let fetchAuthSessionStateResolver = FetchAuthSessionState.Resolver()
                let fetchAuthSessionResolution = fetchAuthSessionStateResolver.resolve(
                    oldState: fetchAuthSessionState, byApplying: event)
                guard case let .fetchedAuthSession(sessionData) = isAuthorizationEvent(event)?.eventType else {
                    let authorizationState = AuthorizationState.fetchingAuthSession(fetchAuthSessionResolution.newState)
                    return .init(newState: authorizationState, actions: fetchAuthSessionResolution.actions)
                }
                return .init(newState: AuthorizationState.sessionEstablished(sessionData))
            }
        }

        private func resolveNotConfigured(
            byApplying authorizationEvent: AuthorizationEvent
        ) -> StateResolution<StateType> {
            switch authorizationEvent.eventType {
            case .configure(let authConfiguration):
                let action = LoadPersistedAuthorization(authConfiguration: authConfiguration)
                let resolution = StateResolution(
                    newState: AuthorizationState.configured,
                    actions: [action]
                )
                return resolution
            case .throwError(let authorizationError):
                return .init(newState: AuthorizationState.error(authorizationError))
            default:
                return .from(.notConfigured)
            }
        }
        
        private func resolveFetchAuthSessionEvent() -> StateResolution<StateType> {
            let action = InitializeFetchAuthSession()
            let resolution = StateResolution(
                newState: AuthorizationState.fetchingAuthSession(FetchAuthSessionState.initializingFetchAuthSession),
                actions: [action]
            )
            return resolution
        }

        private func isAuthorizationEvent(_ event: StateMachineEvent) -> AuthorizationEvent? {
            guard let authZEvent = event as? AuthorizationEvent else {
                return nil
            }
            return authZEvent
        }

    }
}
