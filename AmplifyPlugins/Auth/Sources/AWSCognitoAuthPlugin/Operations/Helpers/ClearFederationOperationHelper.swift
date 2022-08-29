//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

struct ClearFederationOperationHelper {

    typealias ClearFederationCompletion = (Result<Void, AuthError>) -> Void

    func clearFederation(_ authStateMachine: AuthStateMachine,
                         completion: @escaping ClearFederationCompletion) {
        
        authStateMachine.getCurrentState { currentState in
            if case .configured(let authNState, let authZState) = currentState,
               case .federatedToIdentityPool = authNState,
               case .sessionEstablished = authZState {
                self.startClearingFederation(with: authStateMachine,
                                              completion: completion)
            } else {
                let authError = AuthError.invalidState(
                    "Clearing of federation failed.",
                    AuthPluginErrorConstants.invalidStateError, nil)
                completion(.failure(authError))
            }
        }
        
    }

    func startClearingFederation(
        with authStateMachine: AuthStateMachine,
        completion: @escaping ClearFederationCompletion) {
            var token: AuthStateMachine.StateChangeListenerToken?
            token = authStateMachine.listen { state in

                guard  case .configured(let authNState, _) = state else {
                    return
                }

                switch authNState {
                case .signedOut(_):
                    if let token = token {
                        authStateMachine.cancel(listenerToken: token)
                    }
                    completion(.success(()))
                case .error(let error):
                    if let token = token {
                        authStateMachine.cancel(listenerToken: token)
                    }
                    completion(.failure(error.authError))
                default:
                    break
                }

            } onSubscribe: {
                let event = AuthenticationEvent.init(eventType: .clearFederationToIdentityPool)
                authStateMachine.send(event)
            }

        }

}
