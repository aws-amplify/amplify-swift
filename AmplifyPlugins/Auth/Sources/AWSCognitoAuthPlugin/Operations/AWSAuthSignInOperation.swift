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

public typealias AmplifySignInOperation = AmplifyOperation<
    AuthSignInRequest,
    AuthSignInResult,
    AuthError>

public class AWSAuthSignInOperation: AmplifySignInOperation,
                                     AuthSignInOperation {

    let authStateMachine: AuthStateMachine

    init(_ request: AuthSignInRequest,
         authStateMachine: AuthStateMachine,
         resultListener: ResultListener?) {

        self.authStateMachine = authStateMachine
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
        authStateMachine.getCurrentState { [weak self] in
            guard case .configured(let authenticationState, _) = $0 else {
                return
            }

            switch authenticationState {
            case .signedIn:
                self?.dispatch(AuthError.invalidState(
                    "There is already a user in signedIn state. SignOut the user first before calling signIn",
                    AuthPluginErrorConstants.invalidStateError, nil))
                self?.finish()
            default:
                self?.doSignIn()
            }
        }
    }

    func doSignIn() {
        if isCancelled {
            finish()
            return
        }

        var token: AuthStateMachine.StateChangeListenerToken?
        token = authStateMachine.listen { [weak self] in
            guard let self = self else {
                return
            }
            guard case .configured(let authNState, let authZState) = $0 else {
                return
            }

            switch authNState {
            case .signedOut:
                self.sendSignInEvent()

            case .signingUp:
                self.sendCancelSignUpEvent()

            case .signedIn:
                if case .sessionEstablished = authZState {
                    self.dispatch(AuthSignInResult(nextStep: .done))
                    self.cancelToken(token)
                    self.finish()
                }

            case .error(let error):
                self.dispatch(AuthError.unknown("Sign in reached an error state", error))
                self.cancelToken(token)
                self.finish()

            case .signingIn(let signInState):
                if case .signingInWithSRP(let srpState, _) = signInState,
                   case .error(let signInError) = srpState {
                    if signInError.isUserUnConfirmed {
                        self.dispatch(AuthSignInResult(nextStep: .confirmSignUp(nil)))
                    } else if signInError.isResetPassword {
                        self.dispatch(AuthSignInResult(nextStep: .resetPassword(nil)))
                    } else {
                        self.dispatch(signInError.authError)
                    }

                    self.cancelToken(token)
                    self.finish()
                } else if case .resolvingSMSChallenge(let challengeState) = signInState,
                         case .waitingForAnswer(let challenge) = challengeState {
                   let delivery = challenge.codeDeliveryDetails
                   self.dispatch(.init(nextStep: .confirmSignInWithSMSMFACode(delivery, nil)))
                   self.cancelToken(token)
                   self.finish()
               }
            default:
                break
            }
        } onSubscribe: { }
    }

    private func sendSignInEvent() {
        let signInData = SignInEventData(username: request.username, password: request.password)
        let event = AuthenticationEvent.init(eventType: .signInRequested(signInData))
        authStateMachine.send(event)
    }

    private func sendCancelSignUpEvent() {
        let event = AuthenticationEvent(eventType: .cancelSignUp)
        authStateMachine.send(event)
    }

    private func dispatch(_ result: AuthSignInResult) {
        let asyncEvent = AWSAuthSignInOperation.OperationResult.success(result)
        dispatch(result: asyncEvent)
    }

    private func dispatch(_ error: AuthError) {
        let asyncEvent = AWSAuthSignInOperation.OperationResult.failure(error)
        dispatch(result: asyncEvent)
    }

    private func cancelToken(_ token: AuthStateMachineToken?) {
        if let token = token {
            authStateMachine.cancel(listenerToken: token)
        }
    }
}
