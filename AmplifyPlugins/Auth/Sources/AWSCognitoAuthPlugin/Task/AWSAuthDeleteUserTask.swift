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
    private var stateListenerToken: AuthStateMachineToken?
    private let taskHelper: AWSAuthTaskHelper
    
    var eventName: HubPayloadEventName {
        HubPayload.EventName.Auth.deleteUserAPI
    }

    init(authStateMachine: AuthStateMachine) {
        self.authStateMachine = authStateMachine
        self.taskHelper = AWSAuthTaskHelper(stateMachineToken: self.stateListenerToken, authStateMachine: authStateMachine)
    }

    func execute() async throws {
        await taskHelper.didStateMachineConfigured()
        let accessToken = try await taskHelper.getAccessToken()
        try await deleteUser(with: accessToken)
    }

    private func deleteUser(with token: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            stateListenerToken = authStateMachine.listen({ [weak self] state in
                guard let self = self else { return }

                guard case .configured(let authNState, _) = state else {
                    let error = AuthError.invalidState("Auth state should be in configured state and authentication state should be in deleting user state", AuthPluginErrorConstants.invalidStateError, nil)
                    continuation.resume(throwing: error)
                    return
                }

                guard case .deletingUser(_, let deleteUserState) = authNState else {
                    return
                }

                switch deleteUserState {
                case .userDeleted:
                    self.cancelToken()
                    continuation.resume()
                case .error(let error):
                    self.cancelToken()
                    continuation.resume(throwing: error)
                default:
                    break
                }

            }, onSubscribe: { [weak self] in
                let deleteUserEvent = DeleteUserEvent(eventType: .deleteUser(token))
                self?.authStateMachine.send(deleteUserEvent)
            })
        }
    }

    private func cancelToken() {
        if let token = stateListenerToken {
            authStateMachine.cancel(listenerToken: token)
        }
    }
}
