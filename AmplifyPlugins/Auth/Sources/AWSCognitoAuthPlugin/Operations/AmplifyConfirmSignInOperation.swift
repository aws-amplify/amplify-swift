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
    let credentialStoreStateMachine: CredentialStoreStateMachine

    init(_ request: AuthConfirmSignInRequest,
         stateMachine: AuthStateMachine,
         credentialStoreStateMachine: CredentialStoreStateMachine,
         resultListener: ResultListener?) {

        self.authStateMachine = stateMachine
        self.credentialStoreStateMachine = credentialStoreStateMachine
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
                // TODO: Return proper error
                return
            }

            switch signInState {
            case .resolvingSMSChallenge(let challengeState):
                guard case .waitingForAnswer = challengeState else {
                    // TODO: Return proper error
                    return
                }
                self?.sendConfirmSignInEvent()
            default:
                print("")
            }
        }
    }

    func sendConfirmSignInEvent() {
        var token: AuthStateMachine.StateChangeListenerToken?
        token = authStateMachine.listen { [weak self] in
            guard let self = self else {
                return
            }
            guard case .configured(let authNState, _) = $0 else {
                return
            }
            switch authNState {

            case .signedIn(let signedInData):
                let cognitoTokens = signedInData.cognitoUserPoolTokens
                self.storeUserPoolTokens(cognitoTokens)

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

    func storeUserPoolTokens(_ tokens: AWSCognitoUserPoolTokens) {
        var token: CredentialStoreStateMachine.StateChangeListenerToken?
        token = credentialStoreStateMachine.listen { [weak self] in
            guard let self = self else {
                return
            }

            switch $0 {
            case .idle:
                self.dispatch(AuthSignInResult(nextStep: .done))
                self.cancelCredentialStoreToken(token)
                self.finish()
            case .error(let credentialStoreError):
                // Unable to save the credentials in the local store
                self.dispatch(credentialStoreError.authError)
                self.cancelCredentialStoreToken(token)
                self.finish()
            default:
                break
            }
        } onSubscribe: {[weak self] in
            guard let self = self else {
                return
            }
            // Send the load locally stored credentials event
            self.sendStoreCredentialsEvent(with: tokens)
        }
    }

    private func sendStoreCredentialsEvent(with userPoolTokens: AWSCognitoUserPoolTokens) {
        let credentials = AmplifyCredentials(userPoolTokens: userPoolTokens,
                                             identityId: nil,
                                             awsCredential: nil)
        let event = CredentialStoreEvent.init(eventType: .storeCredentials(credentials))
        credentialStoreStateMachine.send(event)
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

    private func cancelCredentialStoreToken(_ token: CredentialStoreStateMachineToken?) {
        if let token = token {
            authStateMachine.cancel(listenerToken: token)
        }
    }
}
