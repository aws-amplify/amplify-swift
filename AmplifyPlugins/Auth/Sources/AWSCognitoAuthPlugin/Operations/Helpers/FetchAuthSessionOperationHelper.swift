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
                invokeEvent(event, authStateMachine: authStateMachine, completion: completion)
            case .sessionEstablished(let credentials):

                switch credentials {

                case .userPoolOnly(tokens: let tokens):
                    if (tokens.doesExpire(in: 5)) {
                        let event = AuthorizationEvent(eventType: .refreshSession)
                        invokeEvent(event, authStateMachine: authStateMachine, completion: completion)
                    } else {
                        completion(.success(credentials.cognitoSession))
                    }

                case .identityPoolOnly(identityID: _, credentials: let awsCredentials):
                    if (awsCredentials.doesExpire(in: 5)) {
                        let event = AuthorizationEvent(eventType: .refreshSession)
                        invokeEvent(event, authStateMachine: authStateMachine, completion: completion)
                    } else {
                        completion(.success(credentials.cognitoSession))
                    }

                case .userPoolAndIdentityPool(tokens: let tokens,
                                              identityID: _,
                                              credentials: let awsCredentials):
                    if (awsCredentials.doesExpire(in: 5) || tokens.doesExpire(in: 5)) {
                        let event = AuthorizationEvent(eventType: .refreshSession)
                        invokeEvent(event, authStateMachine: authStateMachine, completion: completion)
                    } else {
                        completion(.success(credentials.cognitoSession))
                    }
                default:
                    let event = AuthorizationEvent(eventType: .refreshSession)
                    invokeEvent(event, authStateMachine: authStateMachine, completion: completion)
                }


            default:
                // TODO:  Add error handling
                fatalError()
            }
        }
    }

    func invokeEvent(_ event: StateMachineEvent,
                     authStateMachine: AuthStateMachine,
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

        } onSubscribe: {
            authStateMachine.send(event)
        }

    }

}
