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
                if let authEvent = event as? AuthenticationEvent {
                    return resolveNotConfigured(byApplying: authEvent)
                } else if let authZEvent = event.isAuthorizationEvent,
                        case .startFederationToIdentityPool = authZEvent {
                    return .init(newState: .federatingToIdentityPool)
                } else {
                    return .from(oldState)
                }
            case .configured:
                if let authEvent = event as? AuthenticationEvent {
                    return resolveConfigured(byApplying: authEvent)
                } else {
                    return .from(oldState)
                }
            case .signingOut(let signOutState):
                return resolveSigningOutState(byApplying: event,
                                              to: signOutState)
            case .signedOut(let signedOutData):
                if let authEvent = event as? AuthenticationEvent {
                    return resolveSignedOut( byApplying: authEvent, to: signedOutData)
                } else if let authZEvent = event.isAuthorizationEvent,
                          case .startFederationToIdentityPool = authZEvent {
                    return .init(newState: .federatingToIdentityPool)
                } else {
                    return .from(oldState)
                }
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

            case .federatedToIdentityPool:
                if let authEvent = event as? AuthenticationEvent,
                   case .clearFederationToIdentityPool = authEvent.eventType {
                    return .init(
                        newState: .clearingFederation,
                        actions: [
                            ClearFederationToIdentityPool()
                        ])
                } else if let authZEvent = event.isAuthorizationEvent,
                          case .startFederationToIdentityPool = authZEvent {
                    return .init(newState: .federatingToIdentityPool)
                } else {
                    return .from(oldState)
                }

            case .federatingToIdentityPool:
                guard let authZEvent = event.isAuthorizationEvent else {
                    return .from(oldState)
                }

                switch authZEvent {
                case .sessionEstablished:
                    return .init(newState: .federatedToIdentityPool)
                case .throwError(let authZError):
                    let authNError = AuthenticationError.service(
                        message: "Authorization error: \(authZError)")
                    return .init(newState: .error(authNError))
                case .receivedSessionError(let sessionError):
                    let authNError = AuthenticationError.service(
                        message: "Session error: \(sessionError)")
                    return .init(newState: .error(authNError))
                default:
                    return .from(oldState)
                }

            case .clearingFederation:
                if let authEvent = event as? AuthenticationEvent,
                   case .clearedFederationToIdentityPool = authEvent.eventType {
                    return .init(newState: .signedOut(SignedOutData(lastKnownUserName: nil)))
                } else if let authEvent = event as? AuthenticationEvent,
                    case .error(let authenticationError) = authEvent.eventType {
                    return .init(newState: .error(authenticationError))
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
                } else if let authZEvent = event.isAuthorizationEvent,
                         case .startFederationToIdentityPool = authZEvent {
                    return .init(newState: .federatingToIdentityPool)
                } else if let authEvent = event as? AuthenticationEvent,
                   case .clearFederationToIdentityPool = authEvent.eventType {
                    return .init(
                        newState: .clearingFederation,
                        actions: [
                            ClearFederationToIdentityPool()
                        ])
                } else {
                    return .from(oldState)
                }
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
            case .initializedFederated:
                return .from(.federatedToIdentityPool)
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
            case .signOutRequested(let eventData):
                let action = InitiateGuestSignOut(signOutEventData: eventData)
                let signOutState = SignOutState.notStarted
                return .init(
                    newState: AuthenticationState.signingOut(signOutState),
                    actions: [action]
                )
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

        private func resolveSigningInState(oldState: AuthenticationState,
                                           event: StateMachineEvent) -> StateResolution<StateType> {
            if let authEvent = event as? AuthenticationEvent,
               case .error(let error) = authEvent.eventType {
                return .init(newState: .error(error))
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
            if let authenEvent = event.isAuthenticationEvent,
               case .cancelSignOut(let data) = authenEvent {

                if let signedInData = data {
                    return .from(.signedIn(signedInData))
                } else {
                    return .from(.signedOut(.init()))
                }
            }
            let resolver = SignOutState.Resolver()
            let resolution = resolver.resolve(oldState: signOutState, byApplying: event)
            switch resolution.newState {
            case .signedOut(let signedOutData):
                let newState = AuthenticationState.signedOut(signedOutData)
                return .init(newState: newState, actions: resolution.actions)
            default:
                let newState = AuthenticationState.signingOut(resolution.newState)
                return .init(newState: newState, actions: resolution.actions)
            }
        }
    }
}
