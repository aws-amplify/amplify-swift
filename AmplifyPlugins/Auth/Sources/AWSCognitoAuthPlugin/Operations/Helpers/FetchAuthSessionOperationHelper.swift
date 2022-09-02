//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

class FetchAuthSessionOperationHelper {

    static let expiryBufferInSeconds = TimeInterval.seconds(2 * 60)

    typealias FetchAuthSessionCompletion = (Result<AuthSession, AuthError>) -> Void

    func fetch(_ authStateMachine: AuthStateMachine,
               forceRefresh: Bool = false) async throws -> AuthSession {
        let state = await authStateMachine.currentState
        guard case .configured(_, let authorizationState) = state  else {
            let message = "Auth state machine not in configured state: \(state)"
            let error = AuthError.invalidState(message, "", nil)
            throw error
        }

        switch authorizationState {
        case .configured:
            // If session has not been established, ask statemachine to invoke fetching
            // a fresh session.
            let event = AuthorizationEvent(eventType: .fetchUnAuthSession)
            await authStateMachine.send(event)
            return try await listenForSession(authStateMachine: authStateMachine)
        case .sessionEstablished(let credentials):

            switch credentials {

            case .userPoolOnly(signedInData: let data):
                if data.cognitoUserPoolTokens.doesExpire(in: Self.expiryBufferInSeconds) ||
                    forceRefresh {
                    let event = AuthorizationEvent(eventType: .refreshSession(forceRefresh))
                    await authStateMachine.send(event)
                    return try await listenForSession(authStateMachine: authStateMachine)
                } else {
                    return credentials.cognitoSession
                }

            case .identityPoolOnly(identityID: _, credentials: let awsCredentials):
                if awsCredentials.doesExpire(in: Self.expiryBufferInSeconds) ||
                    forceRefresh {
                    let event = AuthorizationEvent(eventType: .refreshSession(forceRefresh))
                    await authStateMachine.send(event)
                    return try await listenForSession(authStateMachine: authStateMachine)
                } else {
                   return credentials.cognitoSession
                }

            case .userPoolAndIdentityPool(signedInData: let data,
                                          identityID: _,
                                          credentials: let awsCredentials):
                if  data.cognitoUserPoolTokens.doesExpire(in: Self.expiryBufferInSeconds) ||
                        awsCredentials.doesExpire(in: Self.expiryBufferInSeconds) ||
                        forceRefresh {
                    let event = AuthorizationEvent(eventType: .refreshSession(forceRefresh))
                    await authStateMachine.send(event)
                    return try await listenForSession(authStateMachine: authStateMachine)
                } else {
                    return credentials.cognitoSession
                }

            case .identityPoolWithFederation(let federatedToken, let identityId, let awsCredentials):
                if awsCredentials.doesExpire() || forceRefresh {
                    let event = AuthorizationEvent.init(
                        eventType: .startFederationToIdentityPool(federatedToken, identityId))
                    await authStateMachine.send(event)
                    return try await listenForSession(authStateMachine: authStateMachine)
                } else {
                    return credentials.cognitoSession
                }

            case .noCredentials:
                let event = AuthorizationEvent(eventType: .refreshSession(forceRefresh))
                await authStateMachine.send(event)
                return try await listenForSession(authStateMachine: authStateMachine)
            }

        case .error(let error):
            if case .sessionExpired = error {
                let session = AuthCognitoSignedInSessionHelper.makeExpiredSignedInSession()
                return session
            } else if case .sessionError = error {
                let event = AuthorizationEvent(eventType: .refreshSession(forceRefresh))
                await authStateMachine.send(event)
                return try await listenForSession(authStateMachine: authStateMachine)
            } else {
                let event = AuthorizationEvent(eventType: .fetchUnAuthSession)
                await authStateMachine.send(event)
                return try await listenForSession(authStateMachine: authStateMachine)
            }

        default:
            return try await listenForSession(authStateMachine: authStateMachine)
        }
    }

    func listenForSession(authStateMachine: AuthStateMachine) async throws ->AuthSession {

        let stateSequences = await authStateMachine.listen()
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

        var isSignedIn = false
        if case .signedIn = authenticationState {
            isSignedIn = true
        }
        switch error {
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

}
