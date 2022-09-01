//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPluginsCore

class AWSAuthDeleteUserTask: AuthDeleteUserTask {
    private let authStateMachine: AuthStateMachine
    private let taskHelper: AWSAuthTaskHelper
    
    var eventName: HubPayloadEventName {
        HubPayload.EventName.Auth.deleteUserAPI
    }

    init(authStateMachine: AuthStateMachine) {
        self.authStateMachine = authStateMachine
        self.taskHelper = AWSAuthTaskHelper(authStateMachine: authStateMachine)
    }

    func execute() async throws {
        await taskHelper.didStateMachineConfigured()
        let accessToken = try await taskHelper.getAccessToken()
        try await deleteUser(with: accessToken)
    }

    private func deleteUser(with token: String) async throws {
        let stateSequences = await authStateMachine.listen()
        let deleteUserEvent = DeleteUserEvent(eventType: .deleteUser(token))
        await authStateMachine.send(deleteUserEvent)
        for await state in stateSequences {
            guard case .configured(let authNState, _) = state else {
                let error = AuthError.invalidState("Auth state should be in configured state and authentication state should be in deleting user state", AuthPluginErrorConstants.invalidStateError, nil)
                throw error
            }

            guard case .deletingUser(_, let deleteUserState) = authNState else {
                continue
            }

            switch deleteUserState {
            case .userDeleted:
                break
            case .error(let error):
                throw error
            default:
                continue
            }
        }
    }
}
