//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

class AWSAuthSignOutTask: AuthSignOutTask, DefaultLogger {

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
        log.verbose("Starting execution")
        await taskHelper.didStateMachineConfigured()

        guard case .configured(let authNState, _) = await authStateMachine.currentState else {
            return invalidStateResult()
        }

        if isValidAuthNStateToStart(authNState) {
            log.verbose("Sending signOut event")
            await sendSignOutEvent()
            return await taskHelper.didSignOut()
        } else if case .federatedToIdentityPool = authNState {
            let invalidStateError = AuthError.invalidState(
                "The user is currently federated to identity pool. You must call clearFederationToIdentityPool to clear credentials.",
                AuthPluginErrorConstants.invalidStateError, nil)
            return AWSCognitoSignOutResult.failed(invalidStateError)
        } else {
            return invalidStateResult()
        }

    }

    func isValidAuthNStateToStart(_ authNState: AuthenticationState) -> Bool {
        switch authNState {
        case .signedIn, .signedOut:
            return true
        default:
            return false
        }
    }

    func invalidStateResult() -> AuthSignOutResult {
        let error = AuthError.invalidState("Auth State not in a valid state", AuthPluginErrorConstants.invalidStateError, nil)
        return AWSCognitoSignOutResult.failed(error)
    }

    private func sendSignOutEvent() async {
        let signOutData = SignOutEventData(
            globalSignOut: request.options.globalSignOut,
            presentationAnchor: request.options.presentationAnchorForWebUI)
        let event = AuthenticationEvent(eventType: .signOutRequested(signOutData))
        await authStateMachine.send(event)
    }
}
