//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation


typealias Resolution = StateResolution<AuthState>

extension AuthState {

    struct Resolver: StateMachineResolver {

        typealias StateType = AuthState

        var defaultState: AuthState = .notConfigured

        func resolve(oldState: AuthState, byApplying event: StateMachineEvent) -> Resolution {
            switch oldState {
            case .notConfigured:
                guard case .configureAuth(let authConfiguration) = isAuthEvent(event)?.eventType else {
                    return .from(.notConfigured)
                }
                let newState = AuthState.configuringCredentialStore(CredentialStoreState.notConfigured)
                let action = InitializeCredentialStoreConfiguration(authConfiguration: authConfiguration)
                return .init(newState: newState, actions: [action])

            case .configuringCredentialStore(let credentialStoreState):
                let credentialStoreResolver = CredentialStoreState.Resolver()
                let resolution = credentialStoreResolver.resolve(oldState: credentialStoreState, byApplying: event)

                if let _ = isCredentialStoreEvent(event) {
                    let newState = AuthState.configuringCredentialStore(resolution.newState)
                    return .init(newState: newState, actions: resolution.actions)
                }

                let authEvent = isAuthEvent(event)?.eventType
                if case .configureAuthentication(let authConfiguration) = authEvent {
                    let newState = AuthState.configuringAuthentication(.notConfigured)
                    let action = InitializeAuthenticationConfiguration(configuration: authConfiguration)
                    return .init(newState: newState, actions: [action])

                } else if case .configureAuthorization(let authConfiguration) = authEvent {
                    let newState = AuthState.configuringAuthorization(.notConfigured, .notConfigured)
                    let action = InitializeAuthorizationConfiguration(configuration: authConfiguration)
                    return .init(newState: newState, actions: [action])
                }
                return .from(oldState)

            case .configuringAuthentication(let authenticationState):
                let resolver = AuthenticationState.Resolver()
                let resolution = resolver.resolve(oldState: authenticationState, byApplying: event)
                guard case .authenticationConfigured(let authConfiguration) = isAuthEvent(event)?.eventType else {
                    let newState = AuthState.configuringAuthentication(resolution.newState)
                    return .init(newState: newState, actions: resolution.actions)
                }

                let newState = AuthState.configuringAuthorization(resolution.newState, .notConfigured)
                let action = InitializeAuthorizationConfiguration(configuration: authConfiguration)
                return .init(newState: newState, actions: resolution.actions + [action])

            case .configuringAuthorization(let authenticationState, let authorizationState):
                let authenticationResolver = AuthenticationState.Resolver()
                let authorizationResolver = AuthorizationState.Resolver()
                let authNresolution = authenticationResolver.resolve(oldState: authenticationState, byApplying: event)
                let authZresolution = authorizationResolver.resolve(oldState: authorizationState, byApplying: event)
                guard case .authorizationConfigured = isAuthEvent(event)?.eventType else {
                    let newState = AuthState.configuringAuthorization(authNresolution.newState,
                                                                      authZresolution.newState)
                    return .init(newState: newState, actions: authNresolution.actions + authZresolution.actions)
                }

                let newState = AuthState.configured(authNresolution.newState, authZresolution.newState)
                return .init(newState: newState, actions: authNresolution.actions + authZresolution.actions)

            case .configured(let authenticationState, let authorizationState):
                let authenticationResolver = AuthenticationState.Resolver()
                let authorizationResolver = AuthorizationState.Resolver()
                let authNresolution = authenticationResolver.resolve(oldState: authenticationState, byApplying: event)
                let authZresolution = authorizationResolver.resolve(oldState: authorizationState, byApplying: event)
                let newState = AuthState.configured(authNresolution.newState, authZresolution.newState)
                return .init(newState: newState, actions: authNresolution.actions + authZresolution.actions)
            }

        }

        private func isAuthEvent(_ event: StateMachineEvent) -> AuthEvent? {
            guard let authEvent = event as? AuthEvent else {
                return nil
            }
            return authEvent
        }

        private func isAuthenticationEvent(_ event: StateMachineEvent) -> AuthenticationEvent? {
            guard let authNEvent = event as? AuthenticationEvent else {
                return nil
            }
            return authNEvent
        }

        private func isCredentialStoreEvent(_ event: StateMachineEvent) -> CredentialStoreEvent? {
            guard let credentialStore = event as? CredentialStoreEvent else {
                return nil
            }
            return credentialStore
        }

    }
}
