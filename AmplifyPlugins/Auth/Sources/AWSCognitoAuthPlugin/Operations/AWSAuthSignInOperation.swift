//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import hierarchical_state_machine_swift

public typealias AmplifySignInOperation = AmplifyOperation<AuthSignInRequest, AuthSignInResult, AuthError>
typealias AWSAuthSignInOperationStateMachine = StateMachine<AuthState, AuthEnvironment>

public class AWSAuthSignInOperation: AmplifySignInOperation, AuthSignInOperation {

    let stateMachine: AWSAuthSignInOperationStateMachine
    var statelistenerToken: AWSAuthSignInOperationStateMachine.StateChangeListenerToken?

    init(_ request: AuthSignInRequest,
         stateMachine: AWSAuthSignInOperationStateMachine,
         resultListener: ResultListener?)
    {

        self.stateMachine = stateMachine
        super.init(categoryType: .auth,
                   eventName: HubPayload.EventName.Auth.signInAPI,
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
                self.doSignIn()
            }
        } onSubscribe: { }
    }

    func doSignIn() {
        var token: AWSAuthSignInOperationStateMachine.StateChangeListenerToken?
        token = stateMachine.listen { [weak self] in
            guard let self = self else {
                return
            }
            guard case .configured(let authNState, _) = $0 else {
                return
            }

            switch authNState {
            case .signedIn:
                self.dispatch(AuthSignInResult(nextStep: .done))
                if let token = token {
                    self.stateMachine.cancel(listenerToken: token)
                }
            case .error(_, let error):
                self.dispatch(AuthError.unknown("Some error", error))
                if let token = token {
                    self.stateMachine.cancel(listenerToken: token)
                }
            default:
                break
            }
        } onSubscribe: { }
        sendSignInEvent()
    }


    private func sendSignInEvent() {
        let signInData = SignInEventData(username: request.username, password: request.password)
        let event = AuthenticationEvent.init(eventType: .signInRequested(signInData))
        stateMachine.send(event)
    }

    private func dispatch(_ result: AuthSignInResult) {
        let asyncEvent = AWSAuthSignInOperation.OperationResult.success(result)
        dispatch(result: asyncEvent)
    }

    private func dispatch(_ error: AuthError) {
        let asyncEvent = AWSAuthSignInOperation.OperationResult.failure(error)
        dispatch(result: asyncEvent)
    }
}
