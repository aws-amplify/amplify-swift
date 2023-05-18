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

            if let authEvent = event.isAuthenticationEvent {
                switch authEvent {
                case .signInCompleted(let signedInData):
                    let action = InitializeFetchAuthSessionWithUserPool(
                        signedInData: signedInData)
                    return .init(
                        newState: .fetchingAuthSessionWithUserPool(.notStarted, signedInData),
                        actions: [action])
                case .error(let error):
                    return .init(newState: .error(AuthorizationError.service(error: error)))
                case .cancelSignIn:
                    return .init(newState: .configured)
                default: break
                }
            }

            switch oldState {
            case .notConfigured:
                guard let authZEvent = event.isAuthorizationEvent else {
                    return .from(oldState)
                }
                return resolveNotConfigured(byApplying: authZEvent)

            case .configured:

                if case .fetchUnAuthSession = event.isAuthorizationEvent {
                    let action = InitializeFetchUnAuthSession()
                    return .init(newState: .fetchingUnAuthSession(.notStarted), actions: [action])
                }

                if case .startFederationToIdentityPool(
                    let federatedToken, let identityId) = event.isAuthorizationEvent {

                    let action = InitializeFederationToIdentityPool(
                        federatedToken: federatedToken,
                        developerProvidedIdentityId: identityId)
                    return .init(
                        newState: .federatingToIdentityPool(
                            .notStarted,
                            federatedToken,
                            existingCredentials: .noCredentials),
                        actions: [action])
                }

                return .from(oldState)

            case .sessionEstablished(let credentials):
                if let authNEvent = event.isAuthenticationEvent {
                    if case .signOutRequested = authNEvent {
                        return .from(.signingOut(credentials))
                    } else if case .clearFederationToIdentityPool = authNEvent {
                        return .from(.clearingFederation)
                    }
                }

                if case .startFederationToIdentityPool(let federatedToken, let identityId) = event.isAuthorizationEvent {

                    let action = InitializeFederationToIdentityPool(
                        federatedToken: federatedToken,
                        developerProvidedIdentityId: identityId)
                    return .init(
                        newState: .federatingToIdentityPool(
                            .notStarted,
                            federatedToken,
                            existingCredentials: credentials),
                        actions: [action])
                }

                if case .refreshSession(let forceRefresh) = event.isAuthorizationEvent {
                    let action = InitializeRefreshSession(
                        existingCredentials: credentials,
                        isForceRefresh: forceRefresh)
                    let subState = RefreshSessionState.notStarted
                    return .init(newState: .refreshingSession(
                        existingCredentials: credentials,
                        subState), actions: [action])
                }

                if case .deleteUser = event.isDeleteUserEvent {
                    return .init(newState: .deletingUser)
                }

                return .from(oldState)

            case .federatingToIdentityPool(
                let fetchSessionState, let federatedToken, let credentials):

                if case .fetched(let identityID,
                                 let credentials) = event.isAuthorizationEvent {
                    let amplifyCredentials = AmplifyCredentials.identityPoolWithFederation(
                        federatedToken: federatedToken,
                        identityID: identityID,
                        credentials: credentials)
                    let action = PersistCredentials(credentials: amplifyCredentials)
                    return .init(newState: .storingCredentials(amplifyCredentials),
                                 actions: [action])
                }

                if case .receivedSessionError(let error) = event.isAuthorizationEvent {
                    return .init(newState: .error(.sessionError(error, credentials)))
                }

                if case .throwError(let error) = event.isAuthorizationEvent {
                    return .init(newState: .error(error))
                }

                let resolver = FetchAuthSessionState.Resolver()
                let resolution = resolver.resolve(oldState: fetchSessionState, byApplying: event)
                return .init(
                    newState: .federatingToIdentityPool(
                        resolution.newState,
                        federatedToken,
                        existingCredentials: credentials),
                    actions: resolution.actions)

            case .signingOut(let credentials):
                if let signOutEvent = event.isSignOutEvent,
                   case .signedOutSuccess = signOutEvent {
                    return .init(newState: .configured)
                }
                if let authenEvent = event.isAuthenticationEvent,
                   case .cancelSignOut = authenEvent {
                    if let credentials = credentials {
                        return .init(newState: .sessionEstablished(credentials))
                    } else {
                        return .init(newState: .configured)
                    }
                }
                return .from(oldState)

            case .clearingFederation:
                if let authenticationEvent = event.isAuthenticationEvent,
                   case .clearedFederationToIdentityPool = authenticationEvent {
                    return .init(newState: .configured)
                } else if let authenticationEvent = event.isAuthenticationEvent,
                          case .error(let authenticationError) = authenticationEvent {
                    return .init(newState: .error(AuthorizationError.service(error: authenticationError)))
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
                } else if case .receivedSessionError(let fetchError) = event.isAuthorizationEvent {
                    let amplifyCredentials = AmplifyCredentials.userPoolOnly(
                        signedInData: signedInData)

                    if case .noIdentityPool = fetchError {
                        let action = PersistCredentials(credentials: amplifyCredentials)
                        return .init(newState: .storingCredentials(amplifyCredentials),
                                     actions: [action])
                    }

                    let authorizationError = AuthorizationError.sessionError(
                        fetchError,
                        amplifyCredentials)
                    return .init(newState: .error(authorizationError))

                } else if case .throwError(let error) = event.isAuthorizationEvent {
                    let amplifyCredentials = AmplifyCredentials.userPoolOnly(
                        signedInData: signedInData)
                    let authorizationError = AuthorizationError.sessionError(
                        .service(error),
                        amplifyCredentials)
                    return .init(newState: .error(authorizationError))
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
                
                if case .throwError(let error) = event.isAuthorizationEvent {
                    return .init(newState: .error(error))
                }
                return .from(oldState)

            case .error(let error):
                var existingCredentials: AmplifyCredentials = .noCredentials
                if case .sessionError(_, let credentials) = error {
                    existingCredentials = credentials
                }

                if let authNEvent = event.isAuthenticationEvent {

                    switch authNEvent {
                    case .signInRequested:
                        return .from(.configured)
                    case .signOutRequested:
                        return .from(.signingOut(nil))
                    case .cancelSignIn:
                        return .from(.configured)
                    case .clearFederationToIdentityPool:
                        return .from(.clearingFederation)
                    default: break

                    }
                }
                if case .fetchUnAuthSession = event.isAuthorizationEvent {
                    let action = InitializeFetchUnAuthSession()
                    return .init(newState: .fetchingUnAuthSession(.notStarted), actions: [action])
                }

                // If authorization is under session error, we try to refresh it again to see if
                // it can recover from the error.
                if case .startFederationToIdentityPool(let federatedToken, let identityId) = event.isAuthorizationEvent {

                    let action = InitializeFederationToIdentityPool(
                        federatedToken: federatedToken,
                        developerProvidedIdentityId: identityId)
                    return .init(
                        newState: .federatingToIdentityPool(
                            .notStarted,
                            federatedToken,
                            existingCredentials: existingCredentials),
                        actions: [action])
                }

                // If authorization is under session error, we try to refresh it again to see if
                // it can recover from the error.
                if case .refreshSession(let forceRefresh) = event.isAuthorizationEvent,
                   case .sessionError(_, let credentials) = error {
                    let action = InitializeRefreshSession(
                        existingCredentials: credentials,
                        isForceRefresh: forceRefresh)
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
