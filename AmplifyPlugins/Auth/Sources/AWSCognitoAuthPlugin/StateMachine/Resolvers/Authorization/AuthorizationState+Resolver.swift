//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension AuthorizationState {

    struct Resolver: StateMachineResolver {
        typealias StateType = AuthorizationState
        let defaultState = AuthorizationState.notConfigured

        init() { }

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
            case .configured:
                guard case .fetchAuthSession(let cognitoCredentials) = isAuthorizationEvent(event)?.eventType else {
                    return .from(oldState)
                }
                return resolveFetchAuthSessionEvent(storedCredentials: cognitoCredentials)
            case .sessionEstablished, .error:
                guard case .configure = isAuthorizationEvent(event)?.eventType else {
                    return .from(oldState)
                }
                return .init(newState: .configured)
            case .fetchingAuthSession(let fetchAuthSessionState):
                let fetchAuthSessionStateResolver = FetchAuthSessionState.Resolver()
                let fetchAuthSessionResolution = fetchAuthSessionStateResolver.resolve(
                    oldState: fetchAuthSessionState, byApplying: event)
                guard case let .fetchedAuthSession(sessionData) = isAuthorizationEvent(event)?.eventType else {
                    let authorizationState = AuthorizationState.fetchingAuthSession(fetchAuthSessionResolution.newState)
                    return .init(newState: authorizationState, actions: fetchAuthSessionResolution.actions)
                }
                // Move the Authorization back to configured
                let action = InitializeAuthorizationConfiguration()
                let resolution = StateResolution(
                    newState: AuthorizationState.sessionEstablished(sessionData),
                    actions: [action]
                )
                return resolution
            }
        }

        private func resolveNotConfigured(
            byApplying authorizationEvent: AuthorizationEvent
        ) -> StateResolution<StateType> {
            switch authorizationEvent.eventType {
            case .configure:
                let action = ConfigureAuthorization()
                let resolution = StateResolution(
                    newState: AuthorizationState.configured,
                    actions: [action]
                )
                return resolution
            case .throwError(let authorizationError):
                let action = InitializeAuthorizationConfiguration()
                let resolution = StateResolution(
                    newState: AuthorizationState.error(authorizationError),
                    actions: [action]
                )
                return resolution
            default:
                return .from(.notConfigured)
            }
        }

        private func resolveFetchAuthSessionEvent(storedCredentials: AmplifyCredentials?) -> StateResolution<StateType> {
            let action = InitializeFetchAuthSession(storedCredentials: storedCredentials)
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
