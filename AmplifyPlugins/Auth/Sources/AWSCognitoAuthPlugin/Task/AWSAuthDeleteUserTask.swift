//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPluginsCore

class AWSAuthDeleteUserTask: AuthDeleteUserTask, DefaultLogger {
    private let authStateMachine: AuthStateMachine
    private let taskHelper: AWSAuthTaskHelper
    private let configuration: AuthConfiguration

    var eventName: HubPayloadEventName {
        HubPayload.EventName.Auth.deleteUserAPI
    }

    init(authStateMachine: AuthStateMachine,
         authConfiguraiton: AuthConfiguration) {
        self.authStateMachine = authStateMachine
        self.configuration = authConfiguraiton
        self.taskHelper = AWSAuthTaskHelper(authStateMachine: authStateMachine)
    }

    func execute() async throws {
        log.verbose("Starting execution")
        await taskHelper.didStateMachineConfigured()
        let accessToken = try await taskHelper.getAccessToken()

        do {
            try await deleteUser(with: accessToken)
            log.verbose("Received Success")
        } catch {
            log.verbose("Delete user failed, reconfiguring auth state. \(error)")
            await waitForReConfigure()
            await signOutIfUserWasNotFound(with: error)
            throw error
        }
    }

    private func deleteUser(with token: String) async throws {
        let stateSequences = await authStateMachine.listen()
        let deleteUserEvent = DeleteUserEvent(eventType: .deleteUser(token))
        await authStateMachine.send(deleteUserEvent)
        log.verbose("Waiting for delete user to complete")
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
                return
            case .error(let error):
                throw error
            default:
                continue
            }
        }
    }

    private func signOutIfUserWasNotFound(with error: Error) async {
        guard case AuthError.service(_, _, let underlyingError) = error,
              case .userNotFound = (underlyingError as? AWSCognitoAuthError) else {
            return
        }
        log.verbose("User not found, signing out")
        let signOutData = SignOutEventData(globalSignOut: true)
        let event = AuthenticationEvent(eventType: .signOutRequested(signOutData))
        await authStateMachine.send(event)
        _ = await taskHelper.didSignOut()
    }

    private func waitForReConfigure() async {

        let event = AuthEvent(eventType: .reconfigure(configuration))
        await authStateMachine.send(event)
        await taskHelper.didStateMachineConfigured()
    }
    
    public static var log: Logger {
        Amplify.Logging.logger(forCategory: CategoryType.auth.displayName)
    }
    public var log: Logger {
        Self.log
    }
}
