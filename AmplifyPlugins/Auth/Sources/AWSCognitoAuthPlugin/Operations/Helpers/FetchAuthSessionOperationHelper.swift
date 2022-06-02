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
                // TODO: Validate the credentials, if it is invalid invoke a refresh
                if (credentials.areUserPoolTokenValid &&
                    credentials.areAWSCredentialsValid) {
                    completion(.success(credentials.cognitoSession))
                } else {
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
