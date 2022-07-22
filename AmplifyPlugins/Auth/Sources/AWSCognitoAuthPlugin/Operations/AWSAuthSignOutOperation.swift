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
         resultListener: ResultListener?) {
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

        authStateMachine.getCurrentState { [weak self] state in
            guard let self = self else { return }

            guard case .configured(let authNState, _) = state else {
                self.dispatch(
                    AuthError.invalidState(
                        "Auth State not in a valid state",
                        AuthPluginErrorConstants.invalidStateError,
                        nil))
                return
            }

            switch authNState {
            case .signedOut:
                self.dispatchSuccess()
                self.finish()

            default:
                self.doSignOut()

            }
        }
    }

    func doSignOut() {
        stateListenerToken = authStateMachine.listen {[weak self] in
            guard let self = self else { return }
            guard case .configured(let authNState, let authZState) = $0 else {
                return
            }

            switch authNState {
            case .signedOut:
                
                self.dispatchSuccess()
                if let token = self.stateListenerToken {
                    self.authStateMachine.cancel(listenerToken: token)
                }
                self.finish()

            case .error(let error):

                self.dispatch(error.authError)
                if let token = self.stateListenerToken {
                    self.authStateMachine.cancel(listenerToken: token)
                }
                self.finish()

            case .signingIn:
                self.authStateMachine.send(AuthenticationEvent.init(eventType: .cancelSignIn))

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

    private func sendSignOutEvent() {
        let signOutData = SignOutEventData(globalSignOut: request.options.globalSignOut)
        let event = AuthenticationEvent(eventType: .signOutRequested(signOutData))
        authStateMachine.send(event)
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
