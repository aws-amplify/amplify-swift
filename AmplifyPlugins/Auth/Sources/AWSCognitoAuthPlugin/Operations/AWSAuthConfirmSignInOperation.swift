//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

import AWSCognitoIdentityProvider

public typealias AmplifyConfirmSignInOperation = AmplifyOperation<
    AuthConfirmSignInRequest,
    AuthSignInResult,
    AuthError>

public class AWSAuthConfirmSignInOperation: AmplifyConfirmSignInOperation,
                                            AuthConfirmSignInOperation {

    let authStateMachine: AuthStateMachine

    init(_ request: AuthConfirmSignInRequest,
         stateMachine: AuthStateMachine,
         resultListener: ResultListener?) {

        self.authStateMachine = stateMachine
        super.init(categoryType: .auth,
                   eventName: HubPayload.EventName.Auth.confirmSignInAPI,
                   request: request,
                   resultListener: resultListener)
    }

    override public func main() {
        if isCancelled {
            finish()
            return
        }

        if let validationError = request.hasError() {
            dispatch(validationError)
            finish()
            return
        }

        authStateMachine.getCurrentState { [weak self] in

            guard case .configured(let authenticationState, _) = $0,
                  case .signingIn(let signInState) = authenticationState else {
                self?.dispatch(AuthError.invalidState(
                    "User is not attempting signIn operation",
                    AuthPluginErrorConstants.invalidStateError, nil))
                self?.finish()
                return
            }

            switch signInState {
            case .resolvingSMSChallenge(let challengeState),
                    .resolvingCustomChallenge(let challengeState):
                if case . waitingForAnswer = challengeState {
                    self?.sendSMSAnswer()
                } else {
                    self?.sendInvalidStateError()
                }
            default:
                self?.sendInvalidStateError()
            }
        }
    }

    func sendInvalidStateError() {
        dispatch(AuthError.invalidState(
            "SignIn process is not waiting to confirm signIn",
            AuthPluginErrorConstants.invalidStateError, nil))
        finish()
    }

    func sendSMSAnswer() {
        if isCancelled {
            finish()
            return
        }

        var token: AuthStateMachine.StateChangeListenerToken?
        token = authStateMachine.listen { [weak self] in

            guard let self = self else { return }
            guard case .configured(let authNState, _ ) = $0,
                  case .signingIn(let signInState) = authNState else { return }

            switch signInState {
            case .resolvingSMSChallenge(let challengeState),
                    .resolvingCustomChallenge(let challengeState):
                self.verifyChallengeState(
                    challengeState: challengeState,
                    token: token)
            default: break
            }
        } onSubscribe: { }
    }

    func verifyChallengeState(
        challengeState: SignInChallengeState,
        token: AuthStateMachine.StateChangeListenerToken?) {
            switch challengeState {
            case .waitingForAnswer:
            let answer = self.request.challengeResponse
            let event = SignInChallengeEvent(eventType: .verifyChallengeAnswer(answer))
            self.authStateMachine.send(event)

        case .verifying:
            self.cancelToken(token)
            self.verifyResponse()
        default: break
        }
    }

    func verifyResponse() {
        if isCancelled {
            finish()
            return
        }

        var token: AuthStateMachine.StateChangeListenerToken?
        token = authStateMachine.listen { [weak self] in
            guard let self = self else {
                return
            }
            guard case .configured(let authNState,
                                   let authZState) = $0 else { return }
            switch authNState {

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

                if case .resolvingSMSChallenge(let challengeState) = signInState,
                   case .error(_, let signInError) = challengeState {
                    let authError = signInError.authError

                    if case .service(_, _, let serviceError) = authError,
                       let cognitoError = serviceError as? AWSCognitoAuthError,
                       case .passwordResetRequired = cognitoError {
                        let result = AuthSignInResult(nextStep: .resetPassword(nil))
                        self.dispatch(result)
                        self.cancelToken(token)
                        self.finish()
                    } else if case .service(_, _, let serviceError) = authError,
                              let cognitoError = serviceError as? AWSCognitoAuthError,
                              case .userNotConfirmed = cognitoError {
                        let result = AuthSignInResult(nextStep: .confirmSignUp(nil))
                        self.dispatch(result)
                        self.cancelToken(token)
                        self.finish()
                    } else {
                        self.dispatch(authError)
                        self.cancelToken(token)
                        self.finish()
                    }
                }

                guard let result = UserPoolSignInHelper.checkNextStep(signInState) else { return }
                self.dispatch(result: result)
                self.cancelToken(token)
                self.finish()
            default:
                break
            }
        } onSubscribe: { }
    }

    private func dispatch(_ result: AuthSignInResult) {
        let asyncEvent = AWSAuthSignInOperation.OperationResult.success(result)
        dispatch(result: asyncEvent)
    }

    private func dispatch(_ error: AuthError) {
        dispatch(result: .failure(error))
    }

    private func cancelToken(_ token: AuthStateMachineToken?) {
        if let token = token {
            authStateMachine.cancel(listenerToken: token)
        }
    }
}
