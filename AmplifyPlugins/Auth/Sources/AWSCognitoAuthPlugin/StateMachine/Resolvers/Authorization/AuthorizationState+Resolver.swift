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
                guard case .fetchUnAuthSession = isAuthorizationEvent(event)?.eventType else {
                    return .from(oldState)
                }
                let action = InitializeFetchUnAuthSession(storedCredentials: .noCredentials)
                return .init(newState: .fetchingAuthSession(.notStarted), actions: [action])
            case .sessionEstablished, .error:
                if let authenEvent = event as? AuthenticationEvent,
                   case .signInRequested = authenEvent.eventType {
                    return .from(.signingIn)
                }
                if case .fetchUnAuthSession = isAuthorizationEvent(event)?.eventType {

                    return .init(newState: .fetchingAuthSession(.notStarted))
                }
                return .from(oldState)

            case .signingIn:
                if let authEvent = event as? AuthenticationEvent {
                    switch authEvent.eventType {
//                    case .signInCompleted(let event):
//                        return resolveFetchAuthSessionEvent(storedCredentials: .noCredentials)
//                    case .cancelSignIn:
//                        return resolveFetchAuthSessionEvent(storedCredentials: .noCredentials)
                    default: return .from(.signingIn)
                    }
                }
                return .from(.signingIn)
            case .fetchingAuthSession(let fetchSessionState):

                if case .fetchedAuthSession(let credentials) = isAuthorizationEvent(event)?.eventType {

                    return .init(newState: .sessionEstablished(credentials))
                }

                let resolver = FetchAuthSessionState.Resolver()
                let resolution = resolver.resolve(oldState: fetchSessionState, byApplying: event)
                return .init(newState: .fetchingAuthSession(resolution.newState),
                             actions: resolution.actions)
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
            case .cachedCredentialsAvailable(let credentials):
                let action = ConfigureAuthorization()
                let resolution = StateResolution(
                    newState: AuthorizationState.sessionEstablished(credentials),
                    actions: [action]
                )
                return resolution
            case .throwError(let authorizationError):
                let action = InitializeAuthorizationConfiguration(storedCredentials: .noCredentials)
                let resolution = StateResolution(
                    newState: AuthorizationState.error(authorizationError),
                    actions: [action]
                )
                return resolution
            default:
                return .from(.notConfigured)
            }
        }

//        private func resolveFetchAuthSessionEvent(storedCredentials: AmplifyCredentials)
//        -> StateResolution<StateType> {
//            let action = InitializeFetchAuthSession(storedCredentials: storedCredentials)
//            let resolution = StateResolution(
//                newState: AuthorizationState.fetchingAuthSession(.initializingFetchAuthSession),
//                actions: [action]
//            )
//            return resolution
//        }

        private func isAuthorizationEvent(_ event: StateMachineEvent) -> AuthorizationEvent? {
            guard let authZEvent = event as? AuthorizationEvent else {
                return nil
            }
            return authZEvent
        }

    }
}
