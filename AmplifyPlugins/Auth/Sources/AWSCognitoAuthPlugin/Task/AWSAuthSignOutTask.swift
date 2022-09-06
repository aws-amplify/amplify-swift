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

    func execute() async throws {
        await taskHelper.didStateMachineConfigured()
        await sendSignOutEvent()
        try await doSignOut()
    }

    private func doSignOut() async throws {

        let stateSequences = await authStateMachine.listen()
        for await state in stateSequences {
            guard case .configured(let authNState, _) = state else {
                let error = AuthError.invalidState("Auth State not in a valid state", AuthPluginErrorConstants.invalidStateError,nil)
                throw error
            }

            switch authNState {
            case .signedOut:
                return
            case .error(let error):
                throw error.authError
            case .signingIn:
                await authStateMachine.send(AuthenticationEvent.init(eventType: .cancelSignIn))
            default:
                continue
            }
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
