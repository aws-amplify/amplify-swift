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
            case .configured:
                guard let authEvent = event as? AuthenticationEvent else {
                    return .from(oldState)
                }
                return resolveConfigured(byApplying: authEvent)
            case .signingOut(let signOutState):
                return resolveSigningOutState(byApplying: event,
                                              to: signOutState)
            case .signedOut(let signedOutData):
                if let authEvent = event as? AuthenticationEvent {
                    return resolveSignedOut( byApplying: authEvent, to: signedOutData)
                } else if let signUpEvent = event as? SignUpEvent {
                    let resolver = SignUpState.Resolver()
                    let resolution = resolver.resolve(oldState: .notStarted, byApplying: signUpEvent)
                    let newState = AuthenticationState.signingUp(resolution.newState)
                    return .init(newState: newState, actions: resolution.actions)
                } else {
                    return .from(oldState)
                }
            case .signingUp:
                return resolveSigningUpState(oldState: oldState, event: event)
            case .signingIn:
                return resolveSigningInState(oldState: oldState, event: event)
            case .signedIn(let signedInData):
                if let authEvent = event as? AuthenticationEvent {
                    return resolveSignedIn(byApplying: authEvent, to: signedInData)
                } else if let deleteUserEvent = event as? DeleteUserEvent {
                    return resolveDeleteUser(
                        byApplying: deleteUserEvent,
                        to: .notStarted,
                        with: signedInData)
                } else {
                    return .from(oldState)
                }

            case .deletingUser(let signedInData, let deleteUserState):
                if case let .userSignedOutAndDeleted(signedOutData) = event.isDeleteUserEvent {
                    return .init(newState: AuthenticationState.signedOut(signedOutData))
                } else {
                    return resolveDeleteUser(
                        byApplying: event,
                        to: deleteUserState,
                        with: signedInData)
                }

            case .error:
                if let authEvent = event as? AuthenticationEvent,
                   case .cancelSignIn = authEvent.eventType {
                    return .init(newState: .signedOut(SignedOutData()))
                }
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
                    newState: AuthenticationState.configured,
                    actions: [action]
                )
                return resolution
            default:
                return .from(.notConfigured)
            }
        }

        private func resolveConfigured(
            byApplying authEvent: AuthenticationEvent
        ) -> StateResolution<StateType> {
            switch authEvent.eventType {
            case .initializedSignedIn(let signedInData):
                return .from(.signedIn(signedInData))
            case .initializedSignedOut(let signedOutData):
                return .from(.signedOut(signedOutData))
            default:
                return .from(.configured)
            }
        }

        private func resolveSignedOut(
            byApplying authEvent: AuthenticationEvent,
            to currentSignedOutData: SignedOutData
        ) -> StateResolution<StateType> {
            switch authEvent.eventType {
            case .signInRequested(let signInData):
                let action = InitializeSignInFlow(signInEventData: signInData)
                return .init(newState: .signingIn(.notStarted), actions: [action])
            default:
                return .from(.signedOut(currentSignedOutData))
            }
        }

        private func resolveSignedIn(
            byApplying authEvent: AuthenticationEvent,
            to currentSignedInData: SignedInData
        ) -> StateResolution<StateType> {
            switch authEvent.eventType {
            case .signOutRequested(let signOutEventData):
                let action = InitiateSignOut(signedInData: currentSignedInData,
                                             signOutEventData: signOutEventData)
                let signOutState = SignOutState.notStarted
                let resolution = StateResolution(
                    newState: AuthenticationState.signingOut(signOutState),
                    actions: [action]
                )
                return resolution

            default:
                return .from(.signedIn(currentSignedInData))
            }
        }

        private func resolveDeleteUser(
            byApplying deleteUserEvent: StateMachineEvent,
            to oldState: DeleteUserState,
            with signedInData: SignedInData) -> StateResolution<StateType> {
                let resolver = DeleteUserState.Resolver(signedInData: signedInData)
                let resolution = resolver.resolve(oldState: oldState, byApplying: deleteUserEvent)
                let newState = AuthenticationState.deletingUser(signedInData, resolution.newState)
                return .init(newState: newState, actions: resolution.actions)
            }

        private func resolveSigningUpState(oldState: AuthenticationState,
                                           event: StateMachineEvent)  -> StateResolution<StateType> {
            if let authEvent = event as? AuthenticationEvent,
               case .error(let error) = authEvent.eventType {
                return .from(.error(error))
            }
            if let authEvent = event as? AuthenticationEvent,
               case .cancelSignUp = authEvent.eventType {
                let signedOutData = SignedOutData(lastKnownUserName: nil)
                return .from(.signedOut(signedOutData))
            }
            guard case .signingUp(let signUpState) = oldState else {
                return .from(oldState)
            }
            let resolver = SignUpState.Resolver()
            let resolution = resolver.resolve(oldState: signUpState, byApplying: event)
            let newState = AuthenticationState.signingUp(resolution.newState)
            return .init(newState: newState, actions: resolution.actions)
        }

        private func resolveSigningInState(oldState: AuthenticationState,
                                           event: StateMachineEvent) -> StateResolution<StateType> {
            if let authEvent = event as? AuthenticationEvent,
               case .error(let error) = authEvent.eventType {
                let action = CancelSignIn()
                return .init(newState: .error(error), actions: [action])
            }
            /// Move to signedOut state if cancelSignIn
            if let authEvent = event as? AuthenticationEvent,
               case .cancelSignIn = authEvent.eventType {
                let signedOutData = SignedOutData(lastKnownUserName: nil)
                return .from(.signedOut(signedOutData))
            }

            guard case .signingIn(let signInState) = oldState else {
                return .from(oldState)
            }

            // Move to signedIn state if signin flow completed
            if let authEvent = event as? AuthenticationEvent,
               case .signInCompleted(let signedInData) = authEvent.eventType {
                return .init(newState: .signedIn(signedInData))
            }

            let resolution = SignInState.Resolver().resolve(oldState: signInState,
                                                            byApplying: event)
            return .init(newState: .signingIn(resolution.newState), actions: resolution.actions)

        }

        private func resolveSigningOutState(
            byApplying event: StateMachineEvent,
            to signOutState: SignOutState
        ) -> StateResolution<StateType> {
            let resolver = SignOutState.Resolver()
            let resolution = resolver.resolve(oldState: signOutState, byApplying: event)
            switch resolution.newState {
            case .signedOut(let signedOutData):
                let newState = AuthenticationState.signedOut(signedOutData)
                return .init(newState: newState, actions: resolution.actions)
            case .error(let error):
                let newState = AuthenticationState.error(error)
                return .init(newState: newState, actions: resolution.actions)
            default:
                let newState = AuthenticationState.signingOut(resolution.newState)
                return .init(newState: newState, actions: resolution.actions)
            }
        }
    }
}
