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

public typealias AmplifySignInOperation = AmplifyOperation<AuthSignInRequest, AuthSignInResult, AuthError>
typealias AWSAuthSignInOperationStateMachine = StateMachine<AuthState, AuthEnvironment>
typealias AWSAuthSignInOperationCredentialStoreStateMachine = StateMachine<CredentialStoreState, CredentialEnvironment>

public class AWSAuthSignInOperation: AmplifySignInOperation, AuthSignInOperation {

    let authStateMachine: AWSAuthSignInOperationStateMachine
    let credentialStoreStateMachine: AWSAuthSignInOperationCredentialStoreStateMachine
    var statelistenerToken: AWSAuthSignInOperationStateMachine.StateChangeListenerToken?

    init(_ request: AuthSignInRequest,
         authStateMachine: AWSAuthSignInOperationStateMachine,
         credentialStoreStateMachine: AWSAuthSignInOperationCredentialStoreStateMachine,
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
        doInitialize()
    }

    func doInitialize() {
        var token: AWSAuthSignInOperationStateMachine.StateChangeListenerToken?
        token = authStateMachine.listen { [weak self] in
            guard let self = self else {
                return
            }
            if case .configured = $0 {
                if let token = token {
                    self.authStateMachine.cancel(listenerToken: token)
                }
                self.doSignIn()
            }
        } onSubscribe: { }
    }

    func doSignIn() {
        var token: AWSAuthSignInOperationStateMachine.StateChangeListenerToken?
        token = authStateMachine.listen { [weak self] in
            guard let self = self else {
                return
            }
            guard case .configured(let authNState, _) = $0 else {
                return
            }
            defer {
                self.finish()
            }

            switch authNState {
            case .signedIn(_, let signedInData):
                self.storeUserPoolTokens(tokens: signedInData.cognitoUserPoolTokens)
                if let token = token {
                    self.authStateMachine.cancel(listenerToken: token)
                }
            case .error(_, let error):
                self.dispatch(AuthError.unknown("Some error", error))
                if let token = token {
                    self.authStateMachine.cancel(listenerToken: token)
                }
            case .signingIn(_, let signInState):
                if case .signingInWithSRP(let srpState, _) = signInState,
                   case .error(let signInError) = srpState {
                    let authError = self.mapToAuthError(signInError)
                    self.dispatch(authError)
                    if let token = token {
                        self.authStateMachine.cancel(listenerToken: token)
                    }
                }
            default:
                break
            }
        } onSubscribe: { }
        sendSignInEvent()
    }

    func storeUserPoolTokens(tokens: AWSCognitoUserPoolTokens) {
        var token: AWSAuthSignInOperationCredentialStoreStateMachine.StateChangeListenerToken?
        token = credentialStoreStateMachine.listen { [weak self] in
            guard let self = self else {
                return
            }

            switch $0 {
            case .idle, .error:
                self.dispatch(AuthSignInResult(nextStep: .done))
                if let token = token {
                    self.credentialStoreStateMachine.cancel(listenerToken: token)
                }
            /* Commenting this out for now due to Missing entitlement(OSStatus:-34018) error from SPM
             This is happening due to SPM not supporting testing with Keychain
            case .error(let credentialStoreError):
                // Unable to save the credentials in the local store
                self.dispatch(credentialStoreError.authError)
                if let token = token {
                    self.credentialStoreStateMachine.cancel(listenerToken: token)
                }
            */
            default:
                break
            }

        } onSubscribe: { }

        // Send the load locally stored credentials event
        sendStoreCredentialsEvent(with: tokens)
    }

    func mapToAuthError(_ srpSignInError: SRPSignInError) -> AuthError {
        switch srpSignInError {
        case .configuration(let message):
            return AuthError.configuration(message, "")
        case .service(let error):
            if let initiateAuthError = error as? SdkError<InitiateAuthOutputError> {
                return initiateAuthError.authError
            } else {
                return AuthError.unknown("", error)
            }
        case . invalidServiceResponse(message: let message):
            return AuthError.service(message, "")
        case .calculation:
            return AuthError.unknown("SignIn calculation returned an error")
        case .inputValidation(let field):
            return AuthError.validation(field,
                                        AuthPluginErrorConstants.signInUsernameError.errorDescription,
                                        AuthPluginErrorConstants.signInUsernameError.recoverySuggestion)
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
}
