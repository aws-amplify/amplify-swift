//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public typealias AmplifyFetchSessionOperation = AmplifyOperation<AuthFetchSessionRequest, AuthSession, AuthError>
typealias AWSFetchAuthSessionOperationStateMachine = StateMachine<AuthState, AuthEnvironment>

public class AWSAuthFetchSessionOperation: AmplifyFetchSessionOperation, AuthFetchSessionOperation {
    
    let stateMachine: AWSAuthSignInOperationStateMachine
    
    init(_ request: AuthFetchSessionRequest,
         stateMachine: AWSAuthSignInOperationStateMachine,
         resultListener: ResultListener?) {
        
        self.stateMachine = stateMachine
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
        doInitialize()
    }
    
    func doInitialize() {
        var token: AWSAuthSignInOperationStateMachine.StateChangeListenerToken?
        token = stateMachine.listen { [weak self] in
            guard let self = self else {
                return
            }
            if case .configured = $0 {
                if let token = token {
                    self.stateMachine.cancel(listenerToken: token)
                }
                self.fetchAuthSession()
            }
        } onSubscribe: { }
    }
    
    func fetchAuthSession() {
        var token: AWSAuthSignInOperationStateMachine.StateChangeListenerToken?
        token = stateMachine.listen { [weak self] in
            guard let self = self else {
                return
            }
            guard case .configured(_ , let authZState) = $0 else {
                return
            }
            
            switch authZState {
            case .sessionEstablished(let session):
                self.dispatch(session)
                if let token = token {
                    self.stateMachine.cancel(listenerToken: token)
                }
            case .error(let authorizationError):
                self.dispatch(authorizationError.authError)
                if let token = token {
                    self.stateMachine.cancel(listenerToken: token)
                }
            default:
                break
            }
            
        } onSubscribe: { }
        sendFetchAuthSessionEvent()
    }
    
    private func sendFetchAuthSessionEvent() {
        let event = AuthorizationEvent.init(eventType: .fetchAuthSession)
        stateMachine.send(event)
    }
    
    private func dispatch(_ result: AuthSession) {
        let asyncEvent = AWSAuthFetchSessionOperation.OperationResult.success(result)
        dispatch(result: asyncEvent)
    }
    
    private func dispatch(_ error: AuthError) {
        let asyncEvent = AWSAuthFetchSessionOperation.OperationResult.failure(error)
        dispatch(result: asyncEvent)
    }
    
}
