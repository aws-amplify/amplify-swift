//// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

import ClientRuntime
import AWSCognitoIdentityProvider

public typealias AmplifySignUpOperation = AmplifyOperation<AuthSignUpRequest, AuthSignUpResult, AuthError>
typealias AWSAuthSignUpOperationStateMachine = StateMachine<AuthState, AuthEnvironment>

public class AWSAuthSignUpOperation: AmplifySignUpOperation, AuthSignUpOperation {

    let stateMachine: AuthStateMachine

    init(_ request: AuthSignUpRequest,
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
        var token: AuthStateMachine.StateChangeListenerToken?
        token = stateMachine.listen { [weak self] in
            guard let self = self else {
                return
            }

            if case .configured(let authNState, _) = $0 {
                guard case .signedOut = authNState else {
                    self.cancelListener(token)
                    let message = "Auth state must be signed out to sign up"
                    self.dispatch(message: message, error: .invalidState(message: message))
                    self.finish()
                    return
                }
                self.cancelListener(token)
                self.doSignUp()
            }
        } onSubscribe: { }
    }

    func doSignUp() {
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
            case .signingUp:
                self.cancelListener(token)
                self.dispatch(result: .success(AuthSignUpResult(.confirmUser())))
            case .error(_, let error):
                self.cancelListener(token)
                self.dispatch(message: "failed while signing up", error: .service(error: error))
            default:
                print("default for \(authNState)")
                break
            }
        } onSubscribe: { [weak self] in
            guard let self = self else {
                return
            }
            
            self.sendSignUpEvent()
        }
    }

    private func sendSignUpEvent() {
        guard let password = request.password else {
            let message = "password is nil"
            dispatch(message: message, error: .missingPassword(message: message))
            return
        }

        if let error = SignUpPasswordValidator.validate(password: password) {
            dispatch(message: "invalid password", error: error)
            return
        }

        let signUpData = SignUpEventData(username: request.username, password: password)
        let event = SignUpEvent(eventType: .initiateSignUp(signUpData))
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
