//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

extension AuthenticationState {

    struct Resolver: StateMachineResolver {
        typealias StateType = AuthenticationState
        let defaultState = AuthenticationState.notConfigured

        init() { }

        func resolve(
            oldState: StateType,
            byApplying event: StateMachineEvent
        ) -> StateResolution<StateType> {
            switch oldState {
            case .notConfigured:
                guard let authEvent = event as? AuthenticationEvent else {
                    return .from(oldState)
                }
                return resolveNotConfigured(byApplying: authEvent)
            case .configured(let authConfig):
                guard let authEvent = event as? AuthenticationEvent else {
                    return .from(oldState)
                }
                return resolveConfigured(byApplying: authEvent, to: authConfig)
            case .signingOut(let authenticationConfiguration, let signOutState):
                return resolveSigningOutState(byApplying: event,
                                              to: signOutState,
                                              currentConfiguration: authenticationConfiguration)
            case .signedOut(let authenticationConfiguration, let signedOutData):
                if let authEvent = event as? AuthenticationEvent {
                    return resolveSignedOut(
                        byApplying: authEvent,
                        to: signedOutData,
                        currentConfiguration: authenticationConfiguration)
                } else if let signUpEvent = event as? SignUpEvent {
                    let resolver = SignUpState.Resolver()
                    let resolution = resolver.resolve(oldState: .notStarted, byApplying: signUpEvent)
                    let newState = AuthenticationState.signingUp(authenticationConfiguration, resolution.newState)
                    return .init(newState: newState, actions: resolution.actions)
                } else {
                    return .from(oldState)
                }
            case .signingUp:
                return resolveSigningUpState(oldState: oldState, event: event)
            case .signingIn:
                return resolveSigningInState(oldState: oldState, event: event)
            case .signedIn(let authenticationConfiguration, let signedInData):
                guard let authEvent = event as? AuthenticationEvent else {
                    return .from(oldState)
                }
                return resolveSignedIn(
                    byApplying: authEvent,
                    to: signedInData,
                    currentConfiguration: authenticationConfiguration
                )
            case .error:
                return .from(oldState)
            }
        }

        private func resolveNotConfigured(
            byApplying authEvent: AuthenticationEvent
        ) -> StateResolution<StateType> {

            switch authEvent.eventType {
            case .configure(let authConfig, let cognitoCredentials):
                let action = ConfigureAuthentication(configuration: authConfig, storedCredentials: cognitoCredentials)
                let resolution = StateResolution(
                    newState: AuthenticationState.configured(authConfig),
                    actions: [action]
                )
                return resolution
            default:
                return .from(.notConfigured)
            }
        }

        private func resolveConfigured(
            byApplying authEvent: AuthenticationEvent,
            to currentConfiguration: AuthConfiguration
        ) -> StateResolution<StateType> {
            switch authEvent.eventType {
            case .initializedSignedIn(let signedInData):
                return .from(.signedIn(currentConfiguration, signedInData))
            case .initializedSignedOut(let signedOutData):
                return .from(.signedOut(currentConfiguration, signedOutData))
            default:
                return .from(.configured(currentConfiguration))
            }
        }

        private func resolveSignedOut(
            byApplying authEvent: AuthenticationEvent,
            to currentSignedOutData: SignedOutData,
            currentConfiguration: AuthConfiguration
        ) -> StateResolution<StateType> {
            switch authEvent.eventType {
            case .signInRequested(let signInData):
                /// Initiate signInState notStarted
                /// Send action to check signIN event.
                ///
                let signInState = SignInState.signingInWithSRP(.notStarted, signInData)
                let action = StartSRPFlow(signInEventData: signInData)
                return StateResolution(
                    newState: AuthenticationState.signingIn(currentConfiguration, signInState),
                    actions: [action]
                )
            default:
                return .from(.signedOut(currentConfiguration, currentSignedOutData))
            }
        }

        private func resolveSignedIn(
            byApplying authEvent: AuthenticationEvent,
            to currentSignedInData: SignedInData,
            currentConfiguration: AuthConfiguration
        ) -> StateResolution<StateType> {
            switch authEvent.eventType {
            case .signOutRequested(let signOutEventData):
                let action = InitiateSignOut(signedInData: currentSignedInData,
                                             signOutEventData: signOutEventData)
                let signOutState = SignOutState.notStarted
                let resolution = StateResolution(
                    newState: AuthenticationState.signingOut(currentConfiguration, signOutState),
                    actions: [action]
                )
                return resolution

            default:
                return .from(.signedIn(currentConfiguration, currentSignedInData))
            }
        }

        private func resolveSigningUpState(oldState: AuthenticationState,
                                           event: StateMachineEvent)  -> StateResolution<StateType>
        {
            if let authEvent = event as? AuthenticationEvent,
               case .error(let error) = authEvent.eventType
            {
                return .from(.error(nil, error))
            }
            if let authEvent = event as? AuthenticationEvent,
               case .cancelSignUp(let config) = authEvent.eventType
            {
                let signedOutData = SignedOutData(lastKnownUserName: nil)
                return .from(.signedOut(config, signedOutData))
            }
            guard case .signingUp(let authConfiguration, let signUpState) = oldState else {
                return .from(oldState)
            }
            let resolver = SignUpState.Resolver()
            let resolution = resolver.resolve(oldState: signUpState, byApplying: event)
            let newState = AuthenticationState.signingUp(authConfiguration, resolution.newState)
            return .init(newState: newState, actions: resolution.actions)
        }

        private func resolveSigningInState(
            oldState: AuthenticationState,
            event: StateMachineEvent) -> StateResolution<StateType> {
                if let authEvent = event as? AuthenticationEvent,
                   case .error(let error) = authEvent.eventType {
                    return .from(.error(nil, error))
                }

                /// Move to signedOut state if cancelSignIn
                if let authEvent = event as? AuthenticationEvent,
                   case .cancelSignIn(let config) = authEvent.eventType {
                    let signedOutData = SignedOutData(lastKnownUserName: nil)
                    return .from(.signedOut(config, signedOutData))
                }

                guard case .signingIn(let authConfiguration, let signInState) = oldState else {
                    return .from(oldState)
                }

                /// Move to signedIn state if signin flow completed
                if let authEvent = event as? AuthenticationEvent,
                   case .signInCompleted(let signedInData) = authEvent.eventType {
                    return .init(newState: .signedIn(authConfiguration, signedInData))
                }

                let resolution = SignInState.Resolver().resolve(oldState: signInState,
                                                                   byApplying: event)
                return .init(newState: .signingIn(authConfiguration, resolution.newState),
                             actions: resolution.actions)

            }

        private func resolveSigningOutState(
            byApplying event: StateMachineEvent,
            to signOutState: SignOutState,
            currentConfiguration authConfig: AuthConfiguration
        ) -> StateResolution<StateType> {
            let resolver = SignOutState.Resolver()
            let resolution = resolver.resolve(oldState: signOutState, byApplying: event)
            switch resolution.newState {
            case .signedOut(let signedOutData):
                let newState = AuthenticationState.signedOut(authConfig, signedOutData)
                return .init(newState: newState, actions: resolution.actions)
            case .error(let error):
                let newState = AuthenticationState.error(authConfig, error)
                return .init(newState: newState, actions: resolution.actions)
            default:
                let newState = AuthenticationState.signingOut(authConfig, resolution.newState)
                return .init(newState: newState, actions: resolution.actions)
            }
        }
    }
}
