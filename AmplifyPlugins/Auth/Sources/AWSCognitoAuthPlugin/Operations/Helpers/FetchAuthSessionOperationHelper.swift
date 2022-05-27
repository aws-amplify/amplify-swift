//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

class FetchAuthSessionOperationHelper {
    
    typealias FetchAuthSessionCompletion = (Result<AuthSession, AuthError>) -> ()
    
    let authStateMachine: AuthStateMachine
    let credentialStoreStateMachine: CredentialStoreStateMachine
    
    var completion: FetchAuthSessionCompletion? = nil

    init(authStateMachine: AuthStateMachine,
         credentialStoreStateMachine: CredentialStoreStateMachine)
    {
        self.authStateMachine = authStateMachine
        self.credentialStoreStateMachine = credentialStoreStateMachine
    }
    
    func fetchSession(completion: FetchAuthSessionCompletion?)  {
        self.completion = completion
        initializeCredentialStore { [weak self] in
            self?.fetchStoredCredentials()
        }
    }
    
    private func initializeCredentialStore(completion: @escaping () -> Void) {

        var token: AuthStateMachine.StateChangeListenerToken?
        token = credentialStoreStateMachine.listen { [weak self] in
            guard let self = self else { return }

            switch $0 {
            case .idle:
                completion()
                if let token = token {
                    self.credentialStoreStateMachine.cancel(listenerToken: token)
                }
            default:
                break
            }

        } onSubscribe: { }
    }
    
    private func initializeAuthStateMachine(with storedCredentials: AmplifyCredentials?) {
        
        authStateMachine.getCurrentState { [weak self] state in
            guard case .configured = state  else {
                let message = "Credential store state machine not in idle state: \(state)"
                let error = AuthError.invalidState(message, "", nil)
                self?.dispatch(error)
                return
            }
            self?.fetchAuthSession(with: storedCredentials)
        }
    }


    private func fetchStoredCredentials() {

        var token: AuthStateMachine.StateChangeListenerToken?
        token = credentialStoreStateMachine.listen { [weak self] in
            guard let self = self else { return }

            switch $0 {
            case .success(let credentials):
                self.initializeAuthStateMachine(with: credentials)
                if let token = token {
                    self.credentialStoreStateMachine.cancel(listenerToken: token)
                }
            case .error:
                self.initializeAuthStateMachine(with: nil)
                if let token = token {
                    self.credentialStoreStateMachine.cancel(listenerToken: token)
                }
            default:
                break
            }
        } onSubscribe: { [weak self] in
            guard let self = self else { return }

            // Send the load locally stored credentials event
            let event = CredentialStoreEvent.init(eventType: .loadCredentialStore)
            self.credentialStoreStateMachine.send(event)
        }
    }

    private func fetchAuthSession(with storedCredentials: AmplifyCredentials?) {
        var token: AuthStateMachine.StateChangeListenerToken?
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

    private func storeSession(_ session: AWSAuthCognitoSession) {
        var token: CredentialStoreStateMachine.StateChangeListenerToken?
        token = credentialStoreStateMachine.listen { [weak self] in
            guard let self = self else {
                return
            }

            switch $0 {
            case .success:
                self.dispatch(session)
                if let token = token {
                    self.credentialStoreStateMachine.cancel(listenerToken: token)
                }
            // Due to Missing entitlement(OSStatus:-34018) error from SPM
            // Keychain needs a host app to run successfuly
            case .error(let credentialStoreError):
                // Unable to save the credentials in the local store
                self.dispatch(credentialStoreError.authError)
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
            self.sendStoreCredentialsEvent(with: session.getCognitoCredentials())

        }
    }

    private func sendStoreCredentialsEvent(with credentials: AmplifyCredentials) {
        let event = CredentialStoreEvent.init(eventType: .storeCredentials(credentials))
        credentialStoreStateMachine.send(event)
    }

    private func sendFetchAuthSessionEvent(with storedCredentials: AmplifyCredentials?) {
        let event = AuthorizationEvent.init(eventType: .fetchAuthSession(storedCredentials))
        authStateMachine.send(event)
    }

    private func dispatch(_ result: AuthSession) {
        completion?(.success(result))
    }

    private func dispatch(_ error: AuthError) {
        completion?(.failure(error))
    }

    
}
