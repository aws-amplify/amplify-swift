//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

class AWSAuthSignOutTask: AuthSignOutTask {

    private let request: AuthSignOutRequest
    private let authStateMachine: AuthStateMachine
    private let taskHelper: AWSAuthTaskHelper

    var eventName: HubPayloadEventName {
        HubPayload.EventName.Auth.signOutAPI
    }

    init(_ request: AuthSignOutRequest, authStateMachine: AuthStateMachine) {
        self.request = request
        self.authStateMachine = authStateMachine
        self.taskHelper = AWSAuthTaskHelper(authStateMachine: authStateMachine)
    }

    func execute() async -> AuthSignOutResult {
        await taskHelper.didStateMachineConfigured()
        if  case .configured(let authNState, _) = await authStateMachine.currentState,
            isValidAuthNStateToStart(authNState) {
            await sendSignOutEvent()
            return await doSignOut()
        } else {
            let invalidStateError = AuthError.invalidState(
                "The user is currently federated to identity pool. You must call clearFederationToIdentityPool to clear credentials.",
                AuthPluginErrorConstants.invalidStateError, nil)
            return AWSCognitoSignOutResult.failed(invalidStateError)
        }

    }

    private func doSignOut() async -> AuthSignOutResult {

        let stateSequences = await authStateMachine.listen()
        for await state in stateSequences {
            guard case .configured(let authNState, _) = state else {
                let error = AuthError.invalidState("Auth State not in a valid state", AuthPluginErrorConstants.invalidStateError, nil)
                return AWSCognitoSignOutResult.failed(error)
            }

            switch authNState {
            case .signedOut(let data):
                if data.revokeTokenError != nil ||
                    data.globalSignOutError != nil ||
                    data.hostedUIError != nil {
                    return AWSCognitoSignOutResult.partial(
                        revokeTokenError: data.revokeTokenError,
                        globalSignOutError: data.globalSignOutError,
                        hostedUIError: data.hostedUIError)
                }
                return AWSCognitoSignOutResult.complete
            case .signingIn:
                await authStateMachine.send(AuthenticationEvent.init(eventType: .cancelSignIn))
            case .signingOut(let state):
                if case .error(let error) = state {
                    return AWSCognitoSignOutResult.failed(error.authError)
                }
            default:
                continue
            }
        }
        fatalError()
    }

    func isValidAuthNStateToStart(_ authNState: AuthenticationState) -> Bool {
        switch authNState {
        case .signedIn:
            return true
        default:
            return false
        }
    }

    private func sendSignOutEvent() async {
        let signOutData = SignOutEventData(
            globalSignOut: request.options.globalSignOut,
            presentationAnchor: request.options.presentationAnchorForWebUI)
        let event = AuthenticationEvent(eventType: .signOutRequested(signOutData))
        await authStateMachine.send(event)
    }
}
