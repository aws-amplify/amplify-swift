//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

protocol AuthClearFederationToIdentityPoolTask: AmplifyAuthTask where Request == AuthClearFederationToIdentityPoolRequest,
                                                                      Success == Void,
                                                                      Failure == AuthError {}

public extension HubPayload.EventName.Auth {

    /// eventName for HubPayloads emitted by this operation
    static let clearedFederationToIdentityPoolAPI = "Auth.federationToIdentityPoolCleared"
}

/// - Note: `final` and `@unchecked Sendable`: the task is constructed, run once, and discarded.
public final class AWSAuthClearFederationToIdentityPoolTask: AuthClearFederationToIdentityPoolTask,
                                                             DefaultLogger,
                                                             @unchecked Sendable {
    private let authStateMachine: AuthStateMachine
    private let clearFederationHelper: ClearFederationOperationHelper
    private let taskHelper: AWSAuthTaskHelper

    public var eventName: HubPayloadEventName {
        HubPayload.EventName.Auth.clearedFederationToIdentityPoolAPI
    }

    init(_ request: AuthClearFederationToIdentityPoolRequest, authStateMachine: AuthStateMachine) {
        self.authStateMachine = authStateMachine
        self.clearFederationHelper = ClearFederationOperationHelper()
        self.taskHelper = AWSAuthTaskHelper(authStateMachine: authStateMachine)
    }

    public func execute() async throws {
        await taskHelper.didStateMachineConfigured()
        try await clearFederationHelper.clearFederation(authStateMachine)
        log.verbose("Cleared federation")
        return
    }

}
