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
            case .configured:
                guard let authZEvent = isAuthorizationEvent(event) else {
                    return .from(oldState)
                }
                return resolveConfigured(oldState: oldState, byApplying: authZEvent)
            case .fetchingAuthSession(let fetchAuthSessionState):
                let fetchAuthSessionStateResolver = FetchAuthSessionState.Resolver()
                let fetchAuthSessionResolution = fetchAuthSessionStateResolver.resolve(
                    oldState: fetchAuthSessionState, byApplying: event)
                guard case let .fetchedAuthSession(sessionData) = isAuthorizationEvent(event)?.eventType else {
                    let authorizationState = AuthorizationState.fetchingAuthSession(fetchAuthSessionResolution.newState)
                    return .init(newState: authorizationState, commands: fetchAuthSessionResolution.commands)
                }
                return .init(newState: AuthorizationState.sessionEstablished(sessionData))
            case .sessionEstablished:
                return .from(oldState)
            case .validatingSession:
                guard let authZEvent = isAuthorizationEvent(event) else {
                    return .from(oldState)
                }
                return resolveValidatingSession(oldState: oldState, byApplying: authZEvent)
            case .error:
                return .from(oldState)
            }
        }

        private func resolveNotConfigured(
            byApplying authorizationEvent: AuthorizationEvent
        ) -> StateResolution<StateType> {
            switch authorizationEvent.eventType {
            case .configure(let authConfiguration):
                let command = LoadPersistedAuthorization(authConfiguration: authConfiguration)
                let resolution = StateResolution(
                    newState: AuthorizationState.configured(authConfiguration),
                    commands: [command]
                )
                return resolution
            default:
                return .from(.notConfigured)
            }
        }

        private func resolveConfigured(
            oldState: StateType,
            byApplying authorizationEvent: AuthorizationEvent
        ) -> StateResolution<StateType> {
            switch authorizationEvent.eventType {
            case .fetchAuthSession(let authConfiguration):
                let command = DetermineUserState(authConfiguration: authConfiguration)
                let resolution = StateResolution(
                    newState: AuthorizationState.fetchingAuthSession(FetchAuthSessionState.determiningUserState),
                    commands: [command]
                )
                return resolution
            case .validateSession(let authConfiguration):
                let command = ValidateAuthorizationSession(authConfiguration: authConfiguration)
                let resolution = StateResolution(
                    newState: AuthorizationState.validatingSession,
                    commands: [command]
                )
                return resolution
            default:
                return .from(oldState)
            }
        }

        private func resolveValidatingSession(
            oldState: StateType,
            byApplying authorizationEvent: AuthorizationEvent
        ) -> StateResolution<StateType> {
            switch authorizationEvent.eventType {
            case .fetchAuthSession(let authConfiguration):
                let command = DetermineUserState(authConfiguration: authConfiguration)
                let resolution = StateResolution(
                    newState: AuthorizationState.fetchingAuthSession(FetchAuthSessionState.determiningUserState),
                    commands: [command]
                )
                return resolution
            case .sessionIsValid:
                //TODO: Correctly assign associated value
                return .init(newState: AuthorizationState.sessionEstablished(AuthorizationSessionData()))
            default:
                return .from(oldState)
            }
        }

        private func isAuthorizationEvent(_ event: StateMachineEvent) -> AuthorizationEvent? {
            guard let authZEvent = event as? AuthorizationEvent else {
                return nil
            }
            return authZEvent
        }

    }
}
