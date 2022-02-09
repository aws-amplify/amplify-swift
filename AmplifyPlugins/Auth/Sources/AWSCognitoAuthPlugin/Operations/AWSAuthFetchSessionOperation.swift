//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public typealias AmplifyFetchSessionOperation = AmplifyOperation<AuthFetchSessionRequest, AuthSession, AuthError>
typealias AmplifyFetchSessionOperationAuthStateMachine = StateMachine<AuthState, AuthEnvironment>
typealias AmplifyFetchSessionOperationCredentialStoreStateMachine = StateMachine<CredentialStoreState, CredentialEnvironment>

public class AWSAuthFetchSessionOperation: AmplifyFetchSessionOperation, AuthFetchSessionOperation {

    let authStateMachine: AmplifyFetchSessionOperationAuthStateMachine
    let credentialStoreStateMachine: AmplifyFetchSessionOperationCredentialStoreStateMachine

    init(_ request: AuthFetchSessionRequest,
         authStateMachine: AmplifyFetchSessionOperationAuthStateMachine,
         credentialStoreStateMachine: AmplifyFetchSessionOperationCredentialStoreStateMachine,
         resultListener: ResultListener?) {

        self.authStateMachine = authStateMachine
        self.credentialStoreStateMachine = credentialStoreStateMachine
        super.init(categoryType: .auth,
                   eventName: HubPayload.EventName.Auth.fetchSessionAPI,
                   request: request,
                   resultListener: resultListener)
    }

    override public func main() {
        if isCancelled {
            finish()
            return
        }
        initializeCredentialStore { [weak self] in
            self?.fetchStoredCredentials()
        }
    }

    func initializeCredentialStore(completion: @escaping () -> Void) {

        var token: AWSAuthSignInOperationStateMachine.StateChangeListenerToken?
        token = credentialStoreStateMachine.listen { [weak self] in
            guard let self = self else { return }

            switch $0 {
            case .idle, .error:
                completion()
                if let token = token {
                    self.credentialStoreStateMachine.cancel(listenerToken: token)
                }
            default:
                break
            }

        } onSubscribe: { }
    }

    func fetchStoredCredentials() {

        var token: AWSAuthSignInOperationStateMachine.StateChangeListenerToken?
        token = credentialStoreStateMachine.listen { [weak self] in
            guard let self = self else { return }

            switch $0 {
            case .idle(let credentials):
                self.doInitialize(with: credentials)
                if let token = token {
                    self.credentialStoreStateMachine.cancel(listenerToken: token)
                }
            case .error:
                self.doInitialize(with: nil)
                if let token = token {
                    self.credentialStoreStateMachine.cancel(listenerToken: token)
                }
            default:
                break
            }
        } onSubscribe: { [weak self] in
            guard let self = self else {
                return
            }
            
            // Send the load locally stored credentials event
            let event = CredentialStoreEvent.init(eventType: .loadCredentialStore)
            self.credentialStoreStateMachine.send(event)
        }
    }

    func doInitialize(with storedCredentials: CognitoCredentials?) {
        var token: AWSAuthSignInOperationStateMachine.StateChangeListenerToken?
        token = authStateMachine.listen { [weak self] in
            guard let self = self else {
                return
            }
            // This is to make sure that the AuthZState is not fetching authSession to
            // avoid threading issues.
            guard case .configured(_, let authZState) = $0  else {
                return
            }
            // If still fetchingAuthSession, we will wait
            if case .fetchingAuthSession = authZState,
               case .notConfigured = authZState {
                return
            }
            if let token = token {
                self.authStateMachine.cancel(listenerToken: token)
            }
            self.fetchAuthSession(with: storedCredentials)
        } onSubscribe: { }
    }

    func fetchAuthSession(with storedCredentials: CognitoCredentials?) {
        var token: AWSAuthSignInOperationStateMachine.StateChangeListenerToken?
        token = authStateMachine.listen { [weak self] in
            guard let self = self else {
                return
            }
            guard case .configured(_, let authZState) = $0 else {
                return
            }

            switch authZState {
            case .sessionEstablished(let session):
                // Store the credentials
                self.initializeCredentialStore { [weak self] in
                    self?.storeSession(session)
                }
                if let token = token {
                    self.authStateMachine.cancel(listenerToken: token)
                }
            case .error(let authorizationError):
                self.dispatch(authorizationError.authError)
                if let token = token {
                    self.authStateMachine.cancel(listenerToken: token)
                }
            default:
                break
            }

        } onSubscribe: { [weak self] in
            guard let self = self else {
                return
            }
            
            self.sendFetchAuthSessionEvent(with: storedCredentials)
        }
    }

    func storeSession(_ session: AWSAuthCognitoSession) {
        var token: AWSAuthSignInOperationCredentialStoreStateMachine.StateChangeListenerToken?
        token = credentialStoreStateMachine.listen { [weak self] in
            guard let self = self else {
                return
            }

            switch $0 {
            case .idle, .error:
                self.dispatch(session)
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

        } onSubscribe: { [weak self] in
            guard let self = self else {
                return
            }
            
            // Send the load locally stored credentials event
            self.sendStoreCredentialsEvent(with: session.getCognitoCredentials())
        }
    }

    private func sendStoreCredentialsEvent(with credentials: CognitoCredentials) {
        let event = CredentialStoreEvent.init(eventType: .storeCredentials(credentials))
        credentialStoreStateMachine.send(event)
    }

    private func sendFetchAuthSessionEvent(with storedCredentials: CognitoCredentials?) {
        let event = AuthorizationEvent.init(eventType: .fetchAuthSession(storedCredentials))
        authStateMachine.send(event)
    }

    private func dispatch(_ result: AuthSession) {
        let asyncEvent = AWSAuthFetchSessionOperation.OperationResult.success(result)
        dispatch(result: asyncEvent)
    }

    private func dispatch(_ error: AuthError) {
        let asyncEvent = AWSAuthFetchSessionOperation.OperationResult.failure(error)
        dispatch(result: asyncEvent)
    }

}
