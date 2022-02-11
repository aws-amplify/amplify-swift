//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public typealias AmplifySignOutOperation = AmplifyOperation<AuthSignOutRequest, Void, AuthError>

public class AWSAuthSignOutOperation: AmplifySignOutOperation, AuthSignOutOperation {
    
    let authStateMachine: AuthStateMachine
    let credentialStoreStateMachine: CredentialStoreStateMachine
    var stateListenerToken: CredentialStoreStateMachineToken?
    
    init(_ request: AuthSignOutRequest,
         authStateMachine: AuthStateMachine,
         credentialStoreStateMachine: CredentialStoreStateMachine,
         resultListener: ResultListener?)
    {
        self.authStateMachine = authStateMachine
        self.credentialStoreStateMachine = credentialStoreStateMachine

        super.init(categoryType: .auth,
                   eventName: HubPayload.EventName.Auth.signOutAPI,
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
        stateListenerToken = authStateMachine.listen { [weak self] in
            guard let self = self else {
                return
            }
            
            if case .configured(let authNState, _) = $0 {
                guard case .signedIn = authNState else { 
                    defer {
                        self.finish()
                    }
                    
                    self.dispatchSuccess()
                    return
                }
                
                if let token = self.stateListenerToken {
                    self.authStateMachine.cancel(listenerToken: token)
                }
                self.doSignOut()
            }
        } onSubscribe: { }
    }
    
    func doSignOut() {
        stateListenerToken = authStateMachine.listen {[weak self] in
            guard let self = self else {
                return
            }
            guard case .configured(let authNState, _) = $0 else {
                return
            }

            switch authNState {
            case .signingOut(_, let signOutState):
                if case .signingOutLocally = signOutState {
                    self.clearCredentialStore()
                }

            case .signedOut:
                defer {
                    self.finish()
                }
                
                self.dispatchSuccess()
                if let token = self.stateListenerToken {
                    self.authStateMachine.cancel(listenerToken: token)
                }

            case .error(_, let error):
                defer {
                    self.finish()
                }
                
                self.dispatch(error.authError)
                if let token = self.stateListenerToken {
                    self.authStateMachine.cancel(listenerToken: token)
                }

            default:
                break
            }
        } onSubscribe: { [weak self] in
            guard let self = self else {
                return
            }
            
            self.sendSignOutEvent()
        }
    }
    
    func clearCredentialStore() {
        var token: CredentialStoreStateMachineToken?
        token = credentialStoreStateMachine.listen { [weak self] credentialStoreState in
            guard let self = self else {
                return
            }

            switch credentialStoreState {
            case .success:
                self.sendSignedOutSuccessEvent()
                if let token = token {
                    self.credentialStoreStateMachine.cancel(listenerToken: token)
                }
                
            case .error(let credentialError):
                // If running on simulator, ignore missing entitlement (OSStatus:-34018) error
                // This is due to SPM not supporting testing with Keychain
                #if targetEnvironment(simulator)
                    if case let .securityError(osStatus) = credentialError, osStatus == -34018 {
                        self.sendSignedOutSuccessEvent()
                    } else {
                        self.sendSignedOutFailedEvent(credentialError)
                    }
                #else
                    self.sendSignedOutFailedEvent(credentialError)
                #endif
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
            
            self.sendClearCredentialsEvent()
        }
    }
    
    private func sendSignOutEvent() {
        let signOutData = SignOutEventData(globalSignOut: request.options.globalSignOut) 
        let event = AuthenticationEvent(eventType: .signOutRequested(signOutData))
        authStateMachine.send(event)
    }
    
    private func sendClearCredentialsEvent() {
        let event = CredentialStoreEvent.init(eventType: .clearCredentialStore)
        credentialStoreStateMachine.send(event)
    }
    
    private func sendSignedOutSuccessEvent() {
        let event = SignOutEvent(eventType: .signedOutSuccess)
        authStateMachine.send(event)
    }
    
    private func sendSignedOutFailedEvent(_ credentialStoreError: CredentialStoreError) {
        let authenticationError: AuthenticationError
        switch credentialStoreError {
        case .configuration(let message):
            authenticationError = .configuration(message: message)
        default:
            authenticationError = .unknown(message: credentialStoreError.errorDescription)
        }
        let event = SignOutEvent(eventType: .signedOutFailure(authenticationError))
        authStateMachine.send(event)
    }
    
    private func dispatchSuccess() {
        let asyncEvent = AWSAuthSignOutOperation.OperationResult.success(())
        dispatch(result: asyncEvent)
    }
    
    private func dispatch(_ error: AuthError) {
        let asyncEvent = AWSAuthSignOutOperation.OperationResult.failure(error)
        dispatch(result: asyncEvent)
    }
}
