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
                guard let authZEvent = event.isAuthorizationEvent else {
                    return .from(oldState)
                }
                return resolveNotConfigured(byApplying: authZEvent)

            case .configured:

                if let authNEvent = event.isAuthenticationEvent,
                   case .signInRequested = authNEvent {
                    return .init(newState: .signingIn)
                }

                if case .fetchUnAuthSession = event.isAuthorizationEvent {
                    let action = InitializeFetchUnAuthSession()
                    return .init(newState: .fetchingUnAuthSession(.notStarted), actions: [action])
                }

                return .from(oldState)

            case .sessionEstablished(let credentials):
                if let authNEvent = event.isAuthenticationEvent {
                    if case .signInRequested = authNEvent {
                        return .from(.signingIn)
                    } else if case .signOutRequested = authNEvent {
                        return .from(.signingOut)
                    }
                }

                if case .refreshSession = event.isAuthorizationEvent {
                    let action = InitializeRefreshSession(
                        existingCredentials: credentials)
                    let subState = RefreshSessionState.notStarted
                    return .init(newState: .refreshingSession(
                        existingCredentials: credentials,
                        subState), actions: [action])
                }

                if case .deleteUser = event.isDeleteUserEvent {
                    return .init(newState: .deletingUser)
                }

                return .from(oldState)

            case .signingIn:
                if let authEvent = event.isAuthenticationEvent {
                    switch authEvent {
                    case .signInCompleted(let signedInData):
                        let action = InitializeFetchAuthSessionWithUserPool(
                            signedInData: signedInData)
                        return .init(newState: .fetchingAuthSessionWithUserPool(.notStarted, signedInData),
                                     actions: [action])
                    case .error(let error):
                        return .init(newState: .error(AuthorizationError.service(error: error)))
                    case .cancelSignIn:
                        return .init(newState: .configured)
                    default: return .from(.signingIn)
                    }
                }
                return .from(.signingIn)

            case .signingOut:
                if let signOutEvent = event.isSignOutEvent,
                    case .signedOutSuccess = signOutEvent {
                    return .init(newState: .configured)
                }
                return .from(oldState)

            case .fetchingUnAuthSession(let fetchSessionState):

                if case .fetched(let identityID,
                                 let credentials) = event.isAuthorizationEvent {
                    let amplifyCredentials = AmplifyCredentials.identityPoolOnly(
                        identityID: identityID,
                        credentials: credentials)
                    let action = PersistCredentials(credentials: amplifyCredentials)
                    return .init(newState: .storingCredentials(amplifyCredentials),
                                 actions: [action])
                }

                if case .receivedSessionError(let error) = event.isAuthorizationEvent {
                    return .init(newState: .error(.sessionError(error, .noCredentials)))
                }

                if case .throwError(let error) = event.isAuthorizationEvent {
                    return .init(newState: .error(error))
                }

                let resolver = FetchAuthSessionState.Resolver()
                let resolution = resolver.resolve(oldState: fetchSessionState, byApplying: event)
                return .init(newState: .fetchingUnAuthSession(resolution.newState),
                             actions: resolution.actions)
            case .fetchingAuthSessionWithUserPool(let fetchSessionState, let signedInData):
                if case .fetched(let identityID,
                                 let credentials) = event.isAuthorizationEvent {
                    let amplifyCredentials = AmplifyCredentials.userPoolAndIdentityPool(
                        signedInData: signedInData,
                        identityID: identityID,
                        credentials: credentials)
                    let action = PersistCredentials(credentials: amplifyCredentials)
                    return .init(newState: .storingCredentials(amplifyCredentials),
                                 actions: [action])
                } else if case .receivedSessionError = event.isAuthorizationEvent {
                    // TODO: Handle session errors correctly and pass them back to the user
                    let amplifyCredentials = AmplifyCredentials.userPoolOnly(signedInData: signedInData)
                    let action = PersistCredentials(credentials: amplifyCredentials)
                    return .init(newState: .storingCredentials(amplifyCredentials),
                                 actions: [action])
                } else if case .throwError = event.isAuthorizationEvent {
                    // TODO: Handle session errors correctly and pass them back to the user
                    let amplifyCredentials = AmplifyCredentials.userPoolOnly(signedInData: signedInData)
                    let action = PersistCredentials(credentials: amplifyCredentials)
                    return .init(newState: .storingCredentials(amplifyCredentials),
                                 actions: [action])
                }

                let resolver = FetchAuthSessionState.Resolver()
                let resolution = resolver.resolve(oldState: fetchSessionState, byApplying: event)
                return .init(newState: .fetchingAuthSessionWithUserPool(resolution.newState, signedInData),
                             actions: resolution.actions)

            case .refreshingSession(let existingCredentials, let refreshState):
                if case .refreshed(let amplifyCredentials) = event.isAuthorizationEvent {
                    let action = PersistCredentials(credentials: amplifyCredentials)
                    return .init(newState: .storingCredentials(amplifyCredentials),
                                 actions: [action])
                }

                if case .receivedSessionError(let error) = event.isAuthorizationEvent {
                    return .init(newState: .error(.sessionError(error, existingCredentials)))
                }

                if case .throwError(let error) = event.isAuthorizationEvent {
                    return .init(newState: .error(error))
                }
                let resolver = RefreshSessionState.Resolver()
                let resolution = resolver.resolve(oldState: refreshState, byApplying: event)
                return .init(newState: .refreshingSession(
                    existingCredentials: existingCredentials,
                    resolution.newState), actions: resolution.actions)

            case .storingCredentials:
                if case .sessionEstablished(let credentials) = event.isAuthorizationEvent {
                    return .init(newState: .sessionEstablished(credentials))
                }
                return .from(oldState)

            case .error(let error):
                if let authNEvent = event.isAuthenticationEvent {
                    if case .signInRequested = authNEvent {
                        return .from(.signingIn)
                    } else if case .signOutRequested = authNEvent {
                        return .from(.signingOut)
                    } else if case .cancelSignIn = authNEvent {
                        return .from(.configured)
                    }
                }
                if case .fetchUnAuthSession = event.isAuthorizationEvent {
                    let action = InitializeFetchUnAuthSession()
                    return .init(newState: .fetchingUnAuthSession(.notStarted), actions: [action])
                }

                // If authorization is under session error, we try to refresh it again to see if
                // it can recover from the error.
                if case .refreshSession = event.isAuthorizationEvent,
                   case .sessionError(_, let credentials) = error {
                    let action = InitializeRefreshSession(
                        existingCredentials: credentials)
                    let subState = RefreshSessionState.notStarted
                    return .init(newState: .refreshingSession(
                        existingCredentials: credentials,
                        subState), actions: [action])
                }
                return .from(oldState)

            case .deletingUser:
                if case .userSignedOutAndDeleted = event.isDeleteUserEvent {
                    return .init(newState: .configured)
                }
                return .from(oldState)
            }

        }

        private func resolveNotConfigured(
            byApplying authorizationEvent: AuthorizationEvent.EventType
        ) -> StateResolution<StateType> {
            switch authorizationEvent {
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

    }
}
