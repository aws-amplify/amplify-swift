//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import hierarchical_state_machine_swift

public typealias Resolution = StateResolution<AuthState>

public extension AuthState {

    struct Resolver: StateMachineResolver {

        public typealias StateType = AuthState

        public var defaultState: AuthState = .notConfigured

        public func resolve(oldState: AuthState, byApplying event: StateMachineEvent) -> Resolution {
            switch oldState {
            case .notConfigured:
                guard case .configureAuth(let authConfiguration) = isAuthEvent(event)?.eventType else {
                    return .from(.notConfigured)
                }
                let newState = AuthState.configuring
                let command = InitializeAuthConfiguration(authConfiguration: authConfiguration)
                return .init(newState: newState, commands: [command])

            case .configuring:
                let authEvent = isAuthEvent(event)?.eventType
                if case .configureAuthentication(let authConfiguration) = authEvent {
                    let newState = AuthState.configuringAuthentication(.notConfigured)
                    let command = InitializeAuthenticationConfiguration(configuration: authConfiguration)
                    return .init(newState: newState, commands: [command])

                } else if case .configureAuthorization(let authConfiguration) = authEvent {
                    let newState = AuthState.configuringAuthorization(.notConfigured, .unconfigured)
                    let command = InitializeAuthorizationConfiguration(configuration: authConfiguration)
                    return .init(newState: newState, commands: [command])
                }
                return .from(oldState)

            case .configuringAuthentication(let authenticationState):
                let resolver = AuthenticationState.Resolver()
                let resolution = resolver.resolve(oldState: authenticationState, byApplying: event)
                guard case .authenticationConfigured(let authConfiguration) = isAuthEvent(event)?.eventType else {
                    let newState = AuthState.configuringAuthentication(resolution.newState)
                    return .init(newState: newState, commands: resolution.commands)
                }

                let newState = AuthState.configuringAuthorization(resolution.newState, .unconfigured)
                let command = InitializeAuthorizationConfiguration(configuration: authConfiguration)
                return .init(newState: newState, commands: resolution.commands + [command])


            case .configuringAuthorization(let authenticationState, let authorizationState):
                let authenticationResolver = AuthenticationState.Resolver()
                let authorizationResolver = AuthorizationState.Resolver()
                let authNresolution = authenticationResolver.resolve(oldState: authenticationState, byApplying: event)
                let authZresolution = authorizationResolver.resolve(oldState: authorizationState, byApplying: event)
                guard case .authorizationConfigured = isAuthEvent(event)?.eventType else {
                    let newState = AuthState.configuringAuthorization(authNresolution.newState,
                                                                      authZresolution.newState)
                    return .init(newState: newState, commands: authNresolution.commands + authZresolution.commands)
                }

                let newState = AuthState.configured(authNresolution.newState, authZresolution.newState)
                return .init(newState: newState, commands: authNresolution.commands + authZresolution.commands)

            case .configured(let authenticationState, let authorizationState):
                let authenticationResolver = AuthenticationState.Resolver()
                let authorizationResolver = AuthorizationState.Resolver()
                let authNresolution = authenticationResolver.resolve(oldState: authenticationState, byApplying: event)
                let authZresolution = authorizationResolver.resolve(oldState: authorizationState, byApplying: event)
                let newState = AuthState.configured(authNresolution.newState, authZresolution.newState)
                return .init(newState: newState, commands: authNresolution.commands + authZresolution.commands)
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

    }
}
