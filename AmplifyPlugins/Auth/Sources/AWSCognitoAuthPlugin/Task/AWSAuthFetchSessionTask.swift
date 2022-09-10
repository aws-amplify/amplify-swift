//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

class AWSAuthFetchSessionTask: AuthFetchSessionTask {
    private let request: AuthFetchSessionRequest
    private let authStateMachine: AuthStateMachine
    private let fetchAuthSessionHelper: FetchAuthSessionOperationHelper
    private let taskHelper: AWSAuthTaskHelper

    var eventName: HubPayloadEventName {
        HubPayload.EventName.Auth.fetchSessionAPI
    }

    init(_ request: AuthFetchSessionRequest, authStateMachine: AuthStateMachine) {
        self.request = request
        self.authStateMachine = authStateMachine
        self.fetchAuthSessionHelper = FetchAuthSessionOperationHelper()
        self.taskHelper = AWSAuthTaskHelper(authStateMachine: authStateMachine)
    }

    func execute() async throws -> AuthSession {
        await taskHelper.didStateMachineConfigured()
        let doesNeedForceRefresh = request.options.forceRefresh
        return try await fetchAuthSessionHelper.fetch(authStateMachine,
                                                      forceRefresh: doesNeedForceRefresh)
    }
}
