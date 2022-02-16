//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

import ClientRuntime
import AWSCognitoIdentityProvider

public typealias AmplifySignUpOperation = AmplifyOperation<
    AuthSignUpRequest,
    AuthSignUpResult,
    AuthError>

public class AWSAuthSignUpOperation: AmplifySignUpOperation,
                                     AuthSignUpOperation
{

    let stateMachine: AuthStateMachine

    init(_ request: AuthSignUpRequest,
         stateMachine: AuthStateMachine,
         resultListener: ResultListener?)
    {

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
                    self.doSignUp()
                default:
                    self.cancelListener(token)
                    let message = "Auth state must be signed out to signup"
                    self.dispatch(message: message, error: .invalidState(message: message))
                    self.finish()
                }
            }
        } onSubscribe: { }
    }

    func doSignUp() {
        var token: AuthStateMachineToken?
        token = stateMachine.listen { [weak self] state in
            guard let self = self else {
                return
            }
            guard case .configured(let authNState, _) = state else {
                return
            }

            switch authNState {
            case .signingUp(_, let signUpState):

                switch signUpState {
                case .signingUpInitiated:
                    self.dispatch(result: .success(AuthSignUpResult(.confirmUser())))
                    self.cancelListener(token)
                    self.finish()
                case .error(let error):
                    self.dispatch(message: "Failed while signing up", error: error)
                    self.cancelListener(token)
                    self.finish()
                default:
                    break
                }
            default:
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

        // Convert the attributes to [String: String]
        let attributes = request.options.userAttributes?.reduce(
            into: [String: String]()) {
                $0[$1.key.rawValue] = $1.value
            } ?? [:]
        let signUpData = SignUpEventData(username: request.username,
                                         password: password,
                                         attributes: attributes)
        let event = SignUpEvent(eventType: .initiateSignUp(signUpData))
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
