//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

class FetchAuthSessionOperationHelper: DefaultLogger {



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
            if case .sessionExpired = error {
                log.verbose("Session is expired")
                let session = AuthCognitoSignedInSessionHelper.makeExpiredSignedInSession()
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

            var event: AuthorizationEvent
            if forceRefresh || !credentials.areValid() {
                if case .identityPoolWithFederation(
                    let federatedToken,
                    let identityId,
                    _
                ) = credentials {
                    event = AuthorizationEvent(
                        eventType: .startFederationToIdentityPool(federatedToken, identityId)
                    )
                } else {
                    event = AuthorizationEvent(eventType: .refreshSession(forceRefresh))
                }
                await authStateMachine.send(event)
                return try await listenForSession(authStateMachine: authStateMachine)
            }
            return credentials.cognitoSession
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

    func sessionResultWithError(_ error: AuthorizationError,
                                authenticationState: AuthenticationState)
    throws -> AuthSession {
        log.verbose("Received error - \(error)")

        var isSignedIn = false
        if case .signedIn = authenticationState {
            isSignedIn = true
        }
        switch error {
        case .sessionError(let fetchError, let credentials):
            return try sessionResultWithFetchError(fetchError,
                                                   authenticationState: authenticationState,
                                                   existingCredentials: credentials)
        case .sessionExpired:
            let session = AuthCognitoSignedInSessionHelper.makeExpiredSignedInSession()
            return session
        default:
            let message = "Unknown error occurred"
            let error = AuthError.unknown(message)
            let session = AWSAuthCognitoSession(isSignedIn: isSignedIn,
                                                identityIdResult: .failure(error),
                                                awsCredentialsResult: .failure(error),
                                                cognitoTokensResult: .failure(error))
            return session
        }
    }

    func sessionResultWithFetchError(_ error: FetchSessionError,
                                     authenticationState: AuthenticationState,
                                     existingCredentials: AmplifyCredentials)
    throws -> AuthSession {

        var isSignedIn = false
        if case .signedIn = authenticationState {
            isSignedIn = true
        }

        switch error {

        case .notAuthorized, .noCredentialsToRefresh:
            if !isSignedIn {
                return AuthCognitoSignedOutSessionHelper.makeSessionWithNoGuestAccess()
            }

        case .service(let error):
            if let authError = (error as? AuthErrorConvertible)?.authError {
                let session = AWSAuthCognitoSession(isSignedIn: isSignedIn,
                                                    identityIdResult: .failure(authError),
                                                    awsCredentialsResult: .failure(authError),
                                                    cognitoTokensResult: .failure(authError))
                return session
            }
        default: break

        }
        let message = "Unknown error occurred"
        let error = AuthError.unknown(message)
        let session = AWSAuthCognitoSession(isSignedIn: isSignedIn,
                                            identityIdResult: .failure(error),
                                            awsCredentialsResult: .failure(error),
                                            cognitoTokensResult: .failure(error))
        return session
    }

}
