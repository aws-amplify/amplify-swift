//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public typealias AmplifyFetchSessionOperation = AmplifyOperation<AuthFetchSessionRequest, AuthSession, AuthError>

public class AWSAuthFetchSessionOperation: AmplifyFetchSessionOperation, AuthFetchSessionOperation {

    let authStateMachine: AuthStateMachine
    let credentialStoreStateMachine: CredentialStoreStateMachine
    private let fetchSessionHelper: FetchAuthSessionOperationHelper

    init(_ request: AuthFetchSessionRequest,
         authStateMachine: AuthStateMachine,
         credentialStoreStateMachine: CredentialStoreStateMachine,
         resultListener: ResultListener?) {

        self.authStateMachine = authStateMachine
        self.credentialStoreStateMachine = credentialStoreStateMachine
        fetchSessionHelper = FetchAuthSessionOperationHelper(
            authStateMachine: authStateMachine,
            credentialStoreStateMachine: credentialStoreStateMachine)
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

    func initializeAuthStateMachine(with storedCredentials: AmplifyCredentials?) {

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

    func fetchStoredCredentials() {

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
        }
        
    }

    private func dispatch(_ result: AuthSession) {
        finish()
        let asyncEvent = AWSAuthFetchSessionOperation.OperationResult.success(result)
        dispatch(result: asyncEvent)
    }

    private func dispatch(_ error: AuthError) {
        finish()
        let asyncEvent = AWSAuthFetchSessionOperation.OperationResult.failure(error)
        dispatch(result: asyncEvent)
    }

}
