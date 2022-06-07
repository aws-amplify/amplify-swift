//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
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
        stateMachine.getCurrentState { [weak self] in
            guard case .configured(let authenticationState, _) = $0 else {
                return
            }

            switch authenticationState {
            case .signedOut, .signingUp:
                self?.doConfirmSignUp()
            default:
                let message = "Auth state must be signed out to signup"
                let error = AuthError.invalidState(message, "", nil)
                self?.dispatch(error)
                self?.finish()
            }
        }
     }

    func doConfirmSignUp() {
        var token: AuthStateMachineToken?
        token = stateMachine.listen { [weak self] state in
            guard let self = self else {
                return
            }
            guard self.isCancelled == false else {
                self.finish()
                return
            }
            guard case .configured(let authNState, _) = state else {
                return
            }

            switch authNState {
            case .signingUp(let signUpState):
                switch signUpState {
                case .signedUp:
                    self.dispatch(result: .success(AuthSignUpResult(.done)))
                    self.cancelListener(token)
                    self.finish()
                case .error(let error):
                    self.dispatch(error.authError)
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
        guard !request.code.isEmpty else {
               let error = AuthError.validation(
                AuthPluginErrorConstants.confirmSignUpCodeError.field,
                AuthPluginErrorConstants.confirmSignUpCodeError.errorDescription,
                AuthPluginErrorConstants.confirmSignUpCodeError.recoverySuggestion, nil)
               dispatch(error)
            finish()
            return
        }
        let confirmSignUpData = ConfirmSignUpEventData(
            username: request.username,
            confirmationCode: request.code)
        let event = SignUpEvent(eventType: .confirmSignUp(confirmSignUpData))
        stateMachine.send(event)
    }

    private func dispatch(_ error: AuthError) {
        dispatch(result: .failure(error))
    }

    private func cancelListener(_ token: AuthStateMachineToken?) {
        if let token = token {
            stateMachine.cancel(listenerToken: token)
        }
    }
}
