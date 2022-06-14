//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension AWSCognitoAuthPlugin {

    func setupStateMachine() {

        self.authStateListenerToken = authStateMachine.listen { state in
            self.log.verbose("""
            Auth state change:

            \(state)

            """)

            switch state {
            case .waitingForCachedCredentials:
                let credentialStoreEvent = CredentialStoreEvent(eventType: .loadCredentialStore)
                self.credentialStoreStateMachine.send(credentialStoreEvent)
            case .configured(_, let authorizationState):

                if case .waitingToStore(let credentials) = authorizationState {
                    let credentialStoreEvent = CredentialStoreEvent(
                        eventType: .storeCredentials(credentials))
                    self.credentialStoreStateMachine.send(credentialStoreEvent)
                }
            default: break
            }

        } onSubscribe: { }

        self.credentialStoreStateListenerToken = credentialStoreStateMachine.listen { state in
            self.log.verbose("""
            Credential Store state change:

            \(state)

            """)

            switch state {
            case .success(let credentials):
                let authEvent = AuthEvent.init(eventType: .receivedCachedCredentials(credentials))
                self.authStateMachine.send(authEvent)
            case .error:
                let authEvent = AuthEvent.init(eventType: .cachedCredentialsFailed)
                self.authStateMachine.send(authEvent)
            default: break
            }
        } onSubscribe: { }

        internalConfigure()
    }

    func internalConfigure() {
        let request = AuthConfigureRequest(authConfiguration: authConfiguration)
        let operation = AuthConfigureOperation(
            request: request,
            authStateMachine: authStateMachine,
            credentialStoreStateMachine: credentialStoreStateMachine)
        self.queue.addOperation(operation)
    }
}
