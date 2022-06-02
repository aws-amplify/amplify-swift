//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public typealias AmplifyFetchSessionOperation = AmplifyOperation<AuthFetchSessionRequest, AuthSession, AuthError>

public class AWSAuthFetchSessionOperation: AmplifyFetchSessionOperation, AuthFetchSessionOperation {

    let authStateMachine: AuthStateMachine
    let credentialStoreStateMachine: CredentialStoreStateMachine
    private let fetchSessionHelper: FetchAuthSessionOperationHelper

    init(_ request: AuthFetchSessionRequest,
         authStateMachine: AuthStateMachine,
         credentialStoreStateMachine: CredentialStoreStateMachine,
         resultListener: ResultListener?) {

        self.authStateMachine = authStateMachine
        self.credentialStoreStateMachine = credentialStoreStateMachine
        fetchSessionHelper = FetchAuthSessionOperationHelper(
            authStateMachine: authStateMachine,
            credentialStoreStateMachine: credentialStoreStateMachine)
        super.init(categoryType: .auth,
                   eventName: HubPayload.EventName.Auth.fetchSessionAPI,
                   request: request,
                   resultListener: resultListener)
    }

    override public func main() {
        if isCancelled {
            finish()
            return
        }

        authStateMachine.getCurrentState { [weak self] state in
            guard case .configured(_, let authorizationState) = state  else {
                let message = "Credential store state machine not in idle state: \(state)"
                let error = AuthError.invalidState(message, "", nil)
                self?.dispatch(error)
            }

            switch authorizationState {
            case .configured:
                // If session has not been established, ask statemachine to invoke fetching
                // fresh session.
                let event = AuthorizationEvent(eventType: .fetchUnAuthSession)
                self?.authStateMachine.send(event)
            case .sessionEstablished(let credentials):
                // TODO: Validate the credentials, if it is invalid invoke a refresh
                self?.dispatch(credentials.cognitoSession)
            default:
                fatalError()
            }

        }
    }

    func listenAuthEvents() {
        _ = authStateMachine.listen { [weak self] state in
            guard case .configured(_, let authorizationState) = state  else {
                return
            }

            switch authorizationState {
                case .sessionEstablished(let credentials):
                    self?.dispatch(credentials.cognitoSession)
                default: break
            }

        } onSubscribe: {

        }

    }

    private func dispatch(_ result: AuthSession) {
        let asyncEvent = AWSAuthFetchSessionOperation.OperationResult.success(result)
        dispatch(result: asyncEvent)
        finish()
    }

    private func dispatch(_ error: AuthError) {
        let asyncEvent = AWSAuthFetchSessionOperation.OperationResult.failure(error)
        dispatch(result: asyncEvent)
        finish()
    }

}
