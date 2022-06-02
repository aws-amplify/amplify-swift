//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

struct FetchAuthSessionOperationHelper {

    typealias FetchAuthSessionCompletion = (Result<AuthSession, AuthError>) -> Void

    func fetch(_ authStateMachine: AuthStateMachine,
               completion: @escaping FetchAuthSessionCompletion) {
        authStateMachine.getCurrentState { state in
            guard case .configured(_, let authorizationState) = state  else {
                let message = "Auth state machine not in configured state: \(state)"
                let error = AuthError.invalidState(message, "", nil)
                completion(.failure(error))
                return
            }

            switch authorizationState {
            case .configured:
                // If session has not been established, ask statemachine to invoke fetching
                // a fresh session. 
                let event = AuthorizationEvent(eventType: .fetchUnAuthSession)
                authStateMachine.send(event)

            case .sessionEstablished(let credentials):

                switch credentials {

                case .userPoolOnly(tokens: let tokens):
                    if (tokens.doesExpire(in: 5)) {
                        let event = AuthorizationEvent(eventType: .refreshSession)
                        authStateMachine.send(event)
                    } else {
                        completion(.success(credentials.cognitoSession))
                    }

                case .identityPoolOnly(identityID: _, credentials: let awsCredentials):
                    if (awsCredentials.doesExpire(in: 5)) {
                        let event = AuthorizationEvent(eventType: .refreshSession)
                        authStateMachine.send(event)
                    } else {
                        completion(.success(credentials.cognitoSession))
                    }

                case .userPoolAndIdentityPool(tokens: let tokens,
                                              identityID: _,
                                              credentials: let awsCredentials):
                    if ( tokens.doesExpire(in: 5) || awsCredentials.doesExpire(in: 10 * 60)) {
                        let event = AuthorizationEvent(eventType: .refreshSession)
                        authStateMachine.send(event)
                    } else {
                        completion(.success(credentials.cognitoSession))
                    }
                default:
                    let event = AuthorizationEvent(eventType: .refreshSession)
                    authStateMachine.send(event)
                }

            case .refreshingSession, .fetchingUnAuthSession, .fetchingAuthSessionWithUserPool:
                self.listenForSession(authStateMachine: authStateMachine, completion: completion)
            default:
                // TODO:  Add error handling
                fatalError()
            }
        }
    }

    func listenForSession(authStateMachine: AuthStateMachine,
                     completion: @escaping FetchAuthSessionCompletion) {

        _ = authStateMachine.listen { state in
            guard case .configured(_, let authorizationState) = state  else {
                let message = "Auth state machine not in configured state: \(state)"
                let error = AuthError.invalidState(message, "", nil)
                completion(.failure(error))
                return
            }

            switch authorizationState {
            case .sessionEstablished(let credentials):
                completion(.success(credentials.cognitoSession))
            case .error(_):
                let message = "Auth state machine not in configured state: \(state)"
                let error = AuthError.invalidState(message, "", nil)
                completion(.failure(error))
            default: break;
            }

        } onSubscribe: {}

    }

}
