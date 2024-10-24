//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

class FetchAuthSessionOperationHelper {

    typealias FetchAuthSessionCompletion = (Result<AuthSession, AuthError>) -> Void

    func fetch(_ authStateMachine: AuthStateMachine,
               forceRefresh: Bool = false) async throws -> AuthSession {
        let state = await authStateMachine.currentState
        guard case .configured(_, let authorizationState) = state  else {
            let message = "Auth state machine not in configured state: \(state)"
            let error = AuthError.invalidState(message, "", nil)
            throw error
        }

        log.verbose("Fetching current state")
        switch authorizationState {
        case .configured:
            // If session has not been established, ask statemachine to invoke fetching
            // a fresh session.
            log.verbose("No session found, fetching unauth session")
            let event = AuthorizationEvent(eventType: .fetchUnAuthSession)
            await authStateMachine.send(event)
            return try await listenForSession(authStateMachine: authStateMachine)

        case .sessionEstablished(let credentials):
            log.verbose("Session exists, checking validity")
            return try await refreshIfRequired(
                existingCredentials: credentials,
                authStateMachine: authStateMachine,
                forceRefresh: forceRefresh)

        case .error(let error):
            if case .sessionExpired(let error) = error {
                log.verbose("Session is expired")
                let session = AuthCognitoSignedInSessionHelper.makeExpiredSignedInSession(
                    underlyingError: error)
                return session
            } else if case .sessionError(_, let credentials) = error {
                return try await refreshIfRequired(
                    existingCredentials: credentials,
                    authStateMachine: authStateMachine,
                    forceRefresh: forceRefresh)
            } else {
                log.verbose("Session is in error state \(error)")
                let event = AuthorizationEvent(eventType: .fetchUnAuthSession)
                await authStateMachine.send(event)
                return try await listenForSession(authStateMachine: authStateMachine)
            }

        default:
            return try await listenForSession(authStateMachine: authStateMachine)
        }
    }

    func refreshIfRequired(
        existingCredentials credentials: AmplifyCredentials,
        authStateMachine: AuthStateMachine,
        forceRefresh: Bool) async throws -> AuthSession {

            if forceRefresh || !credentials.areValid() {
                var event: AuthorizationEvent
                switch credentials {
                case .identityPoolWithFederation(let federatedToken, let identityId, _):
                    event = AuthorizationEvent(eventType: .startFederationToIdentityPool(federatedToken, identityId))
                case .noCredentials:
                    event = AuthorizationEvent(eventType: .fetchUnAuthSession)
                case .userPoolOnly, .identityPoolOnly, .userPoolAndIdentityPool:
                    event = AuthorizationEvent(eventType: .refreshSession(forceRefresh))
                }
                await authStateMachine.send(event)
                return try await listenForSession(authStateMachine: authStateMachine)
            } else {
                return credentials.cognitoSession
            }
        }

    func listenForSession(authStateMachine: AuthStateMachine) async throws -> AuthSession {

        let stateSequences = await authStateMachine.listen()
        log.verbose("Waiting for session to establish")
        for await state in stateSequences {
            guard case .configured(let authenticationState, let authorizationState) = state  else {
                let message = "Auth state machine not in configured state: \(state)"
                let error = AuthError.invalidState(message, "", nil)
                throw error
            }

            switch authorizationState {
            case .sessionEstablished(let credentials):
                return credentials.cognitoSession
            case .error(let authorizationError):
                return try sessionResultWithError(
                    authorizationError,
                    authenticationState: authenticationState)
            default: continue
            }
        }
        throw AuthError.invalidState("Could not fetch session due to internal error",
                                     "Auth plugin is in an invalid state")
    }

    func sessionResultWithError(
        _ error: AuthorizationError,
        authenticationState: AuthenticationState
    ) throws -> AuthSession {
        log.verbose("Received fetch auth session error - \(error)")

        var isSignedIn = false
        var authError: AuthError = error.authError

        if case .signedIn = authenticationState {
            isSignedIn = true
        }

        switch error {
        case .sessionError(let fetchError, _):
            if (fetchError == .notAuthorized || fetchError == .noCredentialsToRefresh) && !isSignedIn {
                return AuthCognitoSignedOutSessionHelper.makeSessionWithNoGuestAccess()
            } else {
                authError = fetchError.authError
            }
        case .sessionExpired(let error):
            let session = AuthCognitoSignedInSessionHelper.makeExpiredSignedInSession(
                underlyingError: error)
            return session
        default:
            break
        }

        let session = AWSAuthCognitoSession(
            isSignedIn: isSignedIn,
            identityIdResult: .failure(authError),
            awsCredentialsResult: .failure(authError),
            cognitoTokensResult: .failure(authError))
        return session
    }
}

extension FetchAuthSessionOperationHelper: DefaultLogger { }
