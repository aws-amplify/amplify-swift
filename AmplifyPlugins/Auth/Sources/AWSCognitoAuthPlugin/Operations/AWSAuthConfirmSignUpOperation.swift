//// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

import ClientRuntime
import AWSCognitoIdentityProvider

public typealias AmplifyConfirmSignUpOperation = AmplifyOperation<AuthConfirmSignUpRequest, AuthSignUpResult, AuthError>
typealias AWSAuthConfirmSignUpOperationStateMachine = StateMachine<AuthState, AuthEnvironment>

public class AWSAuthConfirmSignUpOperation: AmplifyConfirmSignUpOperation, AuthConfirmSignUpOperation {

    let stateMachine: AWSAuthConfirmSignUpOperationStateMachine
    var statelistenerToken: AWSAuthSignUpOperationStateMachine.StateChangeListenerToken?

    init(_ request: AuthConfirmSignUpRequest,
         stateMachine: AWSAuthSignUpOperationStateMachine,
         resultListener: ResultListener?) {

        self.stateMachine = stateMachine
        super.init(categoryType: .auth,
                   eventName: HubPayload.EventName.Auth.signUpAPI,
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

            if case .configured(let authNState, _) = $0 {
                guard case .signedOut = authNState else {
                    self.cancelListener(token)
                    let message = "Auth state must be signed out to confirm signup"
                    self.dispatch(message: message, error: .invalidState(message: message))
                    self.finish()
                    return
                }
                self.cancelListener(token)
                self.doConfirmSignUp()
            }
        } onSubscribe: { }
    }

    func doConfirmSignUp() {
        var token: AWSAuthSignUpOperationStateMachine.StateChangeListenerToken?
        token = stateMachine.listen { [weak self] state in
            guard let self = self else {
                return
            }
            guard case .configured(let authNState, _) = state else {
                return
            }
            defer {
                self.finish()
            }

            switch authNState {
            case .signingUp(_ , let signUpState):
                self.cancelListener(token)

                switch signUpState {
                case .signedUp:
                    self.dispatch(result: .success(AuthSignUpResult(.done)))
                case .error(let error):
                    self.dispatch(message: "Failed while confirming signup", error: error)
                default:
                    self.dispatch(message: "Failed while confirming signup", error: .invalidState(message: "\(signUpState.type)"))
                }
            case .error(_, let error):
                self.cancelListener(token)
                self.dispatch(message: "Failed while confirming signing up", error: .service(error: error))
            default:
                self.cancelListener(token)
            }
        } onSubscribe: { }
        sendConfirmSignUpEvent()
    }

    private func sendConfirmSignUpEvent() {
        let confirmSignUpData = ConfirmSignUpEventData(username: request.username, confirmationCode: request.code)
        let event = SignUpEvent(eventType: .confirmSignUp(confirmSignUpData))
        stateMachine.send(event)
    }

    private func dispatch(message: String, error: SignUpError) {
        let result = AWSAuthSignUpOperation.OperationResult.failure(.unknown(message, error))
        dispatch(result: result)
    }

    private func cancelListener(_ token: AWSAuthSignUpOperationStateMachine.StateChangeListenerToken?) {
        if let token = token {
            stateMachine.cancel(listenerToken: token)
        }
    }

}
