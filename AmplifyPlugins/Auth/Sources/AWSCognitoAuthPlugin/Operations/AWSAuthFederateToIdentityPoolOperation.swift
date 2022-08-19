//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public protocol AuthFederateToIdentityPoolOperation: AmplifyOperation<
    AuthFederateToIdentityPoolRequest,
    FederateToIdentityPoolResult,
    AuthError
> {}

public extension HubPayload.EventName.Auth {

    /// eventName for HubPayloads emitted by this operation
    static let federateToIdentityPoolAPI = "Auth.federatedToIdentityPool"
}

public class AWSAuthFederateToIdentityPoolOperation: AmplifyOperation<
    AuthFederateToIdentityPoolRequest,
    FederateToIdentityPoolResult,
    AuthError
>, AuthFederateToIdentityPoolOperation {

    let authStateMachine: AuthStateMachine

    init(_ request: AuthFederateToIdentityPoolRequest,
         authStateMachine: AuthStateMachine,
         resultListener: ResultListener?) {

        self.authStateMachine = authStateMachine
        super.init(categoryType: .auth,
                   eventName: HubPayload.EventName.Auth.federateToIdentityPoolAPI,
                   request: request,
                   resultListener: resultListener)
    }

    override public func main() {
        if isCancelled {
            finish()
            return
        }

        authStateMachine.getCurrentState { [weak self] state in

            guard case .configured(let authNState, let authZState) = state  else {
                self?.sendInvalidStateError()
                return
            }

            if self?.isValidAuthNStateToStart(authNState) == true &&
               self?.isValidAuthZStateToStart(authZState) == true {
                // Clear previous federation before beginning a new one
                if case .federatedToIdentityPool = authNState {
                    self?.clearPreviousFederation()
                } else {
                    self?.startFederatingToIdentityPool()
                }
            } else {
                self?.sendInvalidStateError()
            }
        }
    }

    func clearPreviousFederation() {
        let clearFederationHelper = ClearFederationOperationHelper()
        clearFederationHelper.clearFederation(
            authStateMachine) { [weak self] result in
                switch result {
                case .success:
                    self?.startFederatingToIdentityPool()
                case .failure(let error):
                    self?.dispatch(error)
                }
            }
    }

    func startFederatingToIdentityPool() {
        var token: AuthStateMachine.StateChangeListenerToken?
        token = authStateMachine.listen { [weak self] state in

            guard  case .configured(let authNState, let authZState) = state else {
                return
            }

            switch (authNState, authZState) {
            case (.federatedToIdentityPool, .sessionEstablished(let credentials)):
                self?.dispatch(credentials)
                if let token = token {
                    self?.authStateMachine.cancel(listenerToken: token)
                }
            case (.error(_), .error(let authZError)):
                self?.dispatch(AuthError.service(
                    "Error federating to identity pool",
                    AmplifyErrorMessages.shouldNotHappenReportBugToAWS(),
                    authZError))
                if let token = token {
                    self?.authStateMachine.cancel(listenerToken: token)
                }
            default:
                break
            }

        } onSubscribe: { [weak self] in
            self?.sendStartFederatingToIdentityPoolEvent()
        }

    }

    func sendStartFederatingToIdentityPoolEvent() {
        let federatedToken = FederatedToken(
            token: request.token,
            provider: request.provider)
        let identityId = request.options.developerProvidedIdentityID
        let event = AuthorizationEvent.init(
            eventType: .startFederationToIdentityPool(federatedToken, identityId))
        authStateMachine.send(event)
    }

    func isValidAuthNStateToStart(_ authNState: AuthenticationState) -> Bool {
        switch authNState {
        case .notConfigured, .signedOut, .federatedToIdentityPool:
            return true
        default:
            return false
        }
    }

    func isValidAuthZStateToStart(_ authZState: AuthorizationState) -> Bool {
        switch authZState {
        case .configured, .sessionEstablished:
            return true
        default:
            return false
        }
    }

    func sendInvalidStateError() {
        dispatch(AuthError.invalidState(
            "Federation could not be completed.",
            AuthPluginErrorConstants.invalidStateError, nil))
        finish()
    }

    private func dispatch(_ result: AmplifyCredentials) {
        switch result {
        case .identityPoolWithFederation(_, let identityId, let awsCredentials):
            let federatedResult = FederateToIdentityPoolResult(
                credentials: awsCredentials,
                identityId: identityId)

            let result = Self.OperationResult.success(federatedResult)
            dispatch(result: result)
        default:
            dispatch(AuthError.unknown("Unable to parse credentials to expected output", nil))
        }
        finish()
    }

    private func dispatch(_ error: AuthError) {
        dispatch(result: .failure(error))
        finish()
    }
}
