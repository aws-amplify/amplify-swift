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
        if isCancelled {
            finish()
            return
        }
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
                    let error = AuthError.invalidState(message, "", nil)
                    self.dispatch(error)
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
            if self.isCancelled {
                self.finish()
                return
            }
            guard case .configured(let authNState, _) = state else {
                return
            }
            switch authNState {
            case .signingUp(_, let signUpState):

                switch signUpState {
                case .signingUpInitiated(_, response: let response):
                    self.dispatch(result: .success(response.authResponse))
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
            guard let self = self else {
                return
            }
            self.sendSignUpEvent()
        }
    }

    private func sendSignUpEvent() {

        guard !request.username.isEmpty else {
               let error = AuthError.validation(
                AuthPluginErrorConstants.signUpUsernameError.field,
                AuthPluginErrorConstants.signUpUsernameError.errorDescription,
                AuthPluginErrorConstants.signUpUsernameError.recoverySuggestion, nil)
               dispatch(error)
            finish()
            return
        }

        guard let password = request.password,
           SignUpPasswordValidator.validate(password: password) == nil else {
               let error = AuthError.validation(
                AuthPluginErrorConstants.signUpPasswordError.field,
                AuthPluginErrorConstants.signUpPasswordError.errorDescription,
                AuthPluginErrorConstants.signUpPasswordError.recoverySuggestion, nil)
               dispatch(error)
            finish()
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

    private func dispatch(_ error: AuthError) {
        dispatch(result: .failure(error))
    }

    private func cancelListener(_ token: AuthStateMachineToken?) {
        if let token = token {
            stateMachine.cancel(listenerToken: token)
        }
    }
}
