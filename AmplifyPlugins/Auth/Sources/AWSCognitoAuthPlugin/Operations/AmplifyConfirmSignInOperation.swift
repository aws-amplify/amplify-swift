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
            case .resolvingSMSChallenge(let challengeState):
                guard case .waitingForAnswer = challengeState else {
                    self?.dispatch(AuthError.invalidState(
                        "SignIn process is not waiting to confirm signIn",
                        AuthPluginErrorConstants.invalidStateError, nil))
                    self?.finish()
                    return
                }
                self?.sendSMSAnswer()
            default:
                // TODO: Return proper error
                print("")
            }
        }
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
                  case .signingIn(let signInState) = authNState,
                  case .resolvingSMSChallenge(let challengeState) = signInState else { return }

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

        } onSubscribe: { }
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
