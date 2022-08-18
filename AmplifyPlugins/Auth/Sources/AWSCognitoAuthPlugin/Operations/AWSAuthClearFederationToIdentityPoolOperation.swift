//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public protocol AuthClearFederationToIdentityPoolOperation: AmplifyOperation<
    AuthClearFederationToIdentityPoolRequest,
    Void,
    AuthError
> {}

public extension HubPayload.EventName.Auth {

    /// eventName for HubPayloads emitted by this operation
    static let clearedFederationToIdentityPoolAPI = "Auth.federatedToIdentityPoolCleared"
}

public class AWSAuthClearFederationToIdentityPoolOperation: AmplifyOperation<
    AuthClearFederationToIdentityPoolRequest,
    Void,
    AuthError
>, AuthClearFederationToIdentityPoolOperation {

    let authStateMachine: AuthStateMachine

    init(_ request: AuthClearFederationToIdentityPoolRequest,
         authStateMachine: AuthStateMachine,
         resultListener: ResultListener?) {

        self.authStateMachine = authStateMachine
        super.init(categoryType: .auth,
                   eventName: HubPayload.EventName.Auth.clearedFederationToIdentityPoolAPI,
                   request: request,
                   resultListener: resultListener)
    }

    override public func main() {
        if isCancelled {
            finish()
            return
        }

        authStateMachine.getCurrentState { [weak self] currentState in
            if case .configured(let authNState, let authZState) = currentState,
               case .federatedToIdentityPool = authNState,
               case .sessionEstablished = authZState {
                self?.startClearingFederation()
            } else {
                self?.sendInvalidStateError()
            }
        }

    }

    func startClearingFederation() {
        var token: AuthStateMachine.StateChangeListenerToken?
        token = authStateMachine.listen { [weak self] state in

            guard  case .configured(let authNState, _) = state else {
                return
            }

            switch authNState {
            case .signedOut(_):
                self?.dispatchSuccess()
                if let token = token {
                    self?.authStateMachine.cancel(listenerToken: token)
                }
                self?.finish()
            case .error(let error):
                self?.dispatch(AuthError.service(
                    "Error clearing federation",
                    AmplifyErrorMessages.shouldNotHappenReportBugToAWS(),
                    error))
                if let token = token {
                    self?.authStateMachine.cancel(listenerToken: token)
                }
                self?.finish()
            default:
                break
            }

        } onSubscribe: { [weak self] in
            self?.sendClearFederationEvent()
        }

    }

    func sendClearFederationEvent() {
        let event = AuthenticationEvent.init(eventType: .clearFederationToIdentityPool)
        authStateMachine.send(event)
    }

    func sendInvalidStateError() {
        dispatch(AuthError.invalidState(
            "No federation found.",
            AuthPluginErrorConstants.invalidStateError, nil))
        finish()
    }

    private func dispatchSuccess() {
        let result = AWSAuthClearFederationToIdentityPoolOperation.OperationResult.success(())
        dispatch(result: result)
    }

    private func dispatch(_ error: AuthError) {
        dispatch(result: .failure(error))
    }
}
