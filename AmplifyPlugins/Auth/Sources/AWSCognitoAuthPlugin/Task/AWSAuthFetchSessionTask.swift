//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

class AWSAuthFetchSessionTask: AuthFetchSessionTask, DefaultLogger {
    private let request: AuthFetchSessionRequest
    private let authStateMachine: AuthStateMachine
    private let fetchAuthSessionHelper: FetchAuthSessionOperationHelper
    private let taskHelper: AWSAuthTaskHelper
    private let configuration: AuthConfiguration
    private let forceReconfigure: Bool

    var eventName: HubPayloadEventName {
        HubPayload.EventName.Auth.fetchSessionAPI
    }

    init(
        _ request: AuthFetchSessionRequest,
        authStateMachine: AuthStateMachine,
        configuration: AuthConfiguration,
        environment: Environment,
        forceReconfigure: Bool = false
    ) {
        self.request = request
        self.authStateMachine = authStateMachine
        self.fetchAuthSessionHelper = FetchAuthSessionOperationHelper()
        self.fetchAuthSessionHelper.environment = environment
        self.taskHelper = AWSAuthTaskHelper(authStateMachine: authStateMachine)
        self.configuration = configuration
        self.forceReconfigure = forceReconfigure
    }

    func execute() async throws -> AuthSession {
        log.verbose("Starting execution")
        if forceReconfigure {
            log.verbose("Reconfiguring auth state machine for keychain sharing")
            let event = AuthEvent(eventType: .reconfigure(configuration))
            await authStateMachine.send(event)
        }
        await taskHelper.didStateMachineConfigured()
        let doesNeedForceRefresh = request.options.forceRefresh
        return try await fetchAuthSessionHelper.fetch(authStateMachine,
                                                      forceRefresh: doesNeedForceRefresh)
    }

}
