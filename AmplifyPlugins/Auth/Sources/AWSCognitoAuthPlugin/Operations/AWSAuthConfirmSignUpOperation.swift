//// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

import ClientRuntime
import AWSCognitoIdentityProvider

public typealias AmplifyConfirmSignUpOperation = AmplifyOperation<
    AuthConfirmSignUpRequest,
    AuthSignUpResult,
    AuthError>

public class AWSAuthConfirmSignUpOperation: AmplifyConfirmSignUpOperation,
                                            AuthConfirmSignUpOperation {

    let stateMachine: AuthStateMachine
    var statelistenerToken: AuthStateMachineToken?

    init(_ request: AuthConfirmSignUpRequest,
         stateMachine: AuthStateMachine,
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
        var token: AuthStateMachineToken?
        token = stateMachine.listen { [weak self] in
            guard let self = self else {
                return
            }

            if case .configured(let authNState, _) = $0 {
                switch authNState {
                case .signedOut, .signingUp:
                    self.cancelListener(token)
                    self.doConfirmSignUp()
                default:
                    self.cancelListener(token)
                    let message = "Auth state must be signed out to confirm signup"
                    self.dispatch(message: message, error: .invalidState(message: message))
                    self.finish()
                }
            }
        } onSubscribe: { }
    }

    func doConfirmSignUp() {
        var token: AuthStateMachineToken?
        token = stateMachine.listen { [weak self] state in
            guard let self = self else {
                return
            }
            guard case .configured(let authNState, _) = state else {
                return
            }

            switch authNState {
            case .signingUp(_ , let signUpState):
                switch signUpState {
                case .signedUp:
                    self.dispatch(result: .success(AuthSignUpResult(.done)))
                    self.cancelListener(token)
                    self.finish()
                case .error(let error):
                    self.dispatch(message: "Failed while confirming signup", error: error)
                    self.cancelListener(token)
                    self.finish()
                default:
                    break
                }
            default:
                break
            }
        } onSubscribe: { [weak self] in
            guard let self = self else { return }
            self.sendConfirmSignUpEvent()
        }
    }

    private func sendConfirmSignUpEvent() {
        let confirmSignUpData = ConfirmSignUpEventData(
            username: request.username,
            confirmationCode: request.code)
        let event = SignUpEvent(eventType: .confirmSignUp(confirmSignUpData))
        stateMachine.send(event)
    }

    private func dispatch(message: String, error: SignUpError) {
        let result = AWSAuthSignUpOperation.OperationResult.failure(.unknown(message, error))
        dispatch(result: result)
    }

    private func cancelListener(_ token: AuthStateMachineToken?) {
        if let token = token {
            stateMachine.cancel(listenerToken: token)
        }
    }
}
