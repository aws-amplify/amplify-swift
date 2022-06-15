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

                if let authenEvent = event as? AuthenticationEvent,
                   case .signInRequested = authenEvent.eventType {
                    return .init(newState: .signingIn)
                }

                if case .fetchUnAuthSession = event.isAuthorizationEvent {
                    let action = InitializeFetchUnAuthSession()
                    return .init(newState: .fetchingUnAuthSession(.notStarted), actions: [action])
                }

                return .from(oldState)

            case .sessionEstablished(let credentials):
                if let authenEvent = event as? AuthenticationEvent,
                   case .signInRequested = authenEvent.eventType {
                    return .from(.signingIn)
                }

                if case .refreshSession = event.isAuthorizationEvent {
                    let action = InitializeRefreshSession(existingCredentials: credentials,
                                                          isForceRefresh: false)
                    let subState = RefreshSessionState.notStarted
                    return .init(newState: .refreshingSession(
                        existingCredentials: credentials,
                        subState), actions: [action])
                }

                return .from(oldState)

            case .signingIn:
                if let authEvent = event as? AuthenticationEvent {
                    switch authEvent.eventType {
                    case .signInCompleted(let event):
                        let action = InitializeFetchAuthSessionWithUserPool(
                            tokens: event.cognitoUserPoolTokens)
                        let tokens = event.cognitoUserPoolTokens
                        return .init(newState: .fetchingAuthSessionWithUserPool(.notStarted, tokens),
                                     actions: [action])
                    case .cancelSignIn:
                        let action = InitializeFetchUnAuthSession()
                        return .init(newState: .fetchingUnAuthSession(.notStarted), actions: [action])
                    default: return .from(.signingIn)
                    }
                }
                return .from(.signingIn)
            case .fetchingUnAuthSession(let fetchSessionState):

                if case .fetched(let identityID,
                                 let credentials) = event.isAuthorizationEvent {
                    let amplifyCredentials = AmplifyCredentials.identityPoolOnly(
                        identityID: identityID,
                        credentials: credentials)
                    return .init(newState: .waitingToStore(amplifyCredentials))
                }

                let resolver = FetchAuthSessionState.Resolver()
                let resolution = resolver.resolve(oldState: fetchSessionState, byApplying: event)
                return .init(newState: .fetchingUnAuthSession(resolution.newState),
                             actions: resolution.actions)
            case .fetchingAuthSessionWithUserPool(let fetchSessionState, let tokens):
                if case .fetched(let identityID,
                                 let credentials) = event.isAuthorizationEvent {
                    let amplifyCredentials = AmplifyCredentials.userPoolAndIdentityPool(
                        tokens: tokens,
                        identityID: identityID,
                        credentials: credentials)
                    return .init(newState: .waitingToStore(amplifyCredentials))
                }

                let resolver = FetchAuthSessionState.Resolver()
                let resolution = resolver.resolve(oldState: fetchSessionState, byApplying: event)
                return .init(newState: .fetchingAuthSessionWithUserPool(resolution.newState, tokens),
                             actions: resolution.actions)

            case .refreshingSession(let existingCredentials, let refreshState):
                let resolver = RefreshSessionState.Resolver()
                let resolution = resolver.resolve(oldState: refreshState, byApplying: event)
                return .init(newState: .refreshingSession(
                    existingCredentials: existingCredentials,
                    resolution.newState), actions: resolution.actions)

            case .waitingToStore:
                if case .receivedCachedCredentials(let credentials) = event.isAuthEvent {
                    return .init(newState: .sessionEstablished(credentials))
                }
                return .from(oldState)

            case .error:
                if case .fetchUnAuthSession = event.isAuthorizationEvent {
                    let action = InitializeFetchUnAuthSession()
                    return .init(newState: .fetchingUnAuthSession(.notStarted), actions: [action])
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
