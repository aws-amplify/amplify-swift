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
    let credentialStoreStateMachine: CredentialStoreStateMachine

    init(_ request: AuthSignInRequest,
         authStateMachine: AuthStateMachine,
         credentialStoreStateMachine: CredentialStoreStateMachine,
         resultListener: ResultListener?) {

        self.authStateMachine = authStateMachine
        self.credentialStoreStateMachine = credentialStoreStateMachine
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
        doInitialize { [weak self] authenticationState in
            switch authenticationState {
            case .signedOut:
                self?.doSignIn()
            default:
                // TODO: Should dispatch an error is already signedIn
                // or signingIn
                self?.finish()
            }
        }
    }

    func doInitialize(_ callback: @escaping (AuthenticationState) -> Void) {
        var token: AuthStateMachineToken?
        token = authStateMachine.listen { [weak self] in
            guard let self = self else {
                return
            }
            // Auth should be configured to start the signIn process
            if case .configured(let authenticationState, _) = $0 {
                callback(authenticationState)
                self.cancelToken(token)
            }
        } onSubscribe: { }
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
            guard case .configured(let authNState, _) = $0 else {
                return
            }

            switch authNState {
            case .signedIn(_, let signedInData):
                let cognitoTokens = signedInData.cognitoUserPoolTokens
                self.storeUserPoolTokens(cognitoTokens)
                self.cancelToken(token)
            case .error(_, let error):
                self.dispatch(AuthError.unknown("Some error", error))
                self.cancelToken(token)
                self.finish()
            case .signingIn(_, let signInState):
                if case .signingInWithSRP(let srpState, _) = signInState,
                   case .error(let signInError) = srpState {
                    if (signInError.isUserUnConfirmed) {
                        self.dispatch(AuthSignInResult(nextStep: .confirmSignUp(nil)))
                    } else if (signInError.isResetPassword) {
                        self.dispatch(AuthSignInResult(nextStep: .resetPassword(nil)))
                    } else {
                        self.dispatch(signInError.authError)
                    }

                    self.cancelToken(token)
                    self.finish()
                }
            default:
                break
            }
        } onSubscribe: { [weak self] in
            guard let self = self else {
                return
            }
            self.sendSignInEvent()
        }

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
        let credentials = CognitoCredentials(userPoolTokens: userPoolTokens, identityId: nil, awsCredential: nil)
        let event = CredentialStoreEvent.init(eventType: .storeCredentials(credentials))
        credentialStoreStateMachine.send(event)
    }

    private func sendSignInEvent() {
        let signInData = SignInEventData(username: request.username, password: request.password)
        let event = AuthenticationEvent.init(eventType: .signInRequested(signInData))
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

    // TODO: Find a differnet mechanism to cancel the tokens
    private func cancelToken(_ token: AuthStateMachineToken?) {
        if let token = token {
            self.authStateMachine.cancel(listenerToken: token)
        }
    }

    private func cancelCredentialStoreToken(_ token: CredentialStoreStateMachineToken?) {
        if let token = token {
            self.authStateMachine.cancel(listenerToken: token)
        }
    }
}
